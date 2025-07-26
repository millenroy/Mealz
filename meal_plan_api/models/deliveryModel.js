const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const DeliveryItemSchema = new Schema({
  meal: { type: Schema.Types.ObjectId, ref: 'Meal', required: true },
  status: { 
    type: String, 
    enum: ['scheduled', 'skipped', 'moved'], 
    default: 'scheduled' 
  },
});

const DeliverySchema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  deliveryDate: { type: Date, required: true },
  timeSlot: { type: String, required: true },
  address: { type: String, required: true }, // The selected address nickname
  deliveryType: { 
    type: String, 
    enum: ['delivery', 'pickup'], 
    default: 'delivery' 
  },
  items: [DeliveryItemSchema],
});

module.exports = mongoose.model('Delivery', DeliverySchema);