import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/auth_page.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://xattcymvfutogrxszgen.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhhdHRjeW12ZnV0b2dyeHN6Z2VuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4NjA1NjcsImV4cCI6MjA5MjQzNjU2N30.J3NUi7t87a1zyryKAEVu5_m3-1_Ldk0v839ya4e_sh8',
  );
  runApp(const SushiSocialApp());
}

class SushiSocialApp extends StatelessWidget {
  const SushiSocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sushi Social',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53935),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AuthState> _authStream =
      Supabase.instance.client.auth.onAuthStateChange;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStream,
      builder: (context, _) {
        final session = Supabase.instance.client.auth.currentSession;
        return session == null ? const AuthPage() : const HomePage();
      },
    );
  }
}
