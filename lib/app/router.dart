import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../login_screen.dart';
import '../home_screen.dart';
import '../forgot_password_screen.dart';
import '../register_screen.dart';
import '../profile_screen.dart';


class AppRouter {
  final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },

        routes: <RouteBase>[
          GoRoute(
            path: 'home',
            builder: (BuildContext context, GoRouterState state) {
              return const HomeScreen();
            }
          ),

          GoRoute(
            path: 'forgot-password',
            builder: (BuildContext context, GoRouterState state) {
              return const ForgotPasswordScreen();
            }
          ),

          GoRoute(
            path: 'register',
            builder: (BuildContext context, GoRouterState state) {
              return const RegisterScreen();
            }
          ),

          GoRoute(
            path: 'profile',
            builder: (BuildContext context, GoRouterState state) {
              return const ProfileScreen();
            }
          )
        ]  
      )
    ]
  );
}