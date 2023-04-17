// ignore_for_file: avoid_print

void main() {
  getIntegers().listen((event) {
    print(event);
  }, cancelOnError: false).onError((err) => print(err));
}

Stream<int> getIntegers() async* {
  yield* getTiming();
}

Stream<int> getTiming() async* {
  for (int i = 0; i < 100; i++) {
    await Future.delayed(const Duration(milliseconds: 100));
    if (i == 10) throw 'fuck you';
    yield i;
  }
}

Future<String> getName() {
  return Future.delayed(const Duration(milliseconds: 100), () => "Najibullah");
}
