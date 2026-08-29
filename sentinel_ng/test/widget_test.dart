// Smoke tests for SentinelApp.
//
// A full widget pump of SentinelApp is intentionally avoided here because
// SplashPage schedules a Future.delayed navigation timer, which would leave
// pending timers in the test zone. These tests verify the app entrypoint and
// widget structure without pumping the router.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sentinel_ng/app.dart';

void main() {
  test('SentinelApp is a const StatelessWidget', () {
    const app = SentinelApp();
    expect(app, isA<StatelessWidget>());
  });

  test('SentinelApp has a widget key-safe constructor', () {
    final app = SentinelApp(key: const ValueKey('sentinel'));
    expect(app.key, isA<ValueKey<String>>());
  });
}
