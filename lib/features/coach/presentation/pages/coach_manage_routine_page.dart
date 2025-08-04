import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capbox/features/coach/presentation/widgets/coach_navbar.dart';
import 'package:capbox/features/coach/presentation/widgets/coach_header.dart';
import 'package:capbox/features/coach/presentation/widgets/routine_card_manage.dart';
import 'package:capbox/features/coach/data/services/routine_service.dart';
import 'package:capbox/features/coach/data/dtos/routine_dto.dart';
import 'package:capbox/core/services/aws_api_service.dart';

class CoachManageRoutinePage extends StatefulWidget {
  final String nivel;
  const CoachManageRoutinePage({super.key, required this.nivel});

  @override
  State<CoachManageRoutinePage> createState() => _CoachManageRoutinePageState();
}

class _CoachManageRoutinePageState extends State<CoachManageRoutinePage> {
  int? expandedIndex;
  String selectedCategory = 'calentamiento';
  List<RoutineListDto> rutinas = [];
  bool isLoading = true;
  String? error;
  List<Map<String, dynamic>> _rutinasConDetalles =
      []; // para detalles

  @override
  void initState() {
    super.initState();
    _loadRoutinesForLevel();
  }

  Future<void> _loadRoutinesForLevel() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      print(
        '[CoachManageRoutinePage] Cargando rutinas para nivel: ${widget.nivel}',
      );
      final apiService = context.read<AWSApiService>();
      final routineService = RoutineService(apiService);
      final todasRutinas = await routineService.getRoutines();

      final rutinasFiltradas =
          todasRutinas.where((rutina) {
            final nivelRutina = rutina.nivel.toLowerCase();
            final nivelPagina = widget.nivel.toLowerCase();
            return nivelRutina == nivelPagina;
          }).toList();

      print(
        '[CoachManageRoutinePage] ${rutinasFiltradas.length} rutinas encontradas para nivel ${widget.nivel}',
      );

      List<Map<String, dynamic>> rutinasConDetalles = [];
      for (final rutina in rutinasFiltradas) {
        try {
          print(
            '[CoachManageRoutinePage] Cargando detalle de rutina: ${rutina.nombre}',
          );
          final detalle = await routineService.getRoutineDetail(rutina.id);

          Map<String, List<Map<String, dynamic>>> ejerciciosPorCategoria = {
            'calentamiento': [],
            'resistencia': [],
            'tecnica': [],
          };

          for (final ejercicio in detalle.ejercicios) {
            String categoria = ejercicio.categoria ?? 'tecnica';
            print('[CoachManageRoutinePage] Ejercicio: ${ejercicio.nombre}');
            print('  - Categoría del backend: "$categoria"');
            print('  - Nombre del ejercicio: "${ejercicio.nombre}"');
            print('  - Sets/Reps: "${ejercicio.setsReps}"');
            print('  - Duración: ${ejercicio.duracionEstimadaSegundos}s');

            if ([
              'calentamiento',
              'resistencia',
              'tecnica',
            ].contains(categoria)) {
              print('[CoachManageRoutinePage] Categoría válida: $categoria');
            } else {
              print(
                '[CoachManageRoutinePage] Categoría inválida: $categoria',
              );
            }

            if (ejerciciosPorCategoria.containsKey(categoria)) {
              ejerciciosPorCategoria[categoria]!.add({
                'nombre': ejercicio.nombre,
                'duracion': _formatearDuracion(
                  ejercicio.duracionEstimadaSegundos ?? 0,
                ),
                'setsReps': ejercicio.setsReps ?? '',
              });
              print(
                '[CoachManageRoutinePage] Agregado a categoría: $categoria',
              );
            } else {
              print(
                '[CoachManageRoutinePage] Categoría no válida: $categoria, agregando a técnica',
              );
              ejerciciosPorCategoria['tecnica']!.add({
                'nombre': ejercicio.nombre,
                'duracion': _formatearDuracion(
                  ejercicio.duracionEstimadaSegundos ?? 0,
                ),
                'setsReps': ejercicio.setsReps ?? '',
              });
            }
          }

          print(
            '[CoachManageRoutinePage] Resumen de categorías para ${rutina.nombre}:',
          );
          ejerciciosPorCategoria.forEach((categoria, ejercicios) {
            print('  - $categoria: ${ejercicios.length} ejercicios');
          });

          rutinasConDetalles.add({
            'id': rutina.id,
            'titulo': rutina.nombre,
            'duracion': _formatearDuracion(
              rutina.duracionEstimadaMinutos * 60,
            ),
            'nivel': rutina.nivel.toLowerCase(),
            'ejercicios': rutina.cantidadEjercicios,
            'categorias': ejerciciosPorCategoria,
          });

          print(
            '[CoachManageRoutinePage] Detalle cargado para: ${rutina.nombre}',
          );
        } catch (e) {
          print(
            '[CoachManageRoutinePage] Error cargando detalle de ${rutina.nombre}: $e',
          );
          rutinasConDetalles.add({
            'id': rutina.id,
            'titulo': rutina.nombre,
            'duracion': _formatearDuracion(rutina.duracionEstimadaMinutos * 60),
            'nivel': rutina.nivel.toLowerCase(),
            'ejercicios': rutina.cantidadEjercicios,
            'categorias': {
              'calentamiento': [
                {
                  'nombre': 'Error cargando ejercicios',
                  'duracion': '0 min',
                  'setsReps': '',
                },
              ],
              'resistencia': [
                {
                  'nombre': 'Error cargando ejercicios',
                  'duracion': '0 min',
                  'setsReps': '',
                },
              ],
              'tecnica': [
                {
                  'nombre': 'Error cargando ejercicios',
                  'duracion': '0 min',
                  'setsReps': '',
                },
              ],
            },
          });
        }
      }

