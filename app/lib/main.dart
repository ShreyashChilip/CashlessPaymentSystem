import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'firebase_options.dart';
import 'services/initialization_service.dart';
import 'services/theme_service.dart';
import 'package:page_transition/page_transition.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    final initService = InitializationService();
    await initService.initializeApp();
  } catch (e) {
    print('Initialization error: $e');
    // Continue with app launch even if initialization fails
  }
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'School App',
          theme: themeService.lightTheme,
          darkTheme: themeService.darkTheme,
          themeMode: themeService.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: LoginScreen(),
          debugShowCheckedModeBanner: false,
          onGenerateRoute: (settings) {
            // Add custom page transitions
            switch (settings.name) {
              default:
                return PageTransition(
                  type: PageTransitionType.fade,
                  duration: const Duration(milliseconds: 300),
                  child: settings.name == '/'
                      ? LoginScreen()
                      : LoginScreen(),
                );
            }
          },
        );
      },
    );
  }
}