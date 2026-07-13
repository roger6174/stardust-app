-- ═══════════════════════════════════════════════════════
-- STARDUST VAULT — FINAL MASTER PRODUCTION SYNC (APRIL 2026)
-- ═══════════════════════════════════════════════════════
-- This script is "Idempotent" (Safe to run multiple times).

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- 1. CORE USER SYSTEM (Ensuring Base Exists)
CREATE TABLE IF NOT EXISTS `users` (
  `user_id` int NOT NULL AUTO_INCREMENT,
  `full_name` varchar(255) NOT NULL,
  `email` varchar(255) DEFAULT NULL,
  `mobile` varchar(20) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('USER','ADMIN') DEFAULT 'USER',
  `is_verified` tinyint(1) DEFAULT '0',
  `has_completed_onboarding` tinyint(1) DEFAULT '0',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `mobile` (`mobile`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. AUTH & OTP SYSTEM
CREATE TABLE IF NOT EXISTS `otp_codes` (
  `otp_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `otp_code` varchar(255) NOT NULL,
  `channel` enum('EMAIL','WHATSAPP','SMS') NOT NULL,
  `expires_at` datetime NOT NULL,
  `is_used` tinyint(1) DEFAULT '0',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`otp_id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `pending_registrations` (
  `registration_id` int NOT NULL AUTO_INCREMENT,
  `mobile` varchar(20) NOT NULL,
  `email` varchar(255) DEFAULT NULL,
  `otp_hash` varchar(255) NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`registration_id`),
  UNIQUE KEY `mobile` (`mobile`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. SAFETY PROCEDURE FOR COLUMN UPDATES
DROP PROCEDURE IF EXISTS AddColumnIfMissing;
DELIMITER //
CREATE PROCEDURE AddColumnIfMissing(
    IN p_table_name VARCHAR(64),
    IN p_col_name VARCHAR(64),
    IN p_col_type VARCHAR(255)
)
BEGIN
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = p_table_name
        AND COLUMN_NAME = p_col_name
    ) THEN
        SET @sql = CONCAT('ALTER TABLE `', p_table_name, '` ADD COLUMN `', p_col_name, '` ', p_col_type);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END //
DELIMITER ;

-- Apply Column Deltas
CALL AddColumnIfMissing('users', 'security_code', 'varchar(255) DEFAULT NULL');
CALL AddColumnIfMissing('users', 'last_login_at', 'datetime DEFAULT CURRENT_TIMESTAMP');
CALL AddColumnIfMissing('users', 'inactivity_reminder_count', 'int DEFAULT 0');
CALL AddColumnIfMissing('users', 'succession_status', "enum('NONE','RED','ORANGE','GREEN') DEFAULT 'NONE'");
CALL AddColumnIfMissing('users', 'inactivity_trigger_period', 'int DEFAULT 6');
CALL AddColumnIfMissing('users', 'reminder_interval', 'int DEFAULT 3');
CALL AddColumnIfMissing('users', 'nominee_limit', 'int DEFAULT 2');

-- 4. VAULT & CATEGORIES SYSTEM
CREATE TABLE IF NOT EXISTS `categories` (
  `category_id` int NOT NULL AUTO_INCREMENT,
  `category_key` varchar(50) UNIQUE NOT NULL,
  `label` varchar(100) NOT NULL,
  `parent_key` varchar(50) DEFAULT NULL,
  `icon` varchar(50) DEFAULT 'folder',
  PRIMARY KEY (`category_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `assets` (
  `asset_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `category` varchar(50) NOT NULL,
  `title` varchar(255) NOT NULL,
  `metadata` longtext,
  `is_encrypted` tinyint(1) DEFAULT '1',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`asset_id`),
  CONSTRAINT `assets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. NOMINEES & RECOVERY
CREATE TABLE IF NOT EXISTS `nominees` (
  `nominee_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `full_name` varchar(255) NOT NULL,
  `mobile` varchar(20) NOT NULL,
  `relationship` varchar(100) NOT NULL,
  `is_verified` tinyint(1) DEFAULT '0',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`nominee_id`),
  CONSTRAINT `nominees_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CALL AddColumnIfMissing('nominees', 'linked_user_id', 'int DEFAULT NULL');
CALL AddColumnIfMissing('nominees', 'is_email_verified', 'tinyint(1) DEFAULT 0');
CALL AddColumnIfMissing('nominees', 'is_phone_verified', 'tinyint(1) DEFAULT 0');

CREATE TABLE IF NOT EXISTS `security_questions` (
  `question_id` int NOT NULL AUTO_INCREMENT,
  `question` varchar(255) NOT NULL,
  PRIMARY KEY (`question_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `user_security_answers` (
  `answer_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `question_id` int NOT NULL,
  `answer_hash` varchar(255) NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`answer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. RE-SEED CATEGORIES (Hierarchical Master List)
TRUNCATE TABLE `categories`;

INSERT INTO `categories` (category_key, label, parent_key, icon) VALUES
('ids_personal',  'Identity & Personal Records', NULL, 'person_outline'),
('digital',       'Digital Assets & Profiles',   NULL, 'devices'),
('home_property', 'Real Estate & Valuables',     NULL, 'home'),
('financial',     'Financial Accounts & Assets', NULL, 'payments'),
('legal',         'Legal Matters & Contracts',   NULL, 'gavel'),
('health',        'Health Records & Wellness',   NULL, 'medical_services'),
('family',        'Family & Inner Circle',       NULL, 'groups'),
('aging',         'Future Planning & Care',      NULL, 'elderly'),
('after_gone',    'Legacy & Final Wishes',       NULL, 'auto_awesome');

-- Subcategories (Identity)
INSERT INTO `categories` (category_key, label, parent_key, icon) VALUES
('ids_vital',         'Core Identity Documents',   'ids_personal', 'badge'),
('contact_info',      'Primary Contact Details',     'ids_personal', 'contact_phone'),
('education',         'Academic Records',            'ids_personal', 'school'),
('military',          'Military Service History',   'ids_personal', 'military_tech'),
('personal_misc',     'Other Personal Items',       'ids_personal', 'more_horiz');

-- Subcategories (Digital)
INSERT INTO `categories` (category_key, label, parent_key, icon) VALUES
('passwords',         'Account Credentials',           'digital', 'password'),
('email_accounts',    'Email Platforms',                'digital', 'email'),
('devices',           'Hardware & Devices',            'digital', 'laptop'),
('social_media',      'Social Networks',               'digital', 'share'),
('shopping',          'eCommerce & Shopping',          'digital', 'shopping_cart');

-- Subcategories (Financial)
INSERT INTO `categories` (category_key, label, parent_key, icon) VALUES
('banking',           'Bank Accounts & Cash',          'financial', 'account_balance'),
('cards',             'Credit & Debit Cards',          'financial', 'credit_card'),
('loans',             'Outstanding Loans',             'financial', 'money_off'),
('life_insurance',    'Life Protection Policies',      'financial', 'volunteer_activism');

-- 7. DEFAULT DATA
INSERT IGNORE INTO `security_questions` (question, question_id) VALUES 
('What was your first pet''s name?', 1),
('In what city were you born?', 2),
('What was the name of your first school?', 3),
('What was your childhood nickname?', 4),
('What is your mother''s maiden name?', 5);

DROP PROCEDURE AddColumnIfMissing;
SET FOREIGN_KEY_CHECKS = 1;
COMMIT;
