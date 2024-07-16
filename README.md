# Reflutter

> Coding Flutter in React way

This is an experiment to see if it's possible to code Flutter in React way.
I ignored performance issues caused by helper methods/functional widgets,
this project is just for fun. Don't be so serious.

Check a simple counter example below:

```dart
import 'package:flutter/material.dart';
import '/react.dart';

Widget counter() {
  var count = useState(0);

  increment() {
    count.setState((value) => value + 1);
  }

  decrement() {
    count.setState((value) => value - 1);
  }

  count.useEffect(() {
    debugPrint('count: ${count.value}');
  });

  return Render(
    valueListenable: count,
    builder: (context, value, child) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: increment,
                child: const Text('Increment'),
              ),
              const SizedBox(width: 10),
              Text('$value'),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: decrement,
                child: const Text('Decrement'),
              ),
            ],
          ),
        ],
      );
    },
  );
}
```

### Examples

- [X] Counter
- [ ] Todo List
- [ ] Async Todo list
- [ ] Shared state
- [ ] Sqlite Crud

---

Carlos Costa @ 2024
