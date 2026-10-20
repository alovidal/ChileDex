class ApiConfig {
  // URL del backend desplegado en Vercel.
  // IMPORTANTE: sin "/" al final, porque los servicios agregan
  // rutas como '/usuarios/login' y quedaría '//usuarios/login'.
  static const String baseUrl = 'https://chiledex-backend-n6ru.vercel.app';

  // URL local para desarrollo con emulador Android (opcional).
  static const String baseUrlLocal = 'http://10.0.2.2:8000';
}