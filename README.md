# 🛒 MT-KINGSS E-Commerce Platform

A full-stack e-commerce mobile application built with **Flutter** and **Node.js**. This project features a complete shopping flow, including product discovery, cart management, order processing, and user authentication.

## 📱 Tech Stack

*   **Frontend**: Flutter (Dart) with Provider for state management.
*   **Backend**: Node.js, Express.js.
*   **Database**: MongoDB (Mongoose).
*   **Security**: JWT Authentication, bcryptjs, Helmet, Express Rate Limit.

## ✨ Key Features

*   **Authentication**: JWT-based login/signup with automatic token refresh.
*   **Shopping Cart**: Add, update, and remove items with optimistic UI updates.
*   **Order Management**: Place orders with shipping addresses and view order history.
*   **Product Reviews**: Users can rate and review products.
*   **Wishlist**: Save favorite products for later.
*   **State Preservation**: 5-tab bottom navigation using `IndexedStack` to keep page states alive.

---

## 🚀 How to Run the Project

### 1. Backend Setup

Navigate to the backend directory:
```bash
cd backend
```

Install dependencies:
```bash
npm install
```

Set up your environment variables:
*   Duplicate the `backend/.env.example` file and rename it to `.env`.
*   Update the `MONGO_URI` with your own local or Atlas MongoDB connection string.

Start the server:
```bash
npm run dev
```
*The server will start on `http://localhost:3000` and automatically seed the database with sample products.*

### 2. Frontend (Mobile) Setup

Open a new terminal window and navigate to the mobile directory:
```bash
cd mobile
```

Run the app:
```bash
flutter run
```