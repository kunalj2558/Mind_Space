const mongoose = require('mongoose');

const SafetyReportSchema = new mongoose.Schema({
  reporterId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  reportedUserId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
  appointmentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Appointment',
  },
  category: {
    type: String,
    enum: ['crisis_risk', 'unprofessional_conduct', 'safety_concern', 'billing_dispute', 'technical_failure', 'other'],
    required: true,
  },
  priority: {
    type: String,
    enum: ['low', 'medium', 'high', 'immediate'],
    default: 'medium',
  },
  description: {
    type: String,
    required: true,
  },
  status: {
    type: String,
    enum: ['pending', 'investigating', 'resolved', 'dismissed'],
    default: 'pending',
  },
  adminNotes: {
    type: String,
    default: '',
  },
}, { timestamps: true });

module.exports = mongoose.model('SafetyReport', SafetyReportSchema);
