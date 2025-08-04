import 'package:flutter/foundation.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/aws_api_service.dart';
import '../../../../core/services/user_display_service.dart';
import '../../domain/entities/user.dart';

enum AWSLoginState { initial, loading, authenticated, unauthenticated, error }

class AWSLoginCubit extends ChangeNotifier {
  final AuthService _authService;
  final AWSApiService _apiService;

  AWSLoginState _state = AWSLoginState.initial;
  String? _errorMessage;
  User? _currentUser;

  AWSLoginCubit(this._authService, this._apiService) {
    _checkInitialAuthState();
  }

  AWSLoginState get state => _state;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  bool get isLoading => _state == AWSLoginState.loading;
  bool get isAuthenticated =>
      _state == AWSLoginState.authenticated && _currentUser != null;

  Future<void> _checkInitialAuthState() async {
    try {
      print('LOGIN: Verificando estado inicial de autenticación');

      final isSignedIn = await _authService.isSignedIn();
      if (isSignedIn) {
        print('LOGIN: Usuario ya autenticado');
        await _loadUserProfile();
      } else {
        print('LOGIN: Usuario no autenticado');
        _setState(AWSLoginState.unauthenticated);
      }
    } catch (e) {
      print('LOGIN: Error verificando estado inicial - $e');
      _setState(AWSLoginState.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    try {
      print('LOGIN: Iniciando sesión');
      print('Email: $email');

      _setState(AWSLoginState.loading);
      _clearError();

      final result = await _authService.signIn(
        email: email,
        password: password,
      );

      if (result == null) {
        return;
      }

      print('LOGIN: Autenticación exitosa en Cognito');

      await _loadUserProfile();
    } catch (e) {
      print('LOGIN: Error inesperado - $e');

      String errorMessage = e.toString();
      if (errorMessage.contains('confirma tu correo electrónico')) {
        _setError(
          'Por favor, confirma tu correo electrónico antes de iniciar sesión. Revisa tu bandeja de entrada.',
        );
      } else if (errorMessage.contains('Credenciales incorrectas')) {
        _setError('Credenciales incorrectas. Verifica tu email y contraseña.');
      } else {
        _setError('Error inesperado durante el login: $e');
      }

      _setState(AWSLoginState.error);
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      print('LOGIN: Cargando perfil de usuario desde BACKEND');

      final userProfile = await _apiService.getUserProfile();

      if (userProfile.statusCode == 200) {
        final userData = userProfile.data as Map<String, dynamic>;
        print('LOGIN: Perfil cargado desde backend exitosamente');
        print('LOGIN: Datos del perfil del backend:');
        print('  - ID: ${userData['id']}');
        print('  - Email: ${userData['email']}');
        print('  - Nombre: ${userData['nombre']}');
        print('  - Rol: ${userData['rol']}');
        print('  - Gimnasio: ${userData['gimnasio']}');

        _currentUser = User(
          id: userData['id'],
          name: userData['nombre'],
          email: userData['email'],
          role: _parseRole(userData['rol']),
          createdAt: DateTime.now(),
          token: await _authService.getAccessToken() ?? '',
        );

        print('LOGIN: Usuario creado con datos del backend');
        print('Usuario: ${_currentUser!.name}');
        print('Email: ${_currentUser!.email}');
        print('Rol: ${_currentUser!.role}');
        print('LOGIN: Ruta de home calculada: ${getHomeRoute()}');
        print('LOGIN: Rol parseado: ${_currentUser!.role}');
        print('LOGIN: ¿Es coach? ${_currentUser!.role == UserRole.coach}');
        print('LOGIN: ¿Es athlete? ${_currentUser!.role == UserRole.athlete}');
        print('LOGIN: ¿Es admin? ${_currentUser!.role == UserRole.admin}');

        await autoFixCoachStatus();

        _setState(AWSLoginState.authenticated);

        print('LOGIN: Login exitoso, navegando automáticamente...');
        final homeRoute = getHomeRoute();
        print('LOGIN: Navegando a: $homeRoute');

        _navigateToHome(homeRoute);
      } else {
        print('LOGIN: No se pudo cargar el perfil desde el backend');
        throw Exception(
          'No se pudo cargar el perfil del usuario desde el backend',
        );
      }
    } catch (e) {
      print('LOGIN: Error cargando perfil desde backend - $e');
      _setError('Error cargando perfil de usuario: $e');
      _setState(AWSLoginState.error);
    }
  }

  Future<void> _syncWithBackend() async {
    try {
      print('LOGIN: Sincronizando con backend');

      final response = await _apiService.getUserProfile();

      print('LOGIN: Datos sincronizados con backend');
      print('Respuesta: ${response.data}');
    } catch (e) {
      print('LOGIN: Error sincronizando con backend - $e');
    }
  }

  Future<void> logout() async {
    try {
      print('LOGIN: Cerrando sesión');

      await _authService.signOut();

      _currentUser = null;
      _setState(AWSLoginState.unauthenticated);
      _clearError();

      UserDisplayService.clearGlobalCache();

      print('LOGIN: Sesión cerrada exitosamente');
    } catch (e) {
      print('LOGIN: Error cerrando sesión - $e');
      _currentUser = null;
      _setState(AWSLoginState.unauthenticated);

      UserDisplayService.clearGlobalCache();
    }
  }

  String getHomeRoute() {
    if (_currentUser == null) return '/login';

    print('LOGIN: Calculando ruta para rol: ${_currentUser!.role}');

    switch (_currentUser!.role) {
      case UserRole.athlete:
        print('LOGIN: Dirigiendo a /boxer-home');
        return '/boxer-home';
      case UserRole.coach:
        print('LOGIN: Dirigiendo a /coach-home');
        return '/coach-home';
      case UserRole.admin:
        print('LOGIN: Dirigiendo a /admin-home');
        return '/admin-home';
    }
  }

  Future<bool> needsGymKeyActivation() async {
    try {
      if (_currentUser == null) return false;

      if (_currentUser!.role == UserRole.admin) {
        print('LOGIN: Usuario es ADMIN - Gimnasio creado automáticamente');
        return false;
      }

      print(
        'LOGIN: Verificando vinculación con GET /users/me para ${_currentUser!.role}',
      );

      final response = await _apiService.getUserMe();
      final userData = response.data;

      final gimnasio = userData['gimnasio'];
      final gyms = userData['gyms'] as List?;

      final needsLink = gimnasio == null && (gyms == null || gyms.isEmpty);

      print('LOGIN: Estado gimnasio: ${gimnasio ?? "null"}');
      print('LOGIN: Lista gyms: ${gyms?.length ?? 0} elementos');
      print('LOGIN: Necesita vinculación: $needsLink');

      return needsLink;
    } catch (e) {
      print('LOGIN: Error verificando vinculación - $e');

      if (_currentUser?.role == UserRole.admin) {
        print('LOGIN: Error pero es ADMIN - NO necesita vinculación');
        return false;
      }

      print(
        'LOGIN: Error para ${_currentUser?.role} - asumir que necesita vinculación',
      );
      return true;
    }
  }

  Future<void> autoFixCoachStatus() async {
    try {
      if (_currentUser?.role != UserRole.coach) return;

      print('LOGIN: Verificando si coach necesita auto-fix...');

      final response = await _apiService.getUserMe();
      final userData = response.data;

      if (userData['estado_atleta'] == 'pendiente_datos') {
        print('LOGIN: Coach pendiente detectado, ejecutando auto-fix...');

        try {
          await _apiService.post(
            '/identity/v1/usuarios/fix-coaches-estado',
            data: {},
          );
          print('LOGIN: Auto-fix ejecutado exitosamente');
        } catch (e) {
          print('LOGIN: Auto-fix falló, pero continuando...');
        }
      }
    } catch (e) {
      print('LOGIN: Error en auto-fix - $e');
    }
  }

  Future<String> getRouteWithActivationCheck() async {
    if (_currentUser == null) return '/login';

    print('LOGIN: getRouteWithActivationCheck - Rol: ${_currentUser!.role}');

    final needsActivation = await needsGymKeyActivation();

    if (needsActivation) {
      print('LOGIN: Necesita activación - /gym-key-required');
      return '/gym-key-required';
    }

    if (_currentUser!.role == UserRole.athlete) {
      try {
        print('LOGIN: Verificando estado del atleta...');
        final response = await _apiService.getUserMe();
        final userData = response.data;
        final estadoAtleta = userData['estado_atleta'];
        final datosFisicosCapturados = userData['datos_fisicos_capturados'];

        print('LOGIN: Estado atleta: $estadoAtleta');
        print('LOGIN: Datos físicos capturados: $datosFisicosCapturados');

        if (estadoAtleta == 'pendiente_datos' ||
            datosFisicosCapturados == false) {
          print('LOGIN: Atleta en espera de datos físicos - ir a home');
          return '/boxer-home';
        }

        if (estadoAtleta == 'activo' || datosFisicosCapturados == true) {
          print('LOGIN: Atleta activo - ir a home normal');
          return '/boxer-home';
        }

        if (estadoAtleta == 'inactivo') {
          print('LOGIN: Atleta inactivo - ir a home');
          return '/boxer-home';
        }

        print('LOGIN: Estado atleta desconocido - ir a home');
        return '/boxer-home';
      } catch (e) {
        print('LOGIN: Error verificando estado del atleta - $e');
        return '/boxer-home';
      }
    }

    final homeRoute = getHomeRoute();
    print('LOGIN: Ruta calculada para ${_currentUser!.role}: $homeRoute');
    print('LOGIN: ¿Es coach? ${_currentUser!.role == UserRole.coach}');
    print('LOGIN: ¿Es athlete? ${_currentUser!.role == UserRole.athlete}');
    print('LOGIN: ¿Es admin? ${_currentUser!.role == UserRole.admin}');
    print('LOGIN: Ruta final devuelta: $homeRoute');
    return homeRoute;
  }

  Future<void> checkAuthStatus() async {
    try {
      final isSignedIn = await _authService.isSignedIn();
      if (isSignedIn && _currentUser == null) {
        await _loadUserProfile();
      } else if (!isSignedIn && _currentUser != null) {
        _currentUser = null;
        _setState(AWSLoginState.unauthenticated);
      }
    } catch (e) {
      print('LOGIN: Error verificando estado auth - $e');
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _authService.getAccessToken();
    } catch (e) {
      print('LOGIN: Error obteniendo token - $e');
      return null;
    }
  }

  void _handleLoginError(Exception e) {
    String userMessage;
    final message = e.toString().toLowerCase();

    if (message.contains('incorrect username or password')) {
      userMessage = 'Email o contraseña incorrectos.';
    } else if (message.contains('user is not confirmed')) {
      userMessage =
          'Tu cuenta no está confirmada. Revisa tu email para el código de confirmación.';
    } else if (message.contains('user does not exist')) {
      userMessage = 'No existe una cuenta con este email.';
    } else if (message.contains('password attempts exceeded')) {
      userMessage = 'Demasiados intentos fallidos. Intenta de nuevo más tarde.';
    } else {
      userMessage = 'Error de autenticación: ${e.toString()}';
    }

    _setError(userMessage);
    _setState(AWSLoginState.error);
  }

  void _navigateToHome(String route) {
    print('LOGIN: Navegando a: $route');
    print('LOGIN: Rol actual: ${_currentUser?.role}');
    print('LOGIN: ¿Es coach? ${_currentUser?.role == UserRole.coach}');
    print('LOGIN: ¿Es athlete? ${_currentUser?.role == UserRole.athlete}');
    print('LOGIN: ¿Es admin? ${_currentUser?.role == UserRole.admin}');
  }

  UserRole _parseRole(String? roleString) {
    print('LOGIN: Parseando rol: "$roleString"');
    print('LOGIN: Rol en minúsculas: "${roleString?.toLowerCase()}"');

    switch (roleString?.toLowerCase()) {
      case 'atleta':
      case 'athlete':
      case 'boxer':
      case 'boxeador':
        print('LOGIN: Rol parseado como ATHLETE');
        return UserRole.athlete;
      case 'entrenador':
      case 'coach':
      case 'trainer':
      case 'instructor':
        print('LOGIN: Rol parseado como COACH');
        return UserRole.coach;
      case 'administrador':
      case 'admin':
      case 'administrator':
        print('LOGIN: Rol parseado como ADMIN');
        return UserRole.admin;
      default:
        print('LOGIN: Rol desconocido: "$roleString" - usando default: athlete');
        print('LOGIN: Valor exacto del rol: "$roleString"');
        print('LOGIN: Longitud del rol: ${roleString?.length}');
        print('LOGIN: Caracteres del rol: ${roleString?.codeUnits}');
        return UserRole.athlete;
    }
  }

  void _setState(AWSLoginState newState) {
    print('LOGIN: Cambiando estado de $_state a $newState');
    print('LOGIN: Rol actual: ${_currentUser?.role}');
    print('LOGIN: ¿Es coach? ${_currentUser?.role == UserRole.coach}');
    print('LOGIN: ¿Es athlete? ${_currentUser?.role == UserRole.athlete}');
    print('LOGIN: ¿Es admin? ${_currentUser?.role == UserRole.admin}');

    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}