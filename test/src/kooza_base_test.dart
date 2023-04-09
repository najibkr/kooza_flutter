// import 'package:flutter_test/flutter_test.dart';
// import 'package:kooza_flutter/kooza_flutter.dart';

// void main() {
//   group('Testing Set and Fetch Bool', () {
//     Kooza? kooza;
//     setUp(() async => kooza = await Kooza.init('chat'));
//     tearDown(() => kooza = null);

//     test('Testing Kooza.setBool', () async {
//       final result1 = await kooza?.fetchBool('isOnlineddd');
//       expect(result1, null);

//       await kooza?.setBool('isOnline', false);
//       final result2 = await kooza?.fetchBool('isOnline');
//       expect(result2, false);

//       await kooza?.setBool('isOnline', true);
//       final result3 = await kooza?.fetchBool('isOnline');
//       expect(result3, true);

//       await kooza?.setBool('isOnline', null);
//       final result4 = await kooza?.fetchBool('isOnline');
//       expect(result4, null);
//     });
//   });
// }
