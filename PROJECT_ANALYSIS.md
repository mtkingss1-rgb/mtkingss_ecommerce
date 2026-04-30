# 🏢 MT-KINGSS E-Commerce Platform - Complete Project Analysis

**Project Status**: 🟢 **Core Features Complete | Ready for Play Store Phase 2**  
**Current Version**: 1.0.0  
**Target Platform**: Google Play Store  
**Development Stage**: Feature-complete MVP with quality improvements pending

---

## 📋 TABLE OF CONTENTS
1. [Project Overview](#project-overview)
2. [Technology Stack](#technology-stack)
3. [Architecture & Design Patterns](#architecture--design-patterns)
4. [Completed Features](#completed-features)
5. [Database Schema](#database-schema)
6. [API Endpoints Reference](#api-endpoints-reference)
7. [Frontend Structure](#frontend-structure)
8. [What Needs Improvement](#what-needs-improvement)
9. [Implementation Roadmap (Priority Order)](#implementation-roadmap-priority-order)
10. [Tools & Technologies Recommendations](#tools--technologies-recommendations)

---

## 📱 PROJECT OVERVIEW

**Name**: MT-KINGSS E-Commerce Platform  
**Type**: Full-stack mobile e-commerce application  
**Primary Market**: Cambodia (Bakong QR payment integration)  
**Target Users**: Customers aged 18-50, Android/iOS  
**Business Model**: B2C marketplace with product catalog, shopping cart, orders, reviews, and wishlist

### Key Business Features
- **User Authentication**: Secure JWT-based authentication with token refresh
- **Product Discovery**: Browse, search, filter by category, price range
- **Shopping Cart**: Add/remove items, modify quantities
- **Order Management**: Place orders, view order history, track status
- **Social Features**: Product reviews/ratings, wishlist (saved items)
- **Payment**: Bakong-KHQR (Cambodia QR code payment system)
- **User Profile**: Manage profile, addresses, password, order history

---

## 🛠️ TECHNOLOGY STACK

### **Frontend** (Flutter 3.10.7)
| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| **Framework** | Flutter | 3.10.7 | Cross-platform mobile development |
| **Language** | Dart | 3.10.7 | Primary programming language |
| **UI Framework** | Material Design 3 | - | Modern Material components |
| **State Management** | Provider | 6.1.1 | Reactive state with ChangeNotifier pattern |
| **HTTP Client** | http | 1.6.0 | REST API communication |
| **Security** | flutter_secure_storage | 10.0.0 | Encrypted token storage |
| **Local Storage** | shared_preferences | 2.5.5 | Key-value preferences |
| **QR Code** | qr_flutter | 4.1.0 | QR code generation (payment) |
| **Maps** | google_maps_flutter | 2.5.3 | Location services |
| **Maps Alternative** | flutter_map | 8.2.2 | Fallback mapping solution |

### **Backend** (Node.js + Express)
| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| **Runtime** | Node.js | Latest | JavaScript runtime |
| **Framework** | Express.js | 5.2.1 | REST API framework |
| **Database** | MongoDB | Via Atlas | NoSQL document database |
| **ODM** | Mongoose | 9.2.3 | MongoDB object modeling |
| **Authentication** | JWT (jsonwebtoken) | 9.0.3 | Token-based authentication |
| **Password Hashing** | bcryptjs | 3.0.3 | Secure password encryption |
| **Validation** | Joi | 18.0.2 | Schema validation |
| **Security** | Helmet.js | 8.1.0 | HTTP headers security |
| **CORS** | cors | 2.8.6 | Cross-origin resource sharing |
| **Environment** | dotenv | 17.3.1 | Configuration management |
| **Logging** | Morgan | 1.10.1 | HTTP request logging |
| **Payment** | bakong-khqr | 1.0.20 | Cambodia QR payment |
| **HTTP Client** | axios | 1.13.6 | API communication |
| **Dev Tools** | nodemon | 3.1.14 | Auto-restart on changes |

### **DevOps & Infrastructure**
- **Containerization**: Docker + Docker Compose
- **Package Manager (Frontend)**: pub
- **Package Manager (Backend)**: npm
- **Version Control**: Git
- **IDE**: Visual Studio Code

---

## 🏗️ ARCHITECTURE & DESIGN PATTERNS

### **Frontend Architecture**
```
┌─────────────────────────────────────────┐
│         Material Design 3 UI             │
├─────────────────────────────────────────┤
│      Provider Pattern State Layer        │
│  (CartProvider, multiple ChangeNotifiers)│
├─────────────────────────────────────────┤
│      Repository Pattern (AuthRepository) │
│         + API Client Layer               │
│  (AuthedApiClient with automatic token)  │
│  (Completer pattern for refresh races)   │
├─────────────────────────────────────────┤
│       HTTP + Secure Storage              │
│  (flutter_secure_storage for JWT)        │
├─────────────────────────────────────────┤
│     REST API Communication               │
│    (Token injection + 401 auto-refresh)  │
└─────────────────────────────────────────┘
```

### **Backend Architecture (MVC)**
```
Routes → Controllers → Models → MongoDB
  ↓
  Middleware (Auth, Validation, Error Handling)
  ↓
  Database Layer (Mongoose)
```

### **Key Design Patterns Used**

#### 1. **JWT Token Rotation**
- **Access Token**: 15 minutes expiration
- **Refresh Token**: 7 days expiration
- **Auto-Refresh**: On 401, automatically calls refresh endpoint and retries
- **Race Condition Prevention**: Uses `Completer` to prevent concurrent refresh requests
- **Storage**: Encrypted via `flutter_secure_storage`

#### 2. **State Preservation with IndexedStack**
- All 5 navigation tabs kept in memory simultaneously
- Scroll position, filters, and form state preserved when switching tabs
- Prevents unnecessary rebuilds or lost data

#### 3. **Provider Pattern (ChangeNotifier)**
- `CartProvider`: Global cart state management
- Optimistic updates with rollback on failure
- Auto-fetch cart after changes
- Single source of truth for cart data

#### 4. **Unique Constraints in Database**
- **Addresses**: `user + label` unique (one address label per user)
- **Reviews**: `user + product` unique (one review per user per product)
- **Wishlist**: `user + product` unique (one wishlist entry per product)

#### 5. **Authorization Pattern**
- Middleware checks: `requireAuth`, `requireRole`
- User extracted from JWT token claims
- Role-based access control (Admin routes)

#### 6. **Error Handling Strategy**
- Centralized error handler middleware (backend)
- Consistent error response format
- User-friendly error messages
- Detailed logging for debugging

---

## ✅ COMPLETED FEATURES

### **FRONTEND** (13 Major Pages/Components)

#### **Authentication Flow**
✅ **LoginScreen** (`auth/login_screen.dart`)
- Email/password login form with validation
- Loading state with spinner
- Error message display
- "Sign up" link navigation
- JWT token storage on success

✅ **Registration** (Implied in backend)
- User account creation with email/password
- Password hashing (bcryptjs - 12 salt rounds)
- JWT token generation on signup

#### **Navigation Shell**
✅ **AppBootstrap** (`main.dart`)
- Token initialization on app startup
- Conditional routing (authenticated vs. unauthenticated)
- MultiProvider setup for state management

✅ **MainShell with 5-Tab Navigation** (`main.dart`)
- IndexedStack: Preserves page state while switching tabs
- BottomNavigationBar with 5 tabs:
  - 🏠 **Home** (Tab 0) - Product browsing
  - 🔍 **Search** (Tab 1) - Advanced filtering
  - 🛒 **Cart** (Tab 2) - Shopping cart
  - 📦 **Orders** (Tab 3) - Order history
  - 👤 **Profile** (Tab 4) - User settings

#### **Product Discovery**
✅ **HomePage** (`pages/home_page.dart`) - 233 lines
- 2-column product grid with responsive layout
- Search bar integration
- Sort dropdown (Price: Low-High, High-Low, Newest)
- Category filter chips
- "Add to Cart" button with CartProvider
- Error states and loading spinners
- Pull-to-refresh functionality

✅ **SearchPage** (`pages/search_page.dart`) - 294 lines
- Advanced search filters:
  - Category chips: [All, Phones, Tablets, Accessories, Fragrance]
  - Price range slider: $0-$1000
  - Sort options: Price ascending/descending, newest
- Real-time filter updates
- Results grid with pagination support
- Empty state handling

✅ **ProductDetailsPage** (`products/product_details_page.dart`) - 250+ lines
- Product image display
- Title, price, category, description
- Quantity selector with +/- buttons
- "Add to Cart" button
- Related products carousel (horizontal scroll)
- **ReviewsSection integration** (NEW)
- Stock availability indicator

#### **Shopping Cart**
✅ **CartPage** (`cart/cart_page.dart`) - 476 lines (REBUILT)
- Complete cart UX redesign:
  - Empty state (cart icon + messaging)
  - Product list with checkboxes (select items)
  - Swipe-to-delete with red background
  - Quantity controls (-, number input, +)
  - Price per item + total calculation
  - "Select All" checkbox
- Checkout bar:
  - Total price display
  - "Checkout (X items)" button
  - Disables if no items selected
- Real-time CartProvider updates
- Error handling for failed operations

✅ **CartProvider** (`providers/cart_provider.dart`)
- Global cart state with ChangeNotifier
- Methods: addToCart, removeFromCart, updateQuantity, clearCart
- Auto-fetch from API after changes
- Optimistic UI updates with rollback
- Single source of truth for cart data

#### **Order Management**
✅ **CheckoutReviewPage** (`orders/checkout_review_page.dart`)
- Order summary and final total calculation
- Address selection integration with fallback to Add Address
- "Place Order" logic with API integration and cart refresh

✅ **OrdersPage** (`pages/orders_page.dart`) - 250+ lines (NEW)
- User's order history with status badges
- Status colors:
  - 🟠 PENDING (Orange)
  - 🔵 PAID (Blue)
  - 🟣 SHIPPED (Purple)
  - 🟢 COMPLETED (Green)
  - 🔴 CANCELLED (Red)
- Pull-to-refresh
- Order list with: order ID, date, item count, total
- Tap to view details

✅ **OrderDetailsPage** (`pages/order_details_page.dart`) - 300+ lines (NEW)
- Full order information:
  - Order ID and date
  - Status badge
  - Items list with images, quantities, prices
  - Per-item and total pricing
  - Shipping address (when available)
- Pricing breakdown: Subtotal, Shipping, Tax, Total
- Loading and error states

#### **User Management**
✅ **ProfilePage** (`pages/profile_page.dart`) - 250+ lines
- User menu structure:
  - **Account Section**: Edit Profile, Addresses, Change Password
  - **Preferences Section**: Wishlist
  - **Help Section**: About App, FAQ
  - **App Section**: App Version, Logout
- Menu items with icons and descriptions
- Navigation to feature pages

✅ **EditProfilePage** (`pages/edit_profile_page.dart`) - 150 lines
- Form fields: First Name, Last Name, Phone
- Input validation (required fields)
- API call with loading state
- Success/error snackbar feedback
- Submit button disabled during loading

✅ **ChangePasswordPage** (`pages/change_password_page.dart`) - 200 lines
- Three password fields:
  - Current password (with visibility toggle)
  - New password (min 6 characters)
  - Confirm password (must match)
- Validation:
  - All fields required
  - New password min length 6
  - Passwords must match
  - Current password verified on backend
- Password visibility toggles
- Success/error feedback

✅ **AddressesPage** (`pages/addresses_page.dart`) - 400+ lines
- List of user's addresses with CRUD:
  - **Add**: FAB opens AddAddressPage form
  - **Edit**: Popup menu option opens EditAddressPage
  - **Delete**: Confirmation dialog before deletion
  - **Set Default**: Toggle default address
- Address fields: Label, Street, City, State, Zip, Country
- Default address badge
- Empty state messaging
- Form validation (all fields required)

#### **Social Features**
✅ **ReviewsSection** (`products/reviews_section.dart`) - 300+ lines (NEW)
- **Reviews Display**:
  - Average rating (1-5 stars)
  - Total review count
  - 5-star rating display in summary
  - Review list with user names, ratings, dates
- **Write Review Button** (launches WriteReviewPage)
- Empty state: "No reviews yet. Be the first!"

✅ **WriteReviewPage** (`products/reviews_section.dart`) - 150+ lines (NEW)
- 5-star rating selector (tap stars to rate)
- Review title field (required)
- Review comment textarea (optional)
- Submit with loading state
- Success/error feedback
- Product title displayed at top

✅ **WishlistPage** (`pages/wishlist_page.dart`) - 250+ lines (NEW)
- Wishlist items display:
  - Product image, title, price
  - Stock status indicator
  - Remove from wishlist option
- Pull-to-refresh
- Empty state: "Wishlist is empty"
- PopupMenu for item actions

#### **Data Models**
✅ **Product** (`models/product.dart`)
- Fields: id, title, description, priceUsd, imageUrl, category, stock
- fromJson, toJson, copyWith methods

✅ **Address** (`models/address.dart`)
- Fields: id, label, street, city, state, zipCode, country, isDefault
- fromJson, toJson, copyWith methods

✅ **Order** (`models/order.dart`)
- Fields: id, items (list), totalUsd, status, paymentMethod, createdAt
- Nested OrderItem class for cart items
- fromJson, toJson methods

✅ **Review** (`models/review.dart`) (implied)
- Fields: id, productId, rating, title, comment, userEmail, helpful, createdAt

#### **API Client**
✅ **AuthedApiClient** (`api/authed_api_client.dart`) - 450+ lines
- **User Endpoints**:
  - `me()` - Get current user
  - `updateProfile(firstName, lastName, phone)` - Update profile
  - `changePassword(current, new)` - Change password
  - `getAddresses()` - List addresses
  - `addAddress(...)` - Add address
  - `updateAddress(id, ...)` - Update address
  - `deleteAddress(id)` - Delete address

- **Product Endpoints**:
  - `listProducts()` - Get all products
  - `getProduct(id)` - Get single product
  - `searchProducts(query)` - Search

- **Cart Endpoints**:
  - `getCart()` - Get user's cart
  - `addToCart(productId, quantity)` - Add item
  - `removeFromCart(productId)` - Remove item
  - `updateCartItem(productId, quantity)` - Update quantity
  - `clearCart()` - Empty cart

- **Order Endpoints**:
  - `getMyOrders()` - Get order history
  - `getOrderDetail(orderId)` - Get order details

- **Review Endpoints**:
  - `createReview(productId, rating, title, comment)` - Submit review
  - `getProductReviews(productId)` - Get product reviews
  - `getUserReviews()` - Get user's reviews
  - `deleteReview(reviewId)` - Delete review

- **Wishlist Endpoints**:
  - `addToWishlist(productId)` - Add to wishlist
  - `getWishlist()` - Get wishlist
  - `removeFromWishlist(productId)` - Remove item
  - `isInWishlist(productId)` - Check if in wishlist

- **Auto-Token Refresh**:
  - Automatic JWT refresh on 401 response
  - Concurrent request locking via `Completer` to prevent race conditions
  - Seamless session expiry handling and automatic logout on failure
  - Retry failed requests after token refresh
  - Transparent to UI layer

### **BACKEND** (8 Module Suites)

#### **1. Authentication Module** (`modules/auth/`)
✅ **auth.model.js**
- Schema: email (unique), password (hashed), tokens (refreshToken)
- Password hashing: bcryptjs with 12 salt rounds
- Methods: comparePassword(), generateTokens()

✅ **auth.controller.js**
- `signup()` - Create user, hash password, generate tokens
- `login()` - Verify credentials, return tokens
- `refreshToken()` - Validate refresh token, issue new access token
- Input validation via Joi

✅ **auth.routes.js**
- POST `/api/v1/auth/signup` - Register user
- POST `/api/v1/auth/login` - Authenticate user
- POST `/api/v1/auth/refresh` - Refresh JWT token

#### **2. User Module** (`modules/user/`)
✅ **user.model.js**
- Fields: email, firstName, lastName, phone, addresses (subdocument array)
- Address fields: label (Home/Work), street, city, state, zipCode, country, isDefault
- Timestamps: createdAt, updatedAt
- Unique index on email
- Unique constraint: user + address label

✅ **user.controller.js**
- `me()` - Get current user profile
- `updateProfile(firstName, lastName, phone)` - Update profile
- `changePassword(currentPassword, newPassword)` - Change password with validation
- `getAddresses()` - List all user addresses
- `addAddress(...)` - Create new address, auto-manage default
- `updateAddress(id, ...)` - Update specific address
- `deleteAddress(id)` - Remove address

✅ **user.routes.js** (7 endpoints)
- GET `/api/v1/users/me` - Auth required
- PATCH `/api/v1/users/me` - Auth required
- POST `/api/v1/users/change-password` - Auth required
- GET `/api/v1/users/addresses` - Auth required
- POST `/api/v1/users/addresses` - Auth required
- PATCH `/api/v1/users/addresses/:id` - Auth required
- DELETE `/api/v1/users/addresses/:id` - Auth required

#### **3. Product Module** (`modules/product/`)
✅ **product.model.js**
- Fields: title, description, priceUsd, currency, imageUrl, category, stock, inStock (computed)
- Indexes: title (B-Tree for fast exact matches), category
- Validation: price > 0, stock >= 0
- Default imageUrl: placeholder if not provided

✅ **product.controller.js**
- `listProducts(filters)` - Get all products with category/price filtering
- `getProduct(id)` - Get single product
- `searchProducts(query)` - Search by title

✅ **product.routes.js** (3 public endpoints)
- GET `/api/v1/products` - List/search
- GET `/api/v1/products/:id` - Get one
- GET `/api/v1/products/search?q=...` - Search

#### **4. Cart Module** (`modules/cart/`)
✅ **cart.model.js**
- Fields: user (ref), items (array of {product, quantity}), total
- Timestamps: createdAt, updatedAt
- Index on user for fast lookups

✅ **cart.controller.js**
- `getCart()` - Get user's current cart
- `addToCart(productId, quantity)` - Add or increment item
- `removeFromCart(productId)` - Remove item
- `updateCartItem(productId, quantity)` - Set quantity
- `clearCart()` - Empty cart

✅ **cart.routes.js** (5 endpoints, all Auth required)
- GET `/api/v1/cart` - Get cart
- POST `/api/v1/cart` - Add item
- PATCH `/api/v1/cart/:productId` - Update quantity
- DELETE `/api/v1/cart/:productId` - Remove item
- DELETE `/api/v1/cart` - Clear cart

#### **5. Order Module** (`modules/order/`)
✅ **order.model.js**
- Fields: user (ref), items (array of {product, title, quantity, priceUsd}), totalUsd, status (enum), paymentMethod, address, timestamps
- Status enum: PENDING, PAID, SHIPPED, COMPLETED, CANCELLED
- Index on user for user's orders query
- Immutable (mostly) - status changes only via controller logic

✅ **order.controller.js**
- `createOrder(items, address)` - Create new order from cart
- `getMyOrders()` - Get user's order history
- `getOrderById(id)` - Get single order with auth check
- `updateOrderStatus(id, status)` - Admin only
- `cancelOrder(id)` - Cancel pending order

✅ **order.routes.js** (Auth required)
- GET `/api/v1/orders/my` - Get user's orders
- GET `/api/v1/orders/:id` - Get order details
- POST `/api/v1/orders` - Create order
- PATCH `/api/v1/orders/:id/status` - Update status (admin)
- DELETE `/api/v1/orders/:id` - Cancel order

#### **6. Review Module** (`modules/review/`) ✨ NEW
✅ **review.model.js**
- Fields: product (ref), user (ref), rating (1-5), title, comment, helpful (counter), timestamps
- Unique constraint: user + product (one review per user per product)
- Indexes: product, user, rating

✅ **review.controller.js**
- `createReview(productId, rating, title, comment)` - Create or update review
- `getProductReviews(productId)` - Get reviews for product + avg rating (public)
- `getUserReviews()` - Get current user's reviews
- `deleteReview(reviewId)` - Delete with auth check

✅ **review.routes.js** (4 endpoints)
- POST `/api/v1/reviews` - Create review (Auth required)
- GET `/api/v1/reviews/product/:productId` - Get product reviews (public)
- GET `/api/v1/reviews/me` - Get user's reviews (Auth required)
- DELETE `/api/v1/reviews/:id` - Delete review (Auth required)

#### **7. Wishlist Module** (`modules/wishlist/`) ✨ NEW
✅ **wishlist.model.js**
- Fields: user (ref), product (ref), timestamps
- Unique constraint: user + product (one entry per product)
- Index on user for fast lookups

✅ **wishlist.controller.js**
- `addToWishlist(productId)` - Add to wishlist (checks existence)
- `getWishlist()` - Get user's wishlist with product details
- `removeFromWishlist(productId)` - Delete from wishlist
- `isInWishlist(productId)` - Check if product in wishlist (boolean)

✅ **wishlist.routes.js** (4 endpoints, all Auth required)
- POST `/api/v1/wishlist` - Add item
- GET `/api/v1/wishlist` - Get list
- DELETE `/api/v1/wishlist/:productId` - Remove item
- GET `/api/v1/wishlist/:productId/check` - Check if in wishlist

#### **8. Payment Module** (`modules/payment/`)
✅ **payment.model.js**
- Fields: order (ref), amount, status, paymentMethod (BAKONG_QR), qrCode, timestamp
- Immutable transaction log

✅ **payment.controller.js**
- `generateQRCode(orderId, amount)` - Generate Bakong QR code
- `verifyPayment(orderId)` - Verify payment received
- `getPaymentStatus(orderId)` - Check payment status

✅ **payment.routes.js**
- POST `/api/v1/payments/generate-qr` - Auth required
- GET `/api/v1/payments/:orderId/status` - Auth required

#### **9. Admin Module** (`modules/admin/`)
✅ **admin.controller.js** (Role-based)
- `getStats()` - Dashboard stats
- `getUsers()` - User management
- `getOrders()` - Order management
- `createProduct()` - Create product
- `updateProduct()` - Edit product
- `deleteProduct()` - Remove product
- `getReviews()` - Review moderation

✅ **admin.routes.js** (Protected with role: 'admin')
- GET `/api/v1/admin/stats`
- GET `/api/v1/admin/users`
- GET `/api/v1/admin/orders`
- POST/PATCH/DELETE `/api/v1/admin/products/:id`

#### **Middleware Suite**
✅ **auth.middleware.js**
- `requireAuth` - Verify JWT, extract user from token
- `requireRole(role)` - Check user role (admin, user, etc.)

✅ **validate.middleware.js**
- Request body validation using Joi schemas
- Auto-respond with 400 + error messages

✅ **errorHandler.js**
- Centralized error handling
- Consistent error response format
- HTTP status code mapping
- Stack traces in dev mode only

✅ **morgan.js**
- HTTP request logging
- Debug mode: full request/response logs

---

## 📊 DATABASE SCHEMA

### **Entity-Relationship Diagram**
```
┌────────────┐         ┌──────────────┐         ┌─────────────┐
│    User    │         │   Product    │         │    Order    │
├────────────┤         ├──────────────┤         ├─────────────┤
│ _id (PK)   │         │ _id (PK)     │         │ _id (PK)    │
│ email (U)  │◄────────│              │         │ user_id (FK)│
│ password   │    ┌────│ title        │         │ items[]     │
│ firstName  │    │    │ price        │         │ totalUsd    │
│ lastName   │    │    │ category     │         │ status      │
│ phone      │    │    │ stock        │         │ createdAt   │
│ addresses[]│    │    │ imageUrl     │         └─────────────┘
│ createdAt  │    │    │ createdAt    │              ▲
└────────────┘    │    └──────────────┘              │
      │           │           ▲                       │
      │           │           │ (product_id)         │
      │           │           │                       │
      │     ┌─────▼───────────┴──┐            ┌──────┴────────────┐
      │     │   Cart            │            │    Review          │
      │     ├───────────────────┤            ├────────────────────┤
      │     │ _id (PK)          │            │ _id (PK)           │
      │     │ user_id (FK)      │            │ user_id (FK)       │
      │     │ items[]           │            │ product_id (FK)    │
      │     │   - product       │            │ rating (1-5)       │
      │     │   - quantity      │            │ title              │
      │     │ total             │            │ comment            │
      │     │ createdAt         │            │ helpful (counter)  │
      │     └───────────────────┘            │ createdAt          │
      │                                      └────────────────────┘
      │     ┌─────────────────────┐
      │     │   Wishlist          │
      │     ├─────────────────────┤
      │     │ _id (PK)            │
      │     │ user_id (FK)        │
      │     │ product_id (FK)     │
      │     │ createdAt           │
      │     │ (U: user + product) │
      │     └─────────────────────┘
      │
      └─► addresses[] (subdocument in User)
          - label (Home/Work)
          - street, city, state, zipCode, country
          - isDefault
          - (U: user + label)
```

### **Indexes for Performance**
| Collection | Index | Type | Purpose |
|-----------|-------|------|---------|
| User | email | Unique | Fast user lookup |
| Product | title | B-Tree | Full-text search optimization |
| Product | category | Standard | Filter by category |
| Cart | user_id | Standard | Fast cart retrieval |
| Order | user_id | Standard | Get user's orders |
| Order | status | Standard | Filter orders by status |
| Review | product_id | Standard | Get product reviews |
| Review | user_id | Standard | Get user's reviews |
| Review | user + product | Unique | Prevent duplicate reviews |
| Wishlist | user_id | Standard | Get user's wishlist |
| Wishlist | user + product | Unique | Prevent duplicates |

---

## 🔌 API ENDPOINTS REFERENCE

### **Authentication** (Public)
```
POST   /api/v1/auth/signup              → Register user
POST   /api/v1/auth/login               → Authenticate
POST   /api/v1/auth/refresh             → Refresh JWT token
```

### **User** (Auth Required)
```
GET    /api/v1/users/me                 → Get profile
PATCH  /api/v1/users/me                 → Update profile
POST   /api/v1/users/change-password    → Change password
GET    /api/v1/users/addresses          → List addresses
POST   /api/v1/users/addresses          → Add address
PATCH  /api/v1/users/addresses/:id      → Update address
DELETE /api/v1/users/addresses/:id      → Delete address
```

### **Products** (Public)
```
GET    /api/v1/products                 → List products (with filters)
GET    /api/v1/products/:id             → Get product details
GET    /api/v1/products/search?q=...    → Search products
```

### **Cart** (Auth Required)
```
GET    /api/v1/cart                     → Get cart
POST   /api/v1/cart                     → Add to cart
PATCH  /api/v1/cart/:productId          → Update quantity
DELETE /api/v1/cart/:productId          → Remove from cart
DELETE /api/v1/cart                     → Clear cart
```

### **Orders** (Auth Required)
```
GET    /api/v1/orders/my                → Get order history
GET    /api/v1/orders/:id               → Get order details
POST   /api/v1/orders                   → Create order
PATCH  /api/v1/orders/:id/status        → Update status (admin)
DELETE /api/v1/orders/:id               → Cancel order
```

### **Reviews** (Mixed)
```
POST   /api/v1/reviews                  → Create review (Auth)
GET    /api/v1/reviews/product/:id      → Get product reviews (Public)
GET    /api/v1/reviews/me               → Get user's reviews (Auth)
DELETE /api/v1/reviews/:id              → Delete review (Auth)
```

### **Wishlist** (Auth Required)
```
POST   /api/v1/wishlist                 → Add to wishlist
GET    /api/v1/wishlist                 → Get wishlist
DELETE /api/v1/wishlist/:productId      → Remove from wishlist
GET    /api/v1/wishlist/:productId/check → Check if in wishlist
```

### **Payment** (Auth Required)
```
POST   /api/v1/payments/generate-qr     → Generate Bakong QR
GET    /api/v1/payments/:orderId/status → Check payment status
```

### **Admin** (Admin Role Required)
```
GET    /api/v1/admin/stats              → Dashboard statistics
GET    /api/v1/admin/users              → User management
GET    /api/v1/admin/orders             → Order management
POST   /api/v1/admin/products           → Create product
PATCH  /api/v1/admin/products/:id       → Update product
DELETE /api/v1/admin/products/:id       → Delete product
```

---

## 📁 FRONTEND FILE STRUCTURE

```
mobile/lib/
├── main.dart                           # App entry + routing logic
│
├── src/
│   ├── admin/                          # Admin dashboard (placeholder)
│   │   └── admin_dashboard.dart
│   │
│   ├── api/
│   │   ├── authed_api_client.dart     # HTTP client with JWT + 9 method suites
│   │   └── api_config.dart            # Base URL config
│   │
│   ├── auth/
│   │   ├── auth_repository.dart       # Token management + refresh logic
│   │   ├── auth_api.dart              # Auth endpoints (signup/login)
│   │   └── login_screen.dart          # Login UI
│   │
│   ├── cart/
│   │   └── cart_page.dart             # Shopping cart UI (476 lines)
│   │
│   ├── config/
│   │   └── api_config.dart            # API base URL
│   │
│   ├── models/
│   │   ├── product.dart               # Product data model
│   │   ├── address.dart               # Address model
│   │   ├── order.dart                 # Order + OrderItem models
│   │   ├── review.dart                # Review model (implied)
│   │   └── admin_stats.dart           # Admin dashboard data
│   │
│   ├── orders/
│   │   └── orders_page.dart           # Orders listing (NEW)
│   │
│   ├── pages/
│   │   ├── home_page.dart             # Product grid + search
│   │   ├── search_page.dart           # Advanced filters
│   │   ├── profile_page.dart          # User menu + settings
│   │   ├── edit_profile_page.dart     # Edit profile form
│   │   ├── change_password_page.dart  # Password change form
│   │   ├── addresses_page.dart        # Address management (CRUD)
│   │   ├── wishlist_page.dart         # Wishlist UI (NEW)
│   │   └── order_details_page.dart    # Order details view (NEW)
│   │
│   ├── products/
│   │   ├── product_details_page.dart  # Product page + reviews
│   │   └── reviews_section.dart       # Reviews component (NEW)
│   │
│   ├── providers/
│   │   └── cart_provider.dart         # Global cart state
│   │
│   ├── screens/
│   │   └── login_screen.dart          # Authentication UI
│   │
│   └── storage/
│       └── token_storage.dart         # Secure JWT storage

pubspec.yaml                            # Dependencies manifest
```

---

## 🔄 WHAT NEEDS IMPROVEMENT

### **TIER 1: Critical for Play Store** (Must-Have)
1. **Testing Coverage**
   - ❌ No unit tests for models/providers
   - ❌ No widget tests for UI components
   - ❌ No integration tests for API flows
   - ❌ No backend API tests
   - **Impact**: 🔴 High - Tests required for Play Store
   - **Tools Needed**: flutter_test, Mockito, Jest (Node.js)

2. **Error Handling & Validation**
   - ⚠️ Limited form validation (only required fields)
   - ⚠️ Some edge cases in payment flow not handled
   - ⚠️ Network timeouts not properly managed
   - **Impact**: 🔴 High - User data integrity
   - **Tools Needed**: Input validation package, Dio (HTTP with interceptors)

3. **Security & Performance**
   - ⚠️ No HTTPS enforcement (implicit via firebase)
   - ⚠️ No request rate limiting on backend
   - ⚠️ No API response caching on frontend
   - **Impact**: 🟠 Medium - DDoS vulnerability
   - **Tools Needed**: express-rate-limit, Hive (Flutter caching)

4. **App Stability**
   - ⚠️ No crash reporting
   - ⚠️ No analytics
   - ⚠️ Limited error logging
   - **Impact**: 🟠 Medium - Cannot debug production issues
   - **Tools Needed**: Firebase Crashlytics, Firebase Analytics

### **TIER 2: UX/Quality** (Should-Have)
5. **UI Polish & Accessibility**
   - ⚠️ No dark mode optimization (basic theme only)
   - ⚠️ No accessibility features (semantics, screen reader support)
   - ⚠️ Limited image optimization (no lazy loading)
   - ⚠️ No animation/transitions between routes
   - **Impact**: 🟡 Medium - Rating on Play Store
   - **Tools Needed**: flutter_svg, GetX animations, Accessibility semantics

6. **Advanced Features**
   - ❌ No payment confirmation/callback handling
   - ❌ No order notifications (email/SMS/push)
   - ❌ No image uploads for reviews
   - ❌ No product comparison feature
   - ❌ No wishlist → cart bulk transfer
   - **Impact**: 🟡 Medium - Competitive feature set
   - **Tools Needed**: Firebase Messaging, image_picker, getx

7. **Backend Robustness**
   - ⚠️ No request logging/audit trail
   - ⚠️ No database backup strategy
   - ⚠️ No API rate limiting
   - ⚠️ No transaction handling for orders
   - **Impact**: 🟡 Medium - Data safety
   - **Tools Needed**: Winston (logging), Stripe/Razorpay SDK, Bull (queues)

8. **Documentation & Maintenance**
   - ❌ No API documentation (Swagger/OpenAPI)
   - ❌ No code comments/JSDoc
   - ❌ No deployment guide
   - ❌ No troubleshooting guide
   - **Impact**: 🟡 Medium - Team scaling
   - **Tools Needed**: Swagger UI, JSDoc, GitHub Wiki

### **TIER 3: Nice-to-Have** (Could-Have)
9. **Performance Optimization**
   - ⚠️ No pagination for product list (loads all)
   - ⚠️ No image compression
   - ⚠️ No code splitting/lazy loading
   - ⚠️ No database query optimization
   - **Tools Needed**: flutter_pagination, Image processing libraries, Database indexing

10. **Advanced Search**
    - ❌ No full-text search (only exact match)
    - ❌ No search history
    - ❌ No search suggestions/autocomplete
    - **Tools Needed**: Elasticsearch, Algolia

11. **Admin Dashboard**
    - ⚠️ Endpoints exist but no UI
    - ❌ No analytics/charts
    - ❌ No product management UI
    - ❌ No user management UI
    - ❌ No order tracking UI
    - **Tools Needed**: Flutter charts (fl_chart), DataTables

12. **Social Features**
    - ❌ No user profiles/reputation
    - ❌ No review voting (helpful/unhelpful)
    - ❌ No review comments/replies
    - ❌ No product sharing
    - ❌ No referral system
    - **Tools Needed**: Share plugin, Social SDK

---

## 🎯 IMPLEMENTATION ROADMAP (Priority Order)

### **Phase 1: Critical Stability** (Weeks 1-2)
| Task | Status | File(s) | Tools/Functions | Effort |
|------|--------|---------|-----------------|--------|
| Add input validation | ❌ | pages/*.dart | Dio package, custom validators | 4 days |
| Implement error boundaries | ❌ | main.dart, pages/* | flutter_error_handler | 2 days |
| Add network timeout handling | ❌ | authed_api_client.dart | Dio interceptors | 1 day |
| Setup crash reporting | ❌ | main.dart | Firebase Crashlytics | 1 day |
| Add unit tests (models) | ❌ | test/*.dart | flutter_test, Mockito | 3 days |
| Add widget tests (key flows) | ❌ | test/*.dart | flutter_test, WidgetTester | 4 days |
| **Total**: | | | | **15 days** |

### **Phase 2: Backend Robustness** (Weeks 3-4)
| Task | Status | File(s) | Tools/Functions | Effort |
|------|--------|---------|-----------------|--------|
| Add request logging | ❌ | middlewares/*, controllers/* | Winston logger | 2 days |
| Add rate limiting | ❌ | app.js | express-rate-limit | 1 day |
| Add transaction handling | ❌ | order.controller.js | Mongoose transactions | 2 days |
| Add backup strategy | ❌ | package.json scripts | MongoDB backup tools | 2 days |
| Create Swagger docs | ❌ | swagger.yaml | Swagger UI | 3 days |
| Add API tests | ❌ | test/*.test.js | Jest, Supertest | 5 days |
| **Total**: | | | | **15 days** |

### **Phase 3: UI/UX Enhancements** (Weeks 5-6)
| Task | Status | File(s) | Tools/Functions | Effort |
|------|--------|---------|-----------------|--------|
| Add dark mode polish | ❌ | main.dart, pages/* | ThemeData, CupertinoDynamicColor | 2 days |
| Add accessibility | ❌ | All pages | Semantics widget | 3 days |
| Implement animations | ❌ | pages/*, products/* | GetX, Flutter animations | 4 days |
| Add image lazy loading | ❌ | home_page.dart, search_page.dart | cached_network_image | 2 days |
| Add pagination | ❌ | home_page.dart, search_page.dart | flutter_pagination | 3 days |
| **Total**: | | | | **14 days** |

### **Phase 4: Advanced Features** (Weeks 7-9)
| Task | Status | File(s) | Tools/Functions | Effort |
|------|--------|---------|-----------------|--------|
| Payment callbacks | ❌ | order.model.js, payment/* | Bakong webhook handling | 3 days |
| Push notifications | ❌ | main.dart, providers/* | Firebase Cloud Messaging | 3 days |
| Email notifications | ❌ | order.controller.js | Nodemailer, SendGrid | 2 days |
| Admin dashboard UI | ❌ | admin/*.dart | fl_chart, DataTable2 | 5 days |
| Product image upload | ❌ | admin/*.dart, product.controller.js | image_picker, multer | 3 days |
| Review images/videos | ❌ | reviews_section.dart | image_picker, video_player | 3 days |
| **Total**: | | | | **19 days** |

### **Phase 5: Performance & Optimization** (Week 10)
| Task | Status | File(s) | Tools/Functions | Effort |
|------|--------|---------|-----------------|--------|
| Database query optimization | ❌ | *.controller.js | Index analysis, .explain() | 2 days |
| Image compression | ❌ | product_details_page.dart | image/compression plugin | 1 day |
| API response caching | ❌ | authed_api_client.dart | Hive, GetStorage | 2 days |
| Code splitting | ❌ | main.dart | Flutter route lazy loading | 2 days |
| **Total**: | | | | **7 days** |

**Total Timeline**: ~10 weeks (~70 development days)  
**Team Size**: 2 developers (1 Flutter, 1 Node.js) = 5 weeks  
**Team Size**: 1 full-stack = 10 weeks

---

## 🛠️ TOOLS & TECHNOLOGIES RECOMMENDATIONS

### **Frontend (Flutter) Tools**

#### **Testing & Quality**
| Tool | Purpose | Installation |
|------|---------|--------------|
| **flutter_test** | Unit/widget testing | Built-in with Flutter SDK |
| **Mockito** | Mocking for tests | `pub add dev:mockito` |
| **integration_test** | End-to-end tests | Built-in with Flutter SDK |
| **very_good_analysis** | Lint rules (strict) | `pub add dev:very_good_analysis` |

#### **State Management & Architecture**
| Tool | Purpose | Installation |
|------|---------|--------------|
| **Riverpod** | Modern state mgmt (alternative) | `pub add riverpod` |
| **GetX** | State + routing + dependency injection | `pub add get` |
| **BLoC** | Scalable state architecture | `pub add flutter_bloc` |

#### **API & Networking**
| Tool | Purpose | Installation |
|------|---------|--------------|
| **Dio** | HTTP with interceptors + caching | `pub add dio` |
| **retrofit** | Type-safe API client generation | `pub add retrofit` |
| **graphql** | GraphQL queries (if migrating API) | `pub add graphql` |

#### **UI/UX Enhancements**
| Tool | Purpose | Installation |
|------|---------|--------------|
| **flutter_svg** | SVG rendering + vector graphics | `pub add flutter_svg` |
| **cached_network_image** | Image caching + lazy loading | `pub add cached_network_image` |
| **GetX** | Smooth animations + transitions | `pub add get` |
| **fl_chart** | Beautiful charts for analytics | `pub add fl_chart` |
| **shimmer** | Loading placeholders | `pub add shimmer` |
| **lottie** | Animated assets | `pub add lottie` |

#### **Data & Storage**
| Tool | Purpose | Installation |
|------|---------|--------------|
| **Hive** | Local database + caching | `pub add hive` |
| **sqflite** | SQLite for offline data | `pub add sqflite` |
| **json_serializable** | Auto JSON conversion | `pub add dev:json_serializable` |

#### **Analytics & Monitoring**
| Tool | Purpose | Installation |
|------|---------|--------------|
| **Firebase Crashlytics** | Crash reporting | `pub add firebase_crashlytics` |
| **Firebase Analytics** | User behavior tracking | `pub add firebase_analytics` |
| **Sentry** | Error tracking (alternative) | `pub add sentry_flutter` |

#### **Accessibility & Localization**
| Tool | Purpose | Installation |
|------|---------|--------------|
| **Semantics** | Screen reader support | Built-in Flutter |
| **intl** | Multi-language support | `pub add intl` |
| **easy_localization** | Easy i18n setup | `pub add easy_localization` |

#### **Image & Media**
| Tool | Purpose | Installation |
|------|---------|--------------|
| **image_picker** | Camera + gallery picker | `pub add image_picker` |
| **image_compression** | Image compression | `pub add image_compression` |
| **video_player** | Video playback | `pub add video_player` |

#### **Performance & Profiling**
| Tool | Purpose | Command |
|------|---------|---------|
| **DevTools** | Performance profiling | `flutter pub global activate devtools` |
| **Perfetto** | Low-level tracing | Built-in with DevTools |

### **Backend (Node.js) Tools**

#### **Testing & Quality**
| Tool | Purpose | Installation |
|------|---------|--------------|
| **Jest** | Unit testing framework | `npm install --save-dev jest` |
| **Supertest** | HTTP testing | `npm install --save-dev supertest` |
| **ESLint** | Code quality linting | `npm install --save-dev eslint` |
| **Prettier** | Code formatting | `npm install --save-dev prettier` |

#### **Security & Validation**
| Tool | Purpose | Installation |
|------|---------|--------------|
| **express-rate-limit** | Rate limiting | `npm install express-rate-limit` |
| **express-validator** | Advanced validation | `npm install express-validator` |
| **helmet** | HTTP headers security | `npm install helmet` (Already installed) |
| **cors** | CORS configuration | `npm install cors` (Already installed) |
| **dotenv** | Env variable management | `npm install dotenv` (Already installed) |

#### **Logging & Monitoring**
| Tool | Purpose | Installation |
|------|---------|--------------|
| **Winston** | Structured logging | `npm install winston` |
| **Morgan** | HTTP request logging | `npm install morgan` (Already installed) |
| **Sentry** | Error tracking | `npm install @sentry/node` |
| **New Relic** | APM monitoring | `npm install newrelic` |

#### **Data & Caching**
| Tool | Purpose | Installation |
|------|---------|--------------|
| **Redis** | In-memory caching | `npm install redis` |
| **Bull** | Job queue system | `npm install bull` |
| **node-cache** | Simple memory cache | `npm install node-cache` |

#### **Documentation & API**
| Tool | Purpose | Installation |
|------|---------|--------------|
| **Swagger/OpenAPI** | API documentation | `npm install swagger-jsdoc swagger-ui-express` |
| **JSDoc** | Code documentation | `npm install --save-dev jsdoc` |
| **Postman** | API testing (external) | Download from postman.com |

#### **Payment Integration**
| Tool | Purpose | Installation |
|------|---------|--------------|
| **stripe** | Payment processing | `npm install stripe` |
| **razorpay** | Indian payments | `npm install razorpay` |
| **bakong-khqr** | Cambodia QR payments | `npm install bakong-khqr` (Already installed) |

#### **Email & Notifications**
| Tool | Purpose | Installation |
|------|---------|--------------|
| **Nodemailer** | Email sending | `npm install nodemailer` |
| **SendGrid** | Email delivery (SaaS) | `npm install @sendgrid/mail` |
| **Firebase Admin** | Push notifications | `npm install firebase-admin` |
| **Twilio** | SMS notifications | `npm install twilio` |

#### **File Upload & Storage**
| Tool | Purpose | Installation |
|------|---------|--------------|
| **Multer** | File upload middleware | `npm install multer` |
| **AWS S3** | Cloud storage | `npm install aws-sdk` |
| **Cloudinary** | Image CDN | `npm install cloudinary` |

#### **Database Tools**
| Tool | Purpose | Installation |
|------|---------|--------------|
| **MongoDB Atlas CLI** | Database management | `npm install -g atlas` |
| **Mongoose** | ODM/query builder | `npm install mongoose` (Already installed) |
| **mongo-express** | Web admin | `npm install mongo-express` |

### **Development & DevOps Tools**

| Tool | Purpose | Installation |
|------|---------|--------------|
| **Docker** | Containerization | Download from docker.com |
| **Docker Compose** | Multi-container orchestration | docker-compose.yml (Already set up) |
| **GitHub Actions** | CI/CD pipeline | Configure .github/workflows/ |
| **Firebase** | Hosting + Analytics | google-cloud-sdk |
| **ngrok** | Local tunneling (testing) | Download from ngrok.com |
| **Postman** | API testing tool | Download from postman.com |

---

## 📈 SUCCESS METRICS & KPIs

### **Before Play Store**
- ✅ 95%+ test coverage
- ✅ 0 critical security vulnerabilities
- ✅ <2 second app startup
- ✅ <500ms API response time (p95)
- ✅ 0 unhandled exceptions (monitored)

### **After Play Store (3 months)**
- 10,000+ downloads
- 4.5+ star rating
- <1% daily crash rate
- 90%+ user retention (day 1 → day 7)
- 20%+ conversion rate (browsing → purchase)

---

## 🎓 KEY LEARNINGS & PATTERNS USED

1. **JWT Token Rotation** - Secure auth without exposing long-lived tokens
2. **State Preservation** - IndexedStack vs PageView for maintaining UI state
3. **Unique Constraints** - Database-level duplicate prevention (reviews, addresses)
4. **Provider Pattern** - Global state with automatic UI updates
5. **Middleware Composition** - Reusable authentication/validation logic
6. **Optimistic Updates** - Improve perceived performance in cart operations
7. **Automatic Token Refresh** - Transparent to UI, improves UX

---

## 📞 QUICK REFERENCE

### **Common Commands**
```bash
# Frontend
flutter pub get              # Install dependencies
flutter analyze              # Code quality check
flutter build apk            # Build for Play Store
flutter test                 # Run tests

# Backend
npm install                  # Install dependencies
npm run dev                  # Development server
npm start                    # Production server
npm test                     # Run tests
```

### **Environment Variables** (.env)
```env
# Backend
PORT=3000
MONGODB_URI=mongodb+srv://...
JWT_SECRET=your-secret-key
JWT_REFRESH_SECRET=your-refresh-secret
NODE_ENV=production

# Frontend
BASE_URL=https://your-api.com
APP_NAME=MT-KINGSS
VERSION=1.0.0
```

---

**Last Updated**: April 2026  
**Status**: 🟢 Feature-Complete MVP | Ready for Quality Phase  
**Next Milestone**: Play Store Release v1.1.0
