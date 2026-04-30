import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/src/api/authed_api_client.dart';
import 'package:mobile/src/providers/cart_provider.dart';

// 1. Create the mock class manually using Mocktail (No build_runner needed!)
class MockAuthedApiClient extends Mock implements AuthedApiClient {}

void main() {
  // Initialize the Flutter test environment
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CartProvider', () {
    late MockAuthedApiClient mockApi;
    late CartProvider cartProvider;

    // setUp runs before EVERY test. It ensures we start with fresh objects.
    setUp(() {
      // Give SharedPreferences a fake empty memory to use during tests
      SharedPreferences.setMockInitialValues({});

      mockApi = MockAuthedApiClient();
      cartProvider = CartProvider();
    });

    test('initial cart is null', () {
      expect(cartProvider.cart, isNull);
    });

    test('fetchCart successfully requests cart data from API', () async {
      // 1. ARRANGE: Tell the mock API what to return when getCart is called
      when(() => mockApi.getCart()).thenAnswer((_) async => {
            'items': [],
            'total': 0.0,
          });
      // We also need to mock listProducts since fetchCart calls it
      when(() => mockApi.listProducts()).thenAnswer((_) async => {
            'products': [],
          });

      // 2. ACT: Call the method on our provider
      await cartProvider.fetchCart(mockApi);

      // 3. ASSERT: Verify the provider called the API exactly once
      verify(() => mockApi.getCart()).called(1);
    });

    test('addToCart sends product data to the API', () async {
      // 1. ARRANGE: Set up our test data and mock API response
      const testProductId = 'prod_123';
      const testQuantity = 2;
      
      when(() => mockApi.addToCart(
            productId: testProductId,
            quantity: testQuantity,
          )).thenAnswer((_) async => {});
          
      // addToCart calls fetchCart internally, so we must mock these too!
      when(() => mockApi.getCart()).thenAnswer((_) async => {
            'items': [],
            'total': 0.0,
          });
      when(() => mockApi.listProducts()).thenAnswer((_) async => {
            'products': [],
          });

      // 2. ACT: Trigger the method
      await cartProvider.addToCart(mockApi, testProductId, testQuantity);

      // 3. ASSERT: Verify the provider passed the correct data to the API
      verify(() => mockApi.addToCart(productId: testProductId, quantity: testQuantity)).called(1);
    });
  });
}