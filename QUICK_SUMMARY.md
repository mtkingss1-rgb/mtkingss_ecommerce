# 📊 MT-KINGSS - QUICK PROJECT SUMMARY

## 🎯 What This Project Is
**Full-stack Flutter + Node.js e-commerce app** for Cambodia marketplace with product browsing, cart, orders, reviews, and wishlist.

### **Phase 10: Stability & Polish**
```
✅ Fixed token refresh race condition with Completer queue
✅ Handled session expiration and auto-logout gracefully
✅ Integrated Address selection in Checkout flow
✅ Adapted backend for standalone MongoDB (local dev)
✅ Implemented 15-second network timeouts
```


## ✅ COMPLETED (9 Phases)

### **Phase 1-5: Core App Architecture**
```
✅ 5-Tab Bottom Navigation (IndexedStack preserves state)
✅ User Authentication (JWT + secure storage)
✅ Product Discovery (Home page + Advanced search)
✅ Shopping Cart (with provider state management)
✅ User Profile Management (Edit, Addresses, Password)
```

### **Phase 6-7: Backend Infrastructure**
```
✅ 8 API Modules (Auth, User, Product, Cart, Order, Review, Wishlist, Payment)
✅ JWT Authentication with auto-refresh
✅ MongoDB with unique constraints
✅ Middleware chain (auth, validation, error handling)
✅ Bakong QR payment integration
```

### **Phase 8-9: Social & Order Features**
```
✅ Orders Management (History + Details page)
✅ Product Reviews (1-5 stars, comments)
✅ Wishlist System (Save for later)
✅ Integrated API methods (9 new endpoints)
✅ App compiles clean (flutter analyze ✅)
```

---

## 📱 FRONTEND - What Users See

| Tab | Feature | Status | Details |
|-----|---------|--------|---------|
| 🏠 Home | Product Grid | ✅ | 2-column grid, search, sort, add to cart |
| 🔍 Search | Filters | ✅ | Category chips, price slider, sort |
| 🛒 Cart | Shopping | ✅ | Checkboxes, quantity controls, swipe delete |
| 📦 Orders | History | ✅ | Order list + details with status badges |
| 👤 Profile | Settings | ✅ | Edit profile, addresses, password, wishlist |

**Additional Pages**: Login, Product Details (with reviews), Write Review, Wishlist

---

## 🔧 BACKEND - What Powers It

| Module | Endpoints | Status | Database |
|--------|-----------|--------|----------|
| Auth | signup, login, refresh | ✅ | User collection |
| User | profile, addresses, password | ✅ | User collection |
| Product | list, get, search | ✅ | Product collection |
| Cart | get, add, remove, update | ✅ | Cart collection |
| Order | create, list, details, status | ✅ | Order collection |
| Review | create, get, delete | ✅ | Review collection |
| Wishlist | add, get, remove, check | ✅ | Wishlist collection |
| Payment | generate QR, verify | ✅ | Payment logs |
| Admin | stats, CRUD products | ✅ | Multiple |

**Total**: 40+ API endpoints

---

## 📊 DATABASE - Data Structure

```
User (email unique)
├── profile (firstName, lastName, phone)
├── addresses[] (label unique per user)
└── tokens (JWT refresh)

Product
├── title (indexed)
├── price, stock
└── category (indexed)

Cart (user unique)
└── items[] → products

Order (user indexed)
├── items[] (product, qty, price)
├── status (PENDING/PAID/SHIPPED/COMPLETED)
└── totalUsd

Review (user+product unique)
├── rating (1-5)
├── title, comment
└── helpful counter

Wishlist (user+product unique)
└── product reference
```

---

## 🚀 TECHNOLOGY STACK

### **Frontend**
- Flutter 3.10.7 | Dart | Material Design 3
- HTTP + Provider + Flutter Secure Storage
- QR code + Google Maps integration

### **Backend**
- Node.js | Express 5.2.1 | MongoDB
- JWT | bcryptjs | Joi validation
- Helmet security | CORS enabled
- Bakong payment SDK

---

## ⚡ HOW IT WORKS (User Journey)

```
1. USER DOWNLOADS APP
   ↓
2. LOGIN/SIGNUP
   ├── Send email + password to /auth/signup
   ├── Backend hashes password (bcryptjs)
   ├── JWT tokens returned (access + refresh)
   ├── Store in secure storage
   ↓
3. BROWSE PRODUCTS
   ├── HomePage loads products via GET /products
   ├── Search/filter via query params
   ├── Click product → ProductDetailsPage
   ↓
4. ADD TO CART
   ├── CartProvider.addToCart(productId)
   ├── POST /cart with JWT token
   ├── UI updates optimistically
   ├── Auto-fetch cart to confirm
   ↓
5. VIEW CART
   ├── Select items (checkbox)
   ├── Adjust quantities
   ├── Tap "Checkout (X items)"
   ↓
6. PLACE ORDER
   ├── Create order from cart items
   ├── POST /orders with address
   ├── Generate Bakong QR code
   ├── Customer pays via QR
   ├── Order status: PAID → SHIPPED → COMPLETED
   ↓
7. WRITE REVIEW
   ├── View product review section
   ├── Tap "Write Review"
   ├── Submit 1-5 stars + comment
   ├── POST /reviews (user+product unique)
   ↓
8. VIEW ORDER HISTORY
   ├── OrdersPage shows all orders
   ├── Status badges for each order
   ├── Tap to see order details
   ↓
9. USE WISHLIST
   ├── Save products via heart button
   ├── View wishlist page
   ├── Move to cart or remove
```

