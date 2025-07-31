import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:dio/dio.dart';
import 'package:capbox/core/services/auth_service.dart';
import 'package:capbox/core/services/aws_api_service.dart';
import 'package:capbox/core/services/user_display_service.dart';
import 'package:capbox/features/admin/data/services/gym_service.dart';
import 'package:capbox/features/admin/data/services/admin_gym_key_service.dart';
import 'package:capbox/features/boxer/data/services/user_stats_service.dart';
import 'package:capbox/features/coach/data/services/gym_key_service.dart';
import 'package:capbox/features/admin/presentation/cubit/gym_management_cubit.dart';
import 'package:capbox/features/admin/presentation/cubit/admin_gym_key_cubit.dart';
import 'package:capbox/features/boxer/presentation/cubit/user_stats_cubit.dart';
import 'package:capbox/features/coach/presentation/cubit/gym_key_cubit.dart';
import 'package:capbox/features/auth/presentation/view_models/gym_key_activation_cubit.dart';
import 'package:capbox/core/features/auth/presentation/view_models/login_cubit.dart';
import 'package:capbox/core/features/coach/domain/repositories/planning_repository.dart';
import 'package:capbox/features/auth/application/auth_injector.dart';
import 'package:capbox/features/auth/application/aws_auth_injector.dart';
import 'package:capbox/features/coach/application/planning_injector.dart';

List<SingleChildWidget> appProviders = [
  // Instancia de Dio para servicios HTTP
  Provider<Dio>(
    create: (_) => Dio(
      BaseOptions(
        baseUrl: 'https://api.capbox.site',
      ),
    ),
  ),
  Provider<AuthService>(
    create: (context) => AuthService(context.read<Dio>()),
  ),
  Provider<AWSApiService>(
    create: (context) => AWSApiService(context.read<AuthService>()),
  ),
  Provider<UserDisplayService>(
    create: (context) =>
        UserDisplayService(context.read<AuthService>(), context.read<AWSApiService>()),
  ),
  Provider<GymService>(
    create: (context) => GymService(context.read<AWSApiService>()),
  ),
  Provider<AdminGymKeyService>(
    create: (context) => AdminGymKeyService(context.read<AWSApiService>()),
  ),
  Provider<UserStatsService>(
    create: (context) => UserStatsService(context.read<AWSApiService>()),
  ),
  Provider<GymKeyService>(
    create: (context) => GymKeyService(context.read<AWSApiService>()),
  ),
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
    create: (context) =>
        GymKeyActivationCubit(context.read<AWSApiService>(), context.read<AuthService>()),
  ),
  ...awsAuthProviders,
  ...planningProviders,
  Provider<LoginCubit>(create: (_) => LoginCubit()),
  Provider<PlanningRepository>(create: (_) => PlanningRepository()),
];
