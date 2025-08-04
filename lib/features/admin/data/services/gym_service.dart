import '../../../../core/services/aws_api_service.dart';
import '../dtos/gym_member_dto.dart';

class GymService {
  final AWSApiService _apiService;

  GymService(this._apiService);

  Future<List<GymMemberDto>> getGymMembers() async {
    try {
      final userResponse = await _apiService.getUserMe();
      final userData = userResponse.data;

      String? gymId;

      if (userData['rol'] == 'admin') {
        final ownedGym = userData['ownedGym'];
        if (ownedGym != null) {
          gymId = ownedGym['id'];
        }
      } else {
        final gimnasio = userData['gimnasio'];
        if (gimnasio != null) {
          gymId = gimnasio['id'];
        }
      }

      if (gymId == null) {
        return [];
      }

      final response = await _apiService.getGymMembers(gymId);

      if (response.data is List) {
        return (response.data as List)
            .map((json) => GymMemberDto.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<GymMemberDto>> getPendingRequests() async {
    try {
      final response = await _apiService.getPendingRequests();

      return (response.data as List)
          .map((json) => GymMemberDto.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> approveAthleteWithData({
    required String athleteId,
    required Map<String, dynamic> physicalData,
    required Map<String, dynamic> tutorData,
  }) async {
    try {
      await _apiService.approveAthlete(
        athleteId: athleteId,
        physicalData: physicalData,
        tutorData: tutorData,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<GymMemberDto>> searchMembers(String query) async {
    try {
      final allMembers = await getGymMembers();

      final filtered = allMembers
          .where(
            (member) =>
                member.name.toLowerCase().contains(query.toLowerCase()) ||
                member.email.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();

      return filtered;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<GymMemberDto>> getMembersByRole(String role) async {
    try {
      final allMembers = await getGymMembers();

      final filtered = allMembers
          .where(
            (member) => member.role.toLowerCase() == role.toLowerCase(),
          )
          .toList();

      return filtered;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<GymMemberDto>> getStudents() async {
    return getMembersByRole('atleta');
  }

  Future<List<GymMemberDto>> getCoaches() async {
    return getMembersByRole('entrenador');
  }
}