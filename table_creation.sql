-- ============================================================
-- FILE: table_creation.sql
-- PROJECT: Surplus Food Rescue & NGO Logistics Management
-- Database : food_rescue_db
-- ============================================================
DROP DATABASE IF EXISTS food_rescue_db;
CREATE DATABASE food_rescue_db;
USE food_rescue_db;

-- ============================================================
-- CORE TABLES
-- ============================================================

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
-- STORED PROCEDURES
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
    END IF;

    IF NOW() >= v_expiry THEN
        UPDATE donation_batches SET status = 'expired' WHERE batch_id = p_batch_id;
        SELECT 'ERROR: Batch expired' AS result;
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
END$$

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
-- TRIGGERS
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
-- VIEWS
-- ============================================================
CREATE OR REPLACE VIEW vw_MonthlyImpact AS
SELECT MONTH(created_at) AS month, YEAR(created_at) AS year,
       COUNT(DISTINCT dispatch_id) AS total_dispatches,
       COUNT(DISTINCT batch_id) AS batches_delivered,
       SUM(distance_km) AS total_km
FROM dispatches
WHERE dispatch_status = 'delivered'
GROUP BY YEAR(created_at), MONTH(created_at);

CREATE OR REPLACE VIEW vw_TopDonors AS
SELECT d.donor_id, d.donor_name, d.city,
       COUNT(DISTINCT b.batch_id) AS total_batches,
       SUM(b.quantity_servings) AS total_servings
FROM donors d
LEFT JOIN donation_batches b ON d.donor_id = b.donor_id
GROUP BY d.donor_id, d.donor_name, d.city
ORDER BY total_servings DESC;

CREATE OR REPLACE VIEW vw_VolunteerPerformance AS
SELECT v.volunteer_id, v.full_name, v.vehicle_type, v.city,
       COUNT(d.dispatch_id) AS total_trips,
       SUM(d.distance_km) AS total_km,
       v.rating_average, v.total_deliveries
FROM volunteers v
LEFT JOIN dispatches d ON v.volunteer_id = d.volunteer_id
GROUP BY v.volunteer_id, v.full_name, v.vehicle_type, v.city, v.rating_average, v.total_deliveries;

CREATE OR REPLACE VIEW vw_ExpiryAlert AS
SELECT batch_id, donor_id, food_category, quantity_servings,
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
-- INDEXES
-- ============================================================
CREATE INDEX idx_batch_status ON donation_batches(status, expiry_datetime);
CREATE INDEX idx_dispatch_status ON dispatches(dispatch_status);

-- ============================================================
-- Table creation complete
-- ============================================================
