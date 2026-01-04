import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'models/product.dart';


class Cart extends StatefulWidget {
  final Product product;

  const Cart({super.key, required this.product});

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/'),
        ),
        backgroundColor: const Color(0xFFF5EFE8),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// IMAGE
              Image.network(
                "http://127.0.0.1:5000/uploads/${p.image}",
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 10),

              /// TITLE
              Text(
                p.name,
                style: const TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              /// PRICE
              Text(
                "\$${p.price}",
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              /// RATING
              RatingBarIndicator(
                rating: p.star.toDouble(),
                itemCount: 5,
                itemSize: 20,
                itemBuilder: (context, _) =>
                    const Icon(Icons.star, color: Colors.amber),
              ),

              const SizedBox(height: 20),

              /// DESCRIPTION
              Text(
                p.description,
                style: const TextStyle(fontSize: 15),
              ),

              const SizedBox(height: 30),

              /// SPECIFICATIONS
              const Text(
                "Specifications",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              buildSpec("Engine", p.engine),
              buildSpec("Power", "${p.power} HP"),
              buildSpec("Top speed", "${p.topSpeed} km/h"),
              buildSpec("Fuel Tank", "${p.fuel} liters"),
              buildSpec("Weight", "${p.weight} kg"),
              buildSpec("Mileage", "${p.mileage} km/l"),
            ],
          ),
        ),
      ),
    );
  }

  /// REUSABLE SPEC ROW
  Widget buildSpec(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(title, style: const TextStyle(fontSize: 20)),
          ),
          Text(value, style: const TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}
