-- ============================================================================
-- STARDUST VAULT — SUCCESSION & INACTIVITY MIGRATION
-- Run this in MySQL (RDS via Termius) to enable automated legacy protocol.
-- Purpose: Add inactivity tracking, pulse counts, and status gates.
-- ============================================================================

-- 1. Sync users table with the latest features
ALTER TABLE users ADD COLUMN IF NOT EXISTS `last_login_at` datetime DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE users ADD COLUMN IF NOT EXISTS `inactivity_reminder_count` int DEFAULT '0';
ALTER TABLE users ADD COLUMN IF NOT EXISTS `succession_status` enum('NONE','RED','ORANGE','GREEN') DEFAULT 'NONE';
ALTER TABLE users ADD COLUMN IF NOT EXISTS `inactivity_trigger_period` int DEFAULT '6'; -- Default 6 months
ALTER TABLE users ADD COLUMN IF NOT EXISTS `reminder_interval` int DEFAULT '3';          -- Default every 3 months
ALTER TABLE users ADD COLUMN IF NOT EXISTS `nominee_limit` int DEFAULT '2';               -- Default 2 nominees
ALTER TABLE users ADD COLUMN IF NOT EXISTS `security_code` varchar(255) DEFAULT NULL;

-- 2. Create Audit Logs for security tracking
CREATE TABLE IF NOT EXISTS `audit_logs` (
  `log_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `action` varchar(255) NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `device_info` text,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`log_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `audit_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Update nominees table for verification and linkage
ALTER TABLE nominees ADD COLUMN IF NOT EXISTS `is_email_verified` tinyint(1) DEFAULT '0';
ALTER TABLE nominees ADD COLUMN IF NOT EXISTS `is_phone_verified` tinyint(1) DEFAULT '0';
ALTER TABLE nominees ADD COLUMN IF NOT EXISTS `linked_user_id` int DEFAULT NULL;

-- 4. Create succession_requests table
CREATE TABLE IF NOT EXISTS `succession_requests` (
  `request_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `nominee_id` int NOT NULL,
  `token` varchar(255) NOT NULL,
  `status` enum('PENDING','UNDER_REVIEW','APPROVED','REJECTED') DEFAULT 'PENDING',
  `proof_url` varchar(512) DEFAULT NULL,
  `admin_notes` text,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`request_id`),
  UNIQUE KEY `token` (`token`),
  KEY `user_id` (`user_id`),
  KEY `nominee_id` (`nominee_id`),
  CONSTRAINT `succession_requests_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `succession_requests_ibfk_2` FOREIGN KEY (`nominee_id`) REFERENCES `nominees` (`nominee_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. Create vault_policies table
CREATE TABLE IF NOT EXISTS `vault_policies` (
  `policy_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `inactivity_trigger_period` int NOT NULL,
  `reminder_interval` int NOT NULL,
  `nominee_limit` int NOT NULL,
  `admin_verification_required` tinyint(1) DEFAULT '1',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`policy_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed default policy
INSERT IGNORE INTO vault_policies (name, inactivity_trigger_period, reminder_interval, nominee_limit, admin_verification_required)
VALUES ('Standard Vault Policy', 6, 3, 2, 1);

-- ============================================================================
-- DONE! Database is now ready for InactivityService.js
-- ============================================================================
