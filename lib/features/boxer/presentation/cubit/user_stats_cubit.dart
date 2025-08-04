import 'package:flutter/foundation.dart';
import '../../data/dtos/user_stats_dto.dart';
import '../../data/services/user_stats_service.dart';

enum UserStatsState { initial, loading, loaded, error }

class UserStatsCubit extends ChangeNotifier {
  final UserStatsService _statsService;

  UserStatsState _state = UserStatsState.initial;
  UserStatsDto? _userStats;
  StreakDto? _currentStreak;
  List<GoalDto> _goals = [];
  String? _errorMessage;

  UserStatsCubit(this._statsService);

  UserStatsState get state => _state;
  UserStatsDto? get userStats => _userStats;
  StreakDto? get currentStreak => _currentStreak;
  List<GoalDto> get goals => _goals;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == UserStatsState.loading;
  bool get hasError => _state == UserStatsState.error;
  bool get hasData => _userStats != null;

  Future<void> loadUserStats() async {
    try {
      _setState(UserStatsState.loading);
      _clearError();

      print('CUBIT: Cargando estadísticas del usuario');

      try {
        _userStats = await _statsService.getUserStats();
        _currentStreak = _userStats!.streak;
        _goals = _userStats!.goals;
        print('CUBIT: Estadísticas cargadas desde backend');
      } catch (e) {
        print('CUBIT: Error cargando desde backend, usando datos mock');
        _userStats = _getMockStats();
        _currentStreak = _userStats!.streak;
        _goals = _userStats!.goals;
      }

      _setState(UserStatsState.loaded);
    } catch (e) {
      print('CUBIT: Error cargando estadísticas - $e');
      _setError('Error cargando estadísticas del usuario: $e');
      _setState(UserStatsState.error);
    }
  }

  Future<void> loadStreak() async {
    try {
      print('CUBIT: Cargando racha del usuario');

      _currentStreak = await _statsService.getUserStreak();
      notifyListeners();

      print('CUBIT: Racha cargada - ${_currentStreak!.currentDays} días');
    } catch (e) {
      print('CUBIT: Error cargando racha - $e');
      _setError('Error cargando racha: $e');
    }
  }

  Future<void> loadGoals() async {
    try {
      print('CUBIT: Cargando metas del usuario');

      _goals = await _statsService.getUserGoals();
      notifyListeners();

      print('CUBIT: ${_goals.length} metas cargadas');
    } catch (e) {
      print('CUBIT: Error cargando metas - $e');
      _setError('Error cargando metas: $e');
    }
  }

  Future<void> markWorkoutCompleted() async {
    try {
      print('CUBIT: Marcando entrenamiento completado');

      await _statsService.markWorkoutCompleted();

      if (_currentStreak != null) {
        _currentStreak = StreakDto(
          currentDays: _currentStreak!.currentDays + 1,
          maxDays: _currentStreak!.maxDays,
          lastWorkoutDate: DateTime.now(),
          currentMonth: DateTime.now().month,
          workoutDatesThisMonth: [
            ..._currentStreak!.workoutDatesThisMonth,
            DateTime.now(),
          ],
        );
      }

      notifyListeners();
      print('CUBIT: Entrenamiento marcado, racha actualizada');
    } catch (e) {
      print('CUBIT: Error marcando entrenamiento - $e');
      _setError('Error marcando entrenamiento: $e');
    }
  }

  Future<void> updateGoal(
    String goalId, {
    String? newDescription,
    bool? isCompleted,
    DateTime? newDueDate,
  }) async {
    try {
      print('CUBIT: Actualizando meta $goalId');

      await _statsService.updateGoal(
        goalId,
        newDescription: newDescription,
        isCompleted: isCompleted,
        newDueDate: newDueDate,
      );

      final goalIndex = _goals.indexWhere((goal) => goal.id == goalId);
      if (goalIndex != -1) {
        final updatedGoal = GoalDto(
          id: _goals[goalIndex].id,
          description: newDescription ?? _goals[goalIndex].description,
          isCompleted: isCompleted ?? _goals[goalIndex].isCompleted,
          dueDate: newDueDate ?? _goals[goalIndex].dueDate,
          category: _goals[goalIndex].category,
          priority: _goals[goalIndex].priority,
          progress: _goals[goalIndex].progress,
        );

        _goals[goalIndex] = updatedGoal;
        notifyListeners();
      }

      print('CUBIT: Meta actualizada');
    } catch (e) {
      print('CUBIT: Error actualizando meta - $e');
      _setError('Error actualizando meta: $e');
    }
  }

