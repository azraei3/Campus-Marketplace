import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/chats/chat_list_screen.dart';
import '../screens/chats/chat_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/home_screen.dart';
import '../screens/listings/create_listing_screen.dart';
import '../screens/listings/edit_listing_screen.dart';
import '../screens/listings/listing_analytics_screen.dart';
import '../screens/listings/listing_detail_screen.dart';
import '../screens/listings/my_listings_screen.dart';
import '../screens/listings/saved_listings_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/ratings/seller_profile_screen.dart';
import '../screens/ratings/submit_rating_screen.dart';
import '../screens/register_screen.dart';
import '../screens/requests/incoming_requests_screen.dart';
import '../screens/requests/my_requests_screen.dart';
import '../screens/requests/request_detail_screen.dart';

class AppRouter {
  final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable:
        GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = FirebaseAuth.instance.currentUser != null;
      final bool loggingIn = state.matchedLocation == '/login';
      final bool registering = state.matchedLocation == '/register';
      final bool forgettingPassword =
          state.matchedLocation == '/forgot-password';

      if (!loggedIn) {
        if (!loggingIn && !registering && !forgettingPassword) {
          return '/login';
        }
      } else {
        if (loggingIn) return '/';
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) => const HomeScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'profile',
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: 'listings/create',
            builder: (_, __) => CreateListingScreen(),
          ),
          GoRoute(
            path: 'my-listings',
            builder: (_, __) => const MyListingsScreen(),
          ),
          GoRoute(
            path: 'saved',
            builder: (_, __) => const SavedListingsScreen(),
          ),
          GoRoute(
            path: 'listings/:listingId',
            builder: (_, state) {
              final id = state.pathParameters['listingId'] ?? '';
              return ListingDetailScreen(listingId: id);
            },
            routes: <RouteBase>[
              GoRoute(
                path: 'edit',
                builder: (_, state) {
                  final id = state.pathParameters['listingId'] ?? '';
                  return EditListingScreen(listingId: id);
                },
              ),
              GoRoute(
                path: 'analytics',
                builder: (_, state) {
                  final id = state.pathParameters['listingId'] ?? '';
                  return ListingAnalyticsScreen(listingId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'my-requests',
            builder: (_, __) => const MyRequestsScreen(),
          ),
          GoRoute(
            path: 'incoming-requests',
            builder: (_, __) => const IncomingRequestsScreen(),
          ),
          GoRoute(
            path: 'requests/:requestId',
            builder: (_, state) {
              final id = state.pathParameters['requestId'] ?? '';
              return RequestDetailScreen(requestId: id);
            },
            routes: <RouteBase>[
              GoRoute(
                path: 'rate',
                builder: (_, state) {
                  final id = state.pathParameters['requestId'] ?? '';
                  return SubmitRatingScreen(requestId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'sellers/:sellerId',
            builder: (_, state) {
              final id = state.pathParameters['sellerId'] ?? '';
              return SellerProfileScreen(sellerId: id);
            },
          ),
          GoRoute(
            path: 'chats',
            builder: (_, __) => const ChatListScreen(),
          ),
          GoRoute(
            path: 'chats/:chatId',
            builder: (_, state) {
              final id = state.pathParameters['chatId'] ?? '';
              return ChatScreen(chatId: id);
            },
          ),
        ],
      ),
    ],
  );
}

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
