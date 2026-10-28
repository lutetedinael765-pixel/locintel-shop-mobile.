import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const shopServer = String.fromEnvironment('SHOP_API_BASE', defaultValue: '');
const shopEndpoint = '/api/locintel/shop/v1';

void main() => runApp(const LocintelShop());

class Store {
  final int id;
  final String name, description, logo, banner, icon, color, whatsapp;
  Store.fromJson(Map<String, dynamic> j)
      : id = (j['id'] as num).toInt(), name = '${j['name'] ?? ''}',
        description = '${j['description'] ?? ''}', logo = '${j['logo_url'] ?? ''}',
        banner = '${j['banner_url'] ?? ''}', icon = '${j['icon_url'] ?? ''}',
        color = '${j['primary_color'] ?? '#1769AA'}',
        whatsapp = '${j['whatsapp_number'] ?? ''}';
}
class Product {
  final int id;
  final String name, description, image, currency;
  final double price;
  Product.fromJson(Map<String, dynamic> j)
      : id = (j['id'] as num).toInt(), name = '${j['name'] ?? ''}',
        description = '${j['description'] ?? ''}', image = '${j['image_url'] ?? ''}',
        currency = '${j['currency'] ?? ''}',
        price = (j['price'] as num?)?.toDouble() ?? 0;
}
class ShopApi {
  static Future<Map<String, dynamic>> get(String path, [Map<String, String>? query]) async {
    if (shopServer.isEmpty) throw Exception('Configuration absente : SHOP_API_BASE');
    final base = Uri.parse('${shopServer.replaceAll(RegExp(r'/$'), '')}$shopEndpoint/$path');
    final url = base.replace(queryParameters: query);
    final response = await http.get(url).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception('Serveur HTTP ${response.statusCode}');
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) throw const FormatException('Réponse serveur incorrecte');
    return decoded;
  }
  static Future<List<Store>> stores() async => ((await get('stores'))['stores'] as List<dynamic>? ?? [])
      .map((item) => Store.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  static Future<List<Product>> products(int storeId, {String search = ''}) async =>
      ((await get('stores/$storeId/products', {'q': search}))['products'] as List<dynamic>? ?? [])
      .map((item) => Product.fromJson(Map<String, dynamic>.from(item as Map))).toList();
}
class LocintelShop extends StatelessWidget {
  const LocintelShop({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'LOCINTEL Shop',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF1669A6), scaffoldBackgroundColor: const Color(0xFFF7F9FC)),
    home: const StoresScreen(),
  );
}
class CatalogImage extends StatelessWidget {
  final String url;
  final double? height;
  const CatalogImage({super.key, required this.url, this.height});
  @override Widget build(BuildContext context) => url.isEmpty ? const Center(child: Icon(Icons.storefront, size: 42))
    : Image.network(url, height: height, width: double.infinity, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported_outlined, size: 42)));
}
class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});
  @override State<StoresScreen> createState() => _StoresScreenState();
}
class _StoresScreenState extends State<StoresScreen> {
  late Future<List<Store>> future;
  String query = '';
  @override void initState() { super.initState(); refresh(); }
  void refresh() { future = ShopApi.stores(); }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('LOCINTEL Shop'), centerTitle: false),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: TextField(
        onChanged: (v) => setState(() => query = v.toLowerCase()),
        decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'Rechercher une boutique', filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)))),
      Expanded(child: FutureBuilder<List<Store>>(future: future, builder: (context, snapshot) {
        if (snapshot.hasError) return ErrorRetry(message: '${snapshot.error}', onRetry: () => setState(refresh));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final stores = snapshot.data!.where((s) => s.name.toLowerCase().contains(query)).toList();
        if (stores.isEmpty) return const Center(child: Text('Aucune boutique disponible'));
        return RefreshIndicator(onRefresh: () async { setState(refresh); await future; }, child: ListView.builder(
          itemCount: stores.length, padding: const EdgeInsets.symmetric(horizontal: 14),
          itemBuilder: (context, i) { final store = stores[i];
            return Card(margin: const EdgeInsets.only(bottom: 12), clipBehavior: Clip.antiAlias, child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductsScreen(store: store))),
              child: Row(children: [ SizedBox(width: 105, height: 105, child: CatalogImage(url: store.logo)),
                Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(store.name, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 5),
                    Text(store.description, maxLines: 2, overflow: TextOverflow.ellipsis)]))),
                const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.chevron_right))] )))); },
        ));
      }))
    ]),
  );
}
class ProductsScreen extends StatefulWidget {
  final Store store;
  const ProductsScreen({super.key, required this.store});
  @override State<ProductsScreen> createState() => _ProductsScreenState();
}
class _ProductsScreenState extends State<ProductsScreen> {
  late Future<List<Product>> future;
  final searchController = TextEditingController();
  @override void initState() { super.initState(); load(); }
  void load() { future = ShopApi.products(widget.store.id, search: searchController.text); }
  @override void dispose() { searchController.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.store.name)),
    body: Column(children: [
      if (widget.store.banner.isNotEmpty) SizedBox(height: 130, width: double.infinity, child: CatalogImage(url: widget.store.banner)),
      Padding(padding: const EdgeInsets.all(12), child: TextField(controller: searchController, onSubmitted: (_) => setState(load),
        decoration: InputDecoration(hintText: 'Rechercher un produit', prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(onPressed: () => setState(load), icon: const Icon(Icons.arrow_forward)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))))),
      Expanded(child: FutureBuilder<List<Product>>(future: future, builder: (context, snapshot) {
        if (snapshot.hasError) return ErrorRetry(message: '${snapshot.error}', onRetry: () => setState(load));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty) return const Center(child: Text('Aucun produit publié'));
        return GridView.builder(padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .71, mainAxisSpacing: 10, crossAxisSpacing: 10),
          itemCount: snapshot.data!.length, itemBuilder: (context, i) {
            final product = snapshot.data![i];
            return Card(clipBehavior: Clip.antiAlias, child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetails(product: product, store: widget.store))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: CatalogImage(url: product.image)),
                Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text('${product.price.toStringAsFixed(2)} ${product.currency}', style: const TextStyle(fontWeight: FontWeight.bold))
                ])) ])));
          });
      }))
    ]),
  );
}
class ProductDetails extends StatelessWidget {
  final Product product;
  final Store store;
  const ProductDetails({super.key, required this.product, required this.store});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Détail produit')),
    body: ListView(children: [SizedBox(height: 280, child: CatalogImage(url: product.image)),
      Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(product.name, style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 10),
        Text('${product.price.toStringAsFixed(2)} ${product.currency}', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14), Text(product.description), const SizedBox(height: 22),
        const Text('Le panier, les commandes WhatsApp et WonyaPay seront activés après la création des endpoints de commande sécurisés.',
          style: TextStyle(fontStyle: FontStyle.italic))
      ]))]));
}
class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorRetry({super.key, required this.message, required this.onRetry});
  @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.wifi_off, size: 40),
      const SizedBox(height: 12), Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 12), FilledButton(onPressed: onRetry, child: const Text('Réessayer'))])));
}
