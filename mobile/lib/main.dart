import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'core/api/api_client.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_scope.dart';
import 'core/auth/token_store.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/screens/auth_gate.dart';
import 'features/auth/state/session_controller.dart';
import 'features/auth/state/session_scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.session});
  final SessionController? session;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _themeMode = ValueNotifier(ThemeMode.system);
  late final SessionController _session;

  @override
  void initState() {
    super.initState();
    _session =
        widget.session ??
        SessionController(
          api: AuthApi(
            client: ApiClient(
              client: http.Client(),
              baseUrl: const String.fromEnvironment(
                'API_BASE_URL',
                defaultValue: kDebugMode ? 'http://localhost:3000' : '',
              ),
            ),
          ),
          store: kIsWeb ? EphemeralTokenStore() : SecureTokenStore(),
        );
    _session.restore();
  }

  @override
  void dispose() {
    _themeMode.dispose();
    if (widget.session == null) {
      _session.dispose();
      _session.api.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: _themeMode,
      child: SessionScope(
        session: _session,
        child: ListenableBuilder(
          listenable: _session,
          builder: (_, _) => ValueListenableBuilder(
            valueListenable: _themeMode,
            builder: (_, mode, _) => MaterialApp(
              key: ValueKey(_session.account?.id ?? 'signed-out'),
              title: 'SplitSum',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: mode,
              home: AuthGate(session: _session),
            ),
          ),
        ),
      ),
    );
  }
}
