#include <jni.h>
#include <string>
#include <vector>
#include <android/log.h>
#include "llama.h"
#include "mtmd.h"
#include "mtmd-helper.h"

#define LOG_TAG "SakasamaVlmNative"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

extern "C"
JNIEXPORT jstring JNICALL
Java_com_sakasama_sakasama_1vlm_SakasamaVlmPlugin_scanImageNative(
    JNIEnv *env,
    jobject /* this */,
    jstring j_image_path,
    jstring j_base_model_path,
    jstring j_vision_model_path,
    jstring j_prompt) {

    // 1. Convert JNI strings to std::string
    const char *image_path = env->GetStringUTFChars(j_image_path, nullptr);
    const char *base_model_path = env->GetStringUTFChars(j_base_model_path, nullptr);
    const char *vision_model_path = env->GetStringUTFChars(j_vision_model_path, nullptr);
    const char *prompt = env->GetStringUTFChars(j_prompt, nullptr);

    LOGI("Initializing GOT-OCR Native Inference...");
    
    // 2. Initialize the backend
    llama_backend_init();

    // 3. Load the Language Model
    llama_model_params model_params = llama_model_default_params();
    model_params.n_gpu_layers = 0; // CPU only for optimal RAM handling initially
    struct llama_model *text_model = llama_load_model_from_file(base_model_path, model_params);
    if (!text_model) {
        LOGE("Failed to load text model");
        return env->NewStringUTF("{\"error\": \"Failed to load text model\"}");
    }

    // 4. Create Text Context
    llama_context_params ctx_params_llama = llama_context_default_params();
    ctx_params_llama.n_ctx = 4096; // Need large context for VLM
    ctx_params_llama.n_batch = 1024;
    ctx_params_llama.n_threads = 4;
    struct llama_context *lctx = llama_new_context_with_model(text_model, ctx_params_llama);

    // 5. Initialize the Multimodal Context (mtmd + mmproj)
    struct mtmd_context_params mtmd_params = mtmd_context_params_default();
    mtmd_params.media_marker = "<__image__>";
    mtmd_context *mtmd_ctx = mtmd_init_from_file(vision_model_path, text_model, mtmd_params);
    if (!mtmd_ctx) {
        LOGE("Failed to initialize multimodal context");
        llama_free(lctx);
        llama_free_model(text_model);
        return env->NewStringUTF("{\"error\": \"Failed to load vision projector model\"}");
    }

    // 6. Build the Input Prompt & Prepare Tokens
    std::string full_prompt = std::string(prompt) + "\n<__image__>\n";
    struct mtmd_input_text input_text;
    input_text.text = full_prompt.c_str();
    input_text.add_special = true;
    input_text.parse_special = true;

    // Load Image as Bitmap
    mtmd_bitmap *bitmap = mtmd_helper_bitmap_init_from_file(mtmd_ctx, image_path);
    if (!bitmap) {
        LOGE("Failed to load image");
        return env->NewStringUTF("{\"error\": \"Failed to load image into memory\"}");
    }
    const mtmd_bitmap *bitmaps[] = {bitmap};

    // Tokenize Both
    mtmd_input_chunks *input_chunks = mtmd_input_chunks_init();
    int32_t tokenize_res = mtmd_tokenize(mtmd_ctx, input_chunks, &input_text, bitmaps, 1);
    if (tokenize_res != 0) {
        LOGE("Failed to tokenize MTMD chunks");
        return env->NewStringUTF("{\"error\": \"Failed to process visual prompt tokens\"}");
    }

    // 7. Eval visual and text chunks natively using NDK
    LOGI("Evaluating Visual and Text Tokens...");
    llama_pos n_past = 0;
    int32_t eval_res = mtmd_helper_eval_chunks(mtmd_ctx, lctx, input_chunks, n_past, 0, 1024, true, &n_past);
    if (eval_res != 0) {
        LOGE("Failed to evaluate MTMD chunks");
        return env->NewStringUTF("{\"error\": \"Failed to execute VLM inference graph\"}");
    }

    // 8. Auto-Regressive Generation Loop for the JSON string
    std::string generated_text = "";
    int n_predict = 1024; // Limit output length
    
    // Sample iterator setup
    const llama_vocab * vocab = llama_model_get_vocab(text_model);
    int n_vocab = llama_vocab_n_tokens(vocab);

    for (int i = 0; i < n_predict; i++) {
        // Get logits for the last evaluated token
        float *logits = llama_get_logits_ith(lctx, -1);
        
        // Greedy sampling for maximum determinism with receipt extraction
        llama_token best_token = 0;
        float max_logit = -1e9;
        for (int token_id = 0; token_id < n_vocab; token_id++) {
            if (logits[token_id] > max_logit) {
                max_logit = logits[token_id];
                best_token = token_id;
            }
        }

        // Check for EOS
        if (llama_vocab_is_eog(vocab, best_token)) {
            break;
        }

        // Decode token to string and append
        char token_buf[32];
        int n_chars = llama_token_to_piece(vocab, best_token, token_buf, sizeof(token_buf), 0, true);
        if (n_chars >= 0) {
            generated_text += std::string(token_buf, n_chars);
        }

        // Evaluate the generated token to continue the loop
        llama_batch batch = llama_batch_get_one(&best_token, 1);
        if (llama_decode(lctx, batch)) {
            LOGE("Failed to decode next token");
            break;
        }
        n_past++;
    }

    LOGI("Inference Complete. Extracted Text:\n%s", generated_text.c_str());

    // 9. Memory Cleanup
    mtmd_input_chunks_free(input_chunks);
    mtmd_bitmap_free(bitmap);
    mtmd_free(mtmd_ctx);
    llama_free(lctx);
    llama_free_model(text_model);
    llama_backend_free();

    env->ReleaseStringUTFChars(j_image_path, image_path);
    env->ReleaseStringUTFChars(j_base_model_path, base_model_path);
    env->ReleaseStringUTFChars(j_vision_model_path, vision_model_path);
    env->ReleaseStringUTFChars(j_prompt, prompt);

    return env->NewStringUTF(generated_text.c_str());
}
