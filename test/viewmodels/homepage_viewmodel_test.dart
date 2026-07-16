import 'package:flutter_test/flutter_test.dart';
import 'package:lms_chatbot/app/app.locator.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('HomepageViewModel Tests -', () {
    setUp(() => registerServices());
    tearDown(() => locator.reset());
  });
}