      setState(() {
        rutinas = rutinasFiltradas;
        _rutinasConDetalles =
            rutinasConDetalles; 
        isLoading = false;
      });
    } catch (e) {
      print('[CoachManageRoutinePage] Error cargando rutinas: $e');
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  String _formatearDuracion(int segundos) {
    if (segundos < 60) {
      return '$segundos seg';
    } else if (segundos < 3600) {
      final minutos = segundos ~/ 60;
      final segs = segundos % 60;
      return segs > 0
          ? '$minutos:${segs.toString().padLeft(2, '0')}'
          : '$minutos min';
    } else {
      final horas = segundos ~/ 3600;
      final minutos = (segundos % 3600) ~/ 60;
      return '$horas:${minutos.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _deleteRoutine(String routineId) async {
    try {
      print('[CoachManageRoutinePage] Eliminando rutina: $routineId');
      final apiService = context.read<AWSApiService>();
      final routineService = RoutineService(apiService);
      await routineService.deleteRoutine(routineId);

      print('[CoachManageRoutinePage] Rutina eliminada exitosamente');

      await _loadRoutinesForLevel();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rutina eliminada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('[CoachManageRoutinePage] Error eliminando rutina: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error eliminando rutina: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: const CoachNavBar(currentIndex: 1),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/images/fondo.png', fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.6)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CoachHeader(),
                  const SizedBox(height: 20),
                  Text(
                    'Gestionar rutinas - ${widget.nivel}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child:
                        isLoading
                            ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                            : error != null
                            ? Center(
                              child: Text(
                                error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                            : rutinas.isEmpty
                            ? const Center(
                              child: Text(
                                'No hay rutinas para este nivel',
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                            : ListView.builder(
                              itemCount: rutinas.length,
                              itemBuilder: (context, index) {
                                final rutina = rutinas[index];
                                final rutinaFormateada =
                                    index < _rutinasConDetalles.length
                                        ? _rutinasConDetalles[index]
                                        : {
                                          'id': rutina.id,
                                          'titulo': rutina.nombre,
                                          'duracion': _formatearDuracion(
                                            rutina.duracionEstimadaMinutos * 60,
                                          ),
                                          'nivel': rutina.nivel.toLowerCase(),
                                          'ejercicios':
                                              rutina.cantidadEjercicios,
                                          'categorias': {
                                            'calentamiento': [
                                              {
                                                'nombre': 'Cargando...',
                                                'duracion': '0 min',
                                                'setsReps': '',
                                              },
                                            ],
                                            'resistencia': [
                                              {
                                                'nombre': 'Cargando...',
                                                'duracion': '0 min',
                                                'setsReps': '',
                                              },
                                            ],
                                            'tecnica': [
                                              {
                                                'nombre': 'Cargando...',
                                                'duracion': '0 min',
                                                'setsReps': '',
                                              },
                                            ],
                                          },
                                        };

                                return RoutineCardManage(
                                  rutina: rutinaFormateada,
                                  nivel: widget.nivel,
                                  index: index,
                                  expandedIndex: expandedIndex,
                                  selectedCategory: selectedCategory,
                                  onExpand: (newIndex) {
                                    setState(() {
                                      expandedIndex = newIndex;
                                      selectedCategory = 'calentamiento';
                                    });
                                  },
                                  onCategoryChange: (newCategory) {
                                    setState(
                                      () => selectedCategory = newCategory,
                                    );
                                  },
                                  onDelete:
                                      _deleteRoutine, 
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
