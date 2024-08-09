import 'package:flutter/material.dart';

Widget customText(String text) {
  return Text(
    text,
    style: const TextStyle(
      fontSize: 20,
    ),
  );
}

Widget customTitle(String text) {
  return Text(
    text,
    style: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  );
}

Widget board(List<Widget> children) {
  return Container(
    padding: const EdgeInsets.all(20),
    constraints: const BoxConstraints(
      maxWidth: 300,
      maxHeight: 330,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(
        color: Colors.black,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

Widget statelessWidgetsPage(
  BuildContext context,
) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Stateless Widgets'),
    ),
    body: Center(
      child: Container(
        child: board(
          [
            customTitle('Stateless Widgets'),
            const SizedBox(height: 20),
            customText('A stateless widget is a widget that describes part of the user interface by building a constellation of other widgets that describe the user interface more concretely. '),
          ],
        ),
      ),
    ),
  );
}
