import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../presentation/view_models/aws_login_cubit.dart';
import '../presentation/view_models/aws_register_cubit.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/aws_api_service.dart';

List<SingleChildWidget> get awsAuthProviders => [
  ChangeNotifierProvider<AWSLoginCubit>(
    create:
        (context) => AWSLoginCubit(
          context.read<AuthService>(),
          context.read<AWSApiService>(),
        ),
  ),

  ChangeNotifierProvider<AWSRegisterCubit>(
    create:
        (context) => AWSRegisterCubit(
          context.read<AuthService>(),
          context.read<AWSApiService>(),
        ),
  ),
];
