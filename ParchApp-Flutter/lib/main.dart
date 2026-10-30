import 'package:flutter/material.dart';
import 'app/app.dart';
import 'app/dependency_injection/app_dependencies.dart';
import 'app/dependency_injection/firebase_dependencies.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw before waiting for restored Auth, network and storage.
  runApp(AppBootstrap(initialize: () async {
    final firebase = await FirebaseDependencies.initialize();
    return ParchApp(
        router: createAppRouter(firebase), offline: firebase.mobile);
  }));
}

class AppBootstrap extends StatefulWidget {
  final Future<Widget> Function() initialize;
  const AppBootstrap({super.key, required this.initialize});
  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final Future<Widget> _app = widget.initialize();
  @override
  Widget build(BuildContext context) => FutureBuilder<Widget>(
      future: _app,
      builder: (context, snapshot) {
        if (snapshot.hasData) return snapshot.data!;
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: snapshot.hasError
                            ? const Text(
                                'Unable to start ParchApp. Check your connection and restart.',
                                textAlign: TextAlign.center)
                            : const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            color: Color(0xFF52634F))),
                                    SizedBox(height: 20),
                                    Text('ParchApp',
                                        style: TextStyle(
                                            fontSize: 20,
                                            color: Color(0xFF52634F))),
                                  ])))));
      });
}
