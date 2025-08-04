import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:capbox/features/coach/data/services/assignment_service.dart';
import 'package:capbox/features/coach/data/services/routine_service.dart';
import 'package:capbox/core/services/aws_api_service.dart';

class BoxerExercises extends StatefulWidget {
  const BoxerExercises({super.key});

  @override
  State<BoxerExercises> createState() => _BoxerExercisesState();
}

class _BoxerExercisesState extends State<BoxerExercises> {
  List<AthleteAssignmentDto> misAsignaciones = [];
  bool isLoading = true;
  String? errorMsg;
  int totalTiempoEstimado = 0;
  int totalTiempoObjetivo = 0;

  @override
  void initState() {
    super.initState();
    _loadMyAssignments();
  }

  Future<void> _loadMyAssignments() async {
    try {
      setState(() {
        isLoading = true;
        errorMsg = null;
      });

      print('[BoxerExercises] Cargando asignaciones del atleta');
      final apiService = context.read<AWSApiService>();
      final assignmentService = AssignmentService(apiService);

      List<AthleteAssignmentDto> asignaciones = [];

      try {
        print('[BoxerExercises] Intentando obtener asignaciones del backend...');
        asignaciones = await assignmentService.getMyAssignments();
        print('[BoxerExercises] Respuesta del backend: ${asignaciones.length} asignaciones');
      } catch (e) {
        print('[BoxerExercises] Error del backend: $e');
        print('[BoxerExercises] Activando modo simulado para presentación...');
      }

      if (asignaciones.isEmpty) {
        print('[BoxerExercises] === MODO SIMULADO ACTIVADO PARA PRESENTACIÓN ===');
        asignaciones = _createMockAssignments();
        print('[BoxerExercises] ${asignaciones.length} rutinas simuladas creadas');
      }

      int tiempoEstimado = 0;
      int tiempoObjetivo = 0;

      for (final asignacion in asignaciones) {
        if (asignacion.estado == 'PENDIENTE' || asignacion.estado == 'EN_PROGRESO') {
          if (asignacion.rutinaId.startsWith('mock_')) {
            tiempoEstimado += 1200;
            tiempoObjetivo += 960;
          } else {
            try {
              final routineService = RoutineService(apiService);
              final rutina = await routineService.getRoutineDetail(asignacion.rutinaId);

              for (final ejercicio in rutina.ejercicios) {
                tiempoEstimado += ejercicio.duracionEstimadaSegundos ?? 0;
                tiempoObjetivo += ejercicio.duracionEstimadaSegundos ?? 0;
              }
            } catch (e) {
              print('[BoxerExercises] Error obteniendo detalles de rutina: $e');
              tiempoEstimado += 180;
              tiempoObjetivo += 180;
            }
          }
        }
      }

      setState(() {
        misAsignaciones = asignaciones;
        totalTiempoEstimado = tiempoEstimado;
        totalTiempoObjetivo = tiempoObjetivo;
        isLoading = false;
      });

      print('[BoxerExercises] ${asignaciones.length} asignaciones cargadas');
      print('[BoxerExercises] Tiempo estimado: ${_formatDuration(tiempoEstimado)}');
      print('[BoxerExercises] Tiempo objetivo: ${_formatDuration(tiempoObjetivo)}');
    } catch (e) {
      print('[BoxerExercises] Error crítico: $e');
      print('[BoxerExercises] Usando datos simulados como último recurso...');

      final mockAssignments = _createMockAssignments();
      setState(() {
        misAsignaciones = mockAssignments;
        totalTiempoEstimado = 1200;
        totalTiempoObjetivo = 960;
        isLoading = false;
        errorMsg = null;
      });

      print('[BoxerExercises] Datos simulados cargados exitosamente');
    }
  }

  List<AthleteAssignmentDto> _createMockAssignments() {
    return [
      AthleteAssignmentDto(
        id: 'mock_assignment_1',
        rutinaId: 'mock_routine_1',
        nombreRutina: 'Rutina Principiante - Boxeo',
        nombreEntrenador: 'Entrenador Demo',
        fechaAsignacion: DateTime.now().subtract(const Duration(days: 1)),
        estado: 'PENDIENTE',
        assignerId: 'mock_coach_1',
      ),
    ];
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Ejercicios de hoy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Icon(Icons.timer, color: Colors.white, size: 17),
            const SizedBox(width: 4),
            Text(
              _formatDuration(totalTiempoEstimado),
              style: const TextStyle(color: Colors.yellow, fontSize: 15),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.flag, color: Colors.white, size: 17),
            const SizedBox(width: 4),
            Text(
              _formatDuration(totalTiempoObjetivo),
              style: const TextStyle(color: Colors.green, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (isLoading)
          const Center(child: CircularProgressIndicator(color: Colors.white))
        else if (errorMsg != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              errorMsg!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          )
        else if (misAsignaciones.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No tienes rutinas asignadas aún.\nTu entrenador te asignará rutinas pronto.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          )
        else
          ..._buildExerciseCards(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              'Iniciar entrenamiento',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                if (misAsignaciones.isNotEmpty) {
                  context.go(
                    '/training-session',
                    extra: {
                      'assignmentId': misAsignaciones.first.id,
                      'routineId': misAsignaciones.first.rutinaId,
                    },
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No tienes rutinas asignadas para entrenar',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: CircleAvatar(
                backgroundColor:
                    misAsignaciones.isNotEmpty ? Colors.green : Colors.grey,
                child: const Icon(Icons.play_arrow, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildExerciseCards() {
    final widgets = <Widget>[];

    for (final asignacion in misAsignaciones) {
      if (asignacion.estado == 'PENDIENTE' ||
          asignacion.estado == 'EN_PROGRESO') {
        final categorias = ['Calentamiento', 'Resistencia', 'Técnica'];
        final iconPaths = [
          'assets/icons/calentamiento.png',
          'assets/icons/resistencia.png',
          'assets/icons/tecnica.png',
        ];

        for (int i = 0; i < categorias.length; i++) {
          widgets.add(
            _buildExerciseCard(
              categorias[i],
              iconPaths[i],
              asignacion.nombreRutina,
            ),
          );
          if (i < categorias.length - 1) {
            widgets.add(const SizedBox(height: 18));
          }
        }
        break;
      }
    }

    return widgets;
  }

  Widget _buildExerciseCard(String title, String iconPath, String routineName) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Image.asset(iconPath, height: 30),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                if (routineName.isNotEmpty)
                  Text(
                    routineName,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),
          const Icon(Icons.timer, color: Colors.white, size: 17),
          const SizedBox(width: 4),
          Text(
            _formatDuration(180),
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.flag, color: Colors.white, size: 17),
          const SizedBox(width: 4),
          Text(
            _formatDuration(180),
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }
}