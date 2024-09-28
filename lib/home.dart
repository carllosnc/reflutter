import 'package:flutter/material.dart';

Scaffold home(
  BuildContext context,
) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Reflutter'),
    ),
    body: ListView(
      children: [
        ListTile(
          title: const Text('Stateless Widgets'),
          onTap: () => Navigator.of(context).pushNamed('/stateless_widgets'),
        ),
        ListTile(
          title: const Text('Stateful Widgets'),
          onTap: () => Navigator.of(context).pushNamed('/stateful_widgets'),
        ),
        ListTile(
          title: const Text('Shared State'),
          onTap: () => Navigator.of(context).pushNamed('/share_state'),
        ),
        ListTile(
          title: const Text('Doc Examples'),
          onTap: () => Navigator.of(context).pushNamed('/doc_examples'),
        ),
      ],
    ),
  );
}
