-- ============================================================
-- PROJECT: Surplus Food Rescue & NGO Logistics Management
-- Database : food_rescue_db
-- ============================================================
CREATE DATABASE IF NOT EXISTS food_rescue_db;
USE food_rescue_db;

-- ============================================================
-- CORE TABLES (7 tables for moderate complexity)
-- ============================================================

-- TABLE 1: Donors
CREATE TABLE donors (
    donor_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    donor_name      VARCHAR(150) NOT NULL,
    donor_type      ENUM('restaurant','supermarket','banquet_hall','caterer','farm','bakery','hotel') NOT NULL,
    contact_person  VARCHAR(100) NOT NULL,
    email           VARCHAR(180) UNIQUE NOT NULL,
    phone           VARCHAR(20)  NOT NULL,
    city            VARCHAR(100) NOT NULL,
    is_verified     BOOLEAN DEFAULT TRUE,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- TABLE 2: NGOs
CREATE TABLE ngos (
    ngo_id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ngo_name            VARCHAR(150) NOT NULL,
    ngo_type            ENUM('orphanage','shelter','community_kitchen','old_age_home','school','women_shelter') NOT NULL,
    contact_person      VARCHAR(100) NOT NULL,
    email               VARCHAR(180) UNIQUE NOT NULL,
    phone               VARCHAR(20)  NOT NULL,
    city                VARCHAR(100) NOT NULL,
    daily_capacity_meals INT UNSIGNED NOT NULL,
    has_refrigeration   BOOLEAN DEFAULT FALSE,
    is_verified         BOOLEAN DEFAULT FALSE,
    created_at          DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- TABLE 3: Volunteers
CREATE TABLE volunteers (
    volunteer_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name          VARCHAR(100) NOT NULL,
    email              VARCHAR(180) UNIQUE NOT NULL,
    phone              VARCHAR(20)  NOT NULL,
    vehicle_type       ENUM('bike','scooter','van','truck','car') NOT NULL,
    vehicle_capacity_kg DECIMAL(6,2) NOT NULL,
    city               VARCHAR(100) NOT NULL,
    is_available       BOOLEAN DEFAULT TRUE,
    rating_average     DECIMAL(3,2) DEFAULT 0.00,
    total_deliveries   INT UNSIGNED DEFAULT 0,
    created_at         DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- TABLE 4: Donation_Batches
CREATE TABLE donation_batches (
    batch_id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    donor_id              INT UNSIGNED NOT NULL,
    food_category         ENUM('packaged_meals','raw_produce','dairy','bakery','cooked_food','fruits','vegetables','grains','frozen_food') NOT NULL,
    food_description      VARCHAR(200) NOT NULL,
    quantity_kg           DECIMAL(8,2) NOT NULL,
    quantity_servings     INT UNSIGNED NOT NULL,
    preparation_datetime  DATETIME NOT NULL,
    expiry_datetime       DATETIME NOT NULL,
    requires_refrigeration BOOLEAN DEFAULT FALSE,
    is_vegetarian         BOOLEAN DEFAULT TRUE,
    status                ENUM('available','reserved','dispatched','delivered','expired','cancelled') DEFAULT 'available',
    created_at            DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_batch_donor FOREIGN KEY (donor_id) REFERENCES donors(donor_id) ON DELETE CASCADE
);

-- TABLE 5: NGO_Demands
CREATE TABLE ngo_demands (
    demand_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ngo_id          INT UNSIGNED NOT NULL,
    food_category   ENUM('packaged_meals','raw_produce','dairy','bakery','cooked_food','fruits','vegetables','grains','frozen_food') NOT NULL,
    required_servings INT UNSIGNED NOT NULL,
    priority        ENUM('critical','high','medium','low') DEFAULT 'medium',
    is_active       BOOLEAN DEFAULT TRUE,
    requested_date  DATE NOT NULL,
    CONSTRAINT fk_demand_ngo FOREIGN KEY (ngo_id) REFERENCES ngos(ngo_id) ON DELETE CASCADE
);

-- TABLE 6: Dispatches
CREATE TABLE dispatches (
    dispatch_id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    batch_id              INT UNSIGNED NOT NULL,
    volunteer_id          INT UNSIGNED NOT NULL,
    ngo_id                INT UNSIGNED NOT NULL,
    pickup_address        VARCHAR(300) NOT NULL,
    pickup_datetime       DATETIME NOT NULL,
    delivery_address      VARCHAR(300) NOT NULL,
    delivery_datetime     DATETIME NOT NULL,
    actual_delivery_datetime DATETIME,
    distance_km           DECIMAL(6,2),
    dispatch_status       ENUM('assigned','accepted','picked_up','in_transit','delivered','failed','cancelled') DEFAULT 'assigned',
    notes                 TEXT,
    created_at            DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_dispatch_batch FOREIGN KEY (batch_id) REFERENCES donation_batches(batch_id) ON DELETE CASCADE,
    CONSTRAINT fk_dispatch_volunteer FOREIGN KEY (volunteer_id) REFERENCES volunteers(volunteer_id) ON DELETE CASCADE,
    CONSTRAINT fk_dispatch_ngo FOREIGN KEY (ngo_id) REFERENCES ngos(ngo_id) ON DELETE CASCADE
);

-- TABLE 7: Quality_Compliance_Logs
CREATE TABLE quality_compliance_logs (
    log_id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    batch_id        INT UNSIGNED NOT NULL,
    inspector_name  VARCHAR(100) NOT NULL,
    inspection_type ENUM('pickup','delivery') NOT NULL,
    temperature_c   DECIMAL(4,1) NOT NULL,
    temperature_ok  BOOLEAN NOT NULL,
    condition_status ENUM('Accepted','Partially_Damaged','Spoiled','Rejected') NOT NULL,
    packaging_intact BOOLEAN NOT NULL,
    action_taken    ENUM('none','discarded','rejected','accepted_with_caution','returned') DEFAULT 'none',
    notes           TEXT,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_qcl_batch FOREIGN KEY (batch_id) REFERENCES donation_batches(batch_id) ON DELETE CASCADE
);

-- ============================================================
-- STORED PROCEDURE: sp_MatchDonationToNGO
-- Simplified: Matches a food batch to nearest verified NGO
-- ============================================================
DELIMITER $$

CREATE PROCEDURE sp_MatchDonationToNGO(IN p_batch_id INT UNSIGNED)
BEGIN
    DECLARE v_batch_status VARCHAR(20);
    DECLARE v_food_category VARCHAR(50);
    DECLARE v_quantity_servings INT;
    DECLARE v_expiry DATETIME;
    DECLARE v_donor_city VARCHAR(100);

    DECLARE v_matched_ngo_id INT DEFAULT NULL;
    DECLARE v_matched_ngo_name VARCHAR(150);

    SELECT status, food_category, quantity_servings, expiry_datetime, city
    INTO v_batch_status, v_food_category, v_quantity_servings, v_expiry, v_donor_city
    FROM donation_batches
    WHERE batch_id = p_batch_id;

    IF v_batch_status != 'available' THEN
        SELECT CONCAT('ERROR: Batch is ', v_batch_status) AS result;
        LEAVE proc_end;
    END IF;

    IF NOW() >= v_expiry THEN
        UPDATE donation_batches SET status = 'expired' WHERE batch_id = p_batch_id;
        SELECT 'ERROR: Batch expired' AS result;
        LEAVE proc_end;
    END IF;

    SELECT ngo_id, ngo_name INTO v_matched_ngo_id, v_matched_ngo_name
    FROM ngos
    WHERE is_verified = TRUE
      AND city = v_donor_city
      AND has_refrigeration = (SELECT requires_refrigeration FROM donation_batches WHERE batch_id = p_batch_id)
      AND daily_capacity_meals >= v_quantity_servings
    ORDER BY daily_capacity_meals DESC
    LIMIT 1;

    IF v_matched_ngo_id IS NOT NULL THEN
        SELECT 'SUCCESS' AS result,
               p_batch_id AS batch_id,
               v_matched_ngo_id AS ngo_id,
               v_matched_ngo_name AS ngo_name,
               NOW() AS matched_at;
    ELSE
        SELECT 'INFO: No matching NGO found in same city' AS result;
    END IF;

    SET done = FALSE;
END$$

DELIMITER ;

-- ============================================================
-- STORED PROCEDURE: sp_CompleteDispatch
-- ============================================================
DELIMITER $$

CREATE PROCEDURE sp_CompleteDispatch(
    IN p_dispatch_id INT UNSIGNED,
    IN p_actual_delivery DATETIME,
    IN p_temperature_c DECIMAL(4,1),
    IN p_condition_status VARCHAR(50)
)
BEGIN
    DECLARE v_batch_id INT UNSIGNED;
    DECLARE v_volunteer_id INT UNSIGNED;

    START TRANSACTION;

    SELECT batch_id, volunteer_id
    INTO v_batch_id, v_volunteer_id
    FROM dispatches WHERE dispatch_id = p_dispatch_id FOR UPDATE;

    UPDATE dispatches
    SET actual_delivery_datetime = p_actual_delivery,
        dispatch_status = 'delivered'
    WHERE dispatch_id = p_dispatch_id;

    UPDATE donation_batches
    SET status = 'delivered'
    WHERE batch_id = v_batch_id;

    UPDATE volunteers
    SET total_deliveries = total_deliveries + 1,
        is_available = TRUE
    WHERE volunteer_id = v_volunteer_id;

    INSERT INTO quality_compliance_logs (
        batch_id, inspector_name, inspection_type,
        temperature_c, temperature_ok, condition_status,
        packaging_intact, action_taken
    ) VALUES (
        v_batch_id, 'system', 'delivery',
        p_temperature_c, (p_temperature_c BETWEEN -5 AND 60),
        p_condition_status, TRUE,
        CASE WHEN p_condition_status IN ('Accepted','Partially_Damaged') THEN 'accepted_with_caution' ELSE 'rejected' END
    );

    COMMIT;
    SELECT 'SUCCESS: Dispatch completed' AS result;
END$$

DELIMITER ;

-- ============================================================
-- TRIGGER: trg_CheckFoodExpiry
-- Auto-flags expired or nearly expired food
-- ============================================================
DELIMITER $$

CREATE TRIGGER trg_CheckFoodExpiry
BEFORE UPDATE ON donation_batches
FOR EACH ROW
BEGIN
    DECLARE v_remaining_minutes INT;

    IF NEW.status IN ('available','reserved') THEN
        SET v_remaining_minutes = TIMESTAMPDIFF(MINUTE, NOW(), NEW.expiry_datetime);

        IF v_remaining_minutes <= 0 THEN
            SET NEW.status = 'expired';
        ELSEIF v_remaining_minutes <= 120 THEN
            SET NEW.status = 'expired';
        END IF;
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- TRIGGER 2: trg_AfterDispatchAssigned
-- Auto-reserves batch and notifies volunteer
-- ============================================================
DELIMITER $$

CREATE TRIGGER trg_AfterDispatchAssigned
AFTER INSERT ON dispatches
FOR EACH ROW
BEGIN
    IF NEW.dispatch_status = 'assigned' THEN
        UPDATE donation_batches
        SET status = 'reserved'
        WHERE batch_id = NEW.batch_id AND status = 'available';

        UPDATE volunteers
        SET is_available = FALSE
        WHERE volunteer_id = NEW.volunteer_id;
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- VIEWS (Simplified)
-- ============================================================

-- VIEW 1: Monthly Impact Summary
CREATE OR REPLACE VIEW vw_MonthlyImpact AS
SELECT
    MONTH(created_at) AS month,
    YEAR(created_at) AS year,
    COUNT(DISTINCT dispatch_id) AS total_dispatches,
    COUNT(DISTINCT batch_id) AS batches_delivered,
    SUM(distance_km) AS total_km
FROM dispatches
WHERE dispatch_status = 'delivered'
GROUP BY YEAR(created_at), MONTH(created_at);

-- VIEW 2: Top Donors
CREATE OR REPLACE VIEW vw_TopDonors AS
SELECT
    d.donor_id,
    d.donor_name,
    d.city,
    COUNT(DISTINCT b.batch_id) AS total_batches,
    SUM(b.quantity_servings) AS total_servings
FROM donors d
LEFT JOIN donation_batches b ON d.donor_id = b.donor_id
GROUP BY d.donor_id, d.donor_name, d.city
ORDER BY total_servings DESC;

-- VIEW 3: Volunteer Performance
CREATE OR REPLACE VIEW vw_VolunteerPerformance AS
SELECT
    v.volunteer_id,
    v.full_name,
    v.vehicle_type,
    v.city,
    COUNT(d.dispatch_id) AS total_trips,
    SUM(d.distance_km) AS total_km,
    v.rating_average,
    v.total_deliveries
FROM volunteers v
LEFT JOIN dispatches d ON v.volunteer_id = d.volunteer_id
GROUP BY v.volunteer_id, v.full_name, v.vehicle_type, v.city, v.rating_average, v.total_deliveries;

-- VIEW 4: Urgent Expiry Alert
CREATE OR REPLACE VIEW vw_ExpiryAlert AS
SELECT
    batch_id,
    donor_id,
    food_category,
    quantity_servings,
    expiry_datetime,
    TIMESTAMPDIFF(MINUTE, NOW(), expiry_datetime) AS minutes_left,
    CASE
        WHEN TIMESTAMPDIFF(MINUTE, NOW(), expiry_datetime) <= 0 THEN 'Expired'
        WHEN TIMESTAMPDIFF(MINUTE, NOW(), expiry_datetime) <= 120 THEN 'Critical'
        ELSE 'Warning'
    END AS urgency
FROM donation_batches
WHERE status IN ('available','reserved')
  AND expiry_datetime <= DATE_ADD(NOW(), INTERVAL 4 HOUR);

-- ============================================================
-- INDEXES (Simple)
-- ============================================================
CREATE INDEX idx_batch_status ON donation_batches(status, expiry_datetime);
CREATE INDEX idx_dispatch_status ON dispatches(dispatch_status);

-- ============================================================
-- ACID TRANSACTION EXAMPLE
-- ============================================================
START TRANSACTION;

-- Lock batch to prevent double-claiming
SELECT batch_id, status
FROM donation_batches
WHERE batch_id = 1 AND status = 'available'
FOR UPDATE;

-- Reserve the batch
UPDATE donation_batches
SET status = 'reserved'
WHERE batch_id = 1 AND status = 'available';

-- Assign volunteer
UPDATE volunteers
SET is_available = FALSE
WHERE volunteer_id = 1 AND is_available = TRUE;

-- Create dispatch
INSERT INTO dispatches (batch_id, volunteer_id, ngo_id, pickup_address, pickup_datetime,
                        delivery_address, delivery_datetime, dispatch_status)
VALUES (1, 1, 1, '123 Main St', NOW(), '456 NGO St', DATE_ADD(NOW(), INTERVAL 2 HOUR), 'assigned');

COMMIT;

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
-- SAMPLE QUERIES FOR COURSE
-- ============================================================

-- Q1: Available food batches expiring soon
SELECT batch_id, donor_id, food_category, quantity_servings,
       expiry_datetime,
       TIMESTAMPDIFF(MINUTE, NOW(), expiry_datetime) AS minutes_left
FROM donation_batches
WHERE status = 'available'
  AND expiry_datetime BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 4 HOUR)
ORDER BY expiry_datetime;

-- Q2: Monthly impact
SELECT * FROM vw_MonthlyImpact;

-- Q3: Top donors
SELECT * FROM vw_TopDonors;

-- Q4: Volunteer leaderboard
SELECT * FROM vw_VolunteerPerformance;

-- Q5: Urgent alerts
SELECT * FROM vw_ExpiryAlert;

-- Q6: Call stored procedure
-- CALL sp_MatchDonationToNGO(1);

-- Q7: Food category summary
SELECT
    food_category,
    COUNT(*) AS total_batches,
    SUM(quantity_servings) AS total_servings,
    SUM(CASE WHEN status = 'delivered' THEN quantity_servings ELSE 0 END) AS delivered,
    SUM(CASE WHEN status = 'expired' THEN quantity_servings ELSE 0 END) AS expired
FROM donation_batches
GROUP BY food_category;

-- Q8: NGO demand vs supply
SELECT
    n.ngo_name,
    n.city,
    COUNT(DISTINCT d.demand_id) AS active_demands,
    SUM(d.required_servings) AS total_needed,
    COUNT(DISTINCT dis.batch_id) AS batches_received
FROM ngos n
LEFT JOIN ngo_demands d ON n.ngo_id = d.ngo_id AND d.is_active = TRUE
LEFT JOIN dispatches dis ON n.ngo_id = dis.ngo_id AND dis.dispatch_status = 'delivered'
GROUP BY n.ngo_id, n.ngo_name, n.city;

-- Q9: Cold chain compliance
SELECT
    inspection_type,
    COUNT(*) AS total_checks,
    SUM(CASE WHEN temperature_ok = TRUE THEN 1 ELSE 0 END) AS compliant,
    ROUND(SUM(temperature_ok) / COUNT(*) * 100, 1) AS compliance_pct
FROM quality_compliance_logs
GROUP BY inspection_type;

-- Q10: Verify row counts
SELECT 'donors' AS tbl, COUNT(*) FROM donors
UNION ALL SELECT 'ngos', COUNT(*) FROM ngos
UNION ALL SELECT 'volunteers', COUNT(*) FROM volunteers
UNION ALL SELECT 'donation_batches', COUNT(*) FROM donation_batches
UNION ALL SELECT 'ngo_demands', COUNT(*) FROM ngo_demands
UNION ALL SELECT 'dispatches', COUNT(*) FROM dispatches
UNION ALL SELECT 'quality_logs', COUNT(*) FROM quality_compliance_logs;

-- ============================================================
SELECT 'Surplus Food Rescue System - Moderate Level Complete!' AS status;
-- ============================================================