  Future<void> addGoal(
    String description,
    DateTime dueDate, {
    String category = 'general',
    String priority = 'medium',
  }) async {
    try {
      print('CUBIT: Agregando nueva meta');

      await _statsService.addGoal(description, dueDate);

      final newGoal = GoalDto(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: description,
        isCompleted: false,
        dueDate: dueDate,
        category: category,
        priority: priority,
      );

      _goals.add(newGoal);
      notifyListeners();

      print('CUBIT: Meta agregada');
    } catch (e) {
      print('CUBIT: Error agregando meta - $e');
      _setError('Error agregando meta: $e');
    }
  }

  List<GoalDto> getGoalsByStatus(bool completed) {
    return _goals.where((goal) => goal.isCompleted == completed).toList();
  }

  List<GoalDto> get pendingGoals => getGoalsByStatus(false);

  List<GoalDto> get completedGoals => getGoalsByStatus(true);

  List<GoalDto> get overdueGoals {
    return _goals.where((goal) => goal.isOverdue).toList();
  }

  List<GoalDto> get dueSoonGoals {
    return _goals.where((goal) => goal.isDueSoon).toList();
  }

  double get goalsCompletionPercentage {
    if (_goals.isEmpty) return 0.0;
    final completed = completedGoals.length;
    return completed / _goals.length;
  }

  bool get isStreakActive {
    return _currentStreak?.isActive ?? false;
  }

  String get streakText {
    return _currentStreak?.streakText ?? 'Sin racha activa';
  }

  Future<void> refresh() async {
    await loadUserStats();
  }

  UserStatsDto _getMockStats() {
    final mockStreak = StreakDto(
      currentDays: 5,
      maxDays: 12,
      lastWorkoutDate: DateTime.now().subtract(const Duration(days: 1)),
      currentMonth: DateTime.now().month,
      workoutDatesThisMonth: [
        DateTime.now().subtract(const Duration(days: 1)),
        DateTime.now().subtract(const Duration(days: 2)),
        DateTime.now().subtract(const Duration(days: 3)),
        DateTime.now().subtract(const Duration(days: 5)),
        DateTime.now().subtract(const Duration(days: 6)),
      ],
    );

    final mockGoals = [
      GoalDto(
        id: '1',
        description: '5km en 25 min',
        isCompleted: false,
        dueDate: DateTime.now().add(const Duration(days: 30)),
        category: 'cardio',
        priority: 'high',
      ),
      GoalDto(
        id: '2',
        description: '5kg abajo',
        isCompleted: false,
        dueDate: DateTime.now().add(const Duration(days: 60)),
        category: 'weight',
        priority: 'medium',
      ),
      GoalDto(
        id: '3',
        description: 'Mejorar guardia derecha',
        isCompleted: false,
        dueDate: DateTime.now().add(const Duration(days: 45)),
        category: 'technique',
        priority: 'high',
      ),
      GoalDto(
        id: '4',
        description: 'Tratamiento lesión mano derecha',
        isCompleted: false,
        dueDate: DateTime.now().add(const Duration(days: 14)),
        category: 'health',
        priority: 'urgent',
      ),
    ];

    return UserStatsDto(
      streak: mockStreak,
      goals: mockGoals,
      totalWorkouts: 45,
      totalHours: 67.5,
      favoriteExercise: 'Saco pesado',
      weeklyGoal: 5,
      weeklyCompleted: 3,
    );
  }

  void _setState(UserStatsState newState) {
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