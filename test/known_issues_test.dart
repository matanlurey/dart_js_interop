@JS()
@TestOn('browser')
library test.knonwn_issues;

import 'package:js/js.dart';
import 'package:test/test.dart';

// Hack to detect whether we are running in DDC or Dart2JS.
@JS(r'$dartLoader')
external Object get _$dartLoader;
final bool isDartDevC = _$dartLoader != null;
final bool isDart2JS = !isDartDevC;

// Hack to detect whether Dart2JS's --omit-implicit-checks is enabled.
final bool omitImplicitChecks = (() {
  try {
    Object notAString = 5;
    String implicitString = notAString;
    return implicitString != null;
  } on TypeError catch (_) {
    return false;
  }
})();

// Hack to detect whether DartDevC's --ignore-cast-failures is enabled.
//
// --ignore-cast-failures allows ignoring almost any implicit cast failure
// from C<dynmaic> to C<T>. Otherwise only a small set of whitelisted types
// ignore cast failures.
class _CastMe<T> {}
final bool ignoreCastFailures = (() {
  try {
    final ofDynamic = new _CastMe();
    _CastMe<String> ofString = ofDynamic;
    return ofString != null;
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

@JS()
abstract class JSContainer<T> {
  external factory JSContainer(T value);

  external T get value;
}

@JS()
external JSContainer<String> get valueOfFoo;

// We need at least one example of using a JS-type that is not a Dart object
// (and not something special cased like `JSArray`) to see how something fails
// at runtime/compile-time.
@JS()
@anonymous
abstract class AnonymousJSContainer<T> {
  external factory AnonymousJSContainer({T value});
  external T get value;
}

@JS()
external AnonymousJSContainer<String> get valueOfHelloWorld;

void main() {
  print('Compiler: ${isDartDevC ? 'DartDevC' : 'Dart2JS'}');
  if (!isDartDevC) {
    print('omitImplicitChecks: $omitImplicitChecks');
  } else {
    print('ignoreCastFailures: $ignoreCastFailures');
  }

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

      if (isDartDevC || isDart2JS && omitImplicitChecks) {
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
    if (isDart2JS && omitImplicitChecks) {
      test('succeeds implicitly', () {
        final Object upcastList = listOfValues;
        expect(() {
          List<HasValueField> dogs = upcastList;
          expect(dogs, hasLength(2));
        }, returnsNormally);
      });
    } else {
      test('fails implicitly in DartDevC or Dart2JS without --omit-implicit-checks', () {
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
      }

      if (isDartDevC || isDart2JS && omitImplicitChecks) {
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

  group('treating a JSType as if it has a type argument <T>', () {
    test('succeeds implicitly', () {
      final Object upcastValue = valueOfFoo;
      final JSContainer<String> container = upcastValue;
      expect(container.value, 'Foo');
    });

    test('succeeds explicitly', () {
      final Object upcastValue = valueOfFoo;
      final container = upcastValue as JSContainer<String>;
      expect(container.value, 'Foo');
    });

    test('has a <T> where T = String', () {
      Type extractType<T>(JSContainer<T> j) => T;
      expect(extractType(valueOfFoo), String);
    });

    test('should allow creating a new instance', () {
      final newInstance = new JSContainer(5);
      expect(newInstance is JSContainer<int>, isTrue);
      expect(newInstance.value, 5);
    });
  });

  group('treating an @anonymous JSType as if it has a type argument <T>', () {
    test('succeeds implicitly', () {
      final Object upcastValue = valueOfHelloWorld;
      final AnonymousJSContainer<String> container = upcastValue;
      expect(container.value, 'Hello World');
    });

    test('succeeds explicitly', () {
      final Object upcastValue = valueOfHelloWorld;
      final container = upcastValue as AnonymousJSContainer<String>;
      expect(container.value, 'Hello World');
    });

    test('has a <T> where T = String', () {
      Type extractType<T>(AnonymousJSContainer<T> j) => T;
      expect(extractType(valueOfHelloWorld), String);
    });

    test('should allow creating a new instance', () {
      final newInstance = new AnonymousJSContainer(value: 5);
      expect(newInstance is AnonymousJSContainer<int>, isTrue);
      expect(newInstance.value, 5);
    });
  });
}

final _throwsTypeOrCastError = throwsA(
  anyOf(const TypeMatcher<CastError>(), const TypeMatcher<TypeError>()),
);
