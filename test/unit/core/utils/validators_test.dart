import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/utils/validators.dart';

class MockBuildContext extends Fake implements BuildContext {}

void main() {
  group('Validators.validateEmail', () {
    final context = MockBuildContext();

    test('returns error when value is null', () {
      expect(
        Validators.validateEmail(context, null),
        'Email is required',
      );
    });

    test('returns error when value is empty', () {
      expect(
        Validators.validateEmail(context, ''),
        'Email is required',
      );
    });

    test('returns error when value contains only whitespace', () {
      expect(
        Validators.validateEmail(context, '   '),
        'Email is required',
      );
    });

    test('returns error when email format is invalid', () {
      expect(
        Validators.validateEmail(context, 'invalid-email'),
        'Please enter a valid email',
      );
      expect(
        Validators.validateEmail(context, 'user@'),
        'Please enter a valid email',
      );
      expect(
        Validators.validateEmail(context, '@domain.com'),
        'Please enter a valid email',
      );
      expect(
        Validators.validateEmail(context, 'user@domain'),
        'Please enter a valid email',
      );
    });

    test('returns null for valid email with leading or trailing whitespace', () {
      expect(
        Validators.validateEmail(context, '  user@example.com'),
        isNull,
      );
      expect(
        Validators.validateEmail(context, 'user@example.com  '),
        isNull,
      );
      expect(
        Validators.validateEmail(context, ' \t user@example.com \n '),
        isNull,
      );
    });

    test('returns null for standard valid email', () {
      expect(
        Validators.validateEmail(context, 'user@example.com'),
        isNull,
      );
      expect(
        Validators.validateEmail(context, 'first.last+tag@sub.domain.co'),
        isNull,
      );
    });
  });
}
