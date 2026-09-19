-- ============================================================
-- FILE: data_input.sql
-- PROJECT: Surplus Food Rescue & NGO Logistics Management
-- Database : food_rescue_db
-- NOTE: Run table_creation.sql first before running this file
-- ============================================================
USE food_rescue_db;

-- ============================================================
-- SAMPLE DATA (Moderate - ~300 records total)
-- ============================================================

-- 15 Donors
INSERT INTO donors (donor_name, donor_type, contact_person, email, phone, city, is_verified) VALUES
('Taj Palace Hotel', 'hotel', 'Rajesh Kumar', 'donor1@test.com', '9876543201', 'Mumbai', TRUE),
('Reliance Fresh', 'supermarket', 'Priya Sharma', 'donor2@test.com', '9876543202', 'Mumbai', TRUE),
('The Grand Marriott', 'hotel', 'Suresh Menon', 'donor3@test.com', '9876543203', 'Mumbai', TRUE),
('Shiv Sagar Restaurant', 'restaurant', 'Amit Patel', 'donor4@test.com', '9876543204', 'Mumbai', TRUE),
('City Banquet Hall', 'banquet_hall', 'Kavita Joshi', 'donor5@test.com', '9876543205', 'Mumbai', TRUE),
('Godrej Nature Basket', 'supermarket', 'Neha Singh', 'donor6@test.com', '9876543206', 'Mumbai', TRUE),
('Cafe Coffee Day', 'restaurant', 'Rahul Verma', 'donor7@test.com', '9876543207', 'Pune', TRUE),
('Leela Palace', 'hotel', 'Deepika Nair', 'donor8@test.com', '9876543208', 'Bangalore', TRUE),
('Big Basket Warehouse', 'supermarket', 'Vikram Iyer', 'donor9@test.com', '9876543209', 'Bangalore', TRUE),
('The Oberoi', 'hotel', 'Meena Krishnan', 'donor10@test.com', '9876543210', 'Chennai', TRUE),
('Spice Garden', 'caterer', 'Arun Kumar', 'donor11@test.com', '9876543211', 'Chennai', TRUE),
('Organic Farms', 'farm', 'Lakshmi Devi', 'donor12@test.com', '9876543212', 'Hyderabad', TRUE),
('IKEA Food Court', 'restaurant', 'Sara Ali', 'donor13@test.com', '9876543213', 'Bangalore', TRUE),
('Punjab Grill', 'restaurant', 'Harpreet Singh', 'donor14@test.com', '9876543214', 'Chandigarh', TRUE),
('Royal Orchid', 'hotel', 'Nisha Rathi', 'donor15@test.com', '9876543215', 'Jaipur', TRUE);

-- 10 NGOs
INSERT INTO ngos (ngo_name, ngo_type, contact_person, email, phone, city, daily_capacity_meals, has_refrigeration, is_verified) VALUES
('SOS Children Village', 'orphanage', 'Mary Joseph', 'ngo1@test.com', '9876554001', 'Mumbai', 500, TRUE, TRUE),
('Mumbai Smile Shelter', 'shelter', 'Ramesh Patel', 'ngo2@test.com', '9876554002', 'Mumbai', 300, TRUE, TRUE),
('Bangalore Food Bank', 'community_kitchen', 'Kavitha Rao', 'ngo3@test.com', '9876554003', 'Bangalore', 1000, TRUE, TRUE),
('Chennai Hunger Relief', 'community_kitchen', 'Lakshmi Narayanan', 'ngo4@test.com', '9876554004', 'Chennai', 800, TRUE, TRUE),
('Pune Old Age Home', 'old_age_home', 'Shanti Devi', 'ngo5@test.com', '9876554005', 'Pune', 200, TRUE, TRUE),
('Hyderabad Hope', 'orphanage', 'Salma Begum', 'ngo6@test.com', '9876554006', 'Hyderabad', 400, TRUE, TRUE),
('Delhi Food for All', 'community_kitchen', 'Arvind Kejriwal', 'ngo7@test.com', '9876554007', 'Delhi', 1200, FALSE, TRUE),
('Kochi Shelter', 'shelter', 'George Thomas', 'ngo8@test.com', '9876554008', 'Kochi', 150, TRUE, TRUE),
('Chandigarh Child Care', 'orphanage', 'Jaspreet Kaur', 'ngo9@test.com', '9876554009', 'Chandigarh', 250, TRUE, TRUE),
('Ahmedabad Women Shelter', 'women_shelter', 'Hansa Ben', 'ngo10@test.com', '9876554010', 'Ahmedabad', 180, TRUE, TRUE);

