// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '/react.dart';

/// A counter built entirely with hooks — no StatefulWidget, no globalState.
/// Demonstrates useState, useEffect (with deps + cleanup), useMemo and useRef.
Widget hooksPage() {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Hooks'),
    ),
    body: Center(
      child: HookScope(
        builder: (context) {
          final count = useState(0);
          final double = useMemo(() => count.value * 2, [count.value]);
          final labelRef = useRef<String>('initial');

          useEffect(() {
            labelRef.current = 'count: ${count.value}';
            print('Effect ran: count=${count.value}, double=$double');

            return () {
              print('Cleanup before next effect / on unmount');
            };
          }, [count.value],);

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                labelRef.current,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'doubled: $double',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: () => count.set((v) => v - 1),
                    child: const Text('Decrement'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () => count.set((v) => v + 1),
                    child: const Text('Increment'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ),
  );
}
