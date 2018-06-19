# dart_js_interop

A series of tests and samples of using JS interop with Dart 2.

The samples here _only_ utilize [`package:js`][1], not [`dart:js`][2], the
latter of which is (soft) deprecated and additional updates are not expected.
They are also built and run using the `2.0.0-dev.63.0` SDK.

**NOTE**: This repository is not an official resource.

[1]: https://pub.dartlang.org/documentation/js/latest/
[2]: https://api.dartlang.org/dev/2.0.0-dev.63.0/dart-js/dart-js-library.html

* [Examples](#examples)
  * [Basic Interop](#basic-interop)
* [Limitations](#limitations)
  * [Using ES Modules](#using-es-modules)
  * [Using Web Components](#using-web-components)

## Examples

### Basic Interop

#### Invoking a method

#### Creating a class

#### Creating an object

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
