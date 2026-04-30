const nodemailer = require('nodemailer');
const logger = require('../config/logger');

// Create a transporter using SMTP transport
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: process.env.SMTP_PORT || 587,
  secure: process.env.SMTP_SECURE === 'true', // true for 465, false for other ports
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

/**
 * Send an email
 */
const sendEmail = async (to, subject, html) => {
  try {
    if (!process.env.SMTP_USER || !process.env.SMTP_PASS || process.env.SMTP_USER === 'your_email@gmail.com') {
      logger.warn('[Email Service] SMTP credentials not fully configured. Skipping email send.');
      return;
    }

    const info = await transporter.sendMail({
      from: `"MT-KINGSS" <${process.env.SMTP_USER}>`,
      to,
      subject,
      html,
    });

    logger.info(`[Email Service] Email sent: ${info.messageId}`);
  } catch (error) {
    logger.error(`[Email Service] Error sending email to ${to}: ${error.message}`);
  }
};

/**
 * Send order receipt or confirmation
 */
const sendOrderReceipt = async (user, order) => {
  const isPaid = order.status === 'PAID';
  const subject = isPaid 
    ? `Payment Receipt for MT-KINGSS Order (#${order._id})` 
    : `Order Confirmation from MT-KINGSS (#${order._id})`;
    
  const statusMessage = isPaid
    ? 'We have successfully received your payment. We are now preparing your order for shipment!'
    : 'We have received your order. If you chose Cash on Delivery, we will process it shortly. If paying via Bakong, it will be prepared once payment is confirmed.';

  const itemsHtml = order.items.map(item => `
    <tr>
      <td style="padding: 10px; border-bottom: 1px solid #eee;">${item.title}</td>
      <td style="padding: 10px; text-align: center; border-bottom: 1px solid #eee;">${item.quantity}</td>
      <td style="padding: 10px; text-align: right; border-bottom: 1px solid #eee;">$${(item.priceUsd * item.quantity).toFixed(2)}</td>
    </tr>
  `).join('');

  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; color: #333;">
      <h2 style="color: #5e35b1;">Thank you for your order!</h2>
      <p>Hi ${user.firstName || 'Customer'},</p>
      <p>${statusMessage}</p>
      <table style="width: 100%; border-collapse: collapse; margin-top: 20px;">
        ${itemsHtml}
      </table>
      <h3 style="text-align: right; margin-top: 20px;">Total: $${order.totalUsd.toFixed(2)}</h3>
    </div>
  `;

  await sendEmail(user.email, subject, html);
};

module.exports = { sendEmail, sendOrderReceipt };
