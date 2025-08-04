enum RolUsuario {
  Atleta('Atleta'),
  Entrenador('Entrenador'),
  Admin('Admin');

  const RolUsuario(this.value);
  final String value;
}

class RegisterRequestDto {
  final String email;
  final String password;
  final String nombre;
  final RolUsuario rol;
  final String? nombreGimnasio;

  RegisterRequestDto({
    required this.email,
    required this.password,
    required this.nombre,
    required this.rol,
    this.nombreGimnasio,
  }) {
    if (password.length < 8) {
      throw ArgumentError('La contraseña debe tener al menos 8 caracteres');
    }

    if (!_isValidEmail(email)) {
      throw ArgumentError('El email proporcionado no es válido');
    }

    if (nombre.trim().isEmpty) {
      throw ArgumentError('El nombre es obligatorio');
    }
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'nombre': nombre,
        'rol': rol.value,
        if (nombreGimnasio != null) 'nombreGimnasio': nombreGimnasio,
      };

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

class RegisterResponseDto {
  final int statusCode;
  final String message;
  final RegisterDataDto data;

  RegisterResponseDto({
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory RegisterResponseDto.fromJson(Map<String, dynamic> json) {
    return RegisterResponseDto(
      statusCode: json['statusCode'],
      message: json['message'],
      data: RegisterDataDto.fromJson(json['data']),
    );
  }
}

class RegisterDataDto {
  final String id;
  final String email;

  RegisterDataDto({required this.id, required this.email});

  factory RegisterDataDto.fromJson(Map<String, dynamic> json) {
    return RegisterDataDto(id: json['id'], email: json['email']);
  }
}