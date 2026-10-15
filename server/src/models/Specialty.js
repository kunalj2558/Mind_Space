const mongoose = require('mongoose');

const SpecialtySchema = new mongoose.Schema({
  key: {
    type: String,
    required: true,
    unique: true,
    trim: true,
  },
  name: {
    type: String,
    required: true,
  },
  category: {
    type: String,
    enum: ['medical', 'psychotherapy', 'counselling', 'rehabilitation'],
    default: 'psychotherapy',
  },
  description: {
    type: String,
    default: '',
  },
  scopeOfPractice: {
    type: String,
    default: '',
  },
  badgeColor: {
    type: String,
    default: '#4F46E5',
  },
  icon: {
    type: String,
    default: 'psychology',
  },
  active: {
    type: Boolean,
    default: true,
  },
}, { timestamps: true });

module.exports = mongoose.model('Specialty', SpecialtySchema);
