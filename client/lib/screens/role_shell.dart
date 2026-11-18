import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/errand_provider.dart';
import 'create_errand_screen.dart';
import 'errand_list_screen.dart';
import 'profile_screen.dart';

class RoleShell extends StatefulWidget {
  const RoleShell({super.key, required this.user});

  final User user;

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ErrandProvider>().refreshFor(widget.user.role);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRunner = widget.user.role == UserRole.runner;
    final pages = <Widget>[
      ErrandListScreen(
        mode: isRunner ? ErrandListMode.open : ErrandListMode.mine,
        role: widget.user.role,
      ),
      if (isRunner)
        ErrandListScreen(
          mode: ErrandListMode.assigned,
          role: widget.user.role,
        )
      else
        const CreateErrandScreen(),
      ProfileScreen(user: widget.user),
    ];
    final titles = isRunner
        ? ['Open errands', 'My accepted errands', 'Profile']
        : ['My errands', 'New errand', 'Profile'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ErrandProvider>().refreshFor(widget.user.role),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: isRunner
            ? const [
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Open',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment),
                label: 'Accepted',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ]
            : const [
              NavigationDestination(
                icon: Icon(Icons.list_alt_outlined),
                selectedIcon: Icon(Icons.list_alt),
                label: 'My errands',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: 'New',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
      ),
    );
  }
}
