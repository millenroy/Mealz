const mongoose = require('mongoose');
const Schema = mongoose.Schema;

// This is the catalog of all possible meals a user can swap to.
const MealSchema = new Schema({
  name: { type: String, required: true },
  description: String,
  calories: Number,
  protein: Number,
  carbs: Number,
  fat: Number,
  imageUrl: { type: String, required: true },
});

module.exports = mongoose.model('Meal', MealSchema);