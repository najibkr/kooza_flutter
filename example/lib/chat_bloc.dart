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
  final bool darkMode;
  final List<Message> messages;
  final String? user;
  const ChatState({
    this.darkMode = false,
    this.messages = const [],
    this.user,
  });
  ChatState copyWith({
    List<Message>? messages,
    bool? darkMode,
    String? user,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      darkMode: darkMode ?? this.darkMode,
      user: user ?? this.user,
    );
  }
}

class ChatBloc extends Cubit<ChatState> {
  final Kooza kooza;
  ChatBloc(this.kooza) : super(const ChatState()) {
    streamDarkMode();
    streamUser();
    streamMessages();
  }

  StreamSubscription<bool?>? _darkmodeSub;
  void streamDarkMode() {
    _darkmodeSub?.cancel();
    _darkmodeSub = kooza.streamBool('darkMode').listen((event) {
      if (kDebugMode) {
        print('Fetched dark mode: $event');
      }
      emit(state.copyWith(darkMode: event));
    });
  }

  StreamSubscription<String?>? _userSub;
  void streamUser() {
    _userSub?.cancel();
    _userSub = kooza.streamString('user').listen((event) {
      if (kDebugMode) {
        print('Fetched user: $event');
      }
      emit(state.copyWith(user: event));
    });
  }

  StreamSubscription<List<Map<String, dynamic>>>? _messagesSub;
  void streamMessages() {
    _messagesSub?.cancel();
    _messagesSub = kooza.streamDocs('messages').listen((event) {
      var messages = event.map((e) => Message.fromMap(e)).toList();
      emit(state.copyWith(messages: messages));
      // ignore: avoid_print
    }, onError: (err) => print(err));
  }

  void setDarkMode(bool value) async {
    try {
      await kooza.setBool('darkMode', value, ttl: const Duration(milliseconds: 100));
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  void saveUser(String userName) async {
    try {
      await kooza.setString('user', userName, ttl: const Duration(milliseconds: 100));
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  void saveMessage(String message) async {
    try {
      await kooza.setDoc(
        'messages',
        Message(message: message).toMap(),
        ttl: const Duration(milliseconds: 100),
      );
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  @override
  Future<void> close() async {
    await _userSub?.cancel();
    await _darkmodeSub?.cancel();
    await _messagesSub?.cancel();
    await kooza.close();
    return super.close();
  }
}
