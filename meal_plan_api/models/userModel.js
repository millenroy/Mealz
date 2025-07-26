const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const UserSchema = new Schema({
  name: { type: String, required: true },
  addresses: [{
    nickname: String, // e.g., 'Home', 'Work'
    details: String,
  }],
  subscriptionValidUntil: { type: Date },
});

module.exports = mongoose.model('User', UserSchema);