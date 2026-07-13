-- ============================================================================
-- STARDUST VAULT: HIERARCHICAL MIGRATION SCRIPT (UNIQUIFIED LABELS)
-- ============================================================================

-- STEP 1: SCHEMA UPDATES
ALTER TABLE categories ADD COLUMN IF NOT EXISTS parent_key VARCHAR(50) AFTER category_key;

-- STEP 2: CLEANUP OLD REFERENCE DATA
TRUNCATE TABLE categories;

-- STEP 3: SEED PARENT CATEGORIES (9 Groups)
INSERT INTO categories (category_key, label, parent_key, icon) VALUES
('ids_personal',  'Identity & Personal Records', NULL, 'person_outline'),
('digital',       'Digital Assets & Profiles',   NULL, 'devices'),
('home_property', 'Real Estate & Valuables',     NULL, 'home'),
('financial',     'Financial Accounts & Assets', NULL, 'payments'),
('legal',         'Legal Matters & Contracts',   NULL, 'gavel'),
('health',        'Health Records & Wellness',   NULL, 'medical_services'),
('family',        'Family & Inner Circle',       NULL, 'groups'),
('aging',         'Future Planning & Care',      NULL, 'elderly'),
('after_gone',    'Legacy & Final Wishes',       NULL, 'auto_awesome');

-- STEP 4: SEED SUBCATEGORIES (85 Entries)

-- 4.1 Identity & Personal Records
INSERT INTO categories (category_key, label, parent_key, icon) VALUES
('ids_vital',         'Core Identity Documents',   'ids_personal', 'badge'),
('contact_info',      'Primary Contact Details',     'ids_personal', 'contact_phone'),
('charities',         'Philanthropy & Causes',       'ids_personal', 'favorite'),
('clubs',             'Memberships & Affiliations', 'ids_personal', 'groups'),
('education',         'Academic Records',            'ids_personal', 'school'),
('military',          'Military Service History',   'ids_personal', 'military_tech'),
('personal_misc',     'Other Personal Items',       'ids_personal', 'more_horiz');

-- 4.2 Digital Assets & Profiles
INSERT INTO categories (category_key, label, parent_key, icon) VALUES
('passwords',         'Account Credentials',           'digital', 'password'),
('email_accounts',    'Email Platforms',                'digital', 'email'),
('devices',           'Hardware & Devices',            'digital', 'laptop'),
('wifi',              'Network Access (WiFi)',          'digital', 'wifi'),
('social_media',      'Social Networks',               'digital', 'share'),
('shopping',          'eCommerce & Shopping',          'digital', 'shopping_cart'),
('digital_payment',   'Digital Payment Wallets',       'digital', 'wallet'),
('money_mgmt',        'Spending & Money Apps',         'digital', 'account_balance_wallet'),
('streaming',         'Entertainment Streaming',       'digital', 'movie'),
('music',             'Music & Audio Services',        'digital', 'music_note'),
('gaming',            'Gaming Accounts',               'digital', 'sports_esports'),
('cloud_storage',     'Cloud Storage & Backups',       'digital', 'cloud'),
('travel',            'Travel & Mobility Services',    'digital', 'flight'),
('ticketing',         'Digital Tickets & Passes',      'digital', 'confirmation_number'),
('business_net',      'Professional Networking',       'digital', 'work'),
('software_licenses', 'Software Product Keys',         'digital', 'app_registration'),
('content_subs',      'Digital Subscriptions',         'digital', 'subtitles'),
('conferencing',      'Communication Hubs',            'digital', 'video_chat'),
('domains_hosting',   'Web Domains & Hosting',         'digital', 'public'),
('other_digital',     'Miscellaneous Digital Items',   'digital', 'extension');

-- 4.3 Real Estate & Valuables
INSERT INTO categories (category_key, label, parent_key, icon) VALUES
('homes',             'Residential Properties',        'home_property', 'home'),
('vehicles',          'Automobiles & Transport',       'home_property', 'directions_car'),
('possessions',       'High-Value Possessions',        'home_property', 'diamond'),
('storage',           'External Storage Units',        'home_property', 'warehouse'),
('safe_boxes',        'Bank Safety Deposits',          'home_property', 'inventory_2'),
('home_safes',        'Private Home Safes',            'home_property', 'enhanced_encryption'),
('real_estate',       'Commercial & Land Holdings',    'home_property', 'home_work'),
('bank_lockers',      'Secure Bank Lockers',           'home_property', 'lock_person');

-- 4.4 Financial Accounts & Assets
INSERT INTO categories (category_key, label, parent_key, icon) VALUES
('banking',           'Bank Accounts & Cash',          'financial', 'account_balance'),
('cards',             'Credit & Debit Cards',          'financial', 'credit_card'),
('loans',             'Outstanding Loans',             'financial', 'money_off'),
('businesses',        'Business Ventures',             'financial', 'business'),
('advisors',          'Financial Advisors',            'financial', 'support_agent'),
('life_insurance',    'Life Protection Policies',      'financial', 'volunteer_activism'),
('disability_ins',    'Disability Coverage',           'financial', 'accessible'),
('tax_returns',       'Tax Filings',                   'financial', 'description'),
('social_security',   'Social Security Status',        'financial', 'security'),
('annuities',         'Annuities & Dividends',         'financial', 'payments'),
('pensions',          'Retirement Pensions',           'financial', 'savings'),
('military_benefits', 'Veteran & Military Perks',      'financial', 'military_tech'),
('disability_benefits','Disability Support',            'financial', 'wheelchair_pickup'),
('govt_schemes',      'Government Aid Schemes',        'financial', 'account_balance');

