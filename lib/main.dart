import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/dependency_injection.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  debugPrint('OAUTH_CLIENT_ID: ${dotenv.env['OAUTH_CLIENT_ID']}');
  debugPrint('OAUTH_CLIENT_SECRET: ${dotenv.env['OAUTH_CLIENT_SECRET']?.substring(0, 10)}...');

  runApp(const CapBoxApp());
}

class CapBoxApp extends StatelessWidget {
  const CapBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: getProviders(),   
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'CapBox',
        routerConfig: appRouter,
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.red,
          colorScheme: const ColorScheme.dark(
            primary: Colors.red,
            secondary: Colors.redAccent,
          ),
        ),
      ),
    );
  }
}