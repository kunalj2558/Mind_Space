const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const Patient = require('../models/Patient');
const Doctor = require('../models/Doctor');
const ProfessionalProfile = require('../models/ProfessionalProfile');
const Wallet = require('../models/Wallet');
const generateUniqueCode = require('../utils/generateCode');

// Register
router.post('/register', [
  body('name').notEmpty().withMessage('Name is required'),
  body('email').isEmail().withMessage('Valid email is required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('role').isIn(['patient', 'doctor']).withMessage('Role must be patient or doctor'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ message: errors.array()[0].msg });
    }

    const { name, email, password, phone, role, dob, bloodGroup, emergencyContact,
            specialization, licenseNumber, hospital } = req.body;

    // Check existing user
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Generate unique code
    const uniqueCode = await generateUniqueCode();

    // Create user
    const user = new User({
      name, email, password: hashedPassword, phone, role, uniqueCode,
    });
    await user.save();

    // Create role-specific profile
    if (role === 'patient') {
      const patient = new Patient({
        userId: user._id, dob, bloodGroup, emergencyContact,
      });
      await patient.save();
    } else {
      const doctor = new Doctor({
        userId: user._id, specialization, licenseNumber, hospital,
      });
      await doctor.save();

      // Automatically sync doctor into Clinician Marketplace
      const cleanSpecialty = specialization || 'Psychiatry & Wellbeing';
      await ProfessionalProfile.create({
        userId: user._id,
        publicName: user.name,
        title: cleanSpecialty.includes('Psychiat') ? 'Psychiatrist' : 'Clinical Psychologist',
        specialty: cleanSpecialty,
        registrationNumber: licenseNumber || `REG-${Math.floor(100000 + Math.random() * 900000)}`,
        hospitalAffiliation: hospital || 'MindSpace Wellbeing Network',
        verificationStatus: 'verified',
        consultationModes: ['chat', 'voice', 'video'],
        rates: {
          currency: 'INR',
          ratePerMinute: 20,
          ratePerMinuteVideo: 25,
          ratePerMinuteVoice: 18,
          ratePerMinuteChat: 10,
          session15Min: 300,
          session30Min: 550,
          session60Min: 999,
        },
        isAvailableNow: true,
      });
    }

    // Automatically initialize in-app digital wallet
    await Wallet.create({
      userId: user._id,
      balance: role === 'patient' ? 500 : 0, // ₹500 welcome promo credit for testing
      currency: 'INR',
      transactions: role === 'patient' ? [
        {
          txId: `TX_${Date.now()}`,
          type: 'topup',
          amount: 500,
          description: 'MindSpace Welcome Health Credit',
          paymentMethod: 'Promo Credit',
        }
      ] : [],
    });

    // Generate JWT (30-day expiry)
    const token = jwt.sign(
      { id: user._id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.status(201).json({
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        uniqueCode: user.uniqueCode,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Login
router.post('/login', [
  body('email').isEmail().withMessage('Valid email is required'),
  body('password').notEmpty().withMessage('Password is required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ message: errors.array()[0].msg });
    }

    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { id: user._id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        uniqueCode: user.uniqueCode,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
