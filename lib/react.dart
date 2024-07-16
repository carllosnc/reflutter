import 'package:flutter/material.dart';

// ignore: camel_case_types
class useState extends ValueNotifier {
  useState(super.value);

  useEffect(Function() callback) {
    addListener(callback);
  }

  setState(Function(dynamic value) callback) {
    value = callback(value);
    super.value = value;
  }
}

class Render extends ValueListenableBuilder {
  const Render({
    super.key,
    required super.valueListenable,
    required super.builder,
  });
}
