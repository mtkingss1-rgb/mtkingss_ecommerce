const Order = require('../order/order.model');
const { BakongKHQR } = require('bakong-khqr');
const axios = require('axios');
const emailService = require('../../services/email.service');

exports.generateCheckoutQR = async (req, res, next) => {
  try {
    const { orderId } = req.params;
    const order = await Order.findById(orderId);

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    const lib = new BakongKHQR();

    const individualInfo = {
      bakongAccountID: process.env.BAKONG_ACCOUNT_ID,
      merchantName: "SOKING OEUN", 
      merchantCity: "Phnom Penh",
      amount: order.totalUsd,
      currency: 840, // USD
      storeLabel: "MT-KINGSS",
      terminalLabel: "MobileApp",
      billNumber: "Order_" + orderId.substring(orderId.length - 4),
      merchantType: "DYNAMIC",
      expirationTimestamp: Date.now() + (15 * 60 * 1000) 
    };

    const khqrResponse = lib.generateIndividual(individualInfo);

    if (!khqrResponse || khqrResponse.status.code !== 0) {
      return res.status(500).json({ 
        success: false, 
        message: khqrResponse?.status?.message || "Bakong KHQR Generation Failed" 
      });
    }

    // Store the MD5 immediately so we have a reference to check against
    await Order.findByIdAndUpdate(
      orderId, 
      { $set: { bakongMd5: khqrResponse.data.md5 } }, 
      { strict: false } 
    );

    res.status(200).json({ 
      success: true, 
      qrString: khqrResponse.data.qr, 
      totalUsd: order.totalUsd 
    });

  } catch (error) {
    console.error("[Payment Error] Generate QR:", error.message);
    next(error);
  }
};

exports.verifyPayment = async (req, res, next) => {
  try {
    const { orderId } = req.params;
    
    // 1. Get the current order
    const orderData = await Order.findById(orderId).populate('user').lean();

    if (!orderData) return res.status(404).json({ success: false, message: "Order not found" });
    
    // 2. If already paid, stop immediately (Idempotency)
    if (orderData.status === 'PAID') {
      return res.status(200).json({ success: true, status: 'PAID' });
    }

    const md5Hash = orderData.bakongMd5;
    if (!md5Hash) {
      return res.status(200).json({ success: false, status: 'PENDING', message: 'No MD5 hash found' });
    }

    // 3. Ask Bakong for the "Source of Truth"
    const bakongUrl = "https://api.bakong.nbc.gov.kh/v1/check_transaction_by_md5"; 
    
    try {
      const response = await axios.post(bakongUrl, {
        md5: md5Hash
      }, {
        headers: {
          'Authorization': `Bearer ${process.env.BAKONG_API_KEY}`,
          'Content-Type': 'application/json'
        }
      });

      // 4. ATOMIC UPDATE: Only update if status is still PENDING
      // This prevents "Double Processing" if two requests hit at once.
      if (response.data && response.data.responseCode === 0) {
        const updatedOrder = await Order.findOneAndUpdate(
          { _id: orderId, status: 'PENDING' }, 
          { $set: { status: 'PAID', paidAt: new Date() } },
          { new: true } // Returns the updated document
        );

        if (updatedOrder) {
          console.log(`[Payment Success] Order ${orderId} marked as PAID`);
          
          // Fire off the receipt email
          if (orderData.user && orderData.user.email) {
            emailService.sendOrderReceipt(orderData.user, updatedOrder).catch(err => console.error(`[Email Error] ${err.message}`));
          }
          return res.status(200).json({ success: true, status: 'PAID' });
        }
      }
    } catch (apiErr) {
      // 5. DEFENSIVE LOGGING: Don't let errors pass silently
      console.error(`[Bakong API Error] Order ${orderId}:`, apiErr.response?.data || apiErr.message);
    }

    // Default response if not paid yet or API check failed
    res.status(200).json({ success: false, status: 'PENDING' });

  } catch (error) {
    console.error("[Payment Error] Verify Payment:", error.message);
    next(error);
  }
};