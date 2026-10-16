const mongoose = require('mongoose');

const ProfessionalProfileSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true,
  },
  publicName: {
    type: String,
    required: true,
    trim: true,
  },
  title: {
    type: String,
    required: true,
    enum: ['Psychiatrist', 'Clinical Psychologist', 'Counsellor', 'Therapist', 'Physiotherapist'],
    default: 'Clinical Psychologist',
  },
  specialty: {
    type: String,
    required: true,
  },
  qualifications: {
    type: [String],
    default: [],
  },
  registrationNumber: {
    type: String,
    required: true,
    trim: true,
  },
  registrationBody: {
    type: String,
    default: 'Medical Council of India / Rehabilitation Council of India',
  },
  experienceYears: {
    type: Number,
    default: 1,
  },
  languages: {
    type: [String],
    default: ['English', 'Hindi'],
  },
  bio: {
    type: String,
    default: '',
  },
  hospitalAffiliation: {
    type: String,
    default: '',
  },
  avatarUrl: {
    type: String,
    default: '',
  },
  verificationStatus: {
    type: String,
    enum: ['pending_verification', 'verified', 'rejected', 'suspended'],
    default: 'verified', // Set to verified so seeded/new demo doctors appear bookable immediately
  },
  verificationDate: {
    type: Date,
  },
  consultationModes: {
    type: [String],
    enum: ['chat', 'voice', 'video'],
    default: ['chat', 'voice', 'video'],
  },
  rates: {
    currency: {
      type: String,
      default: 'INR',
    },
    ratePerMinute: {
      type: Number,
      default: 20,
    },
    ratePerMinuteVideo: {
      type: Number,
      default: 25,
    },
    ratePerMinuteVoice: {
      type: Number,
      default: 18,
    },
    ratePerMinuteChat: {
      type: Number,
      default: 10,
    },
    session15Min: {
      type: Number,
      default: 300,
    },
    session30Min: {
      type: Number,
      default: 550,
    },
    session60Min: {
      type: Number,
      default: 999,
    },
  },
  rating: {
    type: Number,
    default: 4.9,
  },
  reviewCount: {
    type: Number,
    default: 12,
  },
  availabilitySlots: [
    {
      dayOfWeek: {
        type: String,
        enum: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
      },
      startTime: String, // '09:00'
      endTime: String,   // '17:00'
      active: {
        type: Boolean,
        default: true,
      },
    },
  ],
  isAvailableNow: {
    type: Boolean,
    default: true,
  },
}, { timestamps: true });

module.exports = mongoose.model('ProfessionalProfile', ProfessionalProfileSchema);
