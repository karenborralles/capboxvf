import '../../domain/entities/user.dart';
import '../dtos/user_profile_dto.dart';
import '../dtos/oauth_token_response_dto.dart';

class UserMapper {
  static User fromUserProfile(UserProfileDto dto, String token) {
    return User(
      id: dto.id,
      email: dto.email,
      name: dto.nombre, 
      role: _parseRole(dto.rol), 
      createdAt: DateTime.now(), 
      token: token,
    );
  }

  static User fromTokenResponse(OAuthTokenResponseDto dto) {
    return User(
      id: '', 
      email: '',
      name: '',
      role: UserRole.athlete, 
      createdAt: DateTime.now(),
      token: dto.accessToken,
    );
  }

  static User fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['nombre'] ?? json['name'] ?? '',
      role: _parseRole(json['rol'] ?? json['role'] ?? 'atleta'),
      createdAt: DateTime.now(),
      token: json['token'] ?? '',
    );
  }

  static UserRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'atleta':
      case 'athlete':
        return UserRole.athlete;
      case 'entrenador':
      case 'coach':
        return UserRole.coach;
      case 'administrador':
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.athlete;
    }
  }

  static Map<String, dynamic> toJson(User user) {
    return {
      'id': user.id,
      'email': user.email,
      'nombre': user.name,
      'rol': _roleToSpanish(user.role),
    };
  }

  static String _roleToSpanish(UserRole role) {
    switch (role) {
      case UserRole.athlete:
        return 'Atleta';
      case UserRole.coach:
        return 'Entrenador';
      case UserRole.admin:
        return 'Administrador';
    }
  }
}