import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_wrapper.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBV70LJ2lI8dvhteNMzCMo4swFiur8fo-M',
        appId: '1:450979258698:web:4ccfb44102d251a413e1b3',
        messagingSenderId: '450979258698',
        projectId: 'intellitrain-3fc95',
        authDomain: 'intellitrain-3fc95.firebaseapp.com',
        storageBucket: 'intellitrain-3fc95.firebasestorage.app',
      ),
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }
  
  runApp(
    const ProviderScope(
      child: IntelliTrainApp(),
    ),
  );
}

class IntelliTrainApp extends StatelessWidget {
  const IntelliTrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IntelliTrain',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(), // Automatically handles auth state
    );
  }
}
