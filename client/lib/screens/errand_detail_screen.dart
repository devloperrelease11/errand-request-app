import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/api_exception.dart';
import '../models/errand.dart';
import '../models/user.dart';
import '../providers/errand_provider.dart';

class ErrandDetailScreen extends StatefulWidget {
  const ErrandDetailScreen({
    super.key,
    required this.errand,
    required this.role,
  });

  final Errand errand;
  final UserRole role;

  @override
  State<ErrandDetailScreen> createState() => _ErrandDetailScreenState();
}

class _ErrandDetailScreenState extends State<ErrandDetailScreen> {
  late Errand _errand;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _errand = widget.errand;
  }

  String? get _action {
    if (widget.role == UserRole.requester) {
      return _errand.status == ErrandStatus.open ? 'cancel' : null;
    }
    return switch (_errand.status) {
      ErrandStatus.open => 'accept',
      ErrandStatus.accepted => 'start',
      ErrandStatus.inProgress => 'complete',
      _ => null,
    };
  }

  Future<void> _perform(String action) async {
    setState(() => _working = true);
    try {
      final updated = await context.read<ErrandProvider>().performAction(
        errand: _errand,
        action: action,
        role: widget.role,
      );
      if (!mounted) return;
      setState(() => _errand = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errand is now ${updated.status.label}')),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : 'The action failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = _action;
    final locale = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_errand.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Chip(
                label: Text('Status: ${_errand.status.label}'),
                avatar: const CircleAvatar(radius: 4),
              ),
              const SizedBox(height: 12),
              Text(_errand.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 20),
              _Section(label: 'Description', content: _errand.description),
              _Section(label: 'Pickup address', content: _errand.pickupAddress),
              _Section(label: 'Drop-off address', content: _errand.dropoffAddress),
              const SizedBox(height: 12),
              Text(
                'Posted ${locale.formatShortDate(_errand.createdAt)}',
                style: theme.textTheme.bodySmall,
              ),
              if (_errand.acceptedAt != null)
                Text(
                  'Accepted ${locale.formatShortDate(_errand.acceptedAt!)}',
                  style: theme.textTheme.bodySmall,
                ),
              if (_errand.completedAt != null)
                Text(
                  'Completed ${locale.formatShortDate(_errand.completedAt!)}',
                  style: theme.textTheme.bodySmall,
                ),
              const SizedBox(height: 28),
              if (action != null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _working ? null : () => _perform(action),
                    icon: _working
                        ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Icon(_actionIcon(action)),
                    label: Text(_actionLabel(action)),
                  ),
                )
              else
                Text(
                  _errand.status.isFinal
                      ? 'This errand is finished.'
                      : 'No action is available for this errand.',
                  style: theme.textTheme.bodyMedium,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _actionIcon(String action) => switch (action) {
    'accept' => Icons.check_circle_outline,
    'start' => Icons.play_arrow,
    'complete' => Icons.done_all,
    _ => Icons.cancel_outlined,
  };

  String _actionLabel(String action) => switch (action) {
    'accept' => 'Accept errand',
    'start' => 'Start errand',
    'complete' => 'Mark completed',
    _ => 'Cancel errand',
  };
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.content});

  final String label;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(content, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
