import 'package:flutter/material.dart';
import 'package:pusher/pusher_sdk.dart';

void main() {
  runApp(const MyApp());
}

/// Minimal host shell. Real usage needs Firebase + panel keys via [PusherSdk.init].
class MyApp extends StatelessWidget {
  /// Creates the example app.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'pusher — call PusherSdk.init(projectId:, statsKey:)\n'
            'statusDelivered=${PusherSdk.statusDelivered}',
            textAlign: .center,
          ),
        ),
      ),
    );
  }
}