-- 10 Volunteers
INSERT INTO volunteers (full_name, email, phone, vehicle_type, vehicle_capacity_kg, city, is_available, rating_average, total_deliveries) VALUES
('Ravi Sharma', 'vol1@test.com', '9845670001', 'van', 150, 'Mumbai', TRUE, 4.5, 120),
('Sunita Devi', 'vol2@test.com', '9845670002', 'scooter', 25, 'Mumbai', TRUE, 4.8, 95),
('Amit Kumar', 'vol3@test.com', '9845670003', 'bike', 10, 'Mumbai', FALSE, 3.9, 45),
('Kavita Patil', 'vol4@test.com', '9845670004', 'van', 200, 'Mumbai', TRUE, 4.7, 210),
('Rajesh Gupta', 'vol5@test.com', '9845670005', 'car', 80, 'Mumbai', TRUE, 4.2, 75),
('Arun Iyer', 'vol6@test.com', '9845670006', 'van', 180, 'Bangalore', TRUE, 4.6, 180),
('Lakshmi Nair', 'vol7@test.com', '9845670007', 'scooter', 20, 'Bangalore', TRUE, 4.85, 110),
('Priya Nambiar', 'vol8@test.com', '9845670008', 'bike', 15, 'Bangalore', TRUE, 4.4, 85),
('Bala Krishnan', 'vol9@test.com', '9845670009', 'car', 85, 'Chennai', TRUE, 4.3, 105),
('Harpreet Singh', 'vol10@test.com', '9845670010', 'truck', 550, 'Chandigarh', TRUE, 4.9, 350);

-- 30 NGO Demands
INSERT INTO ngo_demands (ngo_id, food_category, required_servings, priority, requested_date, is_active) VALUES
(1, 'cooked_food', 200, 'critical', CURDATE(), TRUE),
(1, 'dairy', 100, 'high', CURDATE(), TRUE),
(2, 'cooked_food', 150, 'high', CURDATE(), TRUE),
(2, 'fruits', 80, 'medium', CURDATE(), TRUE),
(3, 'packaged_meals', 300, 'critical', CURDATE(), TRUE),
(3, 'grains', 200, 'high', CURDATE(), TRUE),
(4, 'cooked_food', 250, 'high', CURDATE(), TRUE),
(4, 'vegetables', 100, 'medium', CURDATE(), TRUE),
(5, 'cooked_food', 100, 'medium', CURDATE(), TRUE),
(5, 'dairy', 50, 'low', CURDATE(), TRUE),
(6, 'cooked_food', 180, 'high', CURDATE(), TRUE),
(6, 'fruits', 120, 'medium', CURDATE(), TRUE),
(7, 'packaged_meals', 500, 'critical', CURDATE(), TRUE),
(7, 'grains', 300, 'high', CURDATE(), TRUE),
(8, 'cooked_food', 80, 'medium', CURDATE(), TRUE),
(8, 'dairy', 40, 'low', CURDATE(), TRUE),
(9, 'cooked_food', 120, 'high', CURDATE(), TRUE),
(9, 'fruits', 60, 'medium', CURDATE(), TRUE),
(10, 'cooked_food', 100, 'medium', CURDATE(), TRUE),
(10, 'vegetables', 80, 'low', CURDATE(), TRUE),
(1, 'bakery', 50, 'low', DATE_SUB(CURDATE(), INTERVAL 1 DAY), TRUE),
(2, 'cooked_food', 100, 'medium', DATE_SUB(CURDATE(), INTERVAL 1 DAY), TRUE),
(3, 'frozen_food', 150, 'high', DATE_SUB(CURDATE(), INTERVAL 1 DAY), TRUE),
(4, 'cooked_food', 200, 'critical', DATE_SUB(CURDATE(), INTERVAL 1 DAY), TRUE),
(5, 'grains', 100, 'medium', DATE_SUB(CURDATE(), INTERVAL 1 DAY), TRUE),
(6, 'cooked_food', 150, 'high', DATE_SUB(CURDATE(), INTERVAL 1 DAY), TRUE),
(7, 'packaged_meals', 400, 'critical', DATE_SUB(CURDATE(), INTERVAL 1 DAY), TRUE),
(8, 'dairy', 60, 'low', DATE_SUB(CURDATE(), INTERVAL 1 DAY), TRUE),
(9, 'cooked_food', 130, 'medium', DATE_SUB(CURDATE(), INTERVAL 1 DAY), TRUE),
(10, 'vegetables', 90, 'low', DATE_SUB(CURDATE(), INTERVAL 1 DAY), TRUE);

