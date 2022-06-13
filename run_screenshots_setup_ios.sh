#!/bin/sh
flutter build ios --config-only integration_test/screenshot_test.dart \
--dart-define DISABLE_ADS=true