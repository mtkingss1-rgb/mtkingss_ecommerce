const Joi = require('joi');

const productSchema = Joi.object({
  title: Joi.string().required(),
  description: Joi.string().allow('', null),
  imageUrl: Joi.string().uri().allow('', null),
  category: Joi.string().required(),
  priceUsd: Joi.number().positive().required(),
  stock: Joi.number().integer().min(0).required()
});

// --> ADDED: Strict enforcement for order statuses
const updateOrderStatusSchema = Joi.object({
  status: Joi.string()
    .valid('PENDING', 'PAID', 'SHIPPED', 'COMPLETED', 'CANCELLED')
    .required()
});

module.exports = { 
  productSchema,
  updateOrderStatusSchema
};