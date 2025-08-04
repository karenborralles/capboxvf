import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:capbox/features/coach/presentation/widgets/coach_header.dart';
import 'package:capbox/features/coach/presentation/widgets/coach_navbar.dart';
import 'package:capbox/features/coach/data/services/routine_service.dart';
import 'package:capbox/features/coach/data/dtos/routine_dto.dart';
import 'package:capbox/core/services/aws_api_service.dart';

class CoachCreateRoutinePage extends StatefulWidget {
  const CoachCreateRoutinePage({super.key});

  @override
  State<CoachCreateRoutinePage> createState() => _CoachCreateRoutinePageState();
}

class _CoachCreateRoutinePageState extends State<CoachCreateRoutinePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _exerciseNameController = TextEditingController();
  final TextEditingController _exerciseDescriptionController =
      TextEditingController();
  final TextEditingController _setsRepsController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  String selectedLevel = 'Principiante';
  String activeCategory = 'calentamiento';

  bool isCreatingRoutine = false;

  final Map<String, List<Map<String, dynamic>>> ejerciciosSeleccionados = {
    'calentamiento': [],
    'resistencia': [],
    'tecnica': [],
  };

  @override
  void initState() {
    super.initState();
  }

  void _addExerciseToCategory(
    String category,
    String exerciseName,
    String exerciseDescription,
    String setsReps,
    int durationSeconds,
  ) {
    setState(() {
      ejerciciosSeleccionados[category]?.add({
        'nombre': exerciseName,
        'descripcion': exerciseDescription.isEmpty ? null : exerciseDescription,
        'setsReps': setsReps,
        'duracionEstimadaSegundos': durationSeconds,
        'categoria': category,
      });
    });

    print('[CoachCreateRoutinePage] Ejercicio agregado a $category: $exerciseName');

    _exerciseNameController.clear();
    _exerciseDescriptionController.clear();
    _setsRepsController.clear();
    _durationController.clear();
  }

  void _removeExerciseFromCategory(String category, int index) {
    setState(() {
      ejerciciosSeleccionados[category]?.removeAt(index);
    });
  }

  Future<void> _crearRutina() async {
    if (_nameController.text.isEmpty || _isAllCategoriesEmpty()) {
      _showErrorDialog(
        'Por favor, completa el nombre y añade al menos un ejercicio.',
      );
      return;
    }

    setState(() {
      isCreatingRoutine = true;
    });

    try {
      print('[CoachCreateRoutinePage] Creando rutina: ${_nameController.text}');

      final List<CreateEjercicioDto> ejerciciosParaBackend = [];

      ejerciciosSeleccionados.forEach((categoria, ejercicios) {
        for (var ejercicio in ejercicios) {
          final exerciseId =
              '${ejercicio['nombre'].toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';

          ejerciciosParaBackend.add(
            CreateEjercicioDto(
              id: exerciseId,
              nombre: ejercicio['nombre'],
              descripcion: ejercicio['descripcion'],
              setsReps: ejercicio['setsReps'],
              duracionEstimadaSegundos: ejercicio['duracionEstimadaSegundos'],
              categoria: ejercicio['categoria'],
            ),
          );
        }
      });

      final rutina = CreateRoutineDto(
        nombre: _nameController.text,
        nivel: selectedLevel,
        sportId: "1",
        descripcion:
            _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
        ejercicios: ejerciciosParaBackend,
      );

      print('[CoachCreateRoutinePage] Datos de rutina a enviar:');
      print('- Nombre: ${rutina.nombre}');
      print('- Nivel: ${rutina.nivel}');
      print('- Descripción: ${rutina.descripcion}');
      print('- Ejercicios: ${rutina.ejercicios.length}');

      for (int i = 0; i < rutina.ejercicios.length; i++) {
        final ejercicio = rutina.ejercicios[i];
        print('  Ejercicio ${i + 1}:');
        print('    - Nombre: ${ejercicio.nombre}');
        print('    - Descripción: ${ejercicio.descripcion}');
        print('    - Sets/Reps: ${ejercicio.setsReps}');
        print('    - Duración: ${ejercicio.duracionEstimadaSegundos}s');
        print('    - Categoría: ${ejercicio.categoria}');
      }

      print('[CoachCreateRoutinePage] JSON a enviar:');
      print(rutina.toJson());

      final apiService = context.read<AWSApiService>();
      final routineService = RoutineService(apiService);
      final rutinaId = await routineService.createRoutine(rutina.toJson());

      print('[CoachCreateRoutinePage] Rutina creada exitosamente con ID: $rutinaId');

      _showSuccessDialog('Rutina creada exitosamente', () {
        context.go('/coach-home');
      });
    } catch (e) {
      print('[CoachCreateRoutinePage] Error creando rutina: $e');
      _showErrorDialog('Error creando rutina: $e');
    } finally {
      setState(() {
        isCreatingRoutine = false;
      });
    }
  }

  bool _isAllCategoriesEmpty() {
    return ejerciciosSeleccionados.values.every(
      (exercises) => exercises.isEmpty,
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.grey.shade900,
            title: const Text('Error', style: TextStyle(color: Colors.white)),
            content: Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Aceptar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showSuccessDialog(String message, VoidCallback onOk) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.grey.shade900,
            title: const Text('Éxito', style: TextStyle(color: Colors.white)),
            content: Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onOk();
                },
                child: const Text(
                  'Ir al inicio',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/fondo.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          Column(
            children: [
              const SafeArea(child: CoachHeader()),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Crear rutina',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _formContent(),
                ),
              ),
              const CoachNavBar(currentIndex: 1),
            ],
          ),
          if (isCreatingRoutine)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Creando rutina...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _formContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nombre de la rutina',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.grey.shade900,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _descriptionController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Descripción (opcional)',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.grey.shade900,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: selectedLevel,
          dropdownColor: Colors.grey.shade900,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade900,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items:
              ['Principiante', 'Intermedio', 'Avanzado']
                  .map(
                    (nivel) => DropdownMenuItem(
                      value: nivel,
                      child: Text(
                        nivel,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
          onChanged:
              (value) =>
                  setState(() => selectedLevel = value ?? 'Principiante'),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['calentamiento', 'resistencia', 'tecnica'].map((cat) {
            final selected = activeCategory == cat;
            return GestureDetector(
              onTap: () => setState(() => activeCategory = cat),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: selected ? Colors.red : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  cat[0].toUpperCase() + cat.substring(1),
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildCategoryContent(activeCategory),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton(
            onPressed: isCreatingRoutine ? null : _crearRutina,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(
              isCreatingRoutine ? 'Creando...' : 'Crear rutina',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCategoryContent(String category) {
    final ejercicios = ejerciciosSeleccionados[category] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ejercicios.isNotEmpty) ...[
          Text(
            'Ejercicios en ${category[0].toUpperCase()}${category.substring(1)}:',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...ejercicios.asMap().entries.map((entry) {
            final index = entry.key;
            final ejercicio = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ejercicio['nombre'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (ejercicio['descripcion'] != null &&
                            ejercicio['descripcion'].isNotEmpty)
                          Text(
                            ejercicio['descripcion'],
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        Text(
                          '${ejercicio['setsReps']} - ${ejercicio['duracionEstimadaSegundos']}s',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeExerciseFromCategory(category, index),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
        const Text(
          'Agregar ejercicio:',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _exerciseNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nombre del ejercicio (ej: Burpees, Jab directo)',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.grey.shade900,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _exerciseDescriptionController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Descripción (opcional)',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.grey.shade900,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _setsRepsController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Sets x Reps (ej: 3x12)',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.grey.shade900,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _durationController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Duración en segundos',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.grey.shade900,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_exerciseNameController.text.isNotEmpty &&
                  _setsRepsController.text.isNotEmpty &&
                  _durationController.text.isNotEmpty) {
                _addExerciseToCategory(
                  category,
                  _exerciseNameController.text,
                  _exerciseDescriptionController.text,
                  _setsRepsController.text,
                  int.tryParse(_durationController.text) ?? 60,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text(
              'Agregar ejercicio',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}