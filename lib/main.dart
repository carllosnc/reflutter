import 'package:flutter/material.dart';
import 'home.dart';
import 'examples/stateless_widgets/stateless_widgets_page.dart';
import 'examples/stateful_widgets/stateful_widgets_page.dart';
import 'examples/shared_state/share_state_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => home(context),
        '/stateless_widgets': (context) => statelessWidgetsPage(context),
        '/stateful_widgets': (context) => statefulWidgetPage(),
        '/share_state': (context) => shareStatePage(),
      },
    );
  }
}