-- 50 Donation Batches
INSERT INTO donation_batches (donor_id, food_category, food_description, quantity_kg, quantity_servings, preparation_datetime, expiry_datetime, requires_refrigeration, is_vegetarian, status) VALUES
(1, 'cooked_food', 'Vegetable biryani with raita', 25, 150, DATE_SUB(NOW(), INTERVAL 2 HOUR), DATE_ADD(NOW(), INTERVAL 3 HOUR), TRUE, TRUE, 'available'),
(1, 'packaged_meals', 'Pre-packed vegetarian thali', 15, 80, DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_ADD(NOW(), INTERVAL 5 HOUR), FALSE, TRUE, 'available'),
(2, 'raw_produce', 'Fresh mixed vegetables', 50, 0, DATE_SUB(NOW(), INTERVAL 3 HOUR), DATE_ADD(NOW(), INTERVAL 24 HOUR), TRUE, TRUE, 'available'),
(2, 'fruits', 'Overripe bananas and apples', 30, 0, DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_ADD(NOW(), INTERVAL 12 HOUR), TRUE, TRUE, 'available'),
(3, 'bakery', 'Freshly baked bread and pastries', 20, 120, DATE_SUB(NOW(), INTERVAL 30 MINUTE), DATE_ADD(NOW(), INTERVAL 8 HOUR), FALSE, TRUE, 'available'),
(3, 'dairy', 'Milk and yogurt packets', 35, 200, DATE_SUB(NOW(), INTERVAL 2 HOUR), DATE_ADD(NOW(), INTERVAL 6 HOUR), TRUE, TRUE, 'available'),
(4, 'cooked_food', 'Paneer butter masala and naan', 18, 100, DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_ADD(NOW(), INTERVAL 4 HOUR), TRUE, TRUE, 'available'),
(5, 'cooked_food', 'Wedding feast leftovers', 80, 400, DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_ADD(NOW(), INTERVAL 2 HOUR), TRUE, TRUE, 'available'),
(6, 'grains', 'Rice bags and wheat flour', 100, 0, DATE_SUB(NOW(), INTERVAL 5 HOUR), DATE_ADD(NOW(), INTERVAL 720 HOUR), FALSE, TRUE, 'available'),
(6, 'vegetables', 'Organic tomatoes and onions', 40, 0, DATE_SUB(NOW(), INTERVAL 2 HOUR), DATE_ADD(NOW(), INTERVAL 48 HOUR), TRUE, TRUE, 'available'),
(7, 'packaged_meals', 'Ready-to-eat pasta and sandwiches', 12, 60, DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_ADD(NOW(), INTERVAL 72 HOUR), FALSE, TRUE, 'available'),
(8, 'cooked_food', 'South Indian breakfast - idli, dosa', 35, 250, DATE_SUB(NOW(), INTERVAL 30 MINUTE), DATE_ADD(NOW(), INTERVAL 5 HOUR), TRUE, TRUE, 'available'),
(9, 'fruits', 'Mixed seasonal fruits', 45, 0, DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_ADD(NOW(), INTERVAL 36 HOUR), TRUE, TRUE, 'available'),
(10, 'cooked_food', 'Filter coffee and breakfast items', 10, 80, DATE_SUB(NOW(), INTERVAL 45 MINUTE), DATE_ADD(NOW(), INTERVAL 7 HOUR), TRUE, TRUE, 'available'),
(11, 'cooked_food', 'Biryani and kebabs - non-veg', 22, 120, DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_ADD(NOW(), INTERVAL 3 HOUR), TRUE, FALSE, 'available'),
(12, 'raw_produce', 'Fresh organic vegetables', 60, 0, DATE_SUB(NOW(), INTERVAL 3 HOUR), DATE_ADD(NOW(), INTERVAL 72 HOUR), TRUE, TRUE, 'available'),
(13, 'cooked_food', 'Swedish meatballs and pasta', 15, 90, DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_ADD(NOW(), INTERVAL 6 HOUR), TRUE, FALSE, 'available'),
(14, 'cooked_food', 'Punjabi thali - dal, roti, sabzi', 28, 160, DATE_SUB(NOW(), INTERVAL 45 MINUTE), DATE_ADD(NOW(), INTERVAL 4 HOUR), TRUE, TRUE, 'available'),
(15, 'packaged_meals', 'Canned goods and dry rations', 75, 300, DATE_SUB(NOW(), INTERVAL 10 HOUR), DATE_ADD(NOW(), INTERVAL 8760 HOUR), FALSE, TRUE, 'available'),
(16, 'dairy', 'Cheese blocks and butter', 20, 100, DATE_SUB(NOW(), INTERVAL 2 HOUR), DATE_ADD(NOW(), INTERVAL 168 HOUR), TRUE, TRUE, 'available'),
(17, 'cooked_food', 'Hyderabadi biryani and haleem', 40, 220, DATE_SUB(NOW(), INTERVAL 30 MINUTE), DATE_ADD(NOW(), INTERVAL 3 HOUR), TRUE, FALSE, 'available'),
(18, 'bakery', 'Assorted cakes and pastries', 15, 100, DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_ADD(NOW(), INTERVAL 10 HOUR), FALSE, TRUE, 'available'),
(19, 'cooked_food', 'Chettinad meals with fish curry', 25, 150, DATE_SUB(NOW(), INTERVAL 45 MINUTE), DATE_ADD(NOW(), INTERVAL 5 HOUR), TRUE, FALSE, 'available'),
(20, 'grains', 'Pulses and lentils', 80, 0, DATE_SUB(NOW(), INTERVAL 5 HOUR), DATE_ADD(NOW(), INTERVAL 8760 HOUR), FALSE, TRUE, 'available'),
(1, 'cooked_food', 'Dal makhani and jeera rice', 20, 120, DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_ADD(NOW(), INTERVAL 4 HOUR), TRUE, TRUE, 'reserved'),
(2, 'vegetables', 'Fresh leafy greens', 25, 0, DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_ADD(NOW(), INTERVAL 24 HOUR), TRUE, TRUE, 'available'),
(3, 'packaged_meals', 'Energy bars and protein shakes', 8, 120, DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_ADD(NOW(), INTERVAL 8760 HOUR), FALSE, TRUE, 'available'),
(4, 'cooked_food', 'Subway sandwiches and wraps', 10, 60, DATE_SUB(NOW(), INTERVAL 30 MINUTE), DATE_ADD(NOW(), INTERVAL 6 HOUR), FALSE, FALSE, 'available'),
(5, 'cooked_food', 'Full South Indian meals', 30, 200, DATE_SUB(NOW(), INTERVAL 45 MINUTE), DATE_ADD(NOW(), INTERVAL 5 HOUR), TRUE, TRUE, 'available'),
(6, 'frozen_food', 'Frozen peas and vegetables', 30, 0, DATE_SUB(NOW(), INTERVAL 2 HOUR), DATE_ADD(NOW(), INTERVAL 720 HOUR), TRUE, TRUE, 'available'),
(7, 'cooked_food', 'Momos and thukpa', 12, 80, DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_ADD(NOW(), INTERVAL 5 HOUR), TRUE, FALSE, 'available');