-- 4.5 Legal Matters & Contracts
INSERT INTO categories (category_key, label, parent_key, icon) VALUES
('attorneys',         'Attorneys & Legal Counsel',     'legal', 'gavel'),
('wills',             'Last Will & Testament',         'legal', 'article'),
('poa',               'Power of Attorney Records',     'legal', 'verified'),
('trusts',            'Trusts Distributions',          'legal', 'account_balance'),
('legal_others',      'Significant Legal Papers',      'legal', 'source');

-- 4.6 Health Records & Wellness
INSERT INTO categories (category_key, label, parent_key, icon) VALUES
('health_ins',        'Medical Insurance Plans',       'health', 'health_and_safety'),
('doctors',           'Trusted Medical Experts',       'health', 'medical_information'),
('advance_directive', 'Advance Directives',            'health', 'clinical_notes'),
('medical_records',   'Clinical History Files',        'health', 'receipt_long'),
('medications',       'Prescribed Medications',        'health', 'medication'),
('allergies',         'Allergen Awareness',            'health', 'warning'),
('conditions',        'Medical Condition History',     'health', 'sick'),
('med_devices',       'Vital Medical Equipment',       'health', 'precision_manufacturing'),
('fitness',           'Wellness & Fitness Goals',      'health', 'fitness_center');

-- 4.7 Family & Inner Circle
INSERT INTO categories (category_key, label, parent_key, icon) VALUES
('emergency_contacts', 'Priority Emergency Contacts',   'family', 'contact_emergency'),
('spouse',             'Spouse & Partner Profile',      'family', 'favorite'),
('children',           'Profiles for My Children',      'family', 'child_care'),
('parents',            'Parental Information',          'family', 'family_restroom'),
('pets',               'My Animal Companions',          'family', 'pets'),
('other_fam',          'Extended Family & Circles',     'family', 'group'),
('genealogy',          'Heritage & Family Lore',        'family', 'account_tree'),
('antique_photos',     'Archive of Special Photos',     'family', 'photo_library'),
('recipes',            'Secret Family Recipes',         'family', 'restaurant_menu'),
('family_tree',        'Our Visual Family Tree',        'family', 'hub');

-- 4.8 Future Planning & Care
INSERT INTO categories (category_key, label, parent_key, icon) VALUES
('care_providers',     'Eldercare Professionals',       'aging', 'medical_touch'),
('ltc_insurance',      'Long-Term Care Coverage',       'aging', 'health_and_safety'),
('care_prefs',         'Senior Living Preferences',     'aging', 'handshake'),
('care_finances',      'Allocated Care Funds',          'aging', 'savings');

-- 4.9 Legacy & Final Wishes
INSERT INTO categories (category_key, label, parent_key, icon) VALUES
('final_arrangements', 'End-of-Life Arrangements',       'after_gone', 'church'),
('funeral_prefs',      'Memorial Preferences',          'after_gone', 'open_in_new'),
('legacy_recording',   'Personal Legacy Message',       'after_gone', 'mic'),
('obituary',           'Personal Obituary Draft',       'after_gone', 'notes'),
('letter_all',         'Message to All Contacts',       'after_gone', 'mail_outline'),
('letter_family',      'Personal Letters to Family',    'after_gone', 'contact_mail'),
('memorialization',    'Commemoration Wishes',          'after_gone', 'auto_stories'),
('about_life',         'Ethical Will (Life Lessons)',   'after_gone', 'history_edu');

-- STEP 5: DATA MAPPING (MIGRATE LEGACY TO NEW CANONICAL KEYS)
UPDATE assets SET category = 'banking'           WHERE category IN ('Bank Account', 'Investment', 'banking');
UPDATE assets SET category = 'cards'             WHERE category IN ('Credit Card', 'cards');
UPDATE assets SET category = 'life_insurance'    WHERE category IN ('Insurance', 'insurance');
UPDATE assets SET category = 'homes'             WHERE category IN ('Property', 'real_estate');
UPDATE assets SET category = 'vehicles'          WHERE category IN ('Vehicle', 'vehicles');
UPDATE assets SET category = 'possessions'       WHERE category IN ('Collectible', 'collectibles');
UPDATE assets SET category = 'legal_others'      WHERE category IN ('Legal', 'legal_documents');
UPDATE assets SET category = 'passwords'         WHERE category IN ('Password', 'passwords');
UPDATE assets SET category = 'personal_misc'     WHERE category IN ('Others', 'others');

-- IMPORTANT: Cleanup legacy 'Nominee' assets if they were stored in the general vault
DELETE FROM assets WHERE category = 'Nominee';

COMMIT;
