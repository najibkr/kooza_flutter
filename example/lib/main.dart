import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kooza_flutter/kooza_flutter.dart';
import 'package:provider/provider.dart';

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
    return Provider(
      create: (context) => kooza,
      dispose: (context, value) => value.close(),
      child: BlocProvider(
        create: (context) => ChatBloc(context.read<Kooza>()),
        child: BlocSelector<ChatBloc, ChatState, bool>(
          selector: (state) => state.darkMode,
          builder: (context, state) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Flutter Demo',
            theme: ThemeData(
              brightness: state ? Brightness.dark : Brightness.light,
              primarySwatch: Colors.blue,
            ),
            home: const MyHomePage(),
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kooza'),
        actions: [
          IconButton(
            onPressed: () => context.read<ChatBloc>().deleteAll(),
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: Column(
        children: [
          BlocSelector<ChatBloc, ChatState, bool>(
            selector: (state) => state.darkMode,
            builder: (context, state) => Switch(
              onChanged: context.read<ChatBloc>().setDarkMode,
              value: state,
            ),
          ),
          BlocSelector<ChatBloc, ChatState, String>(
            selector: (state) => state.user ?? '',
            builder: (context, state) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                state,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          InputField(
            hint: 'Enter User Name',
            onPressed: (value) => context.read<ChatBloc>().saveUser(value),
          ),
          InputField(
            hint: 'Enter Message Id',
            onPressed: (value) => context.read<ChatBloc>().streamMessage(value),
          ),
          InputField(
            hint: 'Enter Message Id',
            onPressed: (value) => context.read<ChatBloc>().setId(value),
          ),
          InputField(
            hint: 'Updated Message',
            onPressed: (value) => context.read<ChatBloc>().updateMessage(value),
          ),
          BlocSelector<ChatBloc, ChatState, Message?>(
            selector: (state) => state.message,
            builder: (context, state) => Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                state?.message ?? '',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: BlocSelector<ChatBloc, ChatState, List<Message>>(
              selector: (state) => state.messages,
              builder: (context, state) {
                return ListView.builder(
                  itemCount: state.length,
                  padding: const EdgeInsets.only(bottom: 200),
                  itemBuilder: (context, index) {
                    final message = state[index];
                    return ListTile(
                      leading: IconButton(
                        onPressed: () => context.read<ChatBloc>().deleteMessage(message.id),
                        icon: const Icon(Icons.delete),
                      ),
                      title: Text(message.message ?? 'no message'),
                      subtitle: Text(message.id ?? ''),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: InputField(
        hint: 'Enter a new message',
        onPressed: (value) => context.read<ChatBloc>().saveMessage(value),
      ),
    );
  }
}

class InputField extends StatefulWidget {
  final void Function(String value) onPressed;
  final String hint;
  const InputField({
    super.key,
    required this.onPressed,
    required this.hint,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  String message = 'No content yet';
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).scaffoldBackgroundColor;
    return Container(
      color: theme,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      height: 50,
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(hintText: widget.hint),
              onChanged: (value) => setState(() => message = value),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () => widget.onPressed(message),
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
