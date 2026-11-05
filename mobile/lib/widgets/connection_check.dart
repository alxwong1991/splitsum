import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api/health_api.dart';

class ConnectionCheck extends StatefulWidget {
  const ConnectionCheck({super.key, this.api});

  final HealthApi? api;

  @override
  State<ConnectionCheck> createState() => _ConnectionCheckState();
}

class _ConnectionCheckState extends State<ConnectionCheck> {
  late final HealthApi _api;
  bool _loading = false;
  bool _connected = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api =
        widget.api ??
        HealthApi(
          baseUrl: const String.fromEnvironment('API_BASE_URL'),
          client: http.Client(),
        );
  }

  @override
  void dispose() {
    if (widget.api == null) {
      _api.close();
    }
    super.dispose();
  }

  Future<void> _check() async {
    setState(() {
      _loading = true;
      _connected = false;
      _error = null;
    });
    try {
      await _api.check();
      if (!mounted) return;
      setState(() => _connected = true);
    } on ConnectionCheckException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SplitSum connection',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _api.baseUrl.isEmpty
                  ? 'Backend URL is not configured.'
                  : _api.baseUrl,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (_loading) ...[
              const CircularProgressIndicator(),
              const Text('Checking backend and PostgreSQL...'),
            ] else if (_connected)
              const Text('Connected: backend and PostgreSQL are ready.')
            else if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              )
            else
              const Text('Not checked yet.'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _loading ? null : _check,
              child: const Text('Check connection'),
            ),
          ],
        ),
      ),
    );
  }
}
