import 'package:flutter/foundation.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../firebase_options.dart';

class FirebaseDependencies {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;

  FirebaseDependencies._(
    this.auth,
    this.firestore,
    this.functions,
  );

  static Future<FirebaseDependencies>
      initialize() async {
    // ============================================================
    // USE FIREBASE EMULATORS?
    // ============================================================

    const useEmulators =
        bool.fromEnvironment(
      'USE_FIREBASE_EMULATORS',
      defaultValue: true,
    );

    debugPrint(
      'FIREBASE INIT -> '
      'useEmulators=$useEmulators',
    );

    // ============================================================
    // INITIALIZE FIREBASE
    // ============================================================

    FirebaseApp app;

    try {
      app = Firebase.app();

      debugPrint(
        'FIREBASE INIT -> '
        'Existing DEFAULT app found.',
      );
    } on FirebaseException {
      debugPrint(
        'FIREBASE INIT -> '
        'No DEFAULT app found. Creating it...',
      );

      app =
          await Firebase.initializeApp(
        options:
            DefaultFirebaseOptions
                .currentPlatform,
      );
    }

    debugPrint(
      'FIREBASE INIT -> '
      'app.name=${app.name}',
    );

    debugPrint(
      'FIREBASE INIT -> '
      'projectId=${app.options.projectId}',
    );

    // ============================================================
    // FIREBASE SERVICES
    // ============================================================

    final auth =
        FirebaseAuth.instanceFor(
      app: app,
    );

    final firestore =
        FirebaseFirestore.instanceFor(
      app: app,
    );

    final functions =
        FirebaseFunctions.instanceFor(
      app: app,
      region: 'us-central1',
    );

    // ============================================================
    // FIRESTORE LOCAL CACHE
    // ============================================================
    //
    // IMPORTANT:
    //
    // Previously this was false.
    //
    // Now Firestore is allowed to keep local cached documents,
    // which enables our network -> cache fallback strategy.
    // ============================================================

    firestore.settings =
        const Settings(
      persistenceEnabled: true,
    );

    // ============================================================
    // FIREBASE EMULATORS
    // ============================================================

    if (useEmulators) {
      const configuredHost =
          String.fromEnvironment(
        'FIREBASE_EMULATOR_HOST',
      );

      final String host;

      if (configuredHost.isNotEmpty) {
        host = configuredHost;
      } else if (!kIsWeb &&
          defaultTargetPlatform ==
              TargetPlatform.android) {
        host = '10.0.2.2';
      } else {
        // iOS Simulator, macOS, web, etc.
        host = '127.0.0.1';
      }

      debugPrint(
        '============================================================',
      );

      debugPrint(
        'FIREBASE EMULATOR -> '
        'platform=$defaultTargetPlatform',
      );

      debugPrint(
        'FIREBASE EMULATOR -> '
        'host=$host',
      );

      debugPrint(
        'FIREBASE EMULATOR -> '
        'Auth http://$host:9099',
      );

      debugPrint(
        'FIREBASE EMULATOR -> '
        'Firestore http://$host:8080',
      );

      debugPrint(
        'FIREBASE EMULATOR -> '
        'Functions http://$host:5001',
      );

      debugPrint(
        '============================================================',
      );

      try {
        await auth.useAuthEmulator(
          host,
          9099,
        );

        debugPrint(
          'FIREBASE EMULATOR -> '
          'Auth configured successfully.',
        );
      } catch (error) {
        debugPrint(
          'FIREBASE EMULATOR -> '
          'Auth configuration error: '
          '$error',
        );

        rethrow;
      }

      try {
        firestore
            .useFirestoreEmulator(
          host,
          8080,
        );

        debugPrint(
          'FIREBASE EMULATOR -> '
          'Firestore configured successfully.',
        );
      } catch (error) {
        debugPrint(
          'FIREBASE EMULATOR -> '
          'Firestore configuration error: '
          '$error',
        );

        rethrow;
      }

      try {
        functions
            .useFunctionsEmulator(
          host,
          5001,
        );

        debugPrint(
          'FIREBASE EMULATOR -> '
          'Functions configured successfully.',
        );
      } catch (error) {
        debugPrint(
          'FIREBASE EMULATOR -> '
          'Functions configuration error: '
          '$error',
        );

        rethrow;
      }

      debugPrint(
        'FIREBASE EMULATOR -> '
        'Configuration completed.',
      );
    } else {
      debugPrint(
        'FIREBASE INIT -> '
        'Using REAL Firebase services.',
      );
    }

    // ============================================================
    // AUTH STATE
    // ============================================================

    debugPrint(
      'FIREBASE AUTH -> '
      'Waiting for initial auth state...',
    );

    final initialUser =
        await auth
            .authStateChanges()
            .first;

    debugPrint(
      'FIREBASE AUTH -> '
      'uid=${initialUser?.uid ?? "NONE"}',
    );

    debugPrint(
      'FIREBASE INIT -> Finished.',
    );

    return FirebaseDependencies._(
      auth,
      firestore,
      functions,
    );
  }
}