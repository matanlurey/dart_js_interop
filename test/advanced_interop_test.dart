@JS()
@TestOn('browser')
library test.advanced_interop;

import 'dart:async';

// These are soft-deprecated, but test are present to ensure 1:1.
import 'dart:js' show context;

import 'package:js/js.dart';
import 'package:test/test.dart';

@JS()
external void invokeCallback(void Function() callback);

@JS('Kennel')
abstract class _Kennel {
  external factory _Kennel();
  List<dynamic> get dogs;
}

class Kennel {
  final _jsKennel = _Kennel();
  List<String> get dogs => List.from(_jsKennel.dogs);
}

@JS('fetchGoodBoy')
external void _fetchGoodBoy(void Function(String) callback);

Future<String> fetchGoodBoy() {
  final completer = Completer<String>();
  _fetchGoodBoy(allowInterop(completer.complete));
  return completer.future;
}

@JS('fetchGoodBoys')
external void _fetchGoodBoys(void Function(String) callback, _Options options);

@JS()
@anonymous
abstract class _Options {
  external factory _Options({void Function() onDone});
}

Stream<String> fetchGoodBoys() {
  final controller = StreamController<String>();
  _fetchGoodBoys(
    allowInterop(controller.add),
    _Options(onDone: allowInterop(controller.close)),
  );
  return controller.stream;
}

void main() {
  test('should call a JS function that invokes a callback', () {
    invokeCallback(allowInterop(expectAsync0(() {})));
  });

  test('should call a JS function that invokes a callback [DEPRECATED]', () {
    context.callMethod('invokeCallback', [
      allowInterop(expectAsync0(() {})),
    ]);
  });

  test('should wrap a JS class', () {
    final kennel = Kennel();
    expect(kennel.dogs, const TypeMatcher<List<String>>());
  });

  test('should convert a callback-based API to a Future-based one', () async {
    expect(await fetchGoodBoy(), 'All dogs are good boys!');
  });

  test('should convert a callback-based API to a Stream-based one', () async {
    expect(await fetchGoodBoys().toList(), ['Fido', 'Spot']);
  });
}
