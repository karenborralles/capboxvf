import 'package:dio/dio.dart';
import '../../../../core/api/api_config.dart';
import '../dtos/oauth_token_request_dto.dart';
import '../dtos/oauth_token_response_dto.dart';
import '../dtos/register_request_dto.dart';
import '../dtos/user_profile_dto.dart';
import '../dtos/confirm_email_dto.dart';
import 'dart:convert';

class AuthApiClient {
  final Dio _dio;

  AuthApiClient(this._dio);

  String generateTestEmail() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'test.$timestamp@example.com';
  }

  Future<OAuthTokenResponseDto> login(OAuthTokenRequestDto dto) async {
    final response = await _dio.post(
      ApiConfig.getIdentidadUrl(ApiConfig.oauthToken),
      data: dto.toJson(),
    );
    return OAuthTokenResponseDto.fromJson(response.data);
  }

  Future<RegisterResponseDto> register(RegisterRequestDto dto) async {
    try {
      print('AUTH API: Intentando registro con email: ${dto.email}');

      final jsonData = dto.toJson();
      print('AUTH API: Datos enviados (raw): $jsonData');

      final jsonString = jsonData.toString();
      print('AUTH API: JSON string: $jsonString');

      final response = await _dio.post(
        ApiConfig.getIdentidadUrl(ApiConfig.register),
        data: jsonData,
        options: Options(
          headers: ApiConfig.defaultHeaders,
          validateStatus: (status) => status! < 600,
        ),
      );

      print('AUTH API: Registro exitoso');
      return RegisterResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      print('AUTH API: Error en registro - ${e.message}');
      print('AUTH API: Status code: ${e.response?.statusCode}');

      if (e.response?.data != null) {
        print('AUTH API: Error detallado del backend:');
        print(e.response!.data);

        final errorData = e.response!.data;
        String errorMessage = 'Error desconocido';

        if (errorData is Map<String, dynamic>) {
          if (errorData.containsKey('message')) {
            if (errorData['message'] is List) {
              errorMessage = errorData['message'].join(', ');
            } else {
              errorMessage = errorData['message'].toString();
            }
          } else if (errorData.containsKey('error')) {
            errorMessage = errorData['error'].toString();
          } else {
            errorMessage = errorData.toString();
          }
        } else if (errorData is String) {
          errorMessage = errorData;
        } else if (errorData is List) {
          errorMessage = errorData.join(', ');
        }

        print('AUTH API: Mensaje de error procesado: $errorMessage');

        throw Exception(errorMessage);
      }

      if (e.response?.statusCode == 500) {
        throw Exception(
          'Error del servidor (500): El backend está fallando. Contacta al administrador.',
        );
      } else if (e.response?.statusCode == 400) {
        throw Exception(
          'Datos inválidos: Verifica que todos los campos sean correctos.',
        );
      } else if (e.response?.statusCode == 422) {
        throw Exception(
          'Este correo electrónico ya está registrado. Por favor, intenta con otro.',
        );
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      print('AUTH API: Error inesperado - $e');
      throw Exception('Error inesperado: $e');
    }
  }

  Future<void> testCompleteRegistrationFlow() async {
    try {
      final testEmail = generateTestEmail();
      print('AUTH API: Probando registro con email único: $testEmail');

      final testDto = RegisterRequestDto(
        email: testEmail,
        password: 'test123456',
        nombre: 'Usuario de Prueba',
        rol: RolUsuario.Atleta,
      );

      final response = await register(testDto);

      print('AUTH API: Registro exitoso!');
      print('AUTH API: Email registrado: ${response.data.email}');
      print('AUTH API: ID del usuario: ${response.data.id}');
      print(
        'AUTH API: Revisa la bandeja de entrada de $testEmail para el email de confirmación',
      );
    } catch (e) {
      print('AUTH API: Error en flujo de prueba - $e');
      rethrow;
    }
  }

  Future<UserProfileDto> getUserProfile(String token) async {
    final response = await _dio.get(
      ApiConfig.getIdentidadUrl(ApiConfig.userProfile),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return UserProfileDto.fromJson(response.data);
  }

  Future<OAuthTokenResponseDto> refreshToken(String refreshToken) async {
    final response = await _dio.post(
      ApiConfig.getIdentidadUrl(ApiConfig.oauthToken),
      data: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': ApiConfig.oauthClientId,
        'client_secret': ApiConfig.oauthClientSecret,
      },
    );
    return OAuthTokenResponseDto.fromJson(response.data);
  }

  Future<List<Map<String, dynamic>>> getPendingRequests(String token) async {
    final response = await _dio.get(
      ApiConfig.getIdentidadUrl(ApiConfig.pendingRequests),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> approveAthlete(
    String athleteId,
    String token,
  ) async {
    final response = await _dio.post(
      ApiConfig.getIdentidadUrl(ApiConfig.approveAthlete(athleteId)),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<List<Map<String, dynamic>>> getGymMembers(
    String gymId,
    String token,
  ) async {
    final response = await _dio.get(
      ApiConfig.getIdentidadUrl(ApiConfig.gymMembersByGym(gymId)),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> testDiagnosis() async {
    final testEmail = generateTestEmail();
    final testPassword = 'test123456';

    print('AUTH API: Iniciando prueba de diagnóstico...');
    print('AUTH API: Email de prueba: $testEmail');
    print('AUTH API: Password de prueba: $testPassword');

    await diagnoseRegistrationFlow(testEmail, testPassword);
  }

  Future<void> diagnoseRegistrationFlow(String email, String password) async {
    try {
      print('AUTH API: === DIAGNÓSTICO COMPLETO ===');
      print('AUTH API: Email: $email');
      print('AUTH API: Password: $password');

      print('\nAUTH API: PASO 1: Verificando si usuario existe...');
      final confirmationStatus = await checkUserConfirmationStatus(
        email,
        password,
      );
      print('AUTH API: Estado de confirmación: $confirmationStatus');

      print('\nAUTH API: PASO 2: Intentando registro...');
      try {
        final testDto = RegisterRequestDto(
          email: email,
          password: password,
          nombre: 'Usuario de Prueba',
          rol: RolUsuario.Atleta,
        );

        final registerResponse = await register(testDto);
        print('Registro exitoso: ${registerResponse.data.email}');
        print('Email registrado: ${registerResponse.data.email}');
        print('ID del usuario: ${registerResponse.data.id}');
        print(
          'Revisa la bandeja de entrada de $email para el email de confirmación',
        );
      } catch (e) {
        print('Error en registro: $e');
        if (e.toString().contains('ya está registrado')) {
          print('El usuario ya existe, continuando con verificación...');
        }
      }

      print('\nAUTH API: PASO 3: Verificando estado después del registro...');
      final statusAfterRegister = await checkUserConfirmationStatus(
        email,
        password,
      );
      print('AUTH API: Estado después del registro: $statusAfterRegister');

      print('\nAUTH API: PASO 4: Intentando login real...');
      try {
        const String clientId = 'capbox_mobile_app_prod';
        const String clientSecret =
            'UN_SECRETO_DE_PRODUCCION_MUY_LARGO_Y_SEGURO';

        final loginResponse = await _dio.post(
          ApiConfig.getIdentidadUrl(ApiConfig.oauthToken),
          data: {
            'grant_type': 'password',
            'client_id': clientId,
            'client_secret': clientSecret,
            'username': email,
            'password': password,
          },
          options: Options(
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            validateStatus: (status) => status! < 600,
          ),
        );

        if (loginResponse.statusCode == 200) {
          print('Login exitoso!');
          print(
            'Access Token: ${loginResponse.data['access_token']?.toString().substring(0, 20)}...',
          );
          print(
            'Refresh Token: ${loginResponse.data['refresh_token']?.toString().substring(0, 20)}...',
          );
        } else {
          print('Login fallido');
          print('Status: ${loginResponse.statusCode}');
          print('Mensaje: ${loginResponse.data}');
        }
      } catch (e) {
        print('Error en login: $e');
      }

      print('\nAUTH API: === FIN DEL DIAGNÓSTICO ===');
    } catch (e) {
      print('AUTH API: Error en diagnóstico - $e');
    }
  }

  Future<Map<String, dynamic>> checkUserConfirmationStatus(
    String email,
    String password,
  ) async {
    try {
      print('AUTH API: Verificando estado de confirmación para: $email');

      const String clientId = 'capbox_mobile_app_prod';
      const String clientSecret = 'UN_SECRETO_DE_PRODUCCION_MUY_LARGO_Y_SEGURO';

      final response = await _dio.post(
        ApiConfig.getIdentidadUrl(ApiConfig.oauthToken),
        data: {
          'grant_type': 'password',
          'client_id': clientId,
          'client_secret': clientSecret,
          'username': email,
          'password': password,
        },
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          validateStatus: (status) => status! < 600,
        ),
      );

      if (response.statusCode == 200) {
        print('AUTH API: Usuario confirmado y puede autenticarse');
        return {
          'confirmed': true,
          'message': 'Usuario confirmado',
          'statusCode': response.statusCode,
        };
      } else {
        print('AUTH API: Usuario no confirmado o credenciales incorrectas');
        return {
          'confirmed': false,
          'message': response.data['message'] ?? 'Usuario no confirmado',
          'statusCode': response.statusCode,
        };
      }
    } on DioException catch (e) {
      print('AUTH API: Error verificando confirmación - ${e.message}');

      if (e.response?.data != null) {
        final errorData = e.response!.data;
        String message = 'Error desconocido';

        if (errorData is Map<String, dynamic>) {
          message =
              errorData['message'] ??
              errorData['error'] ??
              'Error del servidor';
        } else if (errorData is String) {
          message = errorData;
        }

        return {
          'confirmed': false,
          'message': message,
          'statusCode': e.response?.statusCode ?? 500,
        };
      }

      return {
        'confirmed': false,
        'message': 'Error de conexión',
        'statusCode': 500,
      };
    } catch (e) {
      print('AUTH API: Error inesperado verificando confirmación - $e');
      return {
        'confirmed': false,
        'message': 'Error inesperado: $e',
        'statusCode': 500,
      };
    }
  }

  Future<void> testEmailConfirmation(String email, String token) async {
    try {
      print('AUTH API: === PRUEBA DE CONFIRMACIÓN DE EMAIL ===');
      print('AUTH API: Email: $email');
      print('AUTH API: Token: $token');

      print('\nAUTH API: PASO 1: Confirmando email...');
      try {
        final confirmDto = ConfirmEmailRequestDto(token: token);
        final confirmResponse = await confirmEmail(confirmDto);
        print('Confirmación exitosa: ${confirmResponse.message}');
      } catch (e) {
        print('Error en confirmación: $e');
      }

      print('\nAUTH API: PASO 2: Verificando estado después de confirmación...');
      print(
        'Para verificar el estado, necesitas proporcionar la contraseña del usuario',
      );

      print('\nAUTH API: === FIN DE PRUEBA DE CONFIRMACIÓN ===');
    } catch (e) {
      print('AUTH API: Error en prueba de confirmación - $e');
    }
  }

  Future<void> testJwtExtraction() async {
    try {
      print('AUTH API: === PRUEBA EXTRACCIÓN JWT ===');

      const String email = 'amizadayguapo@gmail.com';
      const String password = 'Arturo2004!';

      print('AUTH API: PASO 1: Haciendo login para obtener token...');
      const String clientId = 'capbox_mobile_app_prod';
      const String clientSecret = 'UN_SECRETO_DE_PRODUCCION_MUY_LARGO_Y_SEGURO';

      final loginResponse = await _dio.post(
        ApiConfig.getIdentidadUrl(ApiConfig.oauthToken),
        data: {
          'grant_type': 'password',
          'client_id': clientId,
          'client_secret': clientSecret,
          'username': email,
          'password': password,
        },
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          validateStatus: (status) => status! < 600,
        ),
      );

      if (loginResponse.statusCode == 200) {
        final accessToken = loginResponse.data['access_token'];
        print('AUTH API: Login exitoso, token obtenido');
        print('AUTH API: Token: ${accessToken.substring(0, 50)}...');

        print('\nAUTH API: PASO 2: Probando extracción de información del JWT...');

        final parts = accessToken.split('.');
        if (parts.length != 3) {
          print('Token JWT inválido');
          return;
        }

        final payload = parts[1];
        final paddingLength = ((4 - payload.length % 4) % 4).toInt();
        final paddedPayload = payload + '=' * paddingLength;

        try {
          final decodedBytes = base64Url.decode(paddedPayload);
          final decodedString = utf8.decode(decodedBytes);
          final payloadData =
              json.decode(decodedString) as Map<String, dynamic>;

          print('Extracción JWT exitosa');
          print('Payload del token: $payloadData');

          if (payloadData.containsKey('email')) {
            print('Email: ${payloadData['email']}');
          }
          if (payloadData.containsKey('rol')) {
            print('Rol: ${payloadData['rol']}');
          }
          if (payloadData.containsKey('sub')) {
            print('ID: ${payloadData['sub']}');
          }
        } catch (e) {
          print('Error decodificando JWT - $e');
        }
      } else {
        print('Login fallido');
        print('Status: ${loginResponse.statusCode}');
        print('Respuesta: ${loginResponse.data}');
      }

      print('\nAUTH API: === FIN PRUEBA EXTRACCIÓN JWT ===');
    } catch (e) {
      print('AUTH API: Error en prueba de extracción JWT - $e');
    }
  }

  Future<void> testUsersMeEndpoint() async {
    try {
      print('AUTH API: === PRUEBA ENDPOINT /usuarios/me ===');

      const String email = 'amizadayguapo@gmail.com';
      const String password = 'Arturo2004!';

      print('AUTH API: PASO 1: Haciendo login para obtener token...');
      const String clientId = 'capbox_mobile_app_prod';
      const String clientSecret = 'UN_SECRETO_DE_PRODUCCION_MUY_LARGO_Y_SEGURO';

      final loginResponse = await _dio.post(
        ApiConfig.getIdentidadUrl(ApiConfig.oauthToken),
        data: {
          'grant_type': 'password',
          'client_id': clientId,
          'client_secret': clientSecret,
          'username': email,
          'password': password,
        },
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          validateStatus: (status) => status! < 600,
        ),
      );

      if (loginResponse.statusCode == 200) {
        final accessToken = loginResponse.data['access_token'];
        print('AUTH API: Login exitoso, token obtenido');

        print('\nAUTH API: PASO 2: Probando endpoint /identity/v1/usuarios/me...');
        final userResponse = await _dio.get(
          '${ApiConfig.baseUrl}/identity/v1/usuarios/me',
          options: Options(
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            validateStatus: (status) => status! < 600,
          ),
        );

        if (userResponse.statusCode == 200) {
          print('AUTH API: Endpoint /identity/v1/usuarios/me funciona correctamente');
          print('AUTH API: Datos del usuario: ${userResponse.data}');
        } else {
          print('AUTH API: Endpoint /identity/v1/usuarios/me falló');
          print('AUTH API: Status: ${userResponse.statusCode}');
          print('AUTH API: Respuesta: ${userResponse.data}');
        }
      } else {
        print('AUTH API: Login fallido');
        print('AUTH API: Status: ${loginResponse.statusCode}');
        print('AUTH API: Respuesta: ${loginResponse.data}');
      }

      print('\nAUTH API: === FIN PRUEBA ENDPOINT /usuarios/me ===');
    } catch (e) {
      print('AUTH API: Error en prueba de endpoint - $e');
    }
  }

  Future<void> testArturoCase() async {
    try {
      print('AUTH API: === PRUEBA CASO ARTURO ===');

      const String email = 'mr.arturolongo@gmail.com';
      const String password = 'Arturo2004!';
      const String confirmationCode = '198190';

      print('AUTH API: Email: $email');
      print('AUTH API: Password: $password');
      print('AUTH API: Código de confirmación: $confirmationCode');

      print('\nAUTH API: PASO 1: Estado actual...');
      final currentStatus = await checkUserConfirmationStatus(email, password);
      print('AUTH API: Estado actual: $currentStatus');

      print('\nAUTH API: PASO 2: Confirmando con código...');
      try {
        final confirmDto = ConfirmEmailRequestDto(token: confirmationCode);
        final confirmResponse = await confirmEmail(confirmDto);
        print('Confirmación exitosa: ${confirmResponse.message}');
      } catch (e) {
        print('Error en confirmación: $e');
      }

      print('\nAUTH API: PASO 3: Estado después de confirmación...');
      final statusAfterConfirm = await checkUserConfirmationStatus(
        email,
        password,
      );
      print('AUTH API: Estado después de confirmación: $statusAfterConfirm');

      print('\nAUTH API: PASO 4: Intentando login...');
      try {
        const String clientId = 'capbox_mobile_app_prod';
        const String clientSecret =
            'UN_SECRETO_DE_PRODUCCION_MUY_LARGO_Y_SEGURO';

        final loginResponse = await _dio.post(
          ApiConfig.getIdentidadUrl(ApiConfig.oauthToken),
          data: {
            'grant_type': 'password',
            'client_id': clientId,
            'client_secret': clientSecret,
            'username': email,
            'password': password,
          },
          options: Options(
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            validateStatus: (status) => status! < 600,
          ),
        );

        if (loginResponse.statusCode == 200) {
          print('Login exitoso!');
          print(
            'Access Token: ${loginResponse.data['access_token']?.toString().substring(0, 20)}...',
          );
          print(
            'Refresh Token: ${loginResponse.data['refresh_token']?.toString().substring(0, 20)}...',
          );
        } else {
          print('Login fallido');
          print('Status: ${loginResponse.statusCode}');
          print('Mensaje: ${loginResponse.data}');
        }
      } catch (e) {
        print('Error en login: $e');
      }

      print('\nAUTH API: === FIN PRUEBA CASO ARTURO ===');
    } catch (e) {
      print('AUTH API: Error en prueba de Arturo - $e');
    }
  }

  Future<void> testCompleteFlowWithConfirmation(
    String email,
    String password,
    String token,
  ) async {
    try {
      print('AUTH API: === FLUJO COMPLETO CON CONFIRMACIÓN ===');
      print('AUTH API: Email: $email');
      print('AUTH API: Password: $password');
      print('AUTH API: Token: $token');

      print('\nAUTH API: PASO 1: Estado inicial...');
      final initialStatus = await checkUserConfirmationStatus(email, password);
      print('AUTH API: Estado inicial: $initialStatus');

      print('\nAUTH API: PASO 2: Confirmando email...');
      try {
        final confirmDto = ConfirmEmailRequestDto(token: token);
        final confirmResponse = await confirmEmail(confirmDto);
        print('Confirmación exitosa: ${confirmResponse.message}');
      } catch (e) {
        print('Error en confirmación: $e');
        return;
      }

      print('\nAUTH API: PASO 3: Estado después de confirmación...');
      final statusAfterConfirm = await checkUserConfirmationStatus(
        email,
        password,
      );
      print('AUTH API: Estado después de confirmación: $statusAfterConfirm');

      print('\nAUTH API: PASO 4: Intentando login...');
      try {
        const String clientId = 'capbox_mobile_app_prod';
        const String clientSecret =
            'UN_SECRETO_DE_PRODUCCION_MUY_LARGO_Y_SEGURO';

        final loginResponse = await _dio.post(
          ApiConfig.getIdentidadUrl(ApiConfig.oauthToken),
          data: {
            'grant_type': 'password',
            'client_id': clientId,
            'client_secret': clientSecret,
            'username': email,
            'password': password,
          },
          options: Options(
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            validateStatus: (status) => status! < 600,
          ),
        );

        if (loginResponse.statusCode == 200) {
          print('Login exitoso después de confirmación!');
          print(
            'Access Token: ${loginResponse.data['access_token']?.toString().substring(0, 20)}...',
          );
          print(
            'Refresh Token: ${loginResponse.data['refresh_token']?.toString().substring(0, 20)}...',
          );
        } else {
          print('Login fallido después de confirmación');
          print('Status: ${loginResponse.statusCode}');
          print('Mensaje: ${loginResponse.data}');
        }
      } catch (e) {
        print('Error en login después de confirmación: $e');
      }

      print('\nAUTH API: === FIN DEL FLUJO COMPLETO ===');
    } catch (e) {
      print('AUTH API: Error en flujo completo - $e');
    }
  }

  Future<ConfirmEmailResponseDto> confirmEmail(
    ConfirmEmailRequestDto dto,
  ) async {
    try {
      print('AUTH API: Confirmando email con token');

      final response = await _dio.post(
        ApiConfig.getIdentidadUrl(ApiConfig.confirmEmail),
        data: dto.toJson(),
        options: Options(headers: ApiConfig.defaultHeaders),
      );

      print('AUTH API: Email confirmado exitosamente');
      return ConfirmEmailResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      print('AUTH API: Error confirmando email - ${e.message}');
      print('AUTH API: Status code: ${e.response?.statusCode}');

      if (e.response?.data != null) {
        print('AUTH API: Error detallado del backend:');
        print(e.response!.data);

        final errorData = e.response!.data;
        String errorMessage = 'Error desconocido';

        if (errorData is Map<String, dynamic>) {
          errorMessage =
              errorData['message'] ??
              errorData['error'] ??
              'Error del servidor';
        } else if (errorData is String) {
          errorMessage = errorData;
        }

        throw Exception(errorMessage);
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Token de confirmación inválido o expirado.');
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      print('AUTH API: Error inesperado - $e');
      throw Exception('Error inesperado: $e');
    }
  }
}