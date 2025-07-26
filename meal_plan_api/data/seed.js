const User = require('../models/userModel');
const Meal = require('../models/mealModel');
const Delivery = require('../models/deliveryModel');

const seedDatabase = async () => {
    try {
        // Check if data already exists to prevent re-seeding
        const userCount = await User.countDocuments();
        if (userCount > 0) {
            console.log('Database already seeded. Skipping.');
            return;
        }

        console.log('Database is empty. Seeding data...');

        // 1. Create Meals Catalog
        const meals = await Meal.create([
            { name: 'Healthy Lab Seasonal Berry Oats', description: 'Protein 27g, fat 5g, carb 32g, calories 396 cal', imageUrl: 'https://i.imgur.com/7Y5IAZV.jpeg' },
            { name: 'Healthy Lab Original Egg Sandwich', description: 'Protein 15g, fat 11g, Carbs 15g, Calories 290 cal', imageUrl: 'https://i.imgur.com/75mK0OD.jpeg' },
            { name: 'Classic Chicken Salad', description: 'High protein, low carb', imageUrl: 'https://i.imgur.com/Bp1XR73.jpeg' },
            { name: 'Spaghetti Aglio e Olio', description: 'A classic Italian dish', imageUrl: 'https://i.imgur.com/arlpi2l.png' },
            { name: 'Tofu Buddha Bowl', description: 'Plant-based protein bowl', imageUrl: 'https://i.imgur.com/QUkDT5u.jpeg' },
            { name: 'Grilled Salmon with Quinoa', description: 'Omega-3 rich and gluten-free', imageUrl: 'https://i.imgur.com/OFVDRMd.jpeg' },
            { name: 'Vegan Burrito Wrap', description: 'Delicious and nutritious', imageUrl: 'https://i.imgur.com/ST8SFld.jpeg' },
            { name: 'Paneer Tikka Bowl', description: 'Indian spice blend, high protein', imageUrl: 'https://i.imgur.com/L548fKc.jpeg' },
            { name: 'Chicken Stir Fry', description: 'Asian-style with fresh veggies', imageUrl: 'https://i.imgur.com/JfJwA61.png' },
            { name: 'Quinoa Stuffed Peppers', description: 'Colorful, low-calorie option', imageUrl: 'https://i.imgur.com/uvoSxLm.jpeg' },
        ]);

        // 2. Create Users
        const users = await User.create([
            { name: 'Ahamad', addresses: [{ nickname: 'Home', details: '123 Main St' }, { nickname: 'Work', details: '456 Business Ave' }], subscriptionValidUntil: new Date('2025-09-01T23:59:59.999Z'), },
            { name: 'Zack', addresses: [{ nickname: 'Gym', details: '789 Fitness Rd' }], subscriptionValidUntil: new Date('2025-08-25T23:59:59.999Z'), },
            { name: 'Millen', addresses: [{ nickname: 'Studio', details: '101 Art Lane' }, { nickname: 'Warehouse', details: '202 Storage Blvd' },], subscriptionValidUntil: new Date('2025-09-10T23:59:59.999Z'), },
        ]);

        const ahmad = users[0];
        const millen = users[2];

        function getRandomMeals(count) {
            const shuffled = [...meals].sort(() => 0.5 - Math.random());
            return shuffled.slice(0, count).map(m => ({ meal: m._id, status: 'scheduled' }));
        }

        function getRandomTimeSlot() {
            const slots = ['08:00', '12:00', '14:00', '18:00'];
            return slots[Math.floor(Math.random() * slots.length)];
        }

        function getRandomDeliveryType() {
            return Math.random() > 0.2 ? 'delivery' : 'pickup';
        }

        function getRandomAddress(user) {
            const addresses = user.addresses.map(a => a.nickname);
            return addresses[Math.floor(Math.random() * addresses.length)];
        }

        function randomDateInRange(start, end) {
            const date = new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));
            date.setHours(0, 0, 0, 0);
            return date;
        }

        const deliveryDates = [];
        for (let i = 0; i < 7; i++) {
            deliveryDates.push(randomDateInRange(new Date('2025-08-01'), new Date('2025-08-15')));
        }
        deliveryDates.sort((a, b) => a - b);

        const deliveries = [];

        // Ahmad Deliveries
        for (let i = 0; i < 7; i++) {
            deliveries.push({
                userId: ahmad._id,
                deliveryDate: deliveryDates[i],
                timeSlot: getRandomTimeSlot(),
                address: getRandomAddress(ahmad),
                deliveryType: getRandomDeliveryType(),
                items: getRandomMeals(Math.floor(Math.random() * 3) + 1),
            });
        }

        // Millen Deliveries
        for (let i = 0; i < 7; i++) {
            deliveries.push({
                userId: millen._id,
                deliveryDate: deliveryDates[Math.floor(Math.random() * deliveryDates.length)],
                timeSlot: getRandomTimeSlot(),
                address: getRandomAddress(millen),
                deliveryType: getRandomDeliveryType(),
                items: getRandomMeals(Math.floor(Math.random() * 3) + 1),
            });
        }

        const hardcodedDeliveries = [];

        const fixedDates = [
            '2025-07-26',
            '2025-07-27',
            '2025-07-28',
            '2025-07-29',
            '2025-07-30',
            '2025-07-31',
        ];

        // One delivery per day for each user (Ahmad & Millen)
        for (const dateStr of fixedDates) {
            const deliveryDate = new Date(`${dateStr}T00:00:00.000Z`);

            // Ahmad
            hardcodedDeliveries.push({
                userId: ahmad._id,
                deliveryDate,
                timeSlot: getRandomTimeSlot(),
                address: getRandomAddress(ahmad),
                deliveryType: getRandomDeliveryType(),
                items: getRandomMeals(Math.floor(Math.random() * 3) + 1),
            });

            // Millen
            hardcodedDeliveries.push({
                userId: millen._id,
                deliveryDate,
                timeSlot: getRandomTimeSlot(),
                address: getRandomAddress(millen),
                deliveryType: getRandomDeliveryType(),
                items: getRandomMeals(Math.floor(Math.random() * 3) + 1),
            });
        }

        await Delivery.create(deliveries);
        await Delivery.create(hardcodedDeliveries);

        // 3. Create initial delivery schedule for 'Ahamad'
        // await Delivery.create([
        //   {
        //     userId: users[0]._id,
        //     deliveryDate: new Date('2025-08-01T00:00:00.000Z'),
        //     timeSlot: '14:00',
        //     address: 'Home',
        //     deliveryType: 'delivery',
        //     items: [
        //       { meal: meals[0]._id, status: 'scheduled' },
        //       { meal: meals[1]._id, status: 'scheduled' },
        //     ],
        //   },
        //   {
        //     userId: users[0]._id,
        //     deliveryDate: new Date('2025-08-04T00:00:00.000Z'), 
        //     timeSlot: '18:00',
        //     address: 'Work',
        //     deliveryType: 'delivery',
        //     items: [
        //       { meal: meals[2]._id, status: 'scheduled' },
        //     ],
        //   },
        // ]);



        console.log('Database seeded successfully!');
    } catch (error) {
        console.error('Error seeding database:', error);
    }
};

module.exports = seedDatabase;