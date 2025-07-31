import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/router/app_router.dart';
import 'core/dependency_injection/dependency_injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  runApp(const CapBoxApp());
}

class CapBoxApp extends StatelessWidget {
  const CapBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: appProviders, 
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'CapBox',
        routerConfig: appRouter,
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.red,
          colorScheme: ColorScheme.dark(
            primary: Colors.red,
            secondary: Colors.redAccent,
          ),
        ),
      ),
    );
  }
}
