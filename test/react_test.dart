// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reflutter/react.dart';

void main() {
  group('globalState', () {
    test('holds the initial value and is typed', () {
      final counter = globalState<int>(0);
      expect(counter.value, 0);
      expect(counter.value, isA<int>());
    });

    test('setState updates the value via the callback', () {
      final counter = globalState<int>(0);
      counter.setState((v) => v + 5);
      expect(counter.value, 5);
    });

    test('setState notifies listeners exactly once per change', () {
      final counter = globalState<int>(0);
      var calls = 0;
      counter.addListener(() => calls++);

      counter.setState((v) => v + 1);
      expect(calls, 1);

      counter.setState((v) => v + 1);
      expect(calls, 2);
    });

    test('setState with the same value does not notify', () {
      final counter = globalState<int>(0);
      var calls = 0;
      counter.addListener(() => calls++);

      counter.setState((v) => v);
      expect(calls, 0);
    });

    test('useEffect fires on change and the disposer removes it', () {
      final counter = globalState<int>(0);
      var calls = 0;

      final dispose = counter.useEffect(() => calls++);

      counter.setState((v) => v + 1);
      expect(calls, 1);

      dispose();

      counter.setState((v) => v + 1);
      expect(calls, 1);
    });

    test('removeEffect removes a previously registered callback', () {
      final counter = globalState<int>(0);
      var calls = 0;
      void cb() => calls++;

      counter.useEffect(cb);
      counter.setState((v) => v + 1);
      expect(calls, 1);

      counter.removeEffect(cb);
      counter.setState((v) => v + 1);
      expect(calls, 1);
    });

    test('useEffect works when called outside of build', () {
      final counter = globalState<int>(0);
      var calls = 0;
      counter.useEffect(() => calls++);
      counter.setState((v) => v + 1);
      expect(calls, 1);
    });
  });

  group('RenderGlobal', () {
    testWidgets('rebuilds and passes the new value to the builder', (tester) async {
      final counter = globalState<int>(0);
      String? shown;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RenderGlobal<int>(
            valueListenable: counter,
            builder: (context, value, child) {
              shown = value.toString();
              return Text(value.toString());
            },
          ),
        ),
      );

      expect(shown, '0');
      expect(find.text('0'), findsOneWidget);

      counter.setState((v) => v + 1);
      await tester.pump();

      expect(shown, '1');
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('stops listening when unmounted', (tester) async {
      final counter = globalState<int>(0);
      var builds = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RenderGlobal<int>(
            valueListenable: counter,
            builder: (context, value, child) {
              builds++;
              return Text(value.toString());
            },
          ),
        ),
      );
      expect(builds, 1);

      await tester.pumpWidget(const SizedBox.shrink());

      // No exception should be thrown when the listenable changes after the
      // widget was disposed.
      counter.setState((v) => v + 1);
      await tester.pump();
      expect(builds, 1);
    });
  });

  group('RenderLocal', () {
    testWidgets('rebuilds when its StateSetter is called', (tester) async {
      var count = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RenderLocal(
            builder: (context, setState) {
              return TextButton(
                onPressed: () => setState(() => count++),
                child: Text('count $count'),
              );
            },
          ),
        ),
      );

      expect(find.text('count 0'), findsOneWidget);

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(find.text('count 1'), findsOneWidget);
    });
  });

  group('RenderEffect', () {
    testWidgets('registers on mount and removes on unmount', (tester) async {
      final counter = globalState<int>(0);
      var calls = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RenderEffect<int>(
            listenable: counter,
            effect: () => calls++,
            child: const SizedBox.shrink(),
          ),
        ),
      );

      counter.setState((v) => v + 1);
      expect(calls, 1);

      await tester.pumpWidget(const SizedBox.shrink());

      counter.setState((v) => v + 1);
      expect(calls, 1);
    });
  });

  group('debug build guard', () {
    testWidgets('useEffect inside a RenderGlobal builder throws', (tester) async {
      final counter = globalState<int>(0);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RenderGlobal<int>(
            valueListenable: counter,
            builder: (context, value, child) {
              counter.useEffect(() {});
              return Text(value.toString());
            },
          ),
        ),
      );

      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('useEffect inside a RenderLocal builder throws', (tester) async {
      final counter = globalState<int>(0);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RenderLocal(
            builder: (context, setState) {
              counter.useEffect(() {});
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(tester.takeException(), isA<AssertionError>());
    });
  });
}
