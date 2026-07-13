-- ============================================================================
-- STARDUST VAULT — DATABASE MIGRATION
-- Run this in MySQL (RDS via Termius)
-- Date: 2026-04-04
-- Purpose: Normalize category names + add categories reference table
-- ============================================================================

-- STEP 1: Create categories reference table
CREATE TABLE IF NOT EXISTS categories (
    category_key VARCHAR(50) PRIMARY KEY,
    label VARCHAR(100) NOT NULL,
    icon VARCHAR(50) DEFAULT NULL,
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- STEP 2: Seed all 11 categories
INSERT IGNORE INTO categories (category_key, label, icon, sort_order) VALUES
('real_estate',     'Real Estate',       'home_work',              1),
('banking',         'Banking',           'account_balance',        2),
('cards',           'Cards',             'credit_card',            3),
('investments',     'Investments',       'trending_up',            4),
('vehicles',        'Vehicles',          'directions_car',         5),
('collectibles',    'Collectibles',      'diamond',                6),
('insurance',       'Insurance',         'health_and_safety',      7),
('passwords',       'Passwords',         'lock',                   8),
('legal_documents', 'Legal Documents',   'gavel',                  9),
('contacts',        'Contacts',          'contacts',              10),
('others',          'Others',            'folder_special',        11);

-- STEP 3: Change category column from ENUM to VARCHAR(50)
-- First check current column type
-- SHOW COLUMNS FROM assets LIKE 'category';

ALTER TABLE assets MODIFY COLUMN category VARCHAR(50) NOT NULL;

-- STEP 4: Normalize all existing category values
-- Run these UPDATE statements to fix inconsistencies

UPDATE assets SET category = 'cards'           WHERE category IN ('Credit Card', 'credit_card', 'CREDIT_CARD', 'Card');
UPDATE assets SET category = 'banking'         WHERE category IN ('Bank Account', 'bank_account', 'BANK_ACCOUNT', 'Banking');
UPDATE assets SET category = 'insurance'       WHERE category IN ('Insurance', 'INSURANCE', 'insurance_policy');
UPDATE assets SET category = 'real_estate'     WHERE category IN ('Property', 'PROPERTY', 'Real Estate', 'real_estate');
UPDATE assets SET category = 'legal_documents' WHERE category IN ('Legal Document', 'LEGAL', 'Legal', 'legal');
UPDATE assets SET category = 'contacts'        WHERE category IN ('Nominee', 'NOMINEE', 'Contact', 'CONTACT');
UPDATE assets SET category = 'passwords'       WHERE category IN ('Password', 'PASSWORD', 'password');
UPDATE assets SET category = 'investments'     WHERE category IN ('Investment', 'INVESTMENT', 'Investments');
UPDATE assets SET category = 'vehicles'        WHERE category IN ('Vehicle', 'VEHICLE', 'Vehicles');
UPDATE assets SET category = 'collectibles'    WHERE category IN ('Collectible', 'COLLECTIBLE', 'Collectibles');
UPDATE assets SET category = 'others'          WHERE category IN ('Others', 'OTHERS', 'OTHER', 'Miscellaneous');

-- STEP 5: Verify the migration
SELECT category, COUNT(*) as count FROM assets GROUP BY category ORDER BY category;
SELECT * FROM categories ORDER BY sort_order;

-- ============================================================================
-- DONE! All categories are now lowercase snake_case.
-- The backend vaultController.js will use these exact keys.
-- ============================================================================
