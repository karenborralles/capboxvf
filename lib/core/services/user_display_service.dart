import 'auth_service.dart';
import 'aws_api_service.dart';
import '../api/api_config.dart';

class UserDisplayService {
  final AuthService _authService;
  final AWSApiService _apiService;

  UserDisplayData? _cachedData;
  bool _isLoading = false;
  DateTime? _lastLoadTime;

  static UserDisplayService? _globalInstance;

  UserDisplayService(this._authService, this._apiService) {
    _globalInstance = this;
  }

  Future<UserDisplayData> getCurrentUserDisplayData({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedData != null && !_isCacheExpired()) {
      print('DISPLAY: Usando datos cacheados (evitando carga innecesaria)');
      return _cachedData!;
    }

    if (_isLoading) {
      print('DISPLAY: Carga ya en progreso, esperando...');
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_cachedData != null) return _cachedData!;
    }

    return await _loadUserDataFromBackend(forceRefresh);
  }

  Future<UserDisplayData> _loadUserDataFromBackend(bool isRefresh) async {
    _isLoading = true;

    try {
      if (isRefresh) {
        print('DISPLAY: Refrescando datos del usuario...');
      } else {
        print('DISPLAY: Cargando datos del usuario por primera vez...');
      }

      final isAuthenticated = await _authService.isAuthenticated();
      if (!isAuthenticated) {
        throw Exception('Usuario no autenticado');
      }

      final userResponse = await _apiService.get(ApiConfig.userProfile);
      final userData = userResponse.data;

      String? name = userData['nombre'] ?? userData['name'];
      String? role = userData['rol'] ?? userData['role'];
      String? email = userData['email'];

      final firstName = name?.split(' ').first ?? 'Usuario';
      String displayName = firstName;

      if (role?.toLowerCase() == 'administrador') {
        try {
          final gymResponse = await _apiService.get(ApiConfig.userGymKey);
          final gymName = gymResponse.data['nombreGimnasio'] ?? 'Gym Admin';
          displayName = gymName;
        } catch (e) {
          print('DISPLAY: Error obteniendo nombre del gimnasio, usando displayName genérico');
        }
      }

      final avatarInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';

      _cachedData = UserDisplayData(
        fullName: name ?? 'Usuario',
        firstName: firstName,
        displayName: displayName,
        avatarInitial: avatarInitial,
        role: role ?? 'usuario',
        email: email ?? '',
      );

      _lastLoadTime = DateTime.now();
      _isLoading = false;

      print('DISPLAY: Datos cargados y cacheados exitosamente');
      print('${_cachedData!.fullName} (${_cachedData!.role})');

      return _cachedData!;
    } catch (e) {
      _isLoading = false;
      print('DISPLAY: Error cargando datos - $e');

      if (_cachedData != null) {
        print('DISPLAY: Usando datos cacheados previos como fallback');
        return _cachedData!;
      }

      _cachedData = UserDisplayData(
        fullName: 'Usuario',
        firstName: 'Usuario',
        displayName: 'Usuario',
        avatarInitial: 'U',
        role: 'usuario',
        email: '',
      );
      return _cachedData!;
    }
  }

  bool _isCacheExpired() {
    if (_lastLoadTime == null) return true;
    final now = DateTime.now();
    final diff = now.difference(_lastLoadTime!);
    return diff.inMinutes > 15;
  }

  Future<UserDisplayData> refreshUserData() async {
    print('DISPLAY: Refresh manual solicitado');
    return await getCurrentUserDisplayData(forceRefresh: true);
  }

  void clearCache() {
    print('DISPLAY: Limpiando caché de usuario');
    _cachedData = null;
    _lastLoadTime = null;
    _isLoading = false;
  }

  bool get hasCachedData => _cachedData != null;
  bool get isLoading => _isLoading;

  static void clearGlobalCache() {
    if (_globalInstance != null) {
      print('DISPLAY: Limpiando caché global desde logout');
      _globalInstance!.clearCache();
    }
  }

  Future<String> getDisplayName() async {
    try {
      final userData = await getCurrentUserDisplayData();
      return userData.displayName;
    } catch (e) {
      return 'Usuario';
    }
  }

  Future<String> getAvatarInitial() async {
    try {
      final userData = await getCurrentUserDisplayData();
      return userData.avatarInitial;
    } catch (e) {
      return 'U';
    }
  }
}

class UserDisplayData {
  final String fullName;
  final String firstName;
  final String displayName;
  final String avatarInitial;
  final String role;
  final String email;

  UserDisplayData({
    required this.fullName,
    required this.firstName,
    required this.displayName,
    required this.avatarInitial,
    required this.role,
    required this.email,
  });

  bool get isAdmin => role.toLowerCase() == 'administrador';
  bool get isCoach => role.toLowerCase() == 'entrenador';
  bool get isBoxer => role.toLowerCase() == 'boxeador' || role.toLowerCase() == 'atleta';
}