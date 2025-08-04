import 'package:flutter/foundation.dart';
import '../../data/dtos/gym_member_dto.dart';
import '../../data/services/gym_service.dart';

enum GymManagementState { initial, loading, loaded, error }

class GymManagementCubit extends ChangeNotifier {
  final GymService _gymService;

  GymManagementState _state = GymManagementState.initial;
  List<GymMemberDto> _allMembers = [];
  List<GymMemberDto> _filteredMembers = [];
  List<GymMemberDto> _pendingRequests = [];
  String? _errorMessage;
  String _currentFilter = '';

  GymManagementCubit(this._gymService);

  GymManagementState get state => _state;
  List<GymMemberDto> get members => _filteredMembers;
  List<GymMemberDto> get allMembers => _allMembers;
  List<GymMemberDto> get pendingRequests => _pendingRequests;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == GymManagementState.loading;
  bool get hasError => _state == GymManagementState.error;
  bool get isEmpty => _filteredMembers.isEmpty;

  Future<void> loadMembers() async {
    try {
      _setState(GymManagementState.loading);
      _clearError();
      try {
        final members = await _gymService.getGymMembers();
        _allMembers = members;
      } catch (e) {
        _allMembers = _getMockMembers();
      }
      _applyCurrentFilter();
      _setState(GymManagementState.loaded);
    } catch (e) {
      _setError('Error cargando miembros del gimnasio: $e');
      _setState(GymManagementState.error);
    }
  }

  Future<void> loadPendingRequests() async {
    try {
      try {
        final requests = await _gymService.getPendingRequests();
        _pendingRequests = requests;
      } catch (e) {
        _pendingRequests = _getMockPendingRequests();
      }
      notifyListeners();
    } catch (e) {
      _setError('Error cargando solicitudes pendientes: $e');
    }
  }

  void searchMembers(String query) {
    _currentFilter = query;
    _applyCurrentFilter();
    notifyListeners();
  }

  void filterByRole(String role) {
    if (role.isEmpty || role.toLowerCase() == 'todos') {
      _filteredMembers = List.from(_allMembers);
    } else {
      _filteredMembers =
          _allMembers
              .where((member) => member.role.toLowerCase() == role.toLowerCase())
              .toList();
    }
    notifyListeners();
  }

  List<GymMemberDto> getStudents() {
    return _allMembers.where((member) => member.isAthlete).toList();
  }

  List<GymMemberDto> getCoaches() {
    return _allMembers.where((member) => member.isCoach).toList();
  }

  GymMemberDto? getMemberById(String id) {
    try {
      return _allMembers.firstWhere((member) => member.id == id);
    } catch (e) {
      return null;
    }
  }

  void _applyCurrentFilter() {
    if (_currentFilter.isEmpty) {
      _filteredMembers = List.from(_allMembers);
    } else {
      _filteredMembers =
          _allMembers
              .where((member) =>
                  member.name.toLowerCase().contains(_currentFilter.toLowerCase()) ||
                  member.email.toLowerCase().contains(_currentFilter.toLowerCase()) ||
                  member.role.toLowerCase().contains(_currentFilter.toLowerCase()))
              .toList();
    }
  }

  List<GymMemberDto> _getMockMembers() {
    return [
      GymMemberDto.mock(id: '1', name: 'Arturo Amizaday Jimenez Ojendis', role: 'atleta'),
      GymMemberDto.mock(id: '2', name: 'Ana Karen Álvarez Borralles', role: 'atleta'),
      GymMemberDto.mock(id: '3', name: 'Jonathan Dzul Mendoza', role: 'atleta'),
      GymMemberDto.mock(id: '4', name: 'Juan Jimenez', role: 'atleta'),
      GymMemberDto.mock(id: '5', name: 'Nuricumbo Jimenez Pedregal', role: 'atleta'),
      GymMemberDto.mock(id: '6', name: 'Alberto Taboada De La Cruz', role: 'atleta'),
      GymMemberDto.mock(id: '7', name: 'Carlos Fernandez', role: 'entrenador'),
      GymMemberDto.mock(id: '8', name: 'Fernando Dinamita', role: 'entrenador'),
    ];
  }

  List<GymMemberDto> _getMockPendingRequests() {
    return [
      GymMemberDto.mock(id: '9', name: 'Pedro Martinez', role: 'atleta', status: 'pending'),
      GymMemberDto.mock(id: '10', name: 'Maria Rodriguez', role: 'atleta', status: 'pending'),
    ];
  }

  Future<void> approveAthleteWithData({
    required String athleteId,
    required Map<String, dynamic> physicalData,
    required Map<String, dynamic> tutorData,
  }) async {
    try {
      await _gymService.approveAthleteWithData(
        athleteId: athleteId,
        physicalData: physicalData,
        tutorData: tutorData,
      );
      _pendingRequests.removeWhere((member) => member.id == athleteId);
      await loadMembers();
    } catch (e) {
      _setError('Error aprobando atleta: $e');
    }
  }

  Future<void> refresh() async {
    await loadMembers();
    await loadPendingRequests();
  }

  void _setState(GymManagementState newState) {
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