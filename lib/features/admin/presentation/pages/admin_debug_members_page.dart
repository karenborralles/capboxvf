import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_navbar.dart';
import '../cubit/gym_management_cubit.dart';
import '../../data/dtos/gym_member_dto.dart';
import '../../../../core/services/aws_api_service.dart';

class AdminDebugMembersPage extends StatefulWidget {
  const AdminDebugMembersPage({super.key});

  @override
  State<AdminDebugMembersPage> createState() => _AdminDebugMembersPageState();
}

class _AdminDebugMembersPageState extends State<AdminDebugMembersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<GymManagementCubit>();
      cubit.loadMembers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const AdminHeader(),
          Expanded(
            child: Consumer<GymManagementCubit>(
              builder: (context, cubit, child) {
                if (cubit.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  );
                }

                if (cubit.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${cubit.errorMessage}',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => cubit.loadMembers(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                return _buildMembersList(cubit);
              },
            ),
          ),
          const AdminNavBar(currentIndex: 0),
        ],
      ),
    );
  }

  Widget _buildMembersList(GymManagementCubit cubit) {
    final allMembers = cubit.allMembers;
    final atletas = allMembers.where((m) => m.isAthlete).toList();
    final entrenadores = allMembers.where((m) => m.isCoach).toList();
    final admins = allMembers.where((m) => m.isAdmin).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLinkSection(),
          const SizedBox(height: 16),
          _buildStatsCard(allMembers, atletas, entrenadores, admins),
          const SizedBox(height: 16),
          _buildRoleSection('Entrenadores', entrenadores, Colors.orange),
          const SizedBox(height: 16),
          _buildRoleSection('Atletas', atletas, Colors.blue),
          const SizedBox(height: 16),
          _buildRoleSection('Administradores', admins, Colors.red),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => cubit.loadMembers(),
              icon: const Icon(Icons.refresh),
              label: const Text('Recargar Datos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkSection() {
    return Card(
      color: Colors.orange[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Admin No Vinculado',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'El administrador no está vinculado a ningún gimnasio. Debe vincularse primero para poder ver los miembros.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showLinkDialog(),
                    icon: const Icon(Icons.link),
                    label: const Text('Vincular a Gimnasio'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkDialog() {
    final TextEditingController keyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Vincular Admin a Gimnasio',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ingresa la clave del gimnasio para vincular el administrador:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: keyController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Clave del gimnasio',
                hintStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final key = keyController.text.trim();
              if (key.isNotEmpty) {
                Navigator.pop(context);
                _linkAdminToGym(key);
              }
            },
            child: const Text('Vincular'),
          ),
        ],
      ),
    );
  }

  Future<void> _linkAdminToGym(String gymKey) async {
    try {
      final apiService = context.read<AWSApiService>();
      final response = await apiService.linkAccountToGym(gymKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin vinculado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      final cubit = context.read<GymManagementCubit>();
      await cubit.loadMembers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error vinculando: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatsCard(
    List<GymMemberDto> allMembers,
    List<GymMemberDto> atletas,
    List<GymMemberDto> entrenadores,
    List<GymMemberDto> admins,
  ) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas del Gimnasio',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatRow('Total de miembros', allMembers.length, Colors.white),
            _buildStatRow('Atletas', atletas.length, Colors.blue),
            _buildStatRow('Entrenadores', entrenadores.length, Colors.orange),
            _buildStatRow('Administradores', admins.length, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSection(
    String title,
    List<GymMemberDto> members,
    Color color,
  ) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    members.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (members.isEmpty)
              const Text(
                'No hay miembros en esta categoría',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...members.map((member) => _buildMemberTile(member)),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(GymMemberDto member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            member.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(member.email, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getRoleColor(member.role),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  member.role,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: member.isApproved ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  member.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'atleta':
        return Colors.blue;
      case 'entrenador':
        return Colors.orange;
      case 'administrador':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}