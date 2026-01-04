import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'models/product.dart';


/// ================== HOME PAGE ==================
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final String baseUrl = "https://motorcycles-zroi.onrender.com";

  Map<String, dynamic>? user;
  bool loadingUser = true;
  bool loadingProducts = true;

  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
    fetchProducts();
  }

  /// ================== LOAD USER ==================
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString("user");

    if (userData != null) {
      user = jsonDecode(userData);
    }

    setState(() => loadingUser = false);
  }

  /// ================== LOGOUT ==================
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    context.go('/login');
  }

  /// ================== FETCH PRODUCTS ==================
  Future<void> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/api/product"));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        products = data.map((item) {
          return Product(
            id: item['id'].toString(),
            name: item['name'],
            description: item['description'],
            price: double.parse(item['price'].toString()),
            star: int.parse(item['star'].toString()),
            engine: item['engine'],
            power: int.parse(item['power'].toString()),
            topSpeed: int.parse(item['topspeed'].toString()),
            fuel: int.parse(item['fuel'].toString()),
            weight: int.parse(item['weight'].toString()),
            mileage: int.parse(item['mileage'].toString()),
            image: item['image'],
          );
        }).toList();
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
    }

    setState(() => loadingProducts = false);
  }

  /// ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5EFE8),
        title: const Text(
          "Moto Store",
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!loadingUser)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: user == null
                  ? ElevatedButton(
                      onPressed: () => context.go('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5EFE8),
                        elevation: 10,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 14,
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(color: Colors.black, fontSize: 18),
                      ),
                    )
                  : Row(
                      children: [
                        Text(
                          "Hi, ${user!['name']}",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 10),
                        if (user!['isAdmin'] == 1)
                          ElevatedButton(
                            onPressed: () => context.go('/admin'),
                            child: const Text("Admin"),
                          ),
                        IconButton(
                          icon: const Icon(Icons.logout),
                          onPressed: _logout,
                        ),
                      ],
                    ),
            ),
        ],
      ),
      body: loadingProducts
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: (products.length / 2).ceil(),
              itemBuilder: (context, index) {
                final first = index * 2;
                final second = first + 1;

                return Row(
                  children: [
                    Expanded(
                      child: buildBikeCard(products[first], context),
                    ),
                    if (second < products.length)
                      Expanded(
                        child: buildBikeCard(products[second], context),
                      )
                    else
                      const Expanded(child: SizedBox()),
                  ],
                );
              },
            ),
    );
  }
}

/// ================== BIKE CARD ==================
Widget buildBikeCard(Product product, BuildContext context) {
  return InkWell(
    onTap: () => context.go('/cart', extra: product),
    child: Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              "https://motorcycles-zroi.onrender.com/uploads/${product.image}",
              height: 120,
              width: 220,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              "\$${product.price}",
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            RatingBarIndicator(
              rating: product.star.toDouble(),
              itemCount: 5,
              itemSize: 20,
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.amber),
            ),
          ],
        ),
      ),
    ),
  );
}
