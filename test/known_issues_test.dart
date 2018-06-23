@JS()
@TestOn('browser')
library test.knonwn_issues;

import 'package:js/js.dart';
import 'package:test/test.dart';

// Hack to detect whether --omit-implicit-checks is enabled.
final bool omitImplicitChecks = (() {
  try {
    Object notAString = 5;
    String implicitString = notAString;
    return implicitString != null;
  } on TypeError catch (_) {
    return false;
  }
})();

@JS()
external List<String> get listOfDogs;

@JS()
@anonymous
abstract class HasValueField {
  @JS()
  external String get value;
}

@JS()
external List<HasValueField> get listOfValues;

void main() {
  group('treating JSArray as JSArray<String>', () {
    test('succeeds implicitly', () {
      List<String> dogs = listOfDogs;
      expect(dogs, ['Fido', 'Spot']);
    });

    test('fails explicitly', () {
      final Object upcastList = listOfDogs;
      expect(() => upcastList as List<String>, _throwsTypeOrCastError);
    });

    test('fails an "is" check', () {
      expect(listOfDogs is List<String>, isFalse);
    });

    test('succeeds during a for-loop', () {
      var results = <String>[];
      expect(() {
        for (final dog in listOfDogs) {
          results.add(dog);
        }
      }, returnsNormally);
      expect(results, ['Fido', 'Spot']);
    });

    group('during a .map call', () {
      void callMapMethod() {
        listOfDogs.map((dog) => '$dog').toList();
        listOfDogs.map((String dog) => '$dog').toList();
      }

      if (omitImplicitChecks) {
        test('succeeds', () {
          expect(callMapMethod, returnsNormally);
        });
      } else {
        test('fails without --omit-implicit-checks', () {
          expect(callMapMethod, _throwsTypeOrCastError);
        });
      }
    });
  });

  group('treating JSArray as JSArray<JSType>', () {
    if (omitImplicitChecks) {
      test('succeeds implicitly', () {
        final Object upcastList = listOfValues;
        expect(() {
          List<HasValueField> dogs = upcastList;
          expect(dogs, hasLength(2));
        }, returnsNormally);
      });
    } else {
      test('fails implicitly without --omit-implicit-checks', () {
        final Object upcastList = listOfValues;
        expect(() {
          List<HasValueField> dogs = upcastList;
          expect(dogs, hasLength(2));
        }, _throwsTypeOrCastError);
      });
    }

    test('fails explicitly', () {
      final Object upcastList = listOfValues;
      expect(
        () => upcastList as List<HasValueField>,
        _throwsTypeOrCastError,
      );
    });

    test('fails an "is" check', () {
      expect(listOfValues is List<HasValueField>, isFalse);
    });

    test('succeeds during a for-loop', () {
      var results = <String>[];
      expect(() {
        for (final dog in listOfValues) {
          results.add(dog.value);
        }
      }, returnsNormally);
      expect(results, ['Fido', 'Spot']);
    });

    group('during a .map call', () {
      void callMapMethod() {
        listOfValues.map((dog) => '${dog.value}').toList();
        listOfValues.map((HasValueField dog) => '${dog.value}').toList();
      }

      if (omitImplicitChecks) {
        test('succeeds', () {
          expect(callMapMethod, returnsNormally);
        });
      } else {
        test('fails without --omit-implicit-checks', () {
          expect(callMapMethod, _throwsTypeOrCastError);
        });
      }
    });
  });
}

final _throwsTypeOrCastError = throwsA(
  anyOf(const TypeMatcher<CastError>(), const TypeMatcher<TypeError>()),
);
