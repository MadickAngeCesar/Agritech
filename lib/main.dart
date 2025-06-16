import 'package:agritech/screens/feature%20page/feature_page.dart';
import 'package:agritech/screens/forgot%20screen/forgot_reset_screen.dart';
import 'package:agritech/screens/market%20place/manage_products_screen.dart';
import 'package:agritech/screens/profile/my_profile.dart';
import 'package:agritech/screens/sign%20in/signIn.dart';
import 'package:agritech/screens/signUp/signUp.dart';
import 'package:agritech/screens/weather/weather.dart';
import 'package:agritech/screens/welcome/welcome.dart';
import 'package:agritech/services/api_service.dart';
import 'package:agritech/services/auth_provider.dart';
import 'package:agritech/services/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ProxyProvider<AuthProvider, ApiService>(
          update: (_, authProvider, __) =>
              ApiService(baseUrl: 'http://10.0.2.2:3000', token: authProvider.token),
        ),
        ChangeNotifierProxyProvider<ApiService, CartProvider>(
          create: (context) => CartProvider(Provider.of<ApiService>(context, listen: false)),
          update: (context, apiService, previous) =>
          previous!..updateApiService(apiService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}



class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgritTech',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2E7D32),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFF66BB6A),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: WelcomeScreen(),
      routes: {
        '/signin':(context)=>AuthScreen(),
        '/signup': (context)=>SignUpScreen(),
        '/feature':(context)=>HomeScreen(userData: {}, token: '',),
        '/profile':(context)=>ProfileScreen(userData: {}, token: '',),
        '/weather': (context) => const WeatherScreen(userData: {}, token: '', ),
        '/add-product':(context)=>AddProductScreen(userData: {}, token: '', categories: [], onProductAdded: () {  },),
        '/forgot-reset': (_) => const ForgotResetScreen(),

      },
    );
  }
}