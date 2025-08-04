import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_config.dart';

class AuthTokenResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  AuthTokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) {
    return AuthTokenResponse(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
      expiresIn: json['expires_in'] is int ? json['expires_in'] : 3600,
    );
  }
}

class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  AuthService(this._dio) : _secureStorage = const FlutterSecureStorage();

  Future<AuthTokenResponse> iniciarSesion(String email, String password) async {
    try {
      final formData = {
        'grant_type': 'password',
        'client_id': ApiConfig.oauthClientId,
        'client_secret': ApiConfig.oauthClientSecret,
        'username': email,
        'password': password,
      };

      final response = await _dio.post(
        ApiConfig.oauthToken,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          validateStatus: (status) => status! < 600,
        ),
      );

      if (response.statusCode == 200) {
        final tokenResponse = AuthTokenResponse.fromJson(response.data);
        await _secureStorage.write(
          key: 'access_token',
          value: tokenResponse.accessToken,
        );
        await _secureStorage.write(
          key: 'refresh_token',
          value: tokenResponse.refreshToken,
        );
        return tokenResponse;
      } else {
        throw Exception('Error en autenticación: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          final message = errorData['message']?.toString() ?? '';
          if (message.contains('confirma tu correo electrónico')) {
            throw Exception('Por favor, confirma tu correo electrónico antes de iniciar sesión. Revisa tu bandeja de entrada.');
          } else if (message.contains('Credenciales inválidas')) {
            throw Exception('Credenciales inválidas. Verifica tu email y contraseña.');
          } else {
            throw Exception('Error de autenticación: $message');
          }
        } else {
          throw Exception('Error de autenticación: Credenciales inválidas');
        }
      } else if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          final message = errorData['message']?.toString() ?? '';
          if (message.contains('invalid_client')) {
            throw Exception('Error de configuración del cliente OAuth2. Contacta al administrador.');
          }
        }
      }

      throw Exception('Error en autenticación: ${e.response?.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null;
  }

  Future<void> cerrarSesion() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }

  Future<AuthTokenResponse?> refrescarToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) {
        return null;
      }

      const String clientId = 'capbox_mobile_app_prod';
      const String clientSecret = 'UN_SECRETO_DE_PRODUCCION_MUY_LARGO_Y_SEGURO';

      final response = await _dio.post(
        '/identity/v1/oauth/token',
        data: {
          'grant_type': 'refresh_token',
          'client_id': clientId,
          'client_secret': clientSecret,
          'refresh_token': refreshToken,
        },
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.statusCode == 200) {
        final tokenResponse = AuthTokenResponse.fromJson(response.data);
        await _secureStorage.write(
          key: 'access_token',
          value: tokenResponse.accessToken,
        );
        await _secureStorage.write(
          key: 'refresh_token',
          value: tokenResponse.refreshToken,
        );
        return tokenResponse;
      }
      return null;
    } on DioException catch (e) {
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isUserConfirmed(String email, String password) async {
    try {
      const String clientId = 'capbox_mobile_app_prod';
      const String clientSecret = 'UN_SECRETO_DE_PRODUCCION_MUY_LARGO_Y_SEGURO';

      final response = await _dio.post(
        '/identity/v1/oauth/token',
        data: {
          'grant_type': 'password',
          'client_id': clientId,
          'client_secret': clientSecret,
          'username': email,
          'password': password,
        },
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          final message = errorData['message']?.toString() ?? '';
          return !message.contains('confirma tu correo electrónico');
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, String>>> getUserAttributes() async {
    try {
      final token = await getAccessToken();
      if (token == null) return [];

      final response = await _dio.get(
        '/identity/v1/usuarios/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final userData = response.data as Map<String, dynamic>;
        final attributes = <Map<String, String>>[];

        if (userData.containsKey('email')) {
          attributes.add({'name': 'email', 'value': userData['email'].toString()});
        }
        if (userData.containsKey('nombre')) {
          attributes.add({'name': 'name', 'value': userData['nombre'].toString()});
        }
        if (userData.containsKey('rol')) {
          attributes.add({'name': 'custom:role', 'value': userData['rol'].toString()});
        }

        return attributes;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final token = await getAccessToken();
      if (token == null) return null;

      final response = await _dio.get(
        '/identity/v1/usuarios/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final userData = response.data as Map<String, dynamic>;
        return userData;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isSignedIn() async {
    return await isAuthenticated();
  }

  Future<Map<String, dynamic>?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await iniciarSesion(email, password);
      return {
        'accessToken': result.accessToken,
        'refreshToken': result.refreshToken,
        'expiresIn': result.expiresIn,
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await cerrarSesion();
  }

  Future<Map<String, dynamic>?> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? gymKey,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'nombre': fullName,
          'rol': role,
          'claveGym': gymKey,
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Usuario registrado exitosamente'};
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> confirmSignUp({
    required String email,
    required String confirmationCode,
  }) async {
    try {
      final response = await _dio.post(
        '/identity/v1/auth/confirm-email',
        data: {
          'token': confirmationCode,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status! < 600,
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resendSignUpCode(String email) async {
    try {
      return true;
    } catch (e) {
      return false;
    }
  }
}