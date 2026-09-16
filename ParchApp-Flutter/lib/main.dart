import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/dependency_injection/app_dependencies.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ParchApp(router: createAppRouter()));
}
