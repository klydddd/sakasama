/// Supabase project configuration.
///
/// Replace the placeholder values with your actual Supabase project
/// credentials from: Supabase Dashboard → Settings → API.
class SupabaseConfig {
  SupabaseConfig._();

  /// Your Supabase project URL.
  /// Example: 'https://xyzcompany.supabase.co'
  static const String url = 'https://mjhnnyrfisbtfwinufgc.supabase.co';

  /// Your Supabase anon (public) key.
  /// This is safe to embed in client apps — RLS policies protect data.
  static const String anonKey =
      'sb_publishable_HNt9jid81Mg6p7LGjOoUNQ_DF5nzihN';
}
