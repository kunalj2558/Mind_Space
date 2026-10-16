const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const auth = require('../middleware/auth');
const User = require('../models/User');
const Specialty = require('../models/Specialty');
const ProfessionalProfile = require('../models/ProfessionalProfile');
const Appointment = require('../models/Appointment');
const PaymentOrder = require('../models/PaymentOrder');
const ClinicianMessage = require('../models/ClinicianMessage');
const SafetyReport = require('../models/SafetyReport');
const Wallet = require('../models/Wallet');

// ── Default Seed Data for Marketplace & Specialties ──────────────────────────
const DEFAULT_SPECIALTIES = [
  {
    key: 'psychiatrist',
    name: 'Psychiatrist',
    category: 'medical',
    description: 'Medical doctors specializing in diagnosis, treatment, and medication management for psychiatric conditions.',
    scopeOfPractice: 'Medical assessment, psychotherapy, medication management',
    badgeColor: '#4F46E5',
    icon: 'medical_services',
  },
  {
    key: 'clinical_psychologist',
    name: 'Clinical Psychologist',
    category: 'psychotherapy',
    description: 'Specialists trained in psychometric assessment, cognitive behavioural therapy (CBT), and trauma therapy.',
    scopeOfPractice: 'Evidence-based psychotherapy, psychological assessment (No medication prescribing)',
    badgeColor: '#059669',
    icon: 'psychology',
  },
  {
    key: 'counsellor',
    name: 'Counsellor & Therapist',
    category: 'counselling',
    description: 'Empathetic professionals supporting stress, grief, anxiety, relationship distress, and personal growth.',
    scopeOfPractice: 'Talk therapy, emotional regulation, lifestyle guidance',
    badgeColor: '#D97706',
    icon: 'spa',
  },
  {
    key: 'physiotherapist',
    name: 'Physiotherapist',
    category: 'rehabilitation',
    description: 'Rehabilitation experts targeting stress-induced somatic tension, posture alignment, and chronic body ache.',
    scopeOfPractice: 'Physical rehabilitation, posture correction, somatic stress relief (Not mental health treatment)',
    badgeColor: '#2563EB',
    icon: 'fitness_center',
  },
];

// Seed specialties on launch if empty (Real doctors register dynamically)
async function ensureSeedData() {
  try {
    const count = await Specialty.countDocuments();
    if (count === 0) {
      await Specialty.insertMany(DEFAULT_SPECIALTIES);
    }
  } catch (err) {
    console.warn('V2 ensureSeedData notice:', err.message);
  }
}

// Call on module load
ensureSeedData();

// ── 1. Specialties Taxonomy ──────────────────────────────────────────────────
router.get('/specialties', async (req, res) => {
  try {
    const specialties = await Specialty.find({ active: true });
    res.json({ specialties });
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch specialties' });
  }
});

// ── 2. Clinician Discovery & Marketplace ─────────────────────────────────────
router.get('/professionals', async (req, res) => {
  try {
    const { specialty, language, mode, query, availableNow } = req.query;
    const filter = { verificationStatus: 'verified' };

    if (specialty) {
      filter.specialty = { $regex: new RegExp(specialty, 'i') };
    }
    if (language) {
      filter.languages = { $in: [new RegExp(language, 'i')] };
    }
    if (mode) {
      filter.consultationModes = mode;
    }
    if (availableNow === 'true') {
      filter.isAvailableNow = true;
    }
    if (query) {
      filter.$or = [
        { publicName: { $regex: query, $options: 'i' } },
        { bio: { $regex: query, $options: 'i' } },
        { specialty: { $regex: query, $options: 'i' } },
      ];
    }

    const professionals = await ProfessionalProfile.find(filter)
      .sort({ rating: -1, reviewCount: -1 });

    res.json({ professionals });
  } catch (err) {
    res.status(500).json({ message: 'Error retrieving professionals', error: err.message });
  }
});

// Single Clinician Profile
router.get('/professionals/:id', async (req, res) => {
  try {
    const professional = await ProfessionalProfile.findById(req.params.id)
      .populate('userId', 'name email uniqueCode');
    if (!professional) {
      return res.status(404).json({ message: 'Professional profile not found' });
    }
    res.json({ professional });
  } catch (err) {
    res.status(500).json({ message: 'Error fetching profile' });
  }
});

// Clinician Availability
router.get('/professionals/:id/availability', async (req, res) => {
  try {
    const professional = await ProfessionalProfile.findById(req.params.id);
    if (!professional) {
      return res.status(404).json({ message: 'Professional not found' });
    }

    // Generate upcoming available calendar slots for the next 7 days
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const slots = [];
    const now = new Date();

    for (let i = 0; i < 7; i++) {
      const date = new Date(now);
      date.setDate(now.getDate() + i);
      const dayName = days[date.getDay()];
      
      const daySlots = [
        '10:00 AM', '11:30 AM', '02:00 PM', '04:00 PM', '06:30 PM'
      ];

      for (const timeStr of daySlots) {
        slots.push({
          date: date.toISOString().split('T')[0],
          dayName,
          time: timeStr,
          available: true,
        });
      }
    }

    res.json({
      professionalId: professional._id,
      name: professional.publicName,
      rates: professional.rates,
      slots,
    });
  } catch (err) {
    res.status(500).json({ message: 'Error generating availability slots' });
  }
});

// ── 3. Appointments & Scheduling ─────────────────────────────────────────────

// Create/Book an Appointment
router.post('/appointments', auth, async (req, res) => {
  try {
    const {
      professionalProfileId,
      mode,
      durationMinutes,
      scheduledAt,
      serviceType,
      shareSummaryConsent,
    } = req.body;

    const professional = await ProfessionalProfile.findById(professionalProfileId);
    if (!professional) {
      return res.status(404).json({ message: 'Clinician profile not found' });
    }

    const duration = durationMinutes || 30;
    let sessionFee = professional.rates.session30Min;
    if (duration === 15) sessionFee = professional.rates.session15Min;
    if (duration === 60) sessionFee = professional.rates.session60Min;
    
    const platformFee = 50; // Transparent MindSpace platform fee
    const totalAmount = sessionFee + platformFee;

    const appointment = new Appointment({
      patientId: req.user.id,
      professionalId: professional.userId,
      professionalProfileId: professional._id,
      serviceType: serviceType || `${professional.specialty} Consultation`,
      mode: mode || 'video',
      scheduledAt: new Date(scheduledAt || Date.now() + 3600000), // Default 1 hr from now
      durationMinutes: duration,
      status: 'scheduled',
      rateSnapshot: {
        currency: professional.rates.currency || 'INR',
        ratePerMinute: professional.rates.ratePerMinute || 20,
        sessionFee,
        platformFee,
        taxes: 0,
        totalAmount,
        cancellationPolicy: 'Free cancellation up to 2 hours before session start time.',
      },
      patientConsent: {
        emergencyAcknowledged: true,
        privacyConsented: true,
        shareSummaryConsented: !!shareSummaryConsent,
        consentedAt: new Date(),
      },
      providerRoomId: `mindspace_room_${crypto.randomBytes(6).toString('hex')}`,
    });

    await appointment.save();

    // Create a matching payment order in sandbox mode
    const orderId = `ORD_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
    const paymentOrder = new PaymentOrder({
      orderId,
      userId: req.user.id,
      appointmentId: appointment._id,
      amount: totalAmount,
      currency: 'INR',
      breakdown: { sessionFee, platformFee, taxes: 0 },
      status: 'paid', // Auto-cleared in sandbox demo environment
      gateway: 'sandbox_payment',
      paidAt: new Date(),
    });
    await paymentOrder.save();

    appointment.paymentOrderId = paymentOrder._id;
    appointment.paymentStatus = 'captured';
    appointment.status = 'requested'; // Waiting for doctor confirmation
    await appointment.save();

    res.status(201).json({
      message: 'Consultation request sent to doctor. Waiting for acceptance.',
      appointment,
      paymentOrder,
    });
  } catch (err) {
    console.error('Book appointment error:', err);
    res.status(500).json({ message: 'Error scheduling appointment', error: err.message });
  }
});

// List User Appointments (Patient or Doctor)
router.get('/appointments', auth, async (req, res) => {
  try {
    const filter = req.user.role === 'doctor'
      ? { professionalId: req.user.id }
      : { patientId: req.user.id };

    const appointments = await Appointment.find(filter)
      .populate('patientId', 'name email phone uniqueCode')
      .populate('professionalProfileId')
      .sort({ scheduledAt: -1 });

    res.json({ appointments });
  } catch (err) {
    res.status(500).json({ message: 'Error fetching appointments' });
  }
});

// Single Appointment Details
router.get('/appointments/:id', auth, async (req, res) => {
  try {
    const appointment = await Appointment.findById(req.params.id)
      .populate('patientId', 'name email phone uniqueCode')
      .populate('professionalProfileId');

    if (!appointment) {
      return res.status(404).json({ message: 'Appointment not found' });
    }

    // Verify authorized participant
    const isPatient = appointment.patientId._id.toString() === req.user.id;
    const isDoctor = appointment.professionalId.toString() === req.user.id;
    if (!isPatient && !isDoctor) {
      return res.status(403).json({ message: 'Unauthorized for this appointment' });
    }

    res.json({ appointment });
  } catch (err) {
    res.status(500).json({ message: 'Error fetching appointment details' });
  }
});

// Confirm/Complete Appointment
router.post('/appointments/:id/confirm', auth, async (req, res) => {
  try {
    const appointment = await Appointment.findById(req.params.id);
    if (!appointment) return res.status(404).json({ message: 'Appointment not found' });
    
    appointment.status = 'completed';
    await appointment.save();
    res.json({ message: 'Appointment confirmed/completed', appointment });
  } catch (err) {
    res.status(500).json({ message: 'Error updating appointment status' });
  }
});

// Cancel Appointment
router.post('/appointments/:id/cancel', auth, async (req, res) => {
  try {
    const appointment = await Appointment.findById(req.params.id);
    if (!appointment) return res.status(404).json({ message: 'Appointment not found' });

    appointment.status = 'cancelled';
    if (appointment.paymentOrderId) {
      await PaymentOrder.findByIdAndUpdate(appointment.paymentOrderId, { status: 'refunded' });
      appointment.paymentStatus = 'refunded';
    }
    await appointment.save();
    res.json({ message: 'Appointment cancelled and payment marked for refund', appointment });
  } catch (err) {
    res.status(500).json({ message: 'Error cancelling appointment' });
  }
});

// Accept Consultation Request (Doctor only)
router.post('/appointments/:id/accept', auth, async (req, res) => {
  try {
    const appointment = await Appointment.findById(req.params.id);
    if (!appointment) return res.status(404).json({ message: 'Appointment not found' });
    
    if (appointment.professionalId.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Only the assigned clinician can accept this request' });
    }

    appointment.status = 'confirmed';
    await appointment.save();
    res.json({ message: 'Consultation request accepted by doctor', appointment });
  } catch (err) {
    res.status(500).json({ message: 'Error accepting consultation' });
  }
});

// Reject/Decline Consultation Request (Doctor only)
router.post('/appointments/:id/reject', auth, async (req, res) => {
  try {
    const appointment = await Appointment.findById(req.params.id);
    if (!appointment) return res.status(404).json({ message: 'Appointment not found' });

    if (appointment.professionalId.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Unauthorized' });
    }

    appointment.status = 'cancelled';
    if (appointment.paymentOrderId) {
      await PaymentOrder.findByIdAndUpdate(appointment.paymentOrderId, { status: 'refunded' });
      appointment.paymentStatus = 'refunded';
    }
    await appointment.save();
    res.json({ message: 'Consultation request declined', appointment });
  } catch (err) {
    res.status(500).json({ message: 'Error declining consultation' });
  }
});

// Get Logged-in Doctor's Professional Profile & Rates
router.get('/doctor/profile', auth, async (req, res) => {
  try {
    let profile = await ProfessionalProfile.findOne({ userId: req.user.id });
    if (!profile) {
      const user = await User.findById(req.user.id);
      profile = await ProfessionalProfile.create({
        userId: user._id,
        publicName: user.name,
        title: 'Psychiatrist',
        specialty: 'Psychiatry & Wellbeing',
        registrationNumber: 'REG-' + Math.floor(100000 + Math.random() * 900000),
        consultationModes: ['chat', 'voice', 'video'],
        rates: {
          currency: 'INR',
          ratePerMinute: 25,
          session15Min: 350,
          session30Min: 650,
          session60Min: 1200,
        },
        isAvailableNow: true,
      });
    }
    res.json({ profile });
  } catch (err) {
    res.status(500).json({ message: 'Error fetching doctor profile', error: err.message });
  }
});

// Update Logged-in Doctor's Rates, Modes and Availability
router.put('/doctor/profile', auth, async (req, res) => {
  try {
    const { rates, consultationModes, isAvailableNow, bio, title, specialty } = req.body;
    let profile = await ProfessionalProfile.findOne({ userId: req.user.id });
    if (!profile) {
      return res.status(404).json({ message: 'Doctor profile not found' });
    }

    if (rates) {
      profile.rates = {
        currency: rates.currency || profile.rates.currency || 'INR',
        ratePerMinute: Number(rates.ratePerMinute) || profile.rates.ratePerMinute,
        session15Min: Number(rates.session15Min) || profile.rates.session15Min,
        session30Min: Number(rates.session30Min) || profile.rates.session30Min,
        session60Min: Number(rates.session60Min) || profile.rates.session60Min,
      };
    }
    if (consultationModes && Array.isArray(consultationModes)) {
      profile.consultationModes = consultationModes;
    }
    if (typeof isAvailableNow === 'boolean') {
      profile.isAvailableNow = isAvailableNow;
    }
    if (bio !== undefined) profile.bio = bio;
    if (title !== undefined) profile.title = title;
    if (specialty !== undefined) profile.specialty = specialty;

    await profile.save();
    res.json({ message: 'Rates and consultation settings updated successfully', profile });
  } catch (err) {
    res.status(500).json({ message: 'Error updating doctor profile', error: err.message });
  }
});

// ── 4. Consultation Room & Server-Authoritative Timer ────────────────────────

// Generate secure room token
router.post('/appointments/:id/call-token', auth, async (req, res) => {
  try {
    const appointment = await Appointment.findById(req.params.id)
      .populate('professionalProfileId');
    if (!appointment) return res.status(404).json({ message: 'Appointment not found' });

    // Generate token
    const token = crypto.randomBytes(24).toString('hex');
    const roomId = appointment.providerRoomId || `room_${appointment._id}`;

    res.json({
      roomId,
      token,
      mode: appointment.mode,
      durationMinutes: appointment.durationMinutes,
      status: appointment.status,
      ratePerMinute: appointment.rateSnapshot?.ratePerMinute || 20,
    });
  } catch (err) {
    res.status(500).json({ message: 'Error generating call credentials' });
  }
});

// Start Realtime Session (Server Timer)
router.post('/sessions/:id/start', auth, async (req, res) => {
  try {
    const appointment = await Appointment.findById(req.params.id);
    if (!appointment) return res.status(404).json({ message: 'Appointment not found' });

    appointment.serverStartTime = new Date();
    appointment.status = 'active';
    await appointment.save();

    res.json({
      message: 'Consultation session started',
      serverStartTime: appointment.serverStartTime,
      status: appointment.status,
    });
  } catch (err) {
    res.status(500).json({ message: 'Error starting session' });
  }
});

// Lightweight Appointment Status Polling (for real-time dual-sided call termination)
router.get('/appointments/:id/status', auth, async (req, res) => {
  try {
    const appointment = await Appointment.findById(req.params.id)
      .select('status endedAt endedByRole freeMinutesAllowed freeMinutesUsed paidMinutes amountDebited');
    if (!appointment) return res.status(404).json({ message: 'Appointment not found' });
    res.json({
      status: appointment.status,
      endedAt: appointment.endedAt,
      endedByRole: appointment.endedByRole,
      freeMinutesAllowed: appointment.freeMinutesAllowed,
      freeMinutesUsed: appointment.freeMinutesUsed,
      paidMinutes: appointment.paidMinutes,
      amountDebited: appointment.amountDebited,
    });
  } catch (err) {
    res.status(500).json({ message: 'Error checking appointment status' });
  }
});

// End Realtime Session (Compute Server Billable Duration & Settle In-App Wallet)
router.post('/sessions/:id/end', auth, async (req, res) => {
  try {
    const { clinicalNotes } = req.body;
    const appointment = await Appointment.findById(req.params.id)
      .populate('professionalProfileId');
    if (!appointment) return res.status(404).json({ message: 'Appointment not found' });

    // Mark ended at once for dual-sided sync
    appointment.serverEndTime = new Date();
    appointment.endedAt = new Date();
    appointment.endedByRole = req.user.role || 'patient';
    appointment.status = 'completed';

    const startTime = appointment.serverStartTime ? new Date(appointment.serverStartTime) : new Date(Date.now() - 60000);
    const billableSeconds = Math.max(0, Math.floor((appointment.serverEndTime - startTime) / 1000));
    appointment.billableSeconds = billableSeconds;

    // Free minutes quota: 5m for chat, 3m for voice & video
    const mode = appointment.mode || 'video';
    const freeAllowed = mode === 'chat' ? 5 : 3;
    appointment.freeMinutesAllowed = freeAllowed;

    const totalMinutes = Math.max(1, Math.ceil(billableSeconds / 60));
    const freeMinutesUsed = Math.min(totalMinutes, freeAllowed);
    const paidMinutes = Math.max(0, totalMinutes - freeMinutesUsed);

    // Get doctor rate per minute for this specific mode
    const prof = appointment.professionalProfileId || {};
    const rates = prof.rates || {};
    let ratePerMin = 20;
    if (mode === 'video') ratePerMin = rates.ratePerMinuteVideo || rates.ratePerMinute || 25;
    else if (mode === 'voice') ratePerMin = rates.ratePerMinuteVoice || rates.ratePerMinute || 18;
    else if (mode === 'chat') ratePerMin = rates.ratePerMinuteChat || rates.ratePerMinute || 10;

    const amountDebited = paidMinutes * ratePerMin;
    appointment.freeMinutesUsed = freeMinutesUsed;
    appointment.paidMinutes = paidMinutes;
    appointment.amountDebited = amountDebited;

    if (clinicalNotes) {
      appointment.clinicalNotes = clinicalNotes;
    }

    // Settle Patient Wallet & Doctor Wallet
    if (amountDebited > 0) {
      // Debit patient
      const patientWallet = await Wallet.findOne({ userId: appointment.patientId });
      if (patientWallet) {
        patientWallet.balance = Math.max(0, patientWallet.balance - amountDebited);
        patientWallet.transactions.push({
          txId: `TX_${Date.now()}`,
          type: 'session_debit',
          amount: amountDebited,
          description: `Paid ${paidMinutes}m session with ${prof.publicName || 'Doctor'} (${mode.toUpperCase()})`,
          appointmentId: appointment._id,
        });
        await patientWallet.save();
      }

      // Credit doctor
      let doctorWallet = await Wallet.findOne({ userId: appointment.professionalId });
      if (!doctorWallet) {
        doctorWallet = new Wallet({ userId: appointment.professionalId, balance: 0 });
      }
      doctorWallet.balance += amountDebited;
      doctorWallet.transactions.push({
        txId: `TX_${Date.now()}_D`,
        type: 'doctor_payout',
        amount: amountDebited,
        description: `Consultation earnings for ${paidMinutes}m (${mode.toUpperCase()})`,
        appointmentId: appointment._id,
      });
      await doctorWallet.save();
    }

    await appointment.save();

    res.json({
      message: 'Consultation ended and settled successfully',
      totalMinutes,
      freeMinutesAllowed: freeAllowed,
      freeMinutesUsed,
      paidMinutes,
      ratePerMinute: ratePerMin,
      amountDebited,
      status: appointment.status,
      endedByRole: appointment.endedByRole,
      endedAt: appointment.endedAt,
      itemizedSummary: {
        durationMinutes: totalMinutes,
        freeMinutes: freeMinutesUsed,
        paidMinutes: paidMinutes,
        ratePerMinute: ratePerMin,
        totalCharged: amountDebited,
        currency: 'INR',
      },
    });
  } catch (err) {
    console.error('Error ending session:', err);
    res.status(500).json({ message: 'Error ending session', error: err.message });
  }
});

// ── In-App Digital Wallet Endpoints ──────────────────────────────────────────

// Get User Wallet Balance & Ledger
router.get('/wallet/balance', auth, async (req, res) => {
  try {
    let wallet = await Wallet.findOne({ userId: req.user.id });
    if (!wallet) {
      wallet = await Wallet.create({
        userId: req.user.id,
        balance: req.user.role === 'patient' ? 500 : 0,
        currency: 'INR',
        transactions: req.user.role === 'patient' ? [
          {
            txId: `TX_${Date.now()}`,
            type: 'topup',
            amount: 500,
            description: 'MindSpace Welcome Health Credit',
            paymentMethod: 'Promo Credit',
          }
        ] : [],
      });
    }
    res.json({
      balance: wallet.balance,
      currency: wallet.currency,
      transactions: (wallet.transactions || []).reverse(),
    });
  } catch (err) {
    res.status(500).json({ message: 'Error fetching wallet balance' });
  }
});

// Top-Up Wallet (Simulated Bank / UPI Deposit)
router.post('/wallet/topup', auth, async (req, res) => {
  try {
    const { amount, paymentMethod } = req.body;
    const topupAmount = Number(amount);
    if (!topupAmount || topupAmount <= 0) {
      return res.status(400).json({ message: 'Valid top-up amount is required' });
    }

    let wallet = await Wallet.findOne({ userId: req.user.id });
    if (!wallet) {
      wallet = new Wallet({ userId: req.user.id, balance: 0, currency: 'INR' });
    }

    wallet.balance += topupAmount;
    const tx = {
      txId: `TX_${Date.now()}`,
      type: 'topup',
      amount: topupAmount,
      description: `Bank Top-Up via ${paymentMethod || 'UPI / NetBanking'}`,
      paymentMethod: paymentMethod || 'UPI',
      createdAt: new Date(),
    };
    wallet.transactions.push(tx);
    await wallet.save();

    res.status(200).json({
      message: `₹${topupAmount} added to your MindSpace wallet successfully!`,
      balance: wallet.balance,
      transaction: tx,
    });
  } catch (err) {
    res.status(500).json({ message: 'Error processing wallet top-up' });
  }
});

// ── 5. Appointment-Linked Consultation Messages ──────────────────────────────
router.get('/appointments/:id/messages', auth, async (req, res) => {
  try {
    const messages = await ClinicianMessage.find({ appointmentId: req.params.id })
      .populate('senderId', 'name role')
      .sort({ createdAt: 1 });
    res.json({ messages });
  } catch (err) {
    res.status(500).json({ message: 'Error fetching consultation messages' });
  }
});

router.post('/appointments/:id/messages', auth, async (req, res) => {
  try {
    const { message } = req.body;
    if (!message || !message.trim()) {
      return res.status(400).json({ message: 'Message content is required' });
    }

    const appointment = await Appointment.findById(req.params.id);
    if (!appointment) return res.status(404).json({ message: 'Appointment not found' });

    const msg = new ClinicianMessage({
      appointmentId: appointment._id,
      senderId: req.user.id,
      senderRole: req.user.role,
      message: message.trim(),
    });
    await msg.save();

    res.status(201).json({ message: msg });
  } catch (err) {
    res.status(500).json({ message: 'Error sending consultation message' });
  }
});

// ── 6. Billing & Earnings ────────────────────────────────────────────────────
router.get('/patient/billing', auth, async (req, res) => {
  try {
    const orders = await PaymentOrder.find({ userId: req.user.id })
      .populate({
        path: 'appointmentId',
        populate: { path: 'professionalProfileId' },
      })
      .sort({ createdAt: -1 });
    res.json({ orders });
  } catch (err) {
    res.status(500).json({ message: 'Error retrieving billing history' });
  }
});

router.get('/professional/earnings', auth, async (req, res) => {
  try {
    const completedAppointments = await Appointment.find({
      professionalId: req.user.id,
      status: 'completed',
    });

    let grossEarnings = 0;
    let platformFees = 0;
    for (const appt of completedAppointments) {
      grossEarnings += (appt.rateSnapshot?.sessionFee || 500);
      platformFees += (appt.rateSnapshot?.platformFee || 50);
    }
    const netEarnings = grossEarnings - platformFees;

    res.json({
      completedConsultations: completedAppointments.length,
      grossEarnings,
      platformFees,
      netEarnings,
      currency: 'INR',
      payoutStatus: 'Eligible for weekly settlement',
    });
  } catch (err) {
    res.status(500).json({ message: 'Error calculating earnings' });
  }
});

// ── 7. Safety, Emergency Helplines & User Reports ─────────────────────────────
router.get('/safety/resources', (req, res) => {
  res.json({
    notice: 'MindSpace is not an emergency response service. If you or someone you know is in immediate danger, please reach out to trusted emergency helplines immediately.',
    emergencyHelplines: [
      {
        name: 'Tele-MANAS (Govt. of India 24/7 Mental Health)',
        tollFree: '14416',
        secondary: '1800-891-4416',
        languages: '20+ Indian Languages',
        description: 'Comprehensive, round-the-clock free mental health care services provided by MoHFW.',
      },
      {
        name: 'KIRAN National Helpline',
        tollFree: '1800-599-0019',
        languages: '13 Languages',
        description: 'Mental health rehabilitation helpline offering psychological first-aid.',
      },
      {
        name: 'Emergency Response Support System (ERSS)',
        tollFree: '112',
        languages: 'National',
        description: 'All-in-one national emergency number for police, medical, and fire emergencies.',
      },
      {
        name: 'Vandrevala Foundation Helpline',
        tollFree: '9999 666 555',
        languages: 'English, Hindi, Regional',
        description: 'Free crisis intervention and counselling.',
      },
    ],
  });
});

router.post('/safety/reports', auth, async (req, res) => {
  try {
    const { reportedUserId, appointmentId, category, priority, description } = req.body;
    if (!description || !category) {
      return res.status(400).json({ message: 'Category and description are required' });
    }

    const report = new SafetyReport({
      reporterId: req.user.id,
      reportedUserId,
      appointmentId,
      category,
      priority: priority || 'medium',
      description,
    });
    await report.save();

    res.status(201).json({
      message: 'Safety report submitted and queued for immediate administrative review.',
      reportId: report._id,
    });
  } catch (err) {
    res.status(500).json({ message: 'Error submitting safety report' });
  }
});

module.exports = router;
