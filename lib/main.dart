import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/services/fcm_service.dart';
import 'core/navigation.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/call/screens/contacts_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize FCM Service
  await FCMService().initialize();
  
  runApp(
    const ProviderScope(
      child: AgoraCallKitDemoApp(),
    ),
  );
}

class AgoraCallKitDemoApp extends ConsumerStatefulWidget {
  const AgoraCallKitDemoApp({super.key});

  @override
  ConsumerState<AgoraCallKitDemoApp> createState() => _AgoraCallKitDemoAppState();
}

class _AgoraCallKitDemoAppState extends ConsumerState<AgoraCallKitDemoApp> {
  @override
  void initState() {
    super.initState();
    // Validate session on app launch
    Future.microtask(() {
      ref.read(authProvider.notifier).checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Call App',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: const Color(0xFF121214),
        cardColor: const Color(0xFF1C1C1E),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.blueGrey,
          surface: Color(0xFF1C1C1E),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.user != null) {
      return const ContactsScreen();
    } else if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    } else {
      return const LoginScreen();
    }
  }
}
