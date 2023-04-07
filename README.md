## About Kooza
A blazingly fast, reactive, fully asynchronous local database for dart projects.

## Getting Started
It is highly recommended to use flutter for providing kooza_flutter 
to your widget tree:
```dart 
void main() async {
  final kooza = await Kooza.getInstance('myDb');
  runApp(Provider(
    create: (context) =>kooza,
    dispose: (_, kooza) => kooza.close(),
    child: MyApp(kooza: kooza),
  ));
}
```

To set data use the following methods:
```dart
kooza.setBool('isOnline', true, ttl: Duration(miliseconds: 3000));
kooza.setDoc('users', {'name': 'John Doe'}, ttl: Duration(hours: 2));
```

## Additional information

A Package Developed by Najibullah Khoda Rahim

Please, report the bugs through the Github repository:
https://github.com/najibkr/kooza_flutter/issues
