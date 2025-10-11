import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../utils/navigation_utils.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? additionalActions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.additionalActions,
  });

  Future<void> _handleLogout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    NavigationUtils.pushAndRemoveUntil(context, LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            Provider.of<ThemeService>(context).darkMode 
              ? Icons.light_mode 
              : Icons.dark_mode,
          ),
          onPressed: () {
            Provider.of<ThemeService>(context, listen: false).toggleTheme();
          },
        ),
        if (additionalActions != null) ...additionalActions!,
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => _handleLogout(context),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}