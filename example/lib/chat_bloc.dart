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
    return Message(id: map['docId'], message: map['message']);
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
  final Message? message;
  final String? id;
  const ChatState({
    this.darkMode = false,
    this.messages = const [],
    this.user,
    this.message,
    this.id,
  });
  ChatState copyWith({
    List<Message>? messages,
    bool? darkMode,
    String? user,
    Message? message,
    String? id,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      darkMode: darkMode ?? this.darkMode,
      user: user ?? this.user,
      message: message ?? this.message,
      id: id ?? this.id,
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

  void setId(String id) {
    emit(state.copyWith(id: id));
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

  StreamSubscription<Map<String, dynamic>?>? _messageSub;
  void streamMessage(String docId) {
    _messageSub?.cancel();
    _messageSub = kooza.streamDoc('messages', docId).listen((event) {
      emit(state.copyWith(message: Message.fromMap(event)));
      // ignore: avoid_print
    }, onError: (err) => print(err));
  }

  StreamSubscription<List<Map<String, dynamic>>>? _messagesSub;
  void streamMessages() {
    _messagesSub?.cancel();
    _messagesSub = kooza.streamDocs('messages').listen((event) {
      print('messages: $event');
      var messages = event.map((e) => Message.fromMap(e)).toList();
      emit(state.copyWith(messages: messages));
      // ignore: avoid_print
    }, onError: (err) => print(err));
  }

  void setDarkMode(bool value) async {
    try {
      await kooza.setBool('darkMode', value);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  void saveUser(String userName) async {
    try {
      await kooza.setString('user', userName);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
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

  void updateMessage(String message) {
    try {
      kooza.setDoc(
        'messages',
        Message(message: message, id: state.id).toMap(),
        docId: state.id,
      );
    } catch (e) {
      print("update message: $e");
    }
  }

  void deleteMessage(String? docId) async {
    if (docId == null) return;
    try {
      await kooza.deleteDoc('messages', docId);
    } catch (e) {
      if (kDebugMode) {
        print('error deleting message: $e');
      }
    }
  }

  void deleteAll() async {
    try {
      await kooza.deleteKey('messages');
      await kooza.deleteKey('user');
      await kooza.deleteKey('darkMode');
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting messages: $e');
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
