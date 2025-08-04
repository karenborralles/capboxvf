import 'package:capbox/features/auth/presentation/view_models/login_cubit.dart';
import 'package:capbox/features/coach/domain/repositories/planning_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class IntegrationExamplePage extends StatefulWidget {
  @override
  _IntegrationExamplePageState createState() => _IntegrationExamplePageState();
}

class _IntegrationExamplePageState extends State<IntegrationExamplePage> {
  String _status = 'Listo para probar...';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test de Integración CapBox')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Estado: $_status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testLogin,
              child: Text('1. Probar Login OAuth2'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testGetRoutines,
              child: Text('2. Obtener Rutinas'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testGetAssignments,
              child: Text('3. Obtener Asignaciones'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testCheckAuth,
              child: Text('4. Verificar Estado Auth'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testLogin() async {
    setState(() => _status = 'Probando login...');

    try {
      final loginCubit = context.read<LoginCubit>();
      await loginCubit.login('test@email.com', 'password123');

      if (loginCubit.isAuthenticated) {
        setState(() => _status = 'Login exitoso! Usuario: ${loginCubit.currentUser?.name}');
      } else {
        setState(() => _status = 'Login falló: ${loginCubit.errorMessage}');
      }
    } catch (e) {
      setState(() => _status = 'Error en login: ${e.toString()}');
    }
  }

  Future<void> _testGetRoutines() async {
    setState(() => _status = 'Obteniendo rutinas...');

    try {
      final planningRepo = context.read<PlanningRepository>();
      final routines = await planningRepo.getRoutines();

      setState(() => _status = '${routines.length} rutinas obtenidas');
    } catch (e) {
      setState(() => _status = 'Error obteniendo rutinas: ${e.toString()}');
    }
  }

  Future<void> _testGetAssignments() async {
    setState(() => _status = 'Obteniendo asignaciones...');

    try {
      final planningRepo = context.read<PlanningRepository>();
      final assignments = await planningRepo.getMyAssignments();

      setState(() => _status = '${assignments.length} asignaciones obtenidas');
    } catch (e) {
      setState(() => _status = 'Error obteniendo asignaciones: ${e.toString()}');
    }
  }

  Future<void> _testCheckAuth() async {
    setState(() => _status = 'Verificando autenticación...');

    try {
      final loginCubit = context.read<LoginCubit>();
      await loginCubit.checkAuthStatus();

      if (loginCubit.isAuthenticated) {
        setState(() => _status = 'Usuario autenticado: ${loginCubit.currentUser?.name}');
      } else {
        setState(() => _status = 'Usuario no autenticado');
      }
    } catch (e) {
      setState(() => _status = 'Error verificando auth: ${e.toString()}');
    }
  }
}

class ServiceUsageExample {
  static Future<void> loginExample(LoginCubit loginCubit) async {
    try {
      await loginCubit.login('usuario@email.com', 'password');

      if (loginCubit.isAuthenticated) {
        print('Login exitoso');
        print('Usuario: ${loginCubit.currentUser?.name}');
        print('Rol: ${loginCubit.currentUser?.role}');
        print('Ruta home: ${loginCubit.getHomeRoute()}');
      }
    } catch (e) {
      print('Error en login: $e');
    }
  }

  static Future<void> planningExample(PlanningRepository planningRepo) async {
    try {
      final rutinasBasicas = await planningRepo.getRoutines(nivel: 'Principiante');
      print('Rutinas básicas: ${rutinasBasicas.length}');

      if (rutinasBasicas.isNotEmpty) {
        final detalle = await planningRepo.getRoutineDetail(rutinasBasicas.first.id);
        print('Detalle rutina: ${detalle.name}');
      }

      final asignaciones = await planningRepo.getMyAssignments();
      print('Mis asignaciones: ${asignaciones.length}');
    } catch (e) {
      print('Error en planning: $e');
    }
  }
}

class RegisterExample {
  static Future<void> registerUser(String email, String password) async {
    print('Registrando usuario...');
    print('Email: $email');
    print('Rol sugerido: Atleta');
    print('Necesitarás la clave del gimnasio');
  }
}