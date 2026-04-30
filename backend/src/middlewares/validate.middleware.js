const validate = (schema) => (req, res, next) => {
  // abortEarly: false makes sure it returns ALL errors at once, not just the first one
  const { error } = schema.validate(req.body, { abortEarly: false });
  
  if (error) {
    const errorMessage = error.details.map((detail) => detail.message).join(', ');
    return res.status(400).json({ 
      success: false, 
      message: errorMessage 
    });
  }
  
  next();
};

module.exports = validate;