import 'package:flutter/material.dart';

import 'package:flutter_app/src/constants/constants.dart';
import 'package:flutter_app/src/features/auth/auth.dart';
import 'package:flutter_app/src/features/home/home.dart';
import 'package:flutter_app/src/routing/routing.dart';
import 'package:flutter_app/src/services/services.dart';
import 'package:flutter_app/src/theme/theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // Firebase recuerda la sesión: si ya hay un usuario, se entra directo al
    // home (también al abrir la app tocando una notificación)
    final isLoggedIn = AuthService().currentUser != null;

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
