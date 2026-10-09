import 'package:flutter/material.dart';
import 'package:pusher/pusher.dart';

void main() {
  runApp(const MyApp());
}

/// Minimal host shell. Real usage needs Firebase + panel keys via [Pusher.init].
class MyApp extends StatelessWidget {
  /// Creates the example app.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'pusher — call Pusher.init(projectId:, statsKey:)\n'
            'statusDelivered=${Pusher.statusDelivered}',
            textAlign: .center,
          ),
        ),
      ),
    );
  }
}
