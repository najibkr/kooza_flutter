import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kooza_flutter/kooza_flutter.dart';

class Message {
  final String? id;
  final String? message;

  const Message({
    this.id,
    this.message,
  });

  factory Message.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const Message();
    return Message(id: map['id'], message: map['message']);
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'id': id,
      'message': message,
    };
    map.removeWhere((key, value) => value == null);
    return map;
  }
}

class ChatState {
  final List<Message> messages;
  const ChatState({
    this.messages = const [],
  });
  ChatState copyWith(List<Message>? messages) {
    return ChatState(messages: messages ?? this.messages);
  }
}

class ChatBloc extends Cubit<ChatState> {
  final Kooza kooza;
  ChatBloc(this.kooza) : super(const ChatState()) {
    streamMessages();
  }

  StreamSubscription<List<Map<String, dynamic>>>? _messagesSub;

  void streamMessages() {
    _messagesSub?.cancel();
    _messagesSub = kooza.streamDocs('messages').listen((event) {
      var messages = event.map((e) => Message.fromMap(e)).toList();
      emit(state.copyWith(messages));
      // ignore: avoid_print
    }, onError: (err) => print(err));
  }

  void saveMessage(String message) async {
    try {
      await kooza.setDoc('messages', Message(message: message).toMap());
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  @override
  Future<void> close() async {
    await _messagesSub?.cancel();
    return super.close();
  }
}
