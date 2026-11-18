import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'config.dart';

void main() {
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: AppConfig.isConfigured
          ? const ErrandApp()
          : const ConfigurationError(),
    ),
  );
}

class ConfigurationError extends StatelessWidget {
  const ConfigurationError({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'API_BASE_URL is missing. Create client/config.json from '
              'config.example.json and run with --dart-define-from-file=config.json',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
