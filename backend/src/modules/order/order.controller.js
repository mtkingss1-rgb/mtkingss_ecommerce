const mongoose = require('mongoose');
const Order = require('./order.model');
const Cart = require('../cart/cart.model');
const Product = require('../product/product.model'); // ✅ Required to deduct stock
const User = require('../user/user.model'); 
const emailService = require('../../services/email.service');

exports.checkoutCreateOrder = async (req, res, next) => {
  try {
    let order;
    let customer;

    const userId = req.user._id || req.user.id;
    const { addressId, paymentMethod } = req.body || {};

    if (!addressId) {
      throw new Error('Address ID is required to create an order.');
    }

    const cart = await Cart.findOne({ user: userId }).populate('items.product');

    if (!cart || cart.items.length === 0) {
      throw new Error('Cart is empty');
    }
    
    // Verify and embed the shipping address
    const user = await User.findById(userId);
    const shippingAddress = user?.addresses?.id(addressId);
    if (!shippingAddress) {
      throw new Error('Shipping address not found');
    }
    customer = user;

    for (const item of cart.items) {
      const lockedProduct = await Product.findOneAndUpdate(
        { _id: item.product._id, stock: { $gte: item.quantity } },
        { $inc: { stock: -item.quantity } },
        { new: true }
      );

      if (!lockedProduct) {
        throw new Error(`Checkout failed. '${item.product.title}' is out of stock or does not have enough quantity.`);
      }
    }

    const orderItems = cart.items.map((item) => ({
      product: item.product._id,
      title: item.product.title,
      priceUsd: item.product.priceUsd,
      quantity: item.quantity,
    }));

    const totalUsd = orderItems.reduce(
      (sum, i) => sum + i.priceUsd * i.quantity,
      0
    );

    const createdOrders = await Order.create(
      [
        {
          user: userId,
          items: orderItems,
          totalUsd: Number(totalUsd.toFixed(2)),
          currency: 'USD',
          status: 'PENDING',
          paymentMethod: paymentMethod || 'CASH_ON_DELIVERY',
          address: shippingAddress.toObject(),
        },
      ]
    );

    order = createdOrders[0];

    cart.items = [];
    cart.total = 0;
    await cart.save();

    // Send order confirmation email asynchronously
    if (customer && customer.email) {
      emailService.sendOrderReceipt(customer, order).catch(err => console.error(`[Email Error] ${err.message}`));
    }

    // If the transaction was successful, send the response
    res.status(201).json({
      success: true,
      order,
    });
  } catch (err) {
    next(err);
  }
};

exports.getMyOrders = async (req, res, next) => {
  try {
    const userId = req.user._id || req.user.id;
    const orders = await Order.find({ user: userId }).sort({ createdAt: -1 });
    
    res.json({ 
      success: true, 
      orders 
    });
  } catch (err) {
    next(err);
  }
};

exports.getAllOrders = async (req, res, next) => {
  try {
    const orders = await Order.find()
      .populate('user', 'email role')
      .sort({ createdAt: -1 });
      
    res.json({ 
      success: true, 
      orders 
    });
  } catch (err) {
    next(err);
  }
};

exports.updateOrderStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    const order = await Order.findById(req.params.id);
    
    if (!order) {
      return res.status(404).json({ 
        success: false, 
        message: 'Order not found' 
      });
    }

    order.status = status;
    await order.save();

    res.json({ 
      success: true, 
      order 
    });
  } catch (err) {
    next(err);
  }
};