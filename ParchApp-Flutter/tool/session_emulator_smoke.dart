// Focused Android SDK check; local fixtures only. Leaves Auth signed out.
import 'package:flutter/material.dart';
import 'package:parchapp/app/dependency_injection/firebase_dependencies.dart';
import 'package:parchapp/app/dependency_injection/app_dependencies.dart';
import 'package:parchapp/app/router/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String result;
  try {
    if (!const bool.fromEnvironment('USE_FIREBASE_EMULATORS',
        defaultValue: true)) {
      throw StateError('Only local emulators are allowed.');
    }
    final firebase = await FirebaseDependencies.initialize();
    final router = createAppRouter(firebase);
    if (router.routeInformationProvider.value.uri.path != AppRoutes.signIn) {
      throw StateError('Startup bypassed Sign-In.');
    }
    router.dispose();
    try {
      await firebase.auth.signInWithEmailAndPassword(
          email: const String.fromEnvironment('EMULATOR_EMAIL'),
          password: const String.fromEnvironment('EMULATOR_PASSWORD'));
      await firebase.auth.currentUser!.getIdToken(true);
      final activities = await firebase.mobile.call('getActivities', {});
      final profile = await firebase.mobile.call('getProfile', {});
      if (!(activities['activities'] as List).any((a) =>
          a['id'] == const String.fromEnvironment('EMULATOR_ACTIVITY_ID'))) {
        throw StateError('The seeded activity was not returned.');
      }
      if ((profile['name'] as String? ?? '').isEmpty) {
        throw StateError('The real profile was not loaded.');
      }
      result =
          'PASS: explicit Sign-In startup, Android Auth, activity refresh and profile callables.';
    } finally {
      await firebase.auth.signOut();
    }
  } catch (error, stack) {
    result = 'FAIL: $error';
    debugPrintStack(stackTrace: stack);
  }
  debugPrint(result);
  runApp(MaterialApp(home: Scaffold(body: Center(child: Text(result)))));
}
