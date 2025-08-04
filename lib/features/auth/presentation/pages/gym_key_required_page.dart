import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../view_models/gym_key_activation_cubit.dart';

class GymKeyRequiredPage extends StatefulWidget {
  final String userRole;

  const GymKeyRequiredPage({super.key, required this.userRole});

  @override
  State<GymKeyRequiredPage> createState() => _GymKeyRequiredPageState();
}

class _GymKeyRequiredPageState extends State<GymKeyRequiredPage> {
  final TextEditingController _keyController = TextEditingController();
  final Color redColor = const Color(0xFFFF0909);

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  bool get isCoach =>
      widget.userRole.toLowerCase() == 'entrenador' ||
      widget.userRole.toLowerCase() == 'coach';

  String get title => 'Vincular Gimnasio';

  String get subtitle => 'Para continuar, ingresa la clave de tu gimnasio';

  String get hint => 'Ingresa la clave del gimnasio';

  String get helpText =>
      isCoach
          ? '¿No tienes una clave? Solicítala al administrador del gimnasio'
          : '¿No tienes una clave? Solicítala a tu entrenador';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.black.withOpacity(0.8)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Consumer<GymKeyActivationCubit>(
                builder: (context, cubit, child) {
                  return Column(
                    children: [
                      const SizedBox(height: 60),

                      Image.asset(
                        'assets/images/logo.png',
                        height: 120,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(height: 40),

                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: redColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.key, size: 50, color: redColor),
                      ),

                      const SizedBox(height: 32),

                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          fontFamily: 'Inter',
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: TextField(
                          controller: _keyController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Inter',
                          ),
                          decoration: InputDecoration(
                            hintText: hint,
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontFamily: 'Inter',
                            ),
                            prefixIcon: Icon(
                              Icons.key,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        helpText,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                          fontFamily: 'Inter',
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'La clave debe tener al menos una mayúscula y un número',
                        style: TextStyle(
                          color: Colors.blue.withOpacity(0.8),
                          fontSize: 12,
                          fontFamily: 'Inter',
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              cubit.isLoading
                                  ? null
                                  : () => _activateWithKey(cubit),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: redColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              cubit.isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    'Vincular Cuenta',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      TextButton(
                        onPressed: () => _logout(context),
                        child: Text(
                          'Cerrar sesión y volver al login',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      if (cubit.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            cubit.errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontFamily: 'Inter',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _activateWithKey(GymKeyActivationCubit cubit) async {
    final key = _keyController.text.trim();

    if (key.isEmpty) {
      _showError('Por favor ingresa la clave');
      return;
    }

    if (!_isValidKeyFormat(key)) {
      _showError(
        'La clave debe tener al menos 7 caracteres, una letra y un número',
      );
      return;
    }

    try {
      await cubit.activateWithGymKey(key);

      if (cubit.isActivated) {
        final route = isCoach ? '/coach-home' : '/boxer-home';
        if (mounted) {
          context.go(route);
        }
      }
    } catch (e) {
      _showError('Error activando cuenta: $e');
    }
  }

  void _logout(BuildContext context) async {
    try {
      final loginCubit = Provider.of<GymKeyActivationCubit>(
        context,
        listen: false,
      );

      context.go('/');
    } catch (e) {
      print('Error en logout: $e');
      context.go('/');
    }
  }

  bool _isValidKeyFormat(String key) {
    if (key.isEmpty) return false;

    if (key.length < 7) {
      return false;
    }

    final hasLetter = key.contains(RegExp(r'[A-Za-z]'));
    final hasNumber = key.contains(RegExp(r'[0-9]'));

    return hasLetter && hasNumber;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}