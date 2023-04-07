import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kooza_flutter/kooza_flutter.dart';

import 'chat_bloc.dart';

void main() async {
  final kooza = await Kooza.getInstance('chat');
  runApp(MyApp(kooza: kooza));
}

class MyApp extends StatelessWidget {
  final Kooza kooza;
  const MyApp({super.key, required this.kooza});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc(kooza),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kooza')),
      body: BlocSelector<ChatBloc, ChatState, List<Message>>(
        selector: (state) => state.messages,
        builder: (context, state) {
          return ListView.builder(
            itemCount: state.length,
            padding: const EdgeInsets.only(bottom: 200),
            itemBuilder: (context, index) {
              final message = state[index];
              return ListTile(
                title: Text(message.message ?? 'no message'),
              );
            },
          );
        },
      ),
      floatingActionButton: const InputField(),
    );
  }
}

class InputField extends StatefulWidget {
  const InputField({
    super.key,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  String message = 'No content yet';
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      height: 50,
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(hintText: 'Enter a message'),
              onChanged: (value) => setState(() => message = value),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () => context.read<ChatBloc>().saveMessage(message),
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
