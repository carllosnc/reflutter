# Reflutter

> Coding Flutter in React way

This is an experiment to see if it's possible to code Flutter in React way. I ignored performance issues caused by helper methods/functional widgets, this project is just for fun. Don't be so serious.

Check the examples below: A counter sharing state between multiple widgets.

```dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '/react.dart';

var counter = useState(0);

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
        counter.value.toString(),
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
      );
    },
  );
}

Widget page() {
  counter.useEffect(() {
    print('Counter changed to ${counter.value}');
  });

  return Scaffold(
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
  );
}
```

In the example above, all widgets are provides by functions. The `useState` works like a 'global' state and is shared between all widgets. The `useEffect` is called when the state changes and `RenderGlobal` performs side effects to rebuild the view. The state and actions are completely separated from the widgets.

## Examples

- [Stateless widgets and composition](https://github.com/carllosnc/reflutter/tree/master/lib/examples/stateless_widgets)
- [Statefull widget](https://github.com/carllosnc/reflutter/tree/master/lib/examples/stateful_widgets)
- [Sharing state](https://github.com/carllosnc/reflutter/tree/master/lib/examples/shared_state)

## Core concepts

### useState
>define a reactive variable that can be used in multiple widgets

```dart
var counter = useState(0);

incrementAction() {
  counter.setState((value) => value + 1);
}

decrementAction() {
  counter.setState((value) => value - 1);
}
```

| Methods       | Description                                             |
| ------------- | ------------------------------------------------------- |
| `useEffect`   | register a callback to be called when the state changes |
| `removeEfect` | remove a callback from the list of callbacks            |
| `setState`    | update the state value                                  |

### RenderLocal
> perform side effects to rebuild widget when the state is defined inside the component

```dart
Widget counter(){
  //useState defined inside the component
  var counter = useState(0);

  increment() {
    counter.setState((value) => value + 1);
  }

  // RenderLocal is used to perform side effects(reactivity)
  return RenderLocal(
    FilledButton(
      onPressed: increment,
      child: Text(counter.value.toString()),
    ),
  )
}
```

### GlobalRender
> perform side effects to rebuild widget when the state is defined outside the component

```dart
//useState defined outside the component
var counter = useState(0);

//here, actions can be defined outside the component
increment() {
  counter.setState((value) => value + 1);
}

Widget counter(){

  //to perform side effects we need to use GlobalRender
  return GlobalRender(
    FilledButton(
      onPressed: increment,
      child: Text(counter.value.toString()),
    ),
  )
}
```
Knowning the concept of `LocalRender` and `GlobalRender` we can define a simple rule.

- **LocalRender**: use for simple state for a unique widget
- **GlobalRender**: use to share state with multiple widget

## Isolating rendering

To avoid rebuilding some widgets we can isolate `RenderLocal` and `RenderGlobal` using a simple `Column` or another widget that accepts a list of widgets.

```dart
Widget counter(){
  var counter = useState(0);

  increment() {
    counter.setState((value) => value + 1);
  }

  return Column(
    children: [
      //This widget will not be rebuild when the state changes
      Text("Hello world"),
      //
      RenderLocal(
        FilledButton(
          onPressed: increment,
          child: Text(counter.value.toString()),
        ),
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

**1 - Creating new empty Fluhtter project**

```shell
flutter create -e --android-language=kotlin --ios-language=swift --project-name=example --org=cnc --platforms=android app_name
```

**2 - Adding [react.dart](https://github.com/carllosnc/reflutter/blob/master/lib/react.dart) file**

`React.dart` is a simple file that will provide access to `useState`, `RenderLocal` and `RenderGlobal` widgets, add to the project and import as you need.

---

Carlos Costa @ 2024
