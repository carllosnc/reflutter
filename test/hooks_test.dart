// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reflutter/react.dart';

Widget _wrap(Widget child) => Directionality(
      textDirection: TextDirection.ltr,
      child: MaterialApp(home: child),
    );

void main() {
  group('useState', () {
    testWidgets('persists across rebuilds and triggers rebuild on set',
        (tester) async {
      int buildCount = 0;

      await tester.pumpWidget(_wrap(
        HookScope(
          builder: (context) {
            buildCount++;
            final count = useState(0);
            return TextButton(
              onPressed: () => count.set((v) => v + 1),
              child: Text('v:${count.value}'),
            );
          },
        ),
      ),);

      expect(find.text('v:0'), findsOneWidget);
      expect(buildCount, 1);

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(find.text('v:1'), findsOneWidget);
      expect(buildCount, 2);
    });

    testWidgets('multiple useState keep independent slots', (tester) async {
      await tester.pumpWidget(_wrap(
        HookScope(
          builder: (context) {
            final a = useState(0);
            final b = useState(10);
            return Column(
              children: [
                Text('a:${a.value}'),
                Text('b:${b.value}'),
                TextButton(
                  onPressed: () => a.set((v) => v + 1),
                  child: const Text('incA'),
                ),
              ],
            );
          },
        ),
      ),);

      expect(find.text('a:0'), findsOneWidget);
      expect(find.text('b:10'), findsOneWidget);

      await tester.tap(find.text('incA'));
      await tester.pump();

      expect(find.text('a:1'), findsOneWidget);
      expect(find.text('b:10'), findsOneWidget);
    });
  });

  group('useEffect', () {
    testWidgets('runs once on mount with empty deps', (tester) async {
      var runs = 0;

      await tester.pumpWidget(_wrap(
        HookScope(
          builder: (context) {
            useEffect(() {
              runs++;
              return null;
            }, [],);
            return const SizedBox.shrink();
          },
        ),
      ),);
      await tester.pumpAndSettle();

      expect(runs, 1);

      // force rebuild
      await tester.pumpWidget(_wrap(
        HookScope(
          builder: (context) {
            useEffect(() {
              runs++;
              return null;
            }, [],);
            return const SizedBox.shrink();
          },
        ),
      ),);
      await tester.pumpAndSettle();

      expect(runs, 1, reason: 'should not re-run with same deps');
    });

    testWidgets('re-runs when deps change', (tester) async {
      var runs = 0;

      await tester.pumpWidget(_wrap(
        HookScope(
          builder: (context) {
            final count = useState(0);
            useEffect(() {
              runs++;
              return null;
            }, [count.value],);
            return TextButton(
              onPressed: () => count.set((v) => v + 1),
              child: Text('${count.value}'),
            );
          },
        ),
      ),);
      await tester.pumpAndSettle();

      expect(runs, 1);

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      expect(runs, 2);
    });

    testWidgets('runs cleanup before next effect and on unmount',
        (tester) async {
      final cleanups = <String>[];
      var effectRuns = 0;

      await tester.pumpWidget(_wrap(
        HookScope(
          builder: (context) {
            final count = useState(0);
            useEffect(() {
              effectRuns++;
              cleanups.add('effect $effectRuns');
              return () => cleanups.add('cleanup $effectRuns');
            }, [count.value],);
            return TextButton(
              onPressed: () => count.set((v) => v + 1),
              child: Text('${count.value}'),
            );
          },
        ),
      ),);
      await tester.pumpAndSettle();

      expect(cleanups, ['effect 1']);

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      expect(cleanups, ['effect 1', 'cleanup 1', 'effect 2']);

      // unmount
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      expect(cleanups, ['effect 1', 'cleanup 1', 'effect 2', 'cleanup 2']);
    });

    testWidgets('runs every build when deps are omitted', (tester) async {
      var runs = 0;

      await tester.pumpWidget(_wrap(
        HookScope(
          builder: (context) {
            final count = useState(0);
            useEffect(() {
              runs++;
              return null;
            });
            return TextButton(
              onPressed: () => count.set((v) => v + 1),
              child: Text('${count.value}'),
            );
          },
        ),
      ),);
      await tester.pumpAndSettle();

      expect(runs, 1);

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      expect(runs, 2);
    });
  });

  group('useMemo', () {
    testWidgets('recomputes only when deps change', (tester) async {
      var computations = 0;

      await tester.pumpWidget(_wrap(
        HookScope(
          builder: (context) {
            final count = useState(0);
            final doubled = useMemo(() {
              computations++;
              return count.value * 2;
            }, [count.value],);
            return TextButton(
              onPressed: () => count.set((v) => v + 1),
              child: Text('d:$doubled'),
            );
          },
        ),
      ),);

      expect(find.text('d:0'), findsOneWidget);
      expect(computations, 1);

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(find.text('d:2'), findsOneWidget);
      expect(computations, 2);
    });
  });

  group('useRef', () {
    testWidgets('persists across rebuilds without triggering them',
        (tester) async {
      var builds = 0;

      await tester.pumpWidget(_wrap(
        HookScope(
          builder: (context) {
            builds++;
            final ref = useRef(0);
            return TextButton(
              onPressed: () => ref.current = ref.current + 1,
              child: Text('r:${ref.current}'),
            );
          },
        ),
      ),);

      expect(find.text('r:0'), findsOneWidget);

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      // mutating ref.current does NOT rebuild the widget
      expect(find.text('r:0'), findsOneWidget);
      expect(builds, 1);
    });
  });

  group('guards', () {
    testWidgets('useState throws when called outside HookScope',
        (tester) async {
      await tester.pumpWidget(_wrap(
        _ThrowOnBuild(child: () => useState(0)),
      ),);
      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('useEffect throws when called outside HookScope',
        (tester) async {
      await tester.pumpWidget(_wrap(
        _ThrowOnBuild(child: () => useEffect(() => null)),
      ),);
      expect(tester.takeException(), isA<AssertionError>());
    });
  });
}

class _ThrowOnBuild extends StatelessWidget {
  const _ThrowOnBuild({required this.child});
  final void Function() child;
  @override
  Widget build(BuildContext context) {
    child();
    return const SizedBox.shrink();
  }
}
