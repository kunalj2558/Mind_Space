const mongoose = require('mongoose');

const WalletSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true,
  },
  balance: {
    type: Number,
    default: 0,
    min: 0,
  },
  currency: {
    type: String,
    default: 'INR',
  },
  transactions: [
    {
      txId: { type: String, required: true },
      type: {
        type: String,
        enum: ['topup', 'session_debit', 'refund', 'doctor_payout'],
        required: true,
      },
      amount: { type: Number, required: true },
      description: { type: String, default: '' },
      paymentMethod: { type: String, default: 'UPI' },
      appointmentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Appointment' },
      createdAt: { type: Date, default: Date.now },
    },
  ],
}, { timestamps: true });

module.exports = mongoose.model('Wallet', WalletSchema);
