#!/bin/sh
flutter drive --driver=test_driver/integration_test.dart \
--target=integration_test/screenshot_test.dart \
--dart-define DISABLE_ADS=true