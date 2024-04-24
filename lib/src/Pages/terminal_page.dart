import 'package:flutter/material.dart';

class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key});

  static const routeName = '/terminal';

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Terminal')), body: const Center(child: Text('Terminal Page')));
  }
}
