// Local demo entry point for reviewing the REAL routes with test accounts.
// Never distribute this target; main.dart is the cloud app entry point.
import 'package:flutter/material.dart';
import 'package:parchapp/app/app.dart';
import 'package:parchapp/app/dependency_injection/app_dependencies.dart';
import 'package:parchapp/app/dependency_injection/firebase_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!const bool.fromEnvironment('USE_FIREBASE_EMULATORS') ||
      const String.fromEnvironment('FIREBASE_EMULATOR_PROJECT') !=
          'demo-parchapp-activity-metrics') {
    throw StateError('This preview requires the isolated local demo project.');
  }
  final firebase = await FirebaseDependencies.initialize();
  await firebase.auth.signInWithEmailAndPassword(
      email: 'metrics.owner@example.test', password: 'MetricsQa123!');
  await firebase.mobile.refreshSession();
  final router = createAppRouter(firebase)..go('/profile');
  runApp(ParchApp(router: router, offline: firebase.mobile));
}
