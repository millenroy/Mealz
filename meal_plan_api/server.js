const express = require('express');
const mongoose = require('mongoose');
const cors =require('cors');
const seedDatabase = require('./data/seed');

const app = express();
const PORT = 3010;

// Middleware
// app.use(cors());
app.use(
  cors({
    origin: "*",      // Allows all origins
    methods: "*",     // Allows all methods (GET, POST, PUT, DELETE, etc.)
    credentials: true // Allows sending cookies and HTTP authentication credentials
  })
);
app.use(express.json());

// DB Connection
mongoose.connect('mongodb://localhost:27017/meal_plan_v2')
  .then(() => {
    console.log('Connected to MongoDB!');
    // Run the seeder after connecting
    seedDatabase();
  })
  .catch(err => console.error('Could not connect to MongoDB...', err));

// Routes
const apiRoutes = require('./routes/api');
app.use('/api', apiRoutes);

// Start Server
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});