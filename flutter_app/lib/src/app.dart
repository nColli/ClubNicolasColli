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
    //current user esta guardado en la instancia de auth de firebase
    //de guardarlo en el storage y demas se encarga firebase, no la app de por si, eso simplifica que si esta null es porque no inicio
    //si el usuario no es null pero tampoco es valido le va a dar un mensaje de error al fallar la api porque no se puede generar el token - que genera 
    // a partir del usuario que tiene guardard
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
