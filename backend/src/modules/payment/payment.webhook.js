const Order = require('../order/order.model');
const logger = require('../../config/logger');
const emailService = require('../../services/email.service');

exports.bakongWebhook = async (req, res) => {
  try {
    const payload = req.body;
    logger.info(`[WEBHOOK] Received Bakong payment update:`, payload);

    // 1. Verify the signature/hash from Bakong
    // Typically Bakong sends a hash of the transaction data to verify it's authentic.
    // const isValid = verifyBakongSignature(payload);
    // if (!isValid) return res.status(400).send('Invalid signature');

    // 2. Extract transaction details
    // The exact field names depend on your Bakong merchant configuration.
    // Usually, the order ID is passed in the "bill_to", "store_label", or "qr_ref" field during QR generation.
    const orderId = payload.bill_to || payload.order_id || payload.qr_ref;
    const transactionStatus = payload.status; // typically 0 or "SUCCESS" for a successful transaction
    const transactionId = payload.hash || payload.tran_id;

    if (!orderId) {
      logger.warn('[WEBHOOK] Missing order ID in payload');
      return res.status(400).json({ success: false, message: 'Missing order ID' });
    }

    // 3. Find the order
    const order = await Order.findById(orderId).populate('user');
    if (!order) {
      logger.warn(`[WEBHOOK] Order not found: ${orderId}`);
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    // 4. Check if already processed to avoid duplicate processing
    if (['PAID', 'SHIPPED', 'COMPLETED'].includes(order.status)) {
      logger.info(`[WEBHOOK] Order ${orderId} already marked as ${order.status}`);
      return res.status(200).json({ success: true, message: 'Already processed' });
    }

    // 5. Update order status if payment is successful
    if (transactionStatus === 0 || transactionStatus === '0' || transactionStatus === 'SUCCESS') {
      order.status = 'PAID';
      // If your Order schema supports it, you can also log: order.transactionId = transactionId;
      await order.save();
      logger.info(`[WEBHOOK] Order ${orderId} successfully updated to PAID!`);
      
      // Fire off the receipt email
      if (order.user && order.user.email) {
        emailService.sendOrderReceipt(order.user, order).catch(err => logger.error(`[WEBHOOK] Email error: ${err.message}`));
      }
    } else {
      logger.warn(`[WEBHOOK] Payment failed or pending for order ${orderId}. Status: ${transactionStatus}`);
    }

    // Always return 200 OK so Bakong knows we successfully received and handled it
    res.status(200).json({ success: true });
  } catch (error) {
    logger.error(`[WEBHOOK] Error processing Bakong callback: ${error.message}`);
    res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};