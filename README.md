# dart_js_interop

A series of tests and samples of using JS interop with Dart 2.

This repository was built and tested using the `2.0.0-dev.63.0` SDK.

**NOTE**: This repository is not an official resource.

[1]: https://pub.dartlang.org/documentation/js/latest/
[2]: https://api.dartlang.org/dev/2.0.0-dev.63.0/dart-js/dart-js-library.html

* [Running the tests](#running-the-tests)
* [Why `package:js`](#why-packagejs)
* [Examples](#examples)
  * [Basic Interop](#basic-interop)
    * [Invoking a method](#invoking-a-method)
    * [Creating a class](#creating-a-class)
    * [Creating a structured object](#creating-a-structured-object)
    * [Creating an unstructured object](#creating-an-unstructured-object)
* [Limitations](#limitations)
  * [Using ES Modules](#using-es-modules)
  * [Using Web Components](#using-web-components)
  
## Running the tests

To run all of the tests in DartDevCompiler (DDC):

```bash
$ pub run build_runner test
```

To run all of the tests in Dart2JS:

```bash
$ pub run build_runner test -r
```

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

## Examples

### Basic Interop

_See `test/basic_interop_test.dart`._

#### Invoking a method

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

```dart
// lib.dart

@JS()
library lib;

import 'package:js/js.dart';

@JS()
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
```dart
// lib.dart

import 'package:js/js_util.dart' as js;

void main() {
  var object = js.createObject();
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

## Limitations

The following are known limitations of JS interop at the time of writing this
repository. If you have a tight deadline project or strict requirements to use
these features I'd consider writing your own "shims" in JavaScript or TypeScript
and calling into them from Dart, versus trying to use Dart's JS interop
directly.

### Using ES Modules

[ES Modules][3] are not supported.

All JS APIs must exist in the global namespace (`window` in the browser).

[3]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/import

### Using Web Components

[Web Components][4] are not supported.

These require more tie-ins with the compilers than JS interop can provide.

[4]: https://developer.mozilla.org/en-US/docs/Web/Web_Components
