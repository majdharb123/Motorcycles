import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'home.dart';
import 'cart.dart';
import 'register.dart';
import 'login.dart';
import 'admin.dart';
import 'models/product.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final GoRouter _router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => Home()),
        GoRoute(
          path: '/cart',
          builder: (context, state) {
            final product = state.extra as Product?;
            return Cart(product: product!);
          },
        ),
        GoRoute(path: '/register', builder: (context, state) => Register()),
        GoRoute(path: '/login', builder: (context, state) => Login()),
        GoRoute(path: '/admin', builder: (context, state) => Admin()),
      ],
    );
    return MaterialApp.router(
      title: "Moto Store",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
