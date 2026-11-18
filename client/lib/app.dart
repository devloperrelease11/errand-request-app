import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/theme.dart';
import 'core/token_storage.dart';
import 'providers/auth_provider.dart';
import 'providers/errand_provider.dart';
import 'screens/auth_gate.dart';

class ErrandApp extends StatelessWidget {
  const ErrandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ApiClient()),
        Provider(create: (_) => TokenStorage()),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(
            context.read<ApiClient>(),
            context.read<TokenStorage>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ErrandProvider(context.read<ApiClient>()),
        ),
      ],
      child: MaterialApp(
        title: 'Errands',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: const AuthGate(),
      ),
    );
  }
}
