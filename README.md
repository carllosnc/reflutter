# Reflutter

> Coding Flutter in React way

This is an experiment to see if it's possible to code Flutter in React way. I ignored performance issues caused by helper methods/functional widgets, this project is just for fun. Don't be so serious.

Check the examples below: A counter sharing state between multiple widgets.

```dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '/react.dart';

var counter = globalState(0);

incrementAction() {
  counter.setState((value) => value + 1);
}

decrementAction() {
  counter.setState((value) => value - 1);
}

Widget incrementCounter() {
  print('Building increment button');

  return const FilledButton(
    onPressed: incrementAction,
    child: Text('Increment'),
  );
}

Widget decrementCounter() {
  print('Building decrement button');

  return const FilledButton(
    onPressed: decrementAction,
    child: Text('Decrement'),
  );
}

Widget displayCounter() {
  return RenderGlobal(
    valueListenable: counter,
    builder: (context, value, child) {
      print('Building display counter');

      return Text(
        value.toString(),
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
      );
    },
  );
}

Widget page() {
  return RenderEffect(
    listenable: counter,
    effect: () => print('Counter changed to ${counter.value}'),
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Shared State'),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            incrementCounter(),
            const SizedBox(width: 10),
            displayCounter(),
            const SizedBox(width: 10),
            decrementCounter(),
          ],
        ),
      ),
    ),
  );
}
```

In the example above, all widgets are provided by functions. The `globalState` works like a 'global' state and is shared between all widgets. `RenderEffect` binds a side effect to the page's lifetime (registering on mount, removing on unmount) and `RenderGlobal` performs side effects to rebuild the view. The state and actions are completely separated from the widgets.

## Examples

