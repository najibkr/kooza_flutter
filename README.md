## About Kooza
A blazingly fast, reactive, fully asynchronous local database for dart projects.
------------------------------------------------------------------------
![Kooza](https://github.com/najibkr/kooza_flutter/blob/stable/kooza.jpg)  
## Getting Started
**STEP ONE:** Please, add `kooza_flutter` to your package dependencies:
```code
flutter pub add kooza_flutter
```
**STEP TWO:** Please, make sure to initialize `Kooza` in your main.dart file: 
```dart 
void main() async {
  await Kooza.ensureInitialize();
  runApp(const MyApp());
}
```

**STEP THREE:** Please, make sure to close Kooza instance when not in use. There are multiple ways to close the instantiated Kooza instance: 
1. Instantiate `Kooza` with `Provider` package and close it using Provider's dispose method.
2. Instantiate `Kooza` in a `StatefullWidget` and close it using the dispose method inside the State class. 
3. Inject it in your `bloc` and close it using the close method inside your bloc.

For Instance: 
```dart
class AppDataProvider extends StatelessWidget {
  const AppDataProvider({super.key});
  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (context) => Kooza.instance('products'),
      dispose: (_, kooza) => kooza.close(),
      child: BlocProvider(
        create: (c) => ProductsBloc(c.read<Kooza>()),
        child: const MyApp(),
      ),
    );
  }
}
```

## Usage: 

Here is an example of how you can use `Kooza` in your application: 
```dart
class ProductsBloc extends Cubit<ProductsState> {
  final Kooza _kooza;
  ProductsBloc(Kooza kooza)
      : _kooza = kooza,
        super(const ProductsState()) {
    streamDarkMode();
    streamProducts();
  }

  void setProductId(String? id) {
    emit(state.copyWith(product: state.product.copyWith(id: id)));
  }

  void setProductName(String? name) {
    emit(state.copyWith(product: state.product.copyWith(name: name)));
  }

  void setProductPrice(String? price) {
    final newPrice = double.tryParse(price ?? '0.0');
    emit(state.copyWith(product: state.product.copyWith(price: newPrice)));
  }

  StreamSubscription<List<Product>>? _producstsSub;
  void streamProducts() {
    final ref = _kooza.collection('products').snapshots();
    final productsStream = ref.map((collection) => collection.docs.values
        .map((doc) => Product.fromMap(doc.data, doc.id))
        .toList());
    _producstsSub?.cancel();
    _producstsSub = productsStream.listen((products) {
      emit(state.copyWith(products: products));
      // ignore: avoid_print
    }, onError: (e) => kDebugMode ? print('Error: $e') : null);
  }

  void fetchProducts() async {
    try {
      await _producstsSub?.cancel();
      final ref = await _kooza.collection('products').get();
      final result = ref.docs.values
          .map((doc) => Product.fromMap(doc.data, doc.id))
          .toList();
      emit(state.copyWith(products: result));
    } catch (e) {
      if (kDebugMode) print('Error fetching products: $e');
    }
  }

  void saveProduct() async {
    try {
      final id = await _kooza.collection('products').add(
            state.product.toMap(),
            docID: state.product.id,
          );
      emit(state.copyWith(product: state.product.copyWith(id: id)));
    } catch (e) {
      if (kDebugMode) print('Error saving products: $e');
    }
  }

  void deleteProduct(String? id) async {
    try {
      if (id == null) return;
      await _kooza.collection('products').doc(id).delete();
    } catch (e) {
      if (kDebugMode) print('Error saving products: $e');
    }
  }

  void deleteAll() async {
    try {
      await _kooza.collection('products').delete();
    } catch (e) {
      if (kDebugMode) print('Error saving products: $e');
    }
  }

  StreamSubscription? _darkmodeSub;
  void streamDarkMode() {
    _darkmodeSub?.cancel();
    _darkmodeSub = _kooza.singleDoc('isDarkMode').snapshots().listen(
        (event) => emit(state.copyWith(isDarkMode: event.data as bool?)));
  }

  void setDarkMode(bool value) async {
    try {
      await _kooza.singleDoc('isDarkMode').set(value);
    } catch (e) {
      if (kDebugMode) print(e);
    }
  }

  @override
  Future<void> close() async {
    await _producstsSub?.cancel();
    await _kooza.close();
    return super.close();
  }
}
```

## Additional information

A Package Developed by Najibullah Khoda Rahim

Please, report the bugs through the Github repository:
https://github.com/najibkr/kooza_flutter/issues
