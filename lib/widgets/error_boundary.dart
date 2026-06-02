// lib/widgets/error_boundary.dart
import 'package:flutter/material.dart';
import '../screens/error_screen.dart';
import '../services/debug_logger.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({
    super.key,
    required this.child,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  dynamic _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    
    // Capturar errores de Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      DebugLogger.error("Flutter error", details.exception);
      if (mounted) {
        setState(() {
          _error = details.exception;
          _stackTrace = details.stack;
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorScreen(
        errorMessage: _error.toString(),
        stackTrace: _stackTrace,
      );
    }
    return widget.child;
  }
}
