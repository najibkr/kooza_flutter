import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kooza_flutter/kooza_flutter.dart';
import 'package:provider/provider.dart';

class Product {
  final String? id;
  final String? name;
  final double? price;
  const Product({this.id, this.name, this.price});

  Product copyWith({
    String? id,
    String? name,
    double? price,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }

  factory Product.fromMap(Map<String, dynamic>? map, [String? id]) {
    if (map == null) return const Product();
    return Product(
      id: id,
      name: map['name'],
      price: (map['price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'id': id,
      'name': name,
      'price': price,
    };
    map.removeWhere((key, value) => value == null);
    return map;
  }
}

class ProductsState {
  final bool isDarkMode;
  final Product product;
  final List<Product> products;

  const ProductsState({
    this.isDarkMode = false,
    this.product = const Product(),
    this.products = const [],
  });

  ProductsState copyWith({
    bool? isDarkMode,
    Product? product,
    List<Product>? products,
  }) {
    return ProductsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      product: product ?? this.product,
      products: products ?? this.products,
    );
  }
}

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
    final ref = _kooza.collection('my_products').snapshots();
    final productsStream = ref.map((collection) => collection.docs
        .map((doc) => Product.fromMap(doc.data, doc.id))
        .toList());
    _producstsSub?.cancel();

    int counter = 0;
    _producstsSub = productsStream.listen((products) {
      emit(state.copyWith(products: products));
      // ignore: avoid_print
      print('List of products: $products $counter');
      counter++;
    }, onError: (e) => kDebugMode ? print('Error: $e') : null);
  }

  void fetchProducts() async {
    try {
      await _producstsSub?.cancel();
      final ref = await _kooza.collection('my_products').get();
      final result =
          ref.docs.map((doc) => Product.fromMap(doc.data, doc.id)).toList();
      emit(state.copyWith(products: result));
    } catch (e) {
      if (kDebugMode) print('Error fetching products: $e');
    }
  }

  void saveProduct() async {
    try {
      final id = await _kooza
          .collection('my_products')
          .add(state.product.toMap(), ttl: const Duration(milliseconds: 3000));
      emit(state.copyWith(product: state.product.copyWith(id: id)));
    } catch (e) {
      if (kDebugMode) print('Error saving products: $e');
    }
  }

  void deleteProduct(String? id) async {
    try {
      if (id == null) return;
      await _kooza.collection('my_products').doc(id).delete();
    } catch (e) {
      if (kDebugMode) print('Error saving products: $e');
    }
  }

  void deleteAll() async {
    try {
      await _kooza.clear();
    } catch (e) {
      if (kDebugMode) print('Error saving products: $e');
    }
  }

  StreamSubscription? _darkmodeSub;
  void streamDarkMode() {
    _darkmodeSub?.cancel();
    _darkmodeSub =
        _kooza.singleDoc('appThemeData').snapshots<bool>().listen((event) {
      emit(state.copyWith(isDarkMode: event.data));
    });
  }

  void setDarkMode(bool value) async {
    try {
      await _kooza
          .singleDoc('appThemeData')
          .set<bool>(value, ttl: const Duration(milliseconds: 3000));
    } catch (e) {
      if (kDebugMode) print(e);
    }
  }

  @override
  Future<void> close() async {
    await _producstsSub?.cancel();
    return super.close();
  }
}

void main() async {
  final kooza = await Kooza.getInstance('example');
  runApp(AppDataProvider(kooza: kooza));
}

class AppDataProvider extends StatefulWidget {
  final Kooza kooza;
  const AppDataProvider({super.key, required this.kooza});

  @override
  State<AppDataProvider> createState() => _AppDataProviderState();
}

class _AppDataProviderState extends State<AppDataProvider> {
  @override
  void dispose() {
    widget.kooza.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureProvider<int?>(
      initialData: null,
      create: (context) =>
          Future.delayed(const Duration(milliseconds: 5000), () => 20),
      child: BlocProvider(
        create: (c) => ProductsBloc(widget.kooza),
        child: const AppGeneralSetup(),
      ),
    );
  }
}

