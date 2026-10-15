const mongoose = require('mongoose');

const PaymentOrderSchema = new mongoose.Schema({
  orderId: {
    type: String,
    required: true,
    unique: true,
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  appointmentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Appointment',
  },
  amount: {
    type: Number,
    required: true,
  },
  currency: {
    type: String,
    default: 'INR',
  },
  breakdown: {
    sessionFee: {
      type: Number,
      default: 0,
    },
    platformFee: {
      type: Number,
      default: 0,
    },
    taxes: {
      type: Number,
      default: 0,
    },
  },
  status: {
    type: String,
    enum: ['created', 'pending', 'paid', 'failed', 'refunded'],
    default: 'created',
  },
  idempotencyKey: {
    type: String,
    unique: true,
    sparse: true,
  },
  gateway: {
    type: String,
    default: 'sandbox_razorpay',
  },
  gatewayOrderId: {
    type: String,
  },
  gatewayPaymentId: {
    type: String,
  },
  paidAt: {
    type: Date,
  },
  receiptUrl: {
    type: String,
  },
}, { timestamps: true });

module.exports = mongoose.model('PaymentOrder', PaymentOrderSchema);
