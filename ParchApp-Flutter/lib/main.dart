import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/dependency_injection/app_dependencies.dart';
import 'app/dependency_injection/firebase_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final firebase = await FirebaseDependencies.initialize();
    runApp(ParchApp(router: createAppRouter(firebase)));
  } catch (error, stack) {
    debugPrint('ParchApp initialization failed: $error');
    debugPrintStack(stackTrace: stack);
    runApp(const MaterialApp(
        home: Scaffold(
            body: Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                        'Unable to start ParchApp. Check Firebase configuration and restart.'))))));
  }
}