- [Stateless widgets and composition](https://github.com/carllosnc/reflutter/tree/master/lib/examples/stateless_widgets)
- [Statefull widget](https://github.com/carllosnc/reflutter/tree/master/lib/examples/stateful_widgets)
- [Sharing state](https://github.com/carllosnc/reflutter/tree/master/lib/examples/shared_state)
- [Hooks](https://github.com/carllosnc/reflutter/tree/master/lib/examples/hooks)

## Core concepts

### globalState
>define a reactive variable that can be used in multiple widgets

```dart
var counter = globalState(0);

incrementAction() {
  counter.setState((value) => value + 1);
}

decrementAction() {
  counter.setState((value) => value - 1);
}
```

The object provided by `globalState` have the following methods:

| Methods        | Description                                                                  |
| -------------- | ---------------------------------------------------------------------------- |
| `useEffect`    | register a callback to be called when the state changes; returns a disposer  |
| `removeEffect` | remove a callback from the list of callbacks                                 |
| `setState`     | update the state value via a `T Function(T)` callback                        |

> ⚠️ `useEffect` registers a **permanent** listener. Never call it during `build`
> (inside a `builder`, a page function executed at build time, or `RenderGlobal`/
> `RenderLocal` builders) — that would leak a new listener on every rebuild.
> In debug builds, calling it from inside a `RenderGlobal`/`RenderLocal` builder
> throws an `AssertionError`. Register effects at top-level, in a
> `StatefulWidget`'s `initState`, or use [`RenderEffect`](#rendereffect).
> `useEffect` returns a disposer (`VoidCallback`) you can call to unsubscribe.

### RenderLocal
> Reactive widget that updates when the state is defined inside the component

```dart
Widget counter() {
  //local variable defined inside the component
  var count = 0;

  //action that updates the state
  void increment() {
    count++;
  }

  return RenderLocal(
    builder: (context, setState) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilledButton(
            //call the action to update the state
            //setState will rebuild the widget
            onPressed: () => setState(increment),
            child: Text('Increment: $count'),
          ),
        ],
      );
    },
  );
}
```

### RenderGlobal
> Reactive widget that updates when the state is defined outside the component

```dart
//global state that can be used in multiple widgets
var counter = globalState(0);

//action that updates the state
increment() {
  counter.setState((value) => value + 1);
}

counter.useEffect(() {
  print('Counter changed to ${counter.value}');
});

Widget incrementButton() {
  return FilledButton(
    onPressed: increment,
    child: Text('Increment ${counter.value}'),
  );
}

Widget globalCounter() {
  //render global that will rebuild when the state changes
  return RenderGlobal(
    valueListenable: counter,
    builder: (context, value, child) {
      // use the `value` argument instead of `counter.value`
      return incrementButton();
    },
  );
}
```

`globalState` is just a rename of `ValueNotifier` to see more details check the official [documentation](https://api.flutter.dev/flutter/foundation/ValueNotifier-class.html) and `RenderGlobal` is a rename of `ValueListenableBuilder` see more in [documentation](https://api.flutter.dev/flutter/widgets/ValueListenableBuilder-class.html).

Knowing the concept of `LocalRender` and `GlobalRender` we can define a simple rule.

- **LocalRender**: use for simple state for a unique widget
- **GlobalRender**: use to share state with multiple widget

### RenderEffect
> Bind an effect to a widget's lifetime (safe `useEffect` for the widget tree)

```dart
var counter = globalState(0);

Widget page() {
  return RenderEffect(
    listenable: counter,
    effect: () => print('Counter changed to ${counter.value}'),
    child: Scaffold(
      appBar: AppBar(title: const Text('Effect')),
      body: const Center(child: Text('hello')),
    ),
  );
}
```

The effect is registered in `initState` and removed in `dispose`, so it never
leaks across rebuilds. Prefer this over calling `useEffect` from inside a widget
function.

## Hooks

For state that should live *inside* a single widget (not shared globally), the
hooks API mirrors React's function-component model: a [`HookScope`](#hookscope)
owns a list of hook slots, and hooks resolve to the same slot across rebuilds by
call order. This is the closest thing to React's `useState`/`useEffect` that
Flutter can offer without codegen.

### HookScope
> Owns hook state for its subtree (the "function component" boundary).

```dart
HookScope(
  builder: (context) {
    final count = useState(0);
    return FilledButton(
      onPressed: () => count.set((v) => v + 1),
      child: Text('${count.value}'),
    );
  },
)
```

### useState
> Persistent local state that triggers a rebuild on change.

```dart
final count = useState(0);
print(count.value);        // 0
count.set((v) => v + 1);   // rebuilds the HookScope
```

### useEffect
> Side effects with a dependency array + cleanup. Runs after the frame.

```dart
useEffect(() {
  print('count is ${count.value}');
  return () => print('cleanup'); // runs before next effect & on unmount
}, [count.value]);   // re-run only when count.value changes
```

- Omit deps → runs after every build.
- Pass `[]` → runs only on mount.
- Pass `[a, b]` → re-runs when `a` or `b` change (`==`).

### useMemo
> Memoize a computed value, recomputing only when deps change.

```dart
final doubled = useMemo(() => count.value * 2, [count.value]);
```

### useRef
> A mutable container that persists across rebuilds. Mutating it does NOT rebuild.

```dart
final ref = useRef(0);
ref.current = 42; // no rebuild
```

### Rules of hooks

- Call hooks **only** inside a `HookScope` builder (throws an `AssertionError`
  in debug otherwise).
- Call hooks at the **top level** — never inside `if`/`for`/nested functions.
  Slots are assigned by call order, so conditional calls shift the indices and
  corrupt state, exactly as in React.

## Isolating rendering

To avoid rebuilding some widgets we can isolate `RenderLocal` and `RenderGlobal` using a simple `Column` or another widget that accepts a list of widgets.

```dart
Widget counter(){
  var counter = globalState(0);

  increment() {
    counter.setState((value) => value + 1);
  }

  return Column(
    children: [
      //This widget will not be rebuild when the state changes
      const Text("Hello world"),
      RenderLocal(
        builder: (context, setState) {
          return FilledButton(
            onPressed: increment,
            child: Text(counter.value.toString()),
          );
        },
      )
    ],
  );
}
```

## Custom components(widgets)

Dart has a fantastic called [Extension Methods](https://dart.dev/guides/language/extension-methods) that allows us to add methods to existing classes. It will be useful to help us to create components and styles.

**Example** Let's create a card component apply a new method to the `Container` widget.

```dart
extension ContainerExtension on Container {
  Container get card {
    return Container(
      padding: const EdgeInsets.all(8),
      width: 300,
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 5,
            offset: const Offset(0, 5),
          ),
        ],
        color: Colors.red.shade100,
      ),
      child: child,
    );
  }
}
```

In the example above, we are creating a new method `card` that returns a `Container` with a custom style. To use it, we can simply call the method on the `Container` widget.

```dart
Container(
  child: Text("Hello world"),
).card;
```

## New project

**1 - Creating new empty Flutter project**

```shell
flutter create -e --android-language=kotlin --ios-language=swift --project-name=<PROJECT_NAME> --org=cnc --platforms=android <APP_NAME>
```

**2 - Add [react.dart](https://github.com/carllosnc/reflutter/blob/master/lib/react.dart) file**

`React.dart` is a simple file that will provide access to `globalState`, `RenderLocal` and `RenderGlobal` widgets, add to the project and import as you need.

---

Carlos Costa @ 2024
