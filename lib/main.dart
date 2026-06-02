import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'services/permission_service.dart';
import 'services/mesh_service.dart';
import 'services/notification_service.dart';
import 'providers/theme_provider.dart';
import 'widgets/error_boundary.dart';
import 'screens/splash_screen.dart';

void main() async {
  // Capturar errores en main
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    await PermissionService.requestAllPermissions();
    await DatabaseService.database;
    await DatabaseService.initSession();
    await MeshService.start();
    await NotificationService.initialize();
    
    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const EMCCApp(),
      ),
    );
  }, (error, stack) {
    print('Error capturado en main: $error');
    print('Stack trace: $stack');
  });
}

class EMCCApp extends StatelessWidget {
  const EMCCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'EMCC Digital',
          debugShowCheckedModeBanner: false,
          theme: ThemeProvider.lightTheme,
          darkTheme: ThemeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: ErrorBoundary(
            child: const SplashScreen(),
          ),
        );
      },
    );
  }
}

// Import necesario
import 'dart:async';
