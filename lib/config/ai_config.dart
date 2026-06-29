class AiConfig {
  const AiConfig({required this.functionUrl, required this.supabaseAnonKey});

  static const fromEnvironment = AiConfig(
    functionUrl: String.fromEnvironment('ACCESSPULSE_AI_FUNCTION_URL'),
    supabaseAnonKey: String.fromEnvironment('ACCESSPULSE_SUPABASE_ANON_KEY'),
  );

  final String functionUrl;
  final String supabaseAnonKey;

  bool get hasServerWrapper => functionUrl.trim().isNotEmpty;
}
