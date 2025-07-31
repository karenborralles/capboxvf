import 'package:flutter_bloc/flutter_bloc.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(LoginInitial());

  bool isAuthenticated = false;
  String? errorMessage;
  User? currentUser;

  Future<void> login(String email, String password) async {
    try {
      emit(LoginLoading());
      await Future.delayed(Duration(seconds: 2));
      if (email == 'test@email.com' && password == 'password123') {
        isAuthenticated = true;
        currentUser = User(name: 'Test User', role: 'Athlete');
        emit(LoginSuccess());
      } else {
        isAuthenticated = false;
        errorMessage = 'Invalid credentials';
        emit(LoginFailure(errorMessage!));
      }
    } catch (e) {
      isAuthenticated = false;
      errorMessage = e.toString();
      emit(LoginFailure(errorMessage!));
    }
  }

  Future<void> checkAuthStatus() async {
    await Future.delayed(Duration(seconds: 1));
    emit(isAuthenticated ? LoginSuccess() : LoginInitial());
  }

  String getHomeRoute() {
    if (currentUser == null) {
      return '/login';
    }
    switch (currentUser!.role) {
      case 'Athlete':
        return '/athlete/home';
      case 'Coach':
        return '/coach/home';
      default:
        return '/unknown';
    }
  }
}

class User {
  final String name;
  final String role;

  User({required this.name, required this.role});
}

abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {}

class LoginFailure extends LoginState {
  final String error;

  LoginFailure(this.error);
}
