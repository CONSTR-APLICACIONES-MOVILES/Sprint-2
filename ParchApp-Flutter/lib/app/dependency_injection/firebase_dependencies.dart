import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../firebase_options.dart';

/// Uses the checked-in live configuration or the shared demo-parchapp emulators.
class FirebaseDependencies {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;
  FirebaseDependencies._(this.auth, this.firestore, this.functions);

  static Future<FirebaseDependencies> initialize() async {
    const emulators =
        bool.fromEnvironment('USE_FIREBASE_EMULATORS', defaultValue: true);
    // Platform configuration now creates a live default app on Android. Keep
    // it initialized (native Firestore needs a default delegate), and isolate
    // emulator Auth/Firestore/Functions in a separate named app.
    final defaultApp = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    final FirebaseApp app;
    if (emulators) {
      final platform = kIsWeb
          ? 'web'
          : switch (defaultTargetPlatform) {
              TargetPlatform.android => 'android',
              TargetPlatform.iOS || TargetPlatform.macOS => 'ios',
              _ => 'web',
            };
      // Emulator-only placeholders. Android Functions validates API-key syntax
      // even locally; demoProjectId's short generated key fails that validation.
      app = await Firebase.initializeApp(
          name: 'demo-parchapp',
          options: FirebaseOptions(
              apiKey: 'A00000000000000000000000000000000000000',
              appId: '1:1234567890:$platform:0000000000000000000000',
              messagingSenderId: '1234567890',
              projectId: 'demo-parchapp'));
    } else {
      app = defaultApp;
    }
    final auth = FirebaseAuth.instanceFor(app: app);
    final firestore = FirebaseFirestore.instanceFor(app: app);
    final functions =
        FirebaseFunctions.instanceFor(app: app, region: 'us-central1');
    if (emulators) {
      const configuredHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST');
      final host = configuredHost.isNotEmpty
          ? configuredHost
          : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
              ? '10.0.2.2'
              : '127.0.0.1';
      await auth.useAuthEmulator(host, 9099);
      firestore.useFirestoreEmulator(host, 8080);
      firestore.settings = const Settings(persistenceEnabled: false);
      functions.useFunctionsEmulator(host, 5001);
    }
    // Wait for any persisted account before constructing routes/catalog queries.
    await auth.authStateChanges().first;
    return FirebaseDependencies._(auth, firestore, functions);
  }
}