-- 20 Dispatches
INSERT INTO dispatches (batch_id, volunteer_id, ngo_id, pickup_address, pickup_datetime, delivery_address, delivery_datetime, distance_km, dispatch_status) VALUES
(1, 1, 1, 'Taj Palace, Mumbai', DATE_SUB(NOW(), INTERVAL 3 HOUR), 'SOS Children Village', DATE_SUB(NOW(), INTERVAL 1 HOUR), 5.5, 'delivered'),
(2, 2, 2, 'Reliance Fresh, Mumbai', DATE_SUB(NOW(), INTERVAL 2 HOUR), 'Mumbai Smile Shelter', DATE_SUB(NOW(), INTERVAL 30 MINUTE), 3.2, 'delivered'),
(3, 4, 3, 'Grand Marriott, Mumbai', DATE_SUB(NOW(), INTERVAL 4 HOUR), 'Bangalore Food Bank', DATE_SUB(NOW(), INTERVAL 2 HOUR), 12.8, 'delivered'),
(4, 1, 4, 'Shiv Sagar, Mumbai', DATE_SUB(NOW(), INTERVAL 1 HOUR), 'Chennai Hunger Relief', DATE_ADD(NOW(), INTERVAL 1 HOUR), 8.4, 'in_transit'),
(5, 5, 5, 'City Banquet, Mumbai', DATE_SUB(NOW(), INTERVAL 30 MINUTE), 'Pune Old Age Home', DATE_ADD(NOW(), INTERVAL 2 HOUR), 15.2, 'picked_up'),
(6, 6, 6, 'Nature Basket, Mumbai', DATE_ADD(NOW(), INTERVAL 1 HOUR), 'Hyderabad Hope', DATE_ADD(NOW(), INTERVAL 5 HOUR), 18.6, 'assigned'),
(7, 7, 7, 'Cafe Coffee Day, Pune', DATE_SUB(NOW(), INTERVAL 2 HOUR), 'Delhi Food for All', DATE_SUB(NOW(), INTERVAL 30 MINUTE), 6.7, 'delivered'),
(8, 8, 8, 'Leela Palace, Bangalore', DATE_SUB(NOW(), INTERVAL 3 HOUR), 'Kochi Shelter', DATE_SUB(NOW(), INTERVAL 1 HOUR), 9.3, 'delivered'),
(9, 9, 9, 'Big Basket, Bangalore', DATE_SUB(NOW(), INTERVAL 1 HOUR), 'Chandigarh Child Care', DATE_ADD(NOW(), INTERVAL 1 HOUR), 11.5, 'accepted'),
(10, 10, 10, 'Oberoi, Chennai', DATE_ADD(NOW(), INTERVAL 2 HOUR), 'Ahmedabad Women Shelter', DATE_ADD(NOW(), INTERVAL 6 HOUR), 22.1, 'assigned'),
(11, 1, 1, 'Spice Garden, Chennai', DATE_SUB(NOW(), INTERVAL 4 HOUR), 'SOS Children Village', DATE_SUB(NOW(), INTERVAL 2 HOUR), 4.8, 'delivered'),
(12, 2, 2, 'Organic Farms, Hyderabad', DATE_SUB(NOW(), INTERVAL 2 HOUR), 'Mumbai Smile Shelter', DATE_SUB(NOW(), INTERVAL 30 MINUTE), 7.2, 'delivered'),
(13, 4, 3, 'IKEA, Bangalore', DATE_SUB(NOW(), INTERVAL 1 HOUR), 'Bangalore Food Bank', DATE_ADD(NOW(), INTERVAL 1 HOUR), 5.1, 'picked_up'),
(14, 5, 4, 'Punjab Grill, Chandigarh', DATE_ADD(NOW(), INTERVAL 1 HOUR), 'Chennai Hunger Relief', DATE_ADD(NOW(), INTERVAL 4 HOUR), 14.3, 'assigned'),
(15, 6, 5, 'Royal Orchid, Jaipur', DATE_SUB(NOW(), INTERVAL 3 HOUR), 'Pune Old Age Home', DATE_SUB(NOW(), INTERVAL 1 HOUR), 10.7, 'delivered'),
(16, 7, 6, 'Amul Parlour, Ahmedabad', DATE_SUB(NOW(), INTERVAL 2 HOUR), 'Hyderabad Hope', DATE_SUB(NOW(), INTERVAL 30 MINUTE), 8.9, 'delivered'),
(17, 8, 7, 'Biryani Blues, Hyderabad', DATE_SUB(NOW(), INTERVAL 1 HOUR), 'Delhi Food for All', DATE_ADD(NOW(), INTERVAL 2 HOUR), 13.4, 'accepted'),
(18, 9, 8, 'Cakery Shop, Delhi', DATE_ADD(NOW(), INTERVAL 1 HOUR), 'Kochi Shelter', DATE_ADD(NOW(), INTERVAL 5 HOUR), 19.8, 'assigned'),
(19, 10, 9, 'ITC Grand Chola, Chennai', DATE_SUB(NOW(), INTERVAL 4 HOUR), 'Chandigarh Child Care', DATE_SUB(NOW(), INTERVAL 2 HOUR), 6.3, 'delivered'),
(20, 1, 10, 'D-Mart, Pune', DATE_SUB(NOW(), INTERVAL 1 HOUR), 'Ahmedabad Women Shelter', DATE_ADD(NOW(), INTERVAL 1 HOUR), 9.6, 'picked_up');