---

## 🎯 KEY FEATURES BY PRIORITY

### **Tier 1: Core (COMPLETE ✅)**
- User auth (JWT)
- Product browsing
- Shopping cart
- Orders
- Reviews & ratings
- Wishlist
- User profile

### **Tier 2: Quality (NOT STARTED ❌)**
- Testing (unit + widget + integration)
- Error handling & validation
- Crash reporting
- Analytics
- Rate limiting
- Request logging

### **Tier 3: Advanced (NOT STARTED ❌)**
- Admin dashboard UI
- Push notifications
- Email confirmations
- Image uploads
- Payment webhooks
- Full-text search
- Product comparison

---

## 🔴 WHAT NEEDS WORK

| Priority | Issue | Effort | Impact |
|----------|-------|--------|--------|
| 🔴 Critical | No unit tests | 3-5 days | Play Store requirement |
| 🔴 Critical | Partial error boundaries | 1 day | App crashes not caught globally |
| 🟠 High | No rate limiting | 1 day | DDoS vulnerability |
| 🟠 High | No crash reporting | 1 day | Can't debug prod issues |
| 🟡 Medium | No admin dashboard | 5 days | Can't manage products |
| 🟡 Medium | No push notifications | 3 days | Users miss important updates |
| 🟢 Low | No animations | 3-4 days | Better UX but not critical |
| 🟢 Low | No dark mode optimization | 2 days | Better visuals |

**Total Effort**: ~18-23 days for Tier 2 (critical items)


## 🛠️ TOOLS NEEDED (Recommendations)

### **Frontend**
```
Testing:       flutter_test, Mockito
HTTP:          Dio (better than http)
Caching:       Hive, cached_network_image
Notifications: Firebase Cloud Messaging
Analytics:     Firebase Analytics
Crashes:       Firebase Crashlytics
```

### **Backend**
```
Testing:       Jest, Supertest
Logging:       Winston
Rate Limit:    express-rate-limit
Validation:    express-validator
Caching:       Redis
Job Queue:     Bull
Monitoring:    Sentry
Documentation: Swagger UI
```

---

## 📈 METRICS & GOALS

### **Development Status**: 🟢 75% Complete
- Feature-complete MVP ✅
- Core functionality working ✅
- Code compiles without errors ✅
- Missing quality assurance ❌

### **Play Store Requirements**
- ✅ Minimum API level (if set)
- ✅ Material Design compliance
- ❌ Test coverage (0%)
- ❌ Crash reporting (missing)
- ❌ Privacy policy linked
- ❌ Age rating filled

---

## 📝 FILES REFERENCE

**Frontend Key Files** (mobile/lib/src/)
- `main.dart` - App shell + routing
- `pages/` - 7 pages (Home, Search, Cart, Orders, Profile, Edit, Addresses)
- `products/` - Product details + reviews
- `providers/cart_provider.dart` - Global state
- `api/authed_api_client.dart` - 40+ API methods
- `auth/` - Login + token management

**Backend Key Files** (backend/src/)
- `app.js` - Express setup + route mounting
- `modules/` - 8 feature modules
- `middlewares/` - Auth, validation, errors
- `config/` - Database, JWT secrets
- `routes/index.js` - Main router

**Configuration Files**
- `mobile/pubspec.yaml` - Frontend dependencies
- `backend/package.json` - Backend dependencies
- `backend/docker-compose.yml` - MongoDB setup
- `.env` - Secrets (not in git)

---

## 🚀 NEXT STEPS (If You Continue)

1. **Week 1**: Add unit tests (models, providers)
2. **Week 2**: Add widget tests (key screens)
3. **Week 3**: Add API tests (backend)
4. **Week 4**: Setup crash reporting + analytics
5. **Week 5**: Add input validation + error handling
6. **Week 6**: Optimize UI/UX
7. **Week 7**: Build admin dashboard
8. **Week 8**: Setup CI/CD pipeline
9. **Week 9**: Performance optimization
10. **Week 10**: Submit to Play Store

**Estimated Timeline**: 10 weeks with 1 developer (full-stack)

---

## 💡 KEY INSIGHTS

1. **State Management**: Using IndexedStack + Provider is perfect for this app
2. **Security**: JWT rotation + secure storage is production-ready
3. **API Design**: RESTful endpoints are well-organized by module
4. **Database**: Unique constraints prevent data corruption
5. **Main Gap**: No automated testing (critical for Play Store)

---

**Created**: April 27, 2026  
**Status**: Ready for quality improvement phase  
**Recommendation**: Start with Tier 1 (testing + error handling) before Play Store submission
