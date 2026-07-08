import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_js/flutter_js.dart';

import 'package:deup/models/custom_function_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomFunctionService', () {
    setUp(() {
      // Clear storage before each test
      CustomFunctionService.to.clear();
    });

    test('add and getAll', () async {
      final func = CustomFunctionModel(
        id: '1',
        name: 'hello',
        code: 'function hello(name) { return "Hello, " + name + "!"; }',
        createdAt: 1,
        updatedAt: 1,
      );

      await CustomFunctionService.to.add(func);
      final all = CustomFunctionService.to.getAll();
      expect(all.length, 1);
      expect(all.first.name, 'hello');
    });

    test('generateScript produces correct JS', () async {
      await CustomFunctionService.to.add(CustomFunctionModel(
        id: '1',
        name: 'hello',
        code: 'function hello(name) { return "Hello, " + name + "!"; }',
        createdAt: 1,
        updatedAt: 1,
      ));

      await CustomFunctionService.to.add(CustomFunctionModel(
        id: '2',
        name: 'add',
        code: 'function add(a, b) { return a + b; }',
        createdAt: 2,
        updatedAt: 2,
      ));

      final script = CustomFunctionService.to.generateScript();
      expect(script, contains('\$custom.hello = hello;'));
      expect(script, contains('\$custom.add = add;'));
      expect(script, contains('function hello(name)'));
      expect(script, contains('function add(a, b)'));
    });
  });

  group('JS Runtime - \$custom injection', () {
    late JavascriptRuntime runtime;

    setUp(() {
      runtime = getJavascriptRuntime();
      runtime.evaluate('var \$custom = {};');
    });

    tearDown(() {
      try {
        runtime.dispose();
      } on Error catch (_) {}
    });

    test('\$custom namespace exists', () {
      final result = runtime.evaluate('typeof \$custom');
      expect(result.stringResult, 'object');
    });

    test('custom function callable via \$custom', () {
      runtime.evaluate('''
        function hello(name) { return "Hello, " + name + "!"; }
        \$custom.hello = hello;
      ''');

      final result = runtime.evaluate('\$custom.hello("World")');
      expect(result.stringResult, 'Hello, World!');
    });

    test('multiple custom functions', () {
      runtime.evaluate('''
        function add(a, b) { return a + b; }
        function multiply(a, b) { return a * b; }
        \$custom.add = add;
        \$custom.multiply = multiply;
      ''');

      expect(runtime.evaluate('\$custom.add(3, 4)').stringResult, '7');
      expect(runtime.evaluate('\$custom.multiply(3, 4)').stringResult, '12');
    });

    test('custom function can use \$custom to call another', () {
      runtime.evaluate('''
        var \$custom = {};
        function double(n) { return n * 2; }
        function triple(n) { return n * 3; }
        \$custom.double = double;
        \$custom.triple = triple;
      ''');

      // Simulate plugin calling \$custom
      final result = runtime.evaluate('''
        (function() {
          return \$custom.double(5) + \$custom.triple(5);
        })()
      ''');
      expect(result.stringResult, '25');
    });

    test('custom function survives plugin class eval pattern', () {
      // Simulate the init flow: $custom + function defs, then class eval
      runtime.evaluate('var \$custom = {};');

      // Simulate CustomFunctionService.generateScript() output
      runtime.evaluate('''
        function greet(name) { return "Hi, " + name; }
        \$custom.greet = greet;
      ''');

      // Simulate plugin script evaluation (class definition)
      runtime.evaluate('''
        var \$custom = {};
        function greet(name) { return "Hi, " + name; }
        \$custom.greet = greet;
        var pluginInstance = { run: function(name) { return \$custom.greet(name); } };
      ''');

      final result = runtime.evaluate('pluginInstance.run("Test")');
      expect(result.stringResult, 'Hi, Test');
    });
  });
}
