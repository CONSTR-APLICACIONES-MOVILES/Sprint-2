import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/dependency_injection/app_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await _initFirebase();
  runApp(ParchApp(router: createAppRouter(firebaseReady: firebaseReady)));
}

Future<bool> _initFirebase() async {
  try {
    await Firebase.initializeApp();
    return true;
  } catch (error) {
    debugPrint('Firebase not configured, using demo data: $error');
    return false;
  }
}
