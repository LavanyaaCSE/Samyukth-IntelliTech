import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/auth_service.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/main_screen.dart';
import 'models/user_model.dart';

/// AuthWrapper automatically handles navigation based on authentication state
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // User is not logged in, show login screen
          return const LoginScreen();
        } else {
          // User is logged in, show main screen
          // Default to student role, you can enhance this by storing role in Firestore
          return const MainScreen(role: UserRole.student);
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      ),
      error: (error, stack) {
        print('Auth error: $error');
        return const LoginScreen();
      },
    );
  }
}
