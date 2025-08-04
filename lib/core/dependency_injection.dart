import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'services/auth_service.dart';
import 'services/aws_api_service.dart';
import 'services/user_display_service.dart';
import '../features/auth/application/aws_auth_injector.dart';
import '../features/coach/application/planning_injector.dart'; 

import '../features/admin/data/services/gym_service.dart';
import '../features/admin/data/services/admin_gym_key_service.dart';
import '../features/boxer/data/services/user_stats_service.dart';
import '../features/coach/data/services/gym_key_service.dart';

import '../features/admin/presentation/cubit/gym_management_cubit.dart';
import '../features/admin/presentation/cubit/admin_gym_key_cubit.dart';
import '../features/boxer/presentation/cubit/user_stats_cubit.dart';
import '../features/coach/presentation/cubit/gym_key_cubit.dart';
import '../features/auth/presentation/view_models/gym_key_activation_cubit.dart';

List<SingleChildWidget> getProviders() {
  return [
    // Dio HTTP client
    Provider<Dio>(
      create: (_) => Dio(
        BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? 'https://api.capbox.site'),
      ),
    ),

    // Auth
    Provider<AuthService>(
      create: (context) => AuthService(context.read<Dio>()),
    ),

    // API con token automático
    Provider<AWSApiService>(
      create: (context) => AWSApiService(context.read<AuthService>()),
    ),

    // User display info
    Provider<UserDisplayService>(
      create: (context) => UserDisplayService(
        context.read<AuthService>(),
        context.read<AWSApiService>(),
      ),
    ),

    // Gym services
    Provider<GymService>(
      create: (context) => GymService(context.read<AWSApiService>()),
    ),
    Provider<AdminGymKeyService>(
      create: (context) => AdminGymKeyService(context.read<AWSApiService>()),
    ),
    Provider<GymKeyService>(
      create: (context) => GymKeyService(context.read<AWSApiService>()),
    ),

    // User stats
    Provider<UserStatsService>(
      create: (context) => UserStatsService(context.read<AWSApiService>()),
    ),

    // Cubits / ChangeNotifiers
    ChangeNotifierProvider<GymManagementCubit>(
      create: (context) => GymManagementCubit(context.read<GymService>()),
    ),
    ChangeNotifierProvider<AdminGymKeyCubit>(
      create: (context) => AdminGymKeyCubit(context.read<AdminGymKeyService>()),
    ),
    ChangeNotifierProvider<UserStatsCubit>(
      create: (context) => UserStatsCubit(context.read<UserStatsService>()),
    ),
    ChangeNotifierProvider<GymKeyCubit>(
      create: (context) => GymKeyCubit(context.read<GymKeyService>()),
    ),
    ChangeNotifierProvider<GymKeyActivationCubit>(
      create: (context) => GymKeyActivationCubit(
        context.read<AWSApiService>(),
        context.read<AuthService>(),
      ),
    ),

    // inyectores específicos de features
    ...awsAuthProviders,
    ...planningProviders,
  ];
}