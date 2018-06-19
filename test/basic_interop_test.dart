@JS()
@TestOn('browser')
library test.basic_interop;

// These are soft-deprecated, but test are present to ensure 1:1.
import 'dart:js' show context, JsFunction, JsObject;

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js;
import 'package:test/test.dart';

@JS()
external num addNumbers(num a, num b);

@JS()
abstract class Animal {
  external factory Animal(String name);
  external String talk();
}

@JS()
@anonymous
abstract class ObjectWithName {
  external factory ObjectWithName({String name});
  external String get name;
}

void main() {
  test('should call a JS function', () {
    expect(addNumbers(1, 2), 3);
  });

  test('should call a JS function [DEPRECATED]', () {
    // Using JsFunction
    final JsFunction addNumbers = context['addNumbers'];
    expect(addNumbers.apply([1, 2]), 3);

    // Using JsObject
    final JsObject globalWindow = context;
    expect(globalWindow.callMethod('addNumbers', [1, 2]), 3);
  });

  test('should create a JS class', () {
    final animal = new Animal('Dog');
    expect(animal.talk(), 'I am a Dog');
  });

  test('should create a JS class [DEPRECATED]', () {
    final JsFunction animalClass = context['Animal'];
    final animal = new JsObject(animalClass, ['Dog']);
    expect(animal.callMethod('talk'), 'I am a Dog');
  });

  test('should create an anonymous structured JS object', () {
    final named = new ObjectWithName(name: 'Jill User');
    expect(named.name, 'Jill User');
  });

  test('should create an anonymous structured JS object [DEPRECATED]', () {
    final named = new JsObject.jsify({'name': 'Jill User'});
    expect(named['name'], 'Jill User');
  });

  test('should create an unstructured JS object', () {
    final named = js.newObject();
    js.setProperty(named, 'name', 'John User');
    expect(js.getProperty(named, 'name'), 'John User');
  });

  test('should create an unstructured JS object [DEPRECATED]', () {
    final named = new JsObject.jsify({});
    named['name'] = 'John User';
    expect(named['name'], 'John User');
  });
}
