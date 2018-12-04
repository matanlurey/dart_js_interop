# dart_js_interop

A series of tests and samples of using JS interop with Dart 2.

This repository was built and tested using the `2.0.0-dev.63.0` SDK.

**NOTE**: This repository is not an official resource.

[1]: https://pub.dartlang.org/documentation/js/latest/
[2]: https://api.dartlang.org/dev/2.0.0-dev.63.0/dart-js/dart-js-library.html

* [Running the tests](#running-the-tests)
* [Why `package:js`](#why-packagejs)
  * [Getting Started](#getting-started)
* [Examples](#examples)
  * [Basic Interop](#basic-interop)
    * [Invoking a method](#invoking-a-method)
    * [Creating a class](#creating-a-class)
    * [Creating a structured object](#creating-a-structured-object)
    * [Creating an unstructured object](#creating-an-unstructured-object)
  * [Advanced Interop](#advanced-interop)
    * [Passing a callback](#passing-a-callback)
    * [Creating a wrapper class](#creating-a-wrapper-class)
    * [Converting a callback-based API to return a `Future`](#converting-a-callback-based-api-to-return-a-future)
    * [Converting a callback-based API to return a `Stream`](#converting-a-callback-based-api-to-return-a-stream)
* [Limitations and Known Issues](#limitations-and-known-issues)
  * [Generic Type Arguments](#generic-type-arguments)
  * [Using ES Modules](#using-es-modules)
  * [Creating Web Components](#creating-web-components)

## Running the tests

To run all of the tests in DartDevCompiler (DDC):

```bash
$ pub run build_runner test
```

To run all of the tests in Dart2JS:

```bash
$ pub run build_runner test -r
```

To run all of the tests in Dart2JS with spec-compliance mode:

```bash
$ pub run build_runner test -r -c spec
```

(This disables the `--omit-implicit-checks` flag)

## Why `package:js`?

As you can see from the [examples](#examples) below, `package:js` gives a Dart
idiomatic API, as well as offering additional features that are not easily
available using `dart:js`. It is/was out of scope for this documentation to show
the _performance_ benefit (`package:js` almost always emits _better_ JS code
than the same code written using `dart:js`).

Historically, `dart:js` was written primarily for Dartium, where the Dart VM and
JavaScript VM were separate, and required a lot of (untyped) coordination
between the two. Now that both the development and production compilers emit JS
much of the mechanics of `dart:js` are no longer required.

### Getting Started

Using `package:js` has a number of small requirements:

* Import `package:js` and annotate your `library` directive with `@JS()`:

  ```dart
  // Most Dart code doesn't require a library directive anymore, but @JS() does.
  // It is likely this requirement will be relaxed in the future.

  @JS()
  library interop_lib;

  import 'package:js/js.dart';
  ```

* To auto-generate typed wrappers, place an `@JS()` annotation on either a:

  * Top-level `external` method:


  ```dart
  @JS()
  library interop_lib;

  import 'package:js/js.dart';

  // A reference to window.someMethod.
  @JS()
  external void someMethod();
  ```

  * Top-level `external` getter, or setter:


  ```dart
  @JS()
  library interop_lib;

  import 'package:js/js.dart';

  // A reference to window.appVersion;
  @JS()
  external String get appVersion;
  ```

  * Class delcaration:


  ```dart
  @JS()
  library interop_lib;

  import 'package:js/js.dart';

  // A class you will return instances of, but not create.
  @JS()
  abstract class SomeClass {}

  // A class you will want to create from Dart code.
  @JS()
  abstract class SomeClass {
    external factory SomeClass();
  }

  // A class that represents an anonymous JS object (`{}`) and not a real class
  @JS()
  @anonymous
  abstract class PropertyBag {
    external factory PropertyBag({String a, String b});
    external String get a;
    external String get b;
  }
  ```

> _What does the `external` keyword mean?_
>
> This tells the Dart web compilers that the _implementation_ of the method
> is not code you have authored, but rather is implemented _externally_. In this
> case, it is JavaScript code already lodaded on the page.

## Examples

### Basic Interop

_See `test/basic_interop_test.dart`._

#### Invoking A Method

The simplest example, which includes invoking a method defined in JavaScript
with positional parameters, and getting access to the return value. When using
the preferred path (`package:js`) this is extremely easy.

```js
// lib.js

function addNumbers(a, b) {
  return a + b;
}
```

```dart
// lib.dart

@JS()
library lib;

import 'package:js/js.dart';

@JS()
external num addNumbers(num a, num b);

void add1And2() {
  print(addNumbers(1, 2));
}
```

> _DEPRECATED_: The same example using `dart:js`:
>
> ```dart
> import 'dart:js';
>
> void add1And2() {
>   final JsFunction _addNumbers = context['addNumbers'];
>   print(_addNumbers.apply([1, 2]));
> }
> ```

#### Creating a class

To reference a class (or class-like) object defined in JavaScript, it is
possible to define a class structure (and instance methods or fields) similar
to methods.

```js
// lib.js

function Animal(name) {
  this.name = name;
}
Animal.prototype.talk = function() {
  return 'I am a ' + this.name;
};
```

```dart
// lib.dart

@JS()
library lib;

import 'package:js/js.dart';

@JS()
abstract class Animal {
  external factory Animal(String name);
  external String talk();
}

void createAnimal() {
  final animal = new Animal('Dog);
  print(animal.talk());
}
```

> _DEPRECATED_: The same example using `dart:js`:
>
> ```dart
> import 'dart:js';
>
> void createAnimal() {
>   final JsFunction animalClass = context['Animal'];
>   final animal = new JsObject(animalClass, ['Dog']);
>   print(animal.callMethod('talk));
> }
> ```

#### Creating a structured object

Sometimes it is useful to create a _structured_ JavaScript object that does not
directly relate to a class. This is commonly used as optional parameters or
configuration for some APIs. For example, creating `{'name': '...'}`:

```dart
// lib.dart

@JS()
library lib;

import 'package:js/js.dart';

@JS()
@anonymous
abstract class ObjectWithName {
  external factory ObjectWithName({String name});
  external String get name;
}

void createObject() {
  var object = new ObjectWithName(name: 'Joe');
}
```

> _DEPRECATED_: The same example using `dart:js`:
>
> ```dart
> import 'dart:js';
>
> void createObject() {
>   var object = new JsObject.jsify({'name': 'Jill User'});
> }
> ```

#### Creating an unstructured object

Or for creating an _unstructured_ object (without dynamic fields):

```dart
// lib.dart

import 'package:js/js_util.dart' as js;

void main() {
  var object = js.newObject();
  js.setProperty(object, 'anyName', 'anyValue');
}
```

> _DEPRECATED_: The same example using `dart:js`:
>
> ```dart
> import 'dart:js';
>
> void createObject() {
>   var object = new JsObject.jsify({});
>   object['anyName'] = 'anyValue';
> }
> ```

### Advanced Interop

_See `test/advanced_interop_test.dart`._

#### Passing a callback

Passing a function defined in Dart to be invoked from a JavaScript API requires
another bit of boilerplate to ensure compatibility. The `allowInterop` and the
`allowInteropCaptureThis` methods of `package:js` (formerly in `dart:js`) allow
this.

```js
// lib.js

function invokeCallback(callback) {
  callback();
}
```

```dart
// lib.dart

@JS()
library lib;

import 'package:js/js.dart';

@JS()
external void invokeCallback(void Function() callback);

void main() {
  invokeCallback(allowInterop(() => print('Called!)));
}
```

> **WARNING**: If you have code that relies on `Zone` from `dart:async` you may
> need additional wrapper code to ensure that registered callbacks are invoked
> within the correct `Zone`.
>
> ```dart
> @JS()
> library lib;
>
> import 'package:js/js.dart';
>
> @JS('invokeCallback')
> external void _invokeCallback(void Function() callback);
>
> void invokeCallback(void Function() callback) {
>   _invokeCallback(allowInterop(Zone.current.bindCallback(callback))); 
> }
> ```

> _DEPRECATED_: The same example using `dart:js`:
>
> ```dart
> import 'dart:js';
>
> void main() {
>   context.callMethod('invokeCallback', [
>     allowInterop(() => print('Called!)),
>   ]);
> }
> ```

#### Creating a wrapper class

Using `package:js` allows creating a nice API surface for accessing JavaScript
code - but ultimately it is still JavaScript. Sometimes it may be desirable to
create a Dart-specific wrapper to provide more Dart-idiomatic APIs.

For example, JavaScript does not have reified generics (every instance of `List`
which is backed by an `Array` has a type argument of `dynamic`). In the below
example, `dogs` is a `List<dynamic>`, not the expected `List<String>`.

_(See [Generic Type Arguments][#generic-type-arguments] for known issues.)_

```js
// lib.js

function Kennel() {
  this.dogs = ['Spot', 'Fido'];
}
```

```dart
// lib.dart

@JS()
library lib;

import 'package:js/js.dart';

@JS('Kennel')
abstract class _Kennel {
  external factory _Kennel();
  external List<dynamic> get dogs;
}

class Kennel {
  final _jsKennel = new _Kennel();
  List<String> get dogs => new List.from(_jsKennel.dogs);
}
```

#### Converting a callback-based API to return a `Future`

Similar to [passing a callback](passing-a-callback), but exposing a `Future`
based API instead, which is more idiomatic in most Dart code. We'll use the
`Completer` API to accomplish this:

```js
// lib.js

function fetchGoodBoy(callback) {
  callback('All dogs are good boys!');
}
```

```dart
// lib.dart

@JS()
library lib;

import 'dart:async';

import 'package:js/js.dart';

@JS('fecthGoodBoy')
external void _fetchGoodBoy(void Function(String) callback);

Future<String> fetchGoodBoy() {
  final completer = new Completer<void>();
  _invokeCallback(allowInterop(completer.complete));
  return completer.future;
}

void main() async {
  print(await fetchGoodBoy());
}
```

#### Converting a callback-based API to return a `Stream`

For events that occur multiple times (like events).

```js
// lib.js

function fetchGoodBoys(callback, options) {
  callback('Fido');
  callback('Spot');
  if (options.onDone) {
    options.onDone();
  }
}
```

```dart
// lib.dart

@JS()
library lib;

import 'dart:async';

import 'package:js/js.dart';

external void _fetchGoodBoys(void Function(String) callback, _Options options);

@JS()
@anonymous
abstract class _Options {
  external factory _Options({void Function() onDone});
}

Stream<String> fetchGoodBoys() {
  final controller = new StreamController<String>();
  _fetchGoodBoys(allowInterop((dog) {
    controller.add(dog);
  }), new _Options(onDone: allowInterop(() {
    controller.close();
  })));
  return controller.stream;
}
```

## Limitations and Known Issues

_See `test/known_issues_test.dart`._

The following are known limitations of JS interop at the time of writing this
repository. If you have a tight deadline project or strict requirements to use
these features I'd consider writing your own "shims" in JavaScript or TypeScript
and calling into them from Dart, versus trying to use Dart's JS interop
directly.

### Generic Type Arguments

Exposing and using types with reified generic type arguments is not fully
supported by JS interop, and may be inconsistent depending on the compiler and
compiler options used. The only _safe_ route is to _always_ assume that generic
type arguments are not supplied (i.e. are bound to `dynamic`) and use
conversions and casts in [wrapper code](#creating-a-wrapper-class) where
desired.

#### Type annotating external APIs

```js
// lib.js

window.listOfDogs = ['Fido', 'Spot'];
```

```dart
// lib.dart

@JS()
library lib;

import 'package:js/js.dart';

@JS()
external List<String> get listOfDogs;

void main() {
  // Always true.
  print(listOfDogs is List);

  // Always false.
  print(listOfDogs is List<String>);

  Object upcast = listOfDogs;
  // Succeeds in DartDevC, Dart2JS with --omit-implicit-checks
  // Fails (throws `TypeError`) in Dart2JS without --omit-implicit-checks
  List<String> dogs = upcast;

  // Always fails (throws either `CastError` in DDC or `TypeError` in Dart2JS)
  Object upcast = listOfDogs;
  var dogs = upcast as List<String>;

  // Succeeds in DartDevC, Dart2JS with --omit-implicit-checks
  // Fails (throws `TypeError`) in Dart2JS without --omit-implicit-checks
  listOfDogs.map((dog) => '$dog').toList();
}
```

### Using ES Modules

[ES Modules][3] are not supported.

All JS APIs must exist in the global namespace (`window` in the browser).

[3]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/import

### Creating Web Components

Creating [Web Components][4] are not supported.

These require more tie-ins with the compilers than JS interop can provide.
_However_, consuming web components works perfectly fine - you can re-use any
web components authored in another JS framework or vanilla JS.

[4]: https://developer.mozilla.org/en-US/docs/Web/Web_Components
