import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../login_screen.dart';
import '../home_screen.dart';
import '../forgot_password_screen.dart';
import '../register_screen.dart';
import '../profile_screen.dart';

class AppRouter {
  final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()), //tells Gorouter to listen to change, to rerun redirect logic
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = FirebaseAuth.instance.currentUser != null;
      final bool loggingIn = state.matchedLocation == '/login';
      final bool registering = state.matchedLocation == '/register';
      final bool forgettingPassword = state.matchedLocation == '/forgot-password';

      if(!loggedIn){
        //redirect to /login if not logged in and not on public page
        if(!loggingIn && !registering && !forgettingPassword){
          return '/login';
        }
      }
      else {
        if (loggingIn) {
          return '/';
        }
      }
      return null;
    },

    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        }
      ),

      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen();
        },

        routes: <RouteBase>[
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

//This class listens to the stream of auth changes and notifies GoRouter to recheck the redirect logic whenever there is a change (like login/logout)
//uesd in first GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}