class AppGeneralSetup extends StatelessWidget {
  const AppGeneralSetup({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProductsBloc, ProductsState, bool>(
      selector: (state) => state.isDarkMode,
      builder: (context, isDarkMode) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kooza Example App',
        theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
        home: const KoozaHomePage(),
      ),
    );
  }
}

class FormCreateProduct extends StatefulWidget {
  const FormCreateProduct({super.key});

  @override
  State<FormCreateProduct> createState() => _FormCreateProductState();
}

class _FormCreateProductState extends State<FormCreateProduct> {
  final _formKey = GlobalKey<FormState>();

  void _saveProduct(BuildContext context) {
    final formState = _formKey.currentState;
    if (formState?.validate() == true) {
      formState?.save();
      context.read<ProductsBloc>().saveProduct();
      formState?.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final idField = BlocSelector<ProductsBloc, ProductsState, String?>(
      selector: (state) => state.product.id,
      builder: (context, id) => TextFormField(
        decoration: const InputDecoration(hintText: 'Product ID'),
        initialValue: id,
        onSaved: context.read<ProductsBloc>().setProductId,
      ),
    );

    final nameField = BlocSelector<ProductsBloc, ProductsState, String?>(
      selector: (state) => state.product.name,
      builder: (context, name) => TextFormField(
        decoration: const InputDecoration(hintText: 'Product Name'),
        initialValue: name,
        validator: (v) => (v?.trim().isEmpty ?? true) ? 'Add Name' : null,
        onSaved: context.read<ProductsBloc>().setProductName,
      ),
    );

    final priceField = BlocSelector<ProductsBloc, ProductsState, double?>(
      selector: (state) => state.product.price,
      builder: (context, price) => TextFormField(
        decoration: const InputDecoration(hintText: 'Product Price'),
        initialValue: price?.toString(),
        onSaved: context.read<ProductsBloc>().setProductPrice,
      ),
    );

    final saveBtn = TextButton(
      onPressed: () => _saveProduct(context),
      child: const Padding(padding: EdgeInsets.all(8.0), child: Text("Save")),
    );

    final fields = Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(children: [idField, nameField, priceField, saveBtn]),
    );

    return Form(key: _formKey, child: fields);
  }
}

class ListProducts extends StatelessWidget {
  const ListProducts({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProductsBloc, ProductsState, List<Product>>(
      selector: (state) => state.products,
      builder: (context, products) => ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) => ListTile(
          leading: IconButton(
            onPressed: () =>
                context.read<ProductsBloc>().deleteProduct(products[index].id),
            icon: const Icon(Icons.delete),
          ),
          trailing: Text(products[index].price?.toString() ?? '0.0'),
          title: Text(products[index].name ?? ''),
          subtitle: Text(products[index].id ?? ''),
        ),
      ),
    );
  }
}

class KoozaHomePage extends StatelessWidget {
  const KoozaHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final darkModeBtn = BlocSelector<ProductsBloc, ProductsState, bool>(
      selector: (state) => state.isDarkMode,
      builder: (context, state) => Switch(
        onChanged: (v) => context.read<ProductsBloc>().setDarkMode(v),
        value: state,
      ),
    );

    final deleteAllBtn = IconButton(
      onPressed: () => context.read<ProductsBloc>().deleteAll(),
      icon: const Icon(Icons.delete),
    );

    final data = context.watch<int?>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Kooza Example App $data'),
        actions: [darkModeBtn, deleteAllBtn],
      ),
      body: Column(
        children: const [
          FormCreateProduct(),
          Expanded(child: ListProducts()),
        ],
      ),
    );
  }
}

class ProductInputField extends StatelessWidget {
  final void Function(String? value) onSaved;
  final String hint;

  const ProductInputField({
    super.key,
    required this.onSaved,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(hintText: hint),
      onSaved: onSaved,
    );
  }
}
