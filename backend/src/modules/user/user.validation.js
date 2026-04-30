const Joi = require('joi');

const changePasswordSchema = Joi.object({
  currentPassword: Joi.string().required(),
  newPassword: Joi.string().min(6).required(),
});

const updateProfileSchema = Joi.object({
  firstName: Joi.string().allow('').optional(),
  lastName: Joi.string().allow('').optional(),
  phone: Joi.string().allow('').optional(),
});

const addAddressSchema = Joi.object({
  label: Joi.string().required(),
  street: Joi.string().required(),
  city: Joi.string().required(),
  state: Joi.string().required(),
  zipCode: Joi.string().required(),
  country: Joi.string().default('Cambodia'),
  isDefault: Joi.boolean().default(false),
});

const updateAddressSchema = Joi.object({
  label: Joi.string().optional(),
  street: Joi.string().optional(),
  city: Joi.string().optional(),
  state: Joi.string().optional(),
  zipCode: Joi.string().optional(),
  country: Joi.string().optional(),
  isDefault: Joi.boolean().optional(),
});

module.exports = {
  changePasswordSchema,
  updateProfileSchema,
  addAddressSchema,
  updateAddressSchema,
};