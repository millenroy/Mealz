const express = require('express');
const router = express.Router();

const User = require('../models/userModel');
const Meal = require('../models/mealModel');
const Delivery = require('../models/deliveryModel');

// --- CONFIGURATION ENDPOINTS ---
// Get user details (for address dropdown)
router.get('/users', async (req, res) => {
  try {
    const users = await User.find({}, '_id name addresses');
    res.json(users);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

router.get('/users/:id', async (req, res) => {
    try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.json(user);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// Get available time slots (changee to a config collection in the future)
router.get('/config/timeslots', (req, res) => {
  res.json(['08:00', '10:00', '12:00', '14:00', '16:00', '18:00', '20:00', '22:00']);
});

// Get all meals (for swap functionality)
router.get('/meals', async (req, res) => {
  try {
    const meals = await Meal.find({});
    res.json(meals);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// --- DELIVERY ENDPOINTS ---
// Get deliveries for a specific date, populating meal details
router.get('/deliveries', async (req, res) => {
  const { date, userId } = req.query;
  const startDate = new Date(`${date}T00:00:00.000Z`);
  const endDate = new Date(`${date}T23:59:59.999Z`);

  try {
    const deliveries = await Delivery.find({
      userId: userId,
      deliveryDate: { $gte: startDate, $lte: endDate },
    }).populate('items.meal'); // This is IMPORTANT: it fetches the full meal object
    res.json(deliveries);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// Reschedule an entire delivery slot
router.put('/deliveries/:id/reschedule', async (req, res) => {
  try {
    const { newDate } = req.body;
    const delivery = await Delivery.findByIdAndUpdate(req.params.id, { deliveryDate: new Date(newDate) }, { new: true });
    res.json(delivery);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// Update a delivery slot (time, address, type)
router.put('/deliveries/:id/update', async (req, res) => {
    try {
      const { timeSlot, address, deliveryType } = req.body;
      const delivery = await Delivery.findByIdAndUpdate(
        req.params.id, 
        { $set: { timeSlot, address, deliveryType } }, 
        { new: true }
      );
      res.json(delivery);
    } catch (e) { res.status(500).json({ message: e.message }); }
});


// --- ITEM-SPECIFIC ACTIONS ---

// Skip an item
router.put('/deliveries/:deliveryId/items/:itemId/skip', async (req, res) => {
  try {
    await Delivery.updateOne(
      { _id: req.params.deliveryId, 'items._id': req.params.itemId },
      { $set: { 'items.$.status': 'skipped' } }
    );
    res.status(200).json({ message: 'Item skipped' });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// Swap an item
router.put('/deliveries/:deliveryId/items/:itemId/swap', async (req, res) => {
    try {
      const { newMealId } = req.body; // client sends the ID of the new meal
      await Delivery.updateOne(
        { _id: req.params.deliveryId, 'items._id': req.params.itemId },
        { $set: { 'items.$.meal': newMealId, 'items.$.status': 'scheduled' } }
      );
      res.status(200).json({ message: 'Item swapped' });
    } catch (e) { res.status(500).json({ message: e.message }); }
});

module.exports = router;