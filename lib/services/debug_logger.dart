// lib/services/debug_logger.dart
import 'package:flutter/material.dart';

class DebugLogger {
  static final List<String> _logs = [];
  static final List<String> _errors = [];
  static ValueNotifier<List<String>> logsNotifier = ValueNotifier([]);
  static ValueNotifier<List<String>> errorsNotifier = ValueNotifier([]);
  
  static void log(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logEntry = "[$timestamp] $message";
    _logs.add(logEntry);
    print(logEntry);
    logsNotifier.value = List.from(_logs);
  }
  
  static void error(String message, [dynamic error]) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final errorEntry = "[$timestamp] ERROR: $message ${error != null ? "- $error" : ""}";
    _errors.add(errorEntry);
    print(errorEntry);
    errorsNotifier.value = List.from(_errors);
  }
  
  static void clear() {
    _logs.clear();
    _errors.clear();
    logsNotifier.value = [];
    errorsNotifier.value = [];
  }
  
  static Widget buildDebugPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: "Logs", icon: Icon(Icons.info, size: 16)),
                Tab(text: "Errores", icon: Icon(Icons.error, size: 16)),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
            ),
            SizedBox(
              height: 200,
              child: TabBarView(
                children: [
                  ValueListenableBuilder(
                    valueListenable: logsNotifier,
                    builder: (context, logs, _) {
                      return ListView.builder(
                        reverse: true,
                        itemCount: logs.length,
                        itemBuilder: (ctx, i) => Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            logs[logs.length - 1 - i],
                            style: const TextStyle(color: Colors.green, fontSize: 10),
                          ),
                        ),
                      );
                    },
                  ),
                  ValueListenableBuilder(
                    valueListenable: errorsNotifier,
                    builder: (context, errors, _) {
                      return ListView.builder(
                        reverse: true,
                        itemCount: errors.length,
                        itemBuilder: (ctx, i) => Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            errors[errors.length - 1 - i],
                            style: const TextStyle(color: Colors.red, fontSize: 10),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
