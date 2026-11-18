import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/errand.dart';
import '../models/user.dart';
import '../providers/errand_provider.dart';
import 'errand_detail_screen.dart';

enum ErrandListMode { mine, open, assigned }

class ErrandListScreen extends StatelessWidget {
  const ErrandListScreen({
    super.key,
    required this.mode,
    required this.role,
  });

  final ErrandListMode mode;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Consumer<ErrandProvider>(
      builder: (context, provider, _) {
        final items = switch (mode) {
          ErrandListMode.mine => provider.mine,
          ErrandListMode.open => provider.open,
          ErrandListMode.assigned => provider.assigned,
        };
        final state = switch (mode) {
          ErrandListMode.mine => provider.mineState,
          ErrandListMode.open => provider.openState,
          ErrandListMode.assigned => provider.assignedState,
        };
        final error = switch (mode) {
          ErrandListMode.mine => provider.mineError,
          ErrandListMode.open => provider.openError,
          ErrandListMode.assigned => provider.assignedError,
        };

        Future<void> refresh() => provider.refreshFor(role);

        if (state == ListState.initial || state == ListState.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state == ListState.failure) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 48),
                  const SizedBox(height: 12),
                  Text(error ?? 'Could not load errands.', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inbox_outlined, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    switch (mode) {
                      ErrandListMode.mine => 'You have not posted any errands yet.',
                      ErrandListMode.open => 'No open errands right now.',
                      ErrandListMode.assigned => 'You have no accepted errands.',
                    },
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final errand = items[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      role == UserRole.requester ? Icons.assignment : Icons.delivery_dining,
                    ),
                  ),
                  title: Text(
                    errand.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'From: ${errand.pickupAddress}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'To: ${errand.dropoffAddress}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(errand.status.label),
                        avatar: CircleAvatar(
                          backgroundColor: _statusColor(errand.status),
                          radius: 5,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ErrandDetailScreen(
                        errand: errand,
                        role: role,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

Color _statusColor(ErrandStatus status) => switch (status) {
  ErrandStatus.open => Colors.blue,
  ErrandStatus.accepted => Colors.orange,
  ErrandStatus.inProgress => Colors.indigo,
  ErrandStatus.completed => Colors.green,
  ErrandStatus.cancelled => Colors.grey,
  _ => Colors.grey,
};
