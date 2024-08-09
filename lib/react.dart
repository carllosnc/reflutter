import 'package:flutter/material.dart';

// ignore: camel_case_types
class useState extends ValueNotifier {
  useState(super.value);

  useEffect(Function() callback) {
    addListener(callback);
  }

  removeEffect(Function() callback) {
    removeListener(callback);
  }

  setState(Function(dynamic value) callback) {
    value = callback(value);
    super.value = value;
  }
}

class RenderGlobal extends ValueListenableBuilder {
  const RenderGlobal({
    super.key,
    required super.valueListenable,
    required super.builder,
  });
}

class RenderLocal extends StatefulBuilder {
  const RenderLocal({
    super.key,
    required super.builder,
  });
}
