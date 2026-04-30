import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';

import 'src/api/authed_api_client.dart';
import 'src/auth/auth_api.dart';
import 'src/auth/auth_repository.dart';
import 'src/storage/token_storage.dart';

import 'src/cart/cart_page.dart';
import 'src/orders/orders_page.dart'; 
import 'src/screens/login_screen.dart';
import 'src/providers/cart_provider.dart';
import 'src/providers/theme_provider.dart';
import 'src/pages/home_page.dart';
import 'src/pages/search_page.dart';
import 'src/pages/profile_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 1. Handle Flutter framework errors (synchronous)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  // 2. Handle asynchronous Dart errors (e.g., unhandled Futures)
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // 3. User-friendly Error Screen (replaces the Red Screen of Death)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
            SizedBox(height: 16),
            Text(
              'Oops! Something went wrong.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Please try restarting the app.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer rebuilds the MaterialApp instantly when the theme is toggled
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'MT-KINGSS',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.deepPurple,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            cardColor: Colors.white,
            dividerColor: Colors.grey[200],
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: SharedAxisPageTransitionsBuilder(
                  transitionType: SharedAxisTransitionType.horizontal,
                ),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.deepPurple,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            dividerColor: Colors.white10,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: SharedAxisPageTransitionsBuilder(
                  transitionType: SharedAxisTransitionType.horizontal,
                ),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          themeMode: themeProvider.themeMode, 
          home: const AppBootstrap(),
        );
      },
    );
  }
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final TokenStorage _storage;
  late final AuthRepository _authRepo;
  late final AuthedApiClient _api;

  bool _ready = false;
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    _storage = TokenStorage();
    _authRepo = AuthRepository(api: AuthApi(), storage: _storage);
    _api = AuthedApiClient(auth: _authRepo);
    _init();
  }

  Future<void> _init() async {
    final access = await _authRepo.getAccessToken();
    if (!mounted) return;
    setState(() {
      _hasToken = access != null && access.isNotEmpty;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _hasToken 
      ? HomeShell(api: _api, auth: _authRepo) 
      : LoginPage(auth: _authRepo, api: _api);
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.api, required this.auth});
  final AuthedApiClient api;
  final AuthRepository auth;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  bool _loadingMe = true;
  Map<String, dynamic>? _meJson;

  @override
  void initState() {
    super.initState();
    _loadMe();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().fetchCart(widget.api);
    });
  }

  Future<void> _loadMe() async {
    try {
      final j = await widget.api.me();
      if (mounted) setState(() => _meJson = j);
    } catch (e) {
      debugPrint("Me API Error: $e");
    } finally {
      if (mounted) setState(() => _loadingMe = false);
    }
  }

  Future<void> _logout() async {
    await widget.auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage(auth: widget.auth, api: widget.api)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MT-KINGSS', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(tooltip: 'Logout', onPressed: _logout, icon: const Icon(Icons.logout_outlined)),
        ],
      ),
      body: _loadingMe
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _tab,
              children: [
                HomePage(api: widget.api),
                SearchPage(api: widget.api),
                CartPage(api: widget.api),
                OrdersPage(api: widget.api),
                ProfilePage(
                  api: widget.api,
                  auth: widget.auth,
                  onLogout: _logout,
                  userJson: _meJson,
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Consumer<CartProvider>(
              builder: (context, provider, child) {
                final count = provider.cart?.items.length ?? 0;
                return Badge(
                  label: Text('$count'),
                  isLabelVisible: count > 0,
                  backgroundColor: Colors.redAccent,
                  child: const Icon(Icons.shopping_bag),
                );
              },
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_rounded),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}