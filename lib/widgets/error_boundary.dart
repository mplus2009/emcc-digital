// lib/widgets/error_boundary.dart
import 'package:flutter/material.dart';
import '../screens/error_screen.dart';
import '../services/debug_logger.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final VoidCallback? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
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
    // Capturar errores no capturados en Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      DebugLogger.error("Flutter error capturado", details.exception);
      DebugLogger.error("Flutter error stack", details.stack.toString());
      setState(() {
        _error = details.exception;
        _stackTrace = details.stack;
      });
      widget.onError?.call();
    };
    
    // Capturar errores asíncronos
    PlatformDispatcher.instance.onError = (error, stack) {
      DebugLogger.error("Error asíncrono capturado", error);
      DebugLogger.error("Error asíncrono stack", stack.toString());
      setState(() {
        _error = error;
        _stackTrace = stack;
      });
      return true;
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorScreen(
        error: _error!,
        stackTrace: _stackTrace,
        onRetry: () {
          setState(() {
            _error = null;
            _stackTrace = null;
          });
        },
      );
    }
    return widget.child;
  }
}
