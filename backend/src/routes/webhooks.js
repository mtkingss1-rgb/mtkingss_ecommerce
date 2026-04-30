const express = require('express');
const router = express.Router();
const paymentWebhook = require('../modules/payment/payment.webhook');

/**
 * @swagger
 * tags:
 *   name: Webhooks
 *   description: External service webhooks (e.g., Bakong Payment)
 */

/**
 * @swagger
 * /webhooks/bakong:
 *   post:
 *     summary: Bakong Payment Callback
 *     tags: [Webhooks]
 *     security: []
 *     responses:
 *       200:
 *         description: Webhook received successfully
 */
router.post('/bakong', paymentWebhook.bakongWebhook);

module.exports = router;