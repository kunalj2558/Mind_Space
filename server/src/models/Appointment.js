const mongoose = require('mongoose');

const AppointmentSchema = new mongoose.Schema({
  patientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  professionalId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  professionalProfileId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'ProfessionalProfile',
  },
  serviceType: {
    type: String,
    required: true,
    default: 'Mental Wellbeing Consultation',
  },
  mode: {
    type: String,
    enum: ['chat', 'voice', 'video'],
    default: 'video',
  },
  scheduledAt: {
    type: Date,
    required: true,
  },
  durationMinutes: {
    type: Number,
    enum: [15, 30, 45, 60],
    default: 30,
  },
  status: {
    type: String,
    enum: [
      'requested',
      'confirmed',
      'scheduled',
      'payment_pending',
      'paid',
      'waiting_room',
      'ready',
      'connecting',
      'active',
      'completed',
      'cancelled',
      'no_show',
      'refunded',
    ],
    default: 'requested',
  },
  patientConsent: {
    emergencyAcknowledged: {
      type: Boolean,
      default: true,
    },
    privacyConsented: {
      type: Boolean,
      default: true,
    },
    shareSummaryConsented: {
      type: Boolean,
      default: false,
    },
    consentedAt: {
      type: Date,
      default: Date.now,
    },
  },
  rateSnapshot: {
    currency: {
      type: String,
      default: 'INR',
    },
    ratePerMinute: {
      type: Number,
      default: 20,
    },
    sessionFee: {
      type: Number,
      default: 550,
    },
    platformFee: {
      type: Number,
      default: 50,
    },
    taxes: {
      type: Number,
      default: 0,
    },
    totalAmount: {
      type: Number,
      default: 600,
    },
    cancellationPolicy: {
      type: String,
      default: 'Free cancellation up to 2 hours before session start time.',
    },
  },
  paymentOrderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'PaymentOrder',
  },
  paymentStatus: {
    type: String,
    enum: ['unpaid', 'authorized', 'captured', 'refunded', 'waived'],
    default: 'unpaid',
  },
  // Realtime Session Data
  providerRoomId: {
    type: String,
    default: '',
  },
  serverStartTime: {
    type: Date,
  },
  serverEndTime: {
    type: Date,
  },
  billableSeconds: {
    type: Number,
    default: 0,
  },
  freeMinutesAllowed: {
    type: Number,
    default: 3,
  },
  freeMinutesUsed: {
    type: Number,
    default: 0,
  },
  paidMinutes: {
    type: Number,
    default: 0,
  },
  amountDebited: {
    type: Number,
    default: 0,
  },
  endedByRole: {
    type: String,
    enum: ['patient', 'doctor', 'system'],
  },
  endedAt: {
    type: Date,
  },
  clinicalNotes: {
    type: String,
    default: '',
  },
  patientFeedback: {
    rating: Number,
    comment: String,
    createdAt: Date,
  },
}, { timestamps: true });

module.exports = mongoose.model('Appointment', AppointmentSchema);