-- 20 Quality Compliance Logs
INSERT INTO quality_compliance_logs (batch_id, inspector_name, inspection_type, temperature_c, temperature_ok, condition_status, packaging_intact, action_taken, notes) VALUES
(1, 'Inspector A', 'pickup', 4.5, TRUE, 'Accepted', TRUE, 'none', 'Good condition'),
(1, 'Inspector A', 'delivery', 5.2, TRUE, 'Accepted', TRUE, 'accepted_with_caution', 'Delivered on time'),
(2, 'Inspector B', 'pickup', 3.8, TRUE, 'Accepted', TRUE, 'none', 'Fresh items'),
(3, 'Inspector C', 'pickup', 6.1, TRUE, 'Partially_Damaged', TRUE, 'accepted_with_caution', 'Minor bruising'),
(4, 'Inspector D', 'pickup', 4.2, TRUE, 'Accepted', TRUE, 'none', 'Good quality'),
(5, 'Inspector E', 'delivery', 5.5, TRUE, 'Accepted', TRUE, 'accepted_with_caution', 'Hot and fresh'),
(6, 'Inspector A', 'pickup', 3.5, TRUE, 'Accepted', TRUE, 'none', 'Dairy items OK'),
(7, 'Inspector B', 'delivery', 4.8, TRUE, 'Accepted', TRUE, 'accepted_with_caution', 'Delivered safely'),
(8, 'Inspector C', 'pickup', 5.0, TRUE, 'Accepted', TRUE, 'none', 'Ready for transport'),
(9, 'Inspector D', 'delivery', 6.3, FALSE, 'Spoiled', FALSE, 'rejected', 'Temperature breach'),
(10, 'Inspector E', 'pickup', 4.0, TRUE, 'Accepted', TRUE, 'none', 'Good condition'),
(11, 'Inspector A', 'delivery', 4.6, TRUE, 'Accepted', TRUE, 'accepted_with_caution', 'On time delivery'),
(12, 'Inspector B', 'pickup', 3.9, TRUE, 'Accepted', TRUE, 'none', 'Fresh produce'),
(13, 'Inspector C', 'delivery', 5.1, TRUE, 'Partially_Damaged', TRUE, 'accepted_with_caution', 'Slight damage'),
(14, 'Inspector D', 'pickup', 4.3, TRUE, 'Accepted', TRUE, 'none', 'Good quality'),
(15, 'Inspector E', 'delivery', 4.7, TRUE, 'Accepted', TRUE, 'accepted_with_caution', 'Delivered well'),
(16, 'Inspector A', 'pickup', 3.2, TRUE, 'Accepted', TRUE, 'none', 'Cold chain intact'),
(17, 'Inspector B', 'delivery', 5.8, TRUE, 'Accepted', TRUE, 'accepted_with_caution', 'Acceptable'),
(18, 'Inspector C', 'pickup', 4.1, TRUE, 'Accepted', TRUE, 'none', 'Ready to go'),
(19, 'Inspector D', 'delivery', 4.4, TRUE, 'Accepted', TRUE, 'accepted_with_caution', 'Good delivery');

-- ============================================================
-- Data input complete
-- ============================================================
