class EnvConfig {
  static const String v2tSecretKey = String.fromEnvironment(
    'V2T_SECRET_KEY',
    defaultValue: '',
  );
  
  static const String v2tServerUrl = String.fromEnvironment(
    'V2T_SERVER_URL',
    defaultValue: 'https://yourusername.pythonanywhere.com',
  );
}
