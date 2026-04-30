const Joi = require('joi');

const createProductSchema = Joi.object({
  title: Joi.string().min(3).max(255).required(),
  description: Joi.string().min(10).required(),
  priceUsd: Joi.number().positive().precision(2).required(),
  stock: Joi.number().integer().min(0).required(),
  category: Joi.string().required(),
  imageUrl: Joi.string().uri().optional().allow(''), // Allow empty string for optional image
});

const updateProductSchema = Joi.object({
  title: Joi.string().min(3).max(255).optional(),
  description: Joi.string().min(10).optional(),
  priceUsd: Joi.number().positive().precision(2).optional(),
  stock: Joi.number().integer().min(0).optional(),
  category: Joi.string().optional(),
  imageUrl: Joi.string().uri().optional().allow(''),
});

module.exports = {
  createProductSchema,
  updateProductSchema,
};