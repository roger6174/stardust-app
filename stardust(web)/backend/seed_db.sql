USE stardust;

-- 🛡️ Insert Default Vault Policy (Critical for user registration)
INSERT IGNORE INTO vault_policies (policy_id, name, inactivity_trigger_period, reminder_interval, nominee_limit)
VALUES (1, 'Standard Protection', 9, 3, 2);

-- 🔐 Insert Default Security Questions (If not already present)
INSERT IGNORE INTO security_questions (question) VALUES 
('What was the name of your first pet?'),
('What is your mother''s maiden name?'),
('What was the name of your first school?'),
('In which city were you born?'),
('What is your favorite book?');

-- ✅ Verification queries (to check if user creation is possible)
SELECT 'SUCCESS: Default Policy Exists' as Status FROM vault_policies WHERE policy_id = 1;
SELECT count(*) as Total_Questions FROM security_questions;
