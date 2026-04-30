const User = require('./user.model');
const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');

async function me(req, res, next) {
  try {
    const user = await User.findById(req.auth.userId).lean();
    if (!user) return res.status(404).json({ message: 'User not found' });

    res.json({
      user: {
        id: user._id.toString(),
        email: user.email,
        firstName: user.firstName || '',
        lastName: user.lastName || '',
        phone: user.phone || '',
        role: user.role,
        addresses: (user.addresses || []).map((addr) => ({
          id: addr._id.toString(),
          label: addr.label,
          street: addr.street,
          city: addr.city,
          state: addr.state,
          zipCode: addr.zipCode,
          country: addr.country,
          isDefault: addr.isDefault,
        })),
      },
    });
  } catch (err) {
    next(err);
  }
}

async function updateProfile(req, res, next) {
  try {
    const { firstName, lastName, phone } = req.body;
    const user = await User.findByIdAndUpdate(
      req.auth.userId,
      {
        firstName: firstName || '',
        lastName: lastName || '',
        phone: phone || '',
      },
      { new: true }
    ).lean();

    if (!user) return res.status(404).json({ message: 'User not found' });

    res.json({
      message: 'Profile updated successfully',
      user: {
        id: user._id.toString(),
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        phone: user.phone,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function changePassword(req, res, next) {
  try {
    const { currentPassword, newPassword } = req.body;

    const user = await User.findById(req.auth.userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const isValid = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!isValid) {
      return res.status(401).json({ message: 'Current password is incorrect' });
    }

    const newHash = await bcrypt.hash(newPassword, 12);
    user.passwordHash = newHash;
    await user.save();

    res.json({ message: 'Password changed successfully' });
  } catch (err) {
    next(err);
  }
}

async function addAddress(req, res, next) {
  try {
    const { label, street, city, state, zipCode, country, isDefault } = req.body;
    const user = await User.findById(req.auth.userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const newAddress = {
      _id: new mongoose.Types.ObjectId(),
      label,
      street,
      city,
      state,
      zipCode,
      country: country || 'Cambodia',
      isDefault: isDefault || false,
    };

    if (isDefault) {
      user.addresses.forEach((addr) => (addr.isDefault = false));
    }

    user.addresses.push(newAddress);
    await user.save();

    res.status(201).json({
      message: 'Address added successfully',
      address: {
        id: newAddress._id.toString(),
        ...newAddress,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function getAddresses(req, res, next) {
  try {
    const user = await User.findById(req.auth.userId).lean();
    if (!user) return res.status(404).json({ message: 'User not found' });

    res.json({
      addresses: (user.addresses || []).map((addr) => ({
        id: addr._id.toString(),
        label: addr.label,
        street: addr.street,
        city: addr.city,
        state: addr.state,
        zipCode: addr.zipCode,
        country: addr.country,
        isDefault: addr.isDefault,
      })),
    });
  } catch (err) {
    next(err);
  }
}

async function updateAddress(req, res, next) {
  try {
    const { id } = req.params;
    const { label, street, city, state, zipCode, country, isDefault } = req.body;

    const user = await User.findById(req.auth.userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const address = user.addresses.find((a) => a._id.toString() === id);
    if (!address) return res.status(404).json({ message: 'Address not found' });

    if (label) address.label = label;
    if (street) address.street = street;
    if (city) address.city = city;
    if (state) address.state = state;
    if (zipCode) address.zipCode = zipCode;
    if (country) address.country = country;
    if (isDefault) {
      user.addresses.forEach((a) => (a.isDefault = false));
      address.isDefault = true;
    }

    await user.save();

    res.json({
      message: 'Address updated successfully',
      address: {
        id: address._id.toString(),
        label: address.label,
        street: address.street,
        city: address.city,
        state: address.state,
        zipCode: address.zipCode,
        country: address.country,
        isDefault: address.isDefault,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function deleteAddress(req, res, next) {
  try {
    const { id } = req.params;

    const user = await User.findById(req.auth.userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const addressIndex = user.addresses.findIndex((a) => a._id.toString() === id);
    if (addressIndex === -1) {
      return res.status(404).json({ message: 'Address not found' });
    }

    user.addresses.splice(addressIndex, 1);
    await user.save();

    res.json({ message: 'Address deleted successfully' });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  me,
  updateProfile,
  changePassword,
  addAddress,
  getAddresses,
  updateAddress,
  deleteAddress,
};