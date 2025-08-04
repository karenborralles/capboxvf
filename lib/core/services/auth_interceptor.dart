import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;

  AuthInterceptor() : _secureStorage = const FlutterSecureStorage();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      print('AUTH INTERCEPTOR: Procesando petición a ${options.uri}');

      if (_isPublicEndpoint(options.path)) {
        print('AUTH INTERCEPTOR: Endpoint público - sin token requerido');
        return super.onRequest(options, handler);
      }

      final accessToken = await _secureStorage.read(key: 'access_token');

      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
        print('AUTH INTERCEPTOR: Token agregado a la petición');
        print('AUTH INTERCEPTOR: Token: ${accessToken.substring(0, 50)}...');
        print('AUTH INTERCEPTOR: Headers: ${options.headers}');
      } else {
        print('AUTH INTERCEPTOR: No hay token disponible para endpoint privado');
        print('AUTH INTERCEPTOR: Endpoint requiere autenticación pero no hay token');
      }

      return super.onRequest(options, handler);
    } catch (e) {
      print('AUTH INTERCEPTOR: Error procesando petición - $e');
      return super.onRequest(options, handler);
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('AUTH INTERCEPTOR: Respuesta exitosa ${response.statusCode}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('AUTH INTERCEPTOR: Error ${err.response?.statusCode}');

    if (err.response?.statusCode == 401) {
      print('AUTH INTERCEPTOR: Token expirado o inválido - usuario debe reautenticarse');
    }

    super.onError(err, handler);
  }

  bool _isPublicEndpoint(String path) {
    final publicEndpoints = [
      '/auth/register',
      '/oauth/token',
      '/auth/forgot-password',
      '/auth/reset-password',
      '/health',
    ];

    return publicEndpoints.any((endpoint) => path.contains(endpoint));
  }
}