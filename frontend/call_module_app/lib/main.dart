import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/cs_screen.dart';
import 'screens/manager_screen.dart';
import 'screens/technician_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mini Daily Call Module',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: _router,
    );
  }
}

// ── Router: decides which screen to show ──────────────────────────────────────
final _router = GoRouter(
  initialLocation: '/login',

  // On app start, check if already logged in
  redirect: (context, state) async {
    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn) return '/login';

    // If already logged in and trying to go to login, redirect to home
    if (state.matchedLocation == '/login') {
      final role = await AuthService.getRole();
      return _homeForRole(role);
    }
    return null;
  },

  routes: [
    GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/cs', builder: (c, s) => const CsScreen()),
    GoRoute(path: '/manager', builder: (c, s) => const ManagerScreen()),
    GoRoute(path: '/technician', builder: (c, s) => const TechnicianScreen()),
  ],
);

// Which home screen to go to based on role
String _homeForRole(String? role) {
  switch (role) {
    case 'cs':
      return '/cs';
    case 'manager':
      return '/manager';
    case 'technician':
      return '/technician';
    default:
      return '/login';
  }
}
