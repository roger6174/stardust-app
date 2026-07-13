/**
 * ============================================================================
 * STARDUST VAULT — CATEGORY SCHEMAS (FULL-FIDELITY EXPANSION)
 * ============================================================================
 * Single source of truth for all asset categories.
 * Contains precise, industry-standard fields for all 86 asset sub-categories.
 * ============================================================================
 */

const PARENT_CATEGORIES = {
    ids_personal:  { key: 'ids_personal',  label: 'Identity & Personal Records', icon: 'person_outline', color: '#2563EB' },
    digital:       { key: 'digital',       label: 'Digital Assets & Profiles',   icon: 'devices',        color: '#2563EB' },
    home_property: { key: 'home_property', label: 'Real Estate & Valuables',     icon: 'home',           color: '#2563EB' },
    financial:     { key: 'financial',     label: 'Financial Accounts & Assets', icon: 'payments',       color: '#2563EB' },
    legal:         { key: 'legal',         label: 'Legal Matters & Contracts',   icon: 'gavel',          color: '#2563EB' },
    health:        { key: 'health',        label: 'Health Records & Wellness',   icon: 'medical_services',color: '#2563EB' },
    family:        { key: 'family',        label: 'Family & Inner Circle',       icon: 'groups',         color: '#2563EB' },
    aging:         { key: 'aging',         label: 'Future Planning & Care',      icon: 'elderly',        color: '#2563EB' },
    after_gone:    { key: 'after_gone',    label: 'Legacy & Final Wishes',       icon: 'auto_awesome',   color: '#2563EB' },
};

const CATEGORY_SCHEMAS = {
    // ─────────────────────────────────────────────
    // 1. IDENTITY & PERSONAL RECORDS
    // ─────────────────────────────────────────────
    ids_vital: {
        key: 'ids_vital', parent: 'ids_personal', label: 'Core Identity Documents', icon: 'badge',
        fields: [
            { key: 'title', label: 'ID Name', type: 'text', required: true, placeholder: 'e.g. Passport, Aadhaar' },
            { key: 'id_number', label: 'ID Number', type: 'text', required: true, sensitive: true },
            { key: 'id_type', label: 'ID Type', type: 'select', required: true, options: ['Passport', 'Aadhaar', 'PAN Card', 'Voter ID', 'Driving License', 'SSN', 'National ID', 'Other'] },
            { key: 'expiry_date', label: 'Expiry Date', type: 'date', required: false },
            { key: 'issuing_authority', label: 'Issuing Authority', type: 'text', required: false },
            { key: 'file_upload', label: 'Scan ID Document', type: 'file', required: false },
            { key: 'notes', label: 'Notes', type: 'textarea', required: false },
        ]
    },
    contact_info: {
        key: 'contact_info', parent: 'ids_personal', label: 'Primary Contact Details', icon: 'contact_phone',
        fields: [
            { key: 'title', label: 'Label', type: 'text', required: true, placeholder: 'e.g. Primary Residence' },
            { key: 'phone', label: 'Phone', type: 'phone', required: false },
            { key: 'email', label: 'Email', type: 'email', required: false },
            { key: 'alt_phone', label: 'Alternate Phone', type: 'phone', required: false },
            { key: 'address', label: 'Full Address', type: 'textarea', required: false },
        ]
    },
    charities: { 
        key: 'charities', parent: 'ids_personal', label: 'Philanthropy & Causes', icon: 'favorite', 
        fields: [
            { key: 'title', label: 'Organization Name', type: 'text', required: true },
            { key: 'membership_id', label: 'Membership/Donor ID', type: 'text' },
            { key: 'annual_donation', label: 'Annual Contribution', type: 'currency' },
            { key: 'website', label: 'Organization Website', type: 'text' },
            { key: 'file_upload', label: 'Upload Donation Receipt', type: 'file' }
        ] 
    },
    clubs: { 
        key: 'clubs', parent: 'ids_personal', label: 'Memberships & Affiliations', icon: 'groups', 
        fields: [
            { key: 'title', label: 'Club/Group Name', type: 'text', required: true },
            { key: 'status', label: 'Membership Type', type: 'select', options: ['Active', 'Lifetime', 'Associate'] },
            { key: 'expiry_date', label: 'Expiry Date', type: 'date' },
            { key: 'contact_person', label: 'Point of Contact', type: 'text' },
            { key: 'file_upload', label: 'Upload Membership Card', type: 'file' }
        ] 
    },
    education: { 
        key: 'education', parent: 'ids_personal', label: 'Academic Records', icon: 'school', 
        fields: [
            { key: 'title', label: 'Institution Name', type: 'text', required: true },
            { key: 'degree', label: 'Degree/Major', type: 'text', required: true },
            { key: 'grad_year', label: 'Graduation Year', type: 'text' },
            { key: 'student_id', label: 'Student ID/Roll No', type: 'text' },
            { key: 'file_upload', label: 'Scan Degree/Transcripts', type: 'file' }
        ] 
    },
    military: { 
        key: 'military', parent: 'ids_personal', label: 'Military Service History', icon: 'military_tech', 
        fields: [
            { key: 'title', label: 'Service Record Title', type: 'text', required: true },
            { key: 'branch', label: 'Branch of Service', type: 'text', required: true },
            { key: 'service_id', label: 'Service Number', type: 'text', sensitive: true },
            { key: 'rank', label: 'Highest Rank Attained', type: 'text' },
            { key: 'start_date', label: 'Enlistment Date', type: 'date' },
            { key: 'end_date', label: 'Discharge Date', type: 'date' },
            { key: 'file_upload', label: 'Scan Service Records', type: 'file' }
        ] 
    },
    personal_misc: { 
        key: 'personal_misc', parent: 'ids_personal', label: 'Other Personal Items', icon: 'more_horiz', 
        fields: [
            { key: 'title', label: 'Description', type: 'text', required: true },
            { key: 'date', label: 'Relevant Date', type: 'date' },
            { key: 'notes', label: 'Additional Details', type: 'textarea' },
            { key: 'file_upload', label: 'Upload Attachment', type: 'file' }
        ] 
    },

    // ─────────────────────────────────────────────
    // 2. DIGITAL ASSETS & PROFILES
    // ─────────────────────────────────────────────
    passwords: {
        key: 'passwords', parent: 'digital', label: 'Account Credentials', icon: 'password',
        fields: [
            { key: 'title', label: 'Service/Site Name', type: 'text', required: true, placeholder: 'e.g. Google Account' },
            { key: 'username', label: 'Login Username', type: 'text', required: true },
            { key: 'password', label: 'Login Password', type: 'password', required: true, sensitive: true },
            { key: 'url', label: 'Access URL', type: 'text', required: false },
            { key: 'recovery_phone', label: 'Recovery Phone', type: 'phone' },
            { key: 'recovery_email', label: 'Recovery Email', type: 'email' },
            { key: 'two_factor_hint', label: '2FA Method/Hint', type: 'text' },
            { key: 'notes', label: 'Security Codes / Recovery Notes', type: 'textarea', required: false },
        ]
    },
    email_accounts: { 
        key: 'email_accounts', parent: 'digital', label: 'Email Platforms', icon: 'email', 
        fields: [
            { key: 'title', label: 'Platform Name', type: 'text', required: true },
            { key: 'email', label: 'Email Address', type: 'email', required: true },
            { key: 'recovery_email', label: 'Recovery Email', type: 'email' },
            { key: 'two_factor', label: '2FA Method', type: 'select', options: ['SMS', 'Authenticator App', 'Hardware Key', 'Email'] },
            { key: 'notes', label: 'Notes', type: 'textarea' }
        ] 
    },
    devices: { 
        key: 'devices', parent: 'digital', label: 'Hardware & Devices', icon: 'laptop', 
        fields: [
            { key: 'title', label: 'Device Identifier', type: 'text', required: true },
            { key: 'brand', label: 'Brand/Manufacturer', type: 'text' },
            { key: 'model', label: 'Model Name/Number', type: 'text' },
            { key: 'serial_no', label: 'Serial Number', type: 'text', sensitive: true },
            { key: 'purchase_date', label: 'Purchase Date', type: 'date' },
            { key: 'file_upload', label: 'Upload Invoice/Warranty', type: 'file' }
        ] 
    },
    wifi: { 
        key: 'wifi', parent: 'digital', label: 'Network Access (WiFi)', icon: 'wifi', 
        fields: [
            { key: 'title', label: 'SSID / Network Name', type: 'text', required: true },
            { key: 'password', label: 'WiFi Password', type: 'password', required: true, sensitive: true },
            { key: 'security', label: 'Security Type', type: 'select', options: ['WPA2', 'WPA3', 'Open'] },
            { key: 'router_ip', label: 'Router IP Address', type: 'text' },
            { key: 'admin_login', label: 'Router Admin Login', type: 'text' }
        ] 
    },
    social_media: { 
        key: 'social_media', parent: 'digital', label: 'Social Networks', icon: 'share', 
        fields: [
            { key: 'title', label: 'Platform', type: 'text', required: true },
            { key: 'handle', label: 'Username/Handle', type: 'text', required: true },
            { key: 'url', label: 'Profile URL', type: 'text' },
            { key: 'recovery_info', label: 'Recovery Options', type: 'textarea' }
        ] 
    },
    shopping: { 
        key: 'shopping', parent: 'digital', label: 'eCommerce & Shopping', icon: 'shopping_cart', 
        fields: [
            { key: 'title', label: 'Store Name', type: 'text', required: true },
            { key: 'username', label: 'Username', type: 'text' },
            { key: 'linked_card', label: 'Linked Card (Last 4)', type: 'text' }
        ] 
    },
    digital_payment: { 
        key: 'digital_payment', parent: 'digital', label: 'Digital Payment Wallets', icon: 'wallet', 
        fields: [
            { key: 'title', label: 'App Name (UPI/PayPal/etc)', type: 'text', required: true },
            { key: 'linked_phone', label: 'Linked Phone Number', type: 'phone' },
            { key: 'notes', label: 'Notes', type: 'textarea' }
        ] 
    },
    money_mgmt: { 
        key: 'money_mgmt', parent: 'digital', label: 'Spending & Money Apps', icon: 'account_balance_wallet', 
        fields: [
            { key: 'title', label: 'Portfolio/App Name', type: 'text', required: true },
            { key: 'linked_bank', label: 'Linked Bank Account', type: 'text' },
            { key: 'purpose', label: 'Primary Purpose', type: 'text' }
        ] 
    },
    streaming: { 
        key: 'streaming', parent: 'digital', label: 'Entertainment Streaming', icon: 'movie', 
        fields: [
            { key: 'title', label: 'Service Name', type: 'text', required: true },
            { key: 'profile', label: 'Profile/Account Name', type: 'text' },
            { key: 'expiry', label: 'Subscription Expiry', type: 'date' }
        ] 
    },
    music: { 
        key: 'music', parent: 'digital', label: 'Music & Audio Services', icon: 'music_note', 
        fields: [
            { key: 'title', label: 'Platform Name', type: 'text', required: true },
            { key: 'plan', label: 'Plan Type', type: 'text' },
            { key: 'renewal', label: 'Renewal Date', type: 'date' }
        ] 
    },
    gaming: { 
        key: 'gaming', parent: 'digital', label: 'Gaming Accounts', icon: 'sports_esports', 
        fields: [
            { key: 'title', label: 'Platform (Steam/PSN/etc)', type: 'text', required: true },
            { key: 'handle', label: 'Gamertag/Handle', type: 'text', required: true },
            { key: 'value', label: 'Value of Library', type: 'currency' }
        ] 
    },
    cloud_storage: { 
        key: 'cloud_storage', parent: 'digital', label: 'Cloud Storage & Backups', icon: 'cloud', 
        fields: [
            { key: 'title', label: 'Cloud Provider', type: 'text', required: true },
            { key: 'email', label: 'Account Email', type: 'email' },
            { key: 'plan_size', label: 'Storage Size (GB/TB)', type: 'text' },
            { key: 'expiry', label: 'Renewal Date', type: 'date' }
        ] 
    },
    travel: { 
        key: 'travel', parent: 'digital', label: 'Travel & Mobility Services', icon: 'flight', 
        fields: [
            { key: 'title', label: 'Service (Uber/Airbnb/etc)', type: 'text', required: true },
            { key: 'account_id', label: 'Account/Loyalty ID', type: 'text' },
            { key: 'points', label: 'Points/Miles Balance', type: 'text' }
        ] 
    },
    ticketing: { 
        key: 'ticketing', parent: 'digital', label: 'Digital Tickets & Passes', icon: 'confirmation_number', 
        fields: [
            { key: 'title', label: 'Platform Name', type: 'text', required: true },
            { key: 'account', label: 'Account Identifier', type: 'text' },
            { key: 'file_upload', label: 'Upload Ticket/Pass', type: 'file' }
        ] 
    },
    business_net: { 
        key: 'business_net', parent: 'digital', label: 'Professional Networking', icon: 'work', 
        fields: [
            { key: 'title', label: 'Platform (e.g. LinkedIn)', type: 'text', required: true },
            { key: 'handle', label: 'Profile Link/Handle', type: 'text' },
            { key: 'notes', label: 'Notes', type: 'textarea' }
        ] 
    },
    software_licenses: { 
        key: 'software_licenses', parent: 'digital', label: 'Software Product Keys', icon: 'app_registration', 
        fields: [
            { key: 'title', label: 'Application Name', type: 'text', required: true },
            { key: 'license_key', label: 'Product/License Key', type: 'text', sensitive: true },
            { key: 'purchase_date', label: 'Purchase Date', type: 'date' },
            { key: 'expiry', label: 'Expiry Date', type: 'date' }
        ] 
    },
    content_subs: { 
        key: 'content_subs', parent: 'digital', label: 'Digital Subscriptions', icon: 'subtitles', 
        fields: [
            { key: 'title', label: 'Subscription Title', type: 'text', required: true },
            { key: 'price', label: 'Renewal Price', type: 'currency' },
            { key: 'renewal', label: 'Renewal Date', type: 'date' }
        ] 
    },
    conferencing: { 
        key: 'conferencing', parent: 'digital', label: 'Communication Hubs', icon: 'video_chat', 
        fields: [
            { key: 'title', label: 'App Name (Zoom/Slack/etc)', type: 'text', required: true },
            { key: 'email', label: 'Account Email', type: 'email' },
            { key: 'workspace', label: 'Workspace Name', type: 'text' }
        ] 
    },
    domains_hosting: { 
        key: 'domains_hosting', parent: 'digital', label: 'Web Domains & Hosting', icon: 'public', 
        fields: [
            { key: 'title', label: 'Domain/Host Name', type: 'text', required: true },
            { key: 'registrar', label: 'Registrar/Provider', type: 'text' },
            { key: 'expiry', label: 'Expiry Date', type: 'date' },
            { key: 'autorenew', label: 'Auto-Renew Enabled?', type: 'select', options: ['Yes', 'No'] }
        ] 
    },
    other_digital: { 
        key: 'other_digital', parent: 'digital', label: 'Miscellaneous Digital Items', icon: 'extension', 
        fields: [
            { key: 'title', label: 'Description', type: 'text', required: true },
            { key: 'notes', label: 'Additional Details', type: 'textarea' },
            { key: 'file_upload', label: 'Upload Supporting File', type: 'file' }
        ] 
    },

    // ─────────────────────────────────────────────
    // 3. REAL ESTATE & VALUABLES
    // ─────────────────────────────────────────────
    homes: {
        key: 'homes', parent: 'home_property', label: 'Residential Properties', icon: 'home',
        fields: [
            { key: 'title', label: 'Property Nickname', type: 'text', required: true },
            { key: 'address', label: 'Full Address', type: 'textarea', required: true },
            { key: 'ownership', label: 'Ownership Type', type: 'select', required: true, options: ['Sole Owner', 'Joint Owner', 'Tenant', 'Leasehold'] },
            { key: 'property_tax_id', label: 'Property Tax ID', type: 'text' },
            { key: 'file_upload', label: 'Upload Sale Deed/Title', type: 'file' },
        ]
    },
    vehicles: { 
        key: 'vehicles', parent: 'home_property', label: 'Automobiles & Transport', icon: 'directions_car', 
        fields: [
            { key: 'title', label: 'Make & Model', type: 'text', required: true },
            { key: 'plate_number', label: 'Registration Number', type: 'text', required: true },
            { key: 'vin', label: 'VIN / Chassis Number', type: 'text', sensitive: true },
            { key: 'insurance_expiry', label: 'Insurance Expiry', type: 'date' },
            { key: 'rc_expiry', label: 'RC Expiry Date', type: 'date' },
            { key: 'file_upload', label: 'Upload RC/Insurance Copy', type: 'file' }
        ] 
    },
    possessions: { 
        key: 'possessions', parent: 'home_property', label: 'High-Value Possessions', icon: 'diamond', 
        fields: [
            { key: 'title', label: 'Item Name', type: 'text', required: true },
            { key: 'value', label: 'Estimated/Appraised Value', type: 'currency' },
            { key: 'purchase_date', label: 'Purchase Date', type: 'date' },
            { key: 'location', label: 'Current Location', type: 'text' },
            { key: 'file_upload', label: 'Upload Invoice/Appraisal', type: 'file' }
        ] 
    },
    storage: { 
        key: 'storage', parent: 'home_property', label: 'External Storage Units', icon: 'warehouse', 
        fields: [
            { key: 'title', label: 'Facility Name', type: 'text', required: true },
            { key: 'unit_no', label: 'Unit Number', type: 'text' },
            { key: 'key_location', label: 'Key Location', type: 'text' },
            { key: 'access_notes', label: 'Access Instructions', type: 'textarea' }
        ] 
    },
    safe_boxes: { 
        key: 'safe_boxes', parent: 'home_property', label: 'Bank Safety Deposits', icon: 'inventory_2', 
        fields: [
            { key: 'title', label: 'Bank & Branch', type: 'text', required: true },
            { key: 'box_no', label: 'Box Number', type: 'text' },
            { key: 'signatories', label: 'Authorized Signatories', type: 'textarea' },
            { key: 'key_location', label: 'Key Location', type: 'text' },
            { key: 'file_upload', label: 'Upload Rental Agreement', type: 'file' }
        ] 
    },
    home_safes: { 
        key: 'home_safes', parent: 'home_property', label: 'Private Home Safes', icon: 'enhanced_encryption', 
        fields: [
            { key: 'title', label: 'Nickname/Location', type: 'text', required: true },
            { key: 'code_hint', label: 'Access Code Hint', type: 'text' },
            { key: 'key_info', label: 'Physical Key Info', type: 'text' },
            { key: 'summary', label: 'Contents Summary', type: 'textarea' }
        ] 
    },
    real_estate: { 
        key: 'real_estate', parent: 'home_property', label: 'Commercial & Land Holdings', icon: 'home_work', 
        fields: [
            { key: 'title', label: 'Property Title', type: 'text', required: true },
            { key: 'type', label: 'Property Type', type: 'select', options: ['Commercial', 'Agricultural Land', 'Industrial', 'Retail'] },
            { key: 'size', label: 'Size (Sqft/Acre)', type: 'text' },
            { key: 'reg_no', label: 'Registration/Khata Number', type: 'text' },
            { key: 'file_upload', label: 'Upload Land Records', type: 'file' }
        ] 
    },
    bank_lockers: { 
        key: 'bank_lockers', parent: 'home_property', label: 'Secure Bank Lockers', icon: 'lock_person', 
        fields: [
            { key: 'title', label: 'Financial Institution', type: 'text', required: true },
            { key: 'locker_no', label: 'Locker Number', type: 'text' },
            { key: 'rent_due', label: 'Annual Rent Due Date', type: 'date' },
            { key: 'key_info', label: 'Key Identification Info', type: 'text' },
            { key: 'file_upload', label: 'Upload Agreement Scan', type: 'file' }
        ] 
    },

    // ─────────────────────────────────────────────
    // 4. FINANCIAL ACCOUNTS & ASSETS
    // ─────────────────────────────────────────────
    banking: {
        key: 'banking', parent: 'financial', label: 'Bank Accounts & Cash', icon: 'account_balance',
        fields: [
            { key: 'bank_name', label: 'Bank Name', type: 'text', required: true },
            { key: 'account_type', label: 'Account Type', type: 'select', required: true, options: ['Savings', 'Current', 'Fixed Deposit', 'Salary', 'Joint'] },
            { key: 'last_4_digits', label: 'Last 4 Digits', type: 'text', required: true },
            { key: 'ifsc_code', label: 'IFSC / Routing Number', type: 'text' },
            { key: 'nominee', label: 'Registered Nominee', type: 'text' },
            { key: 'file_upload', label: 'Upload Last Statement', type: 'file' },
        ]
    },
    cards: {
        key: 'cards', parent: 'financial', label: 'Credit & Debit Cards', icon: 'credit_card',
        fields: [
            { key: 'bank_name', label: 'Issuing Bank', type: 'text', required: true },
            { key: 'network', label: 'Card Network', type: 'select', required: true, options: ['Visa', 'MasterCard', 'Amex', 'RuPay', 'Other'] },
            { key: 'variant', label: 'Card Variant (e.g. Gold)', type: 'text', required: true },
            { key: 'last_4_digits', label: 'Last 4 Digits', type: 'text', required: true },
            { key: 'expiry', label: 'Expiry (MM/YYYY)', type: 'text', required: true },
            { key: 'limit', label: 'Credit Limit', type: 'currency' },
            { key: 'file_upload', label: 'Upload Statement/Scan', type: 'file' },
        ]
    },
    loans: { 
        key: 'loans', parent: 'financial', label: 'Outstanding Loans', icon: 'money_off', 
        fields: [
            { key: 'title', label: 'Lender Name', type: 'text', required: true },
            { key: 'type', label: 'Loan Type', type: 'select', options: ['Home', 'Personal', 'Auto', 'Business', 'Education'] },
            { key: 'principal', label: 'Initial Principal', type: 'currency' },
            { key: 'emi', label: 'Monthly EMI', type: 'currency' },
            { key: 'end_date', label: 'Maturity Date', type: 'date' },
            { key: 'file_upload', label: 'Upload Loan Agreement', type: 'file' }
        ] 
    },
    businesses: { 
        key: 'businesses', parent: 'financial', label: 'Business Ventures', icon: 'business', 
        fields: [
            { key: 'title', label: 'Enterprise Name', type: 'text', required: true },
            { key: 'entity_type', label: 'Registration Type', type: 'select', options: ['Proprietorship', 'Partnership', 'Pvt Ltd', 'LLP'] },
            { key: 'tax_id', label: 'Tax ID / GSTIN', type: 'text' },
            { key: 'ownership', label: 'Ownership %', type: 'text' },
            { key: 'file_upload', label: 'Upload Biz Certificate', type: 'file' }
        ] 
    },
    advisors: { 
        key: 'advisors', parent: 'financial', label: 'Financial Advisors', icon: 'support_agent', 
        fields: [
            { key: 'title', label: 'Advisor Full Name', type: 'text', required: true },
            { key: 'expertise', label: 'Expertise', type: 'select', options: ['Tax', 'Wealth', 'Legal', 'Insurance'] },
            { key: 'firm', label: 'Firm Name', type: 'text' },
            { key: 'contact', label: 'Contact Details', type: 'text' },
            { key: 'file_upload', label: 'Upload Engagement Letter', type: 'file' }
        ] 
    },
    life_insurance: {
        key: 'life_insurance', parent: 'financial', label: 'Life Protection Policies', icon: 'volunteer_activism',
        fields: [
            { key: 'provider', label: 'Insurance Provider', type: 'text', required: true },
            { key: 'policy_number', label: 'Policy Number (Full)', type: 'text', required: true },
            { key: 'policy_type', label: 'Type', type: 'select', required: true, options: ['Term Life', 'Whole Life', 'Endowment', 'ULIP'] },
            { key: 'sum_assured', label: 'Sum Assured', type: 'currency', required: true },
            { key: 'beneficiary', label: 'Primary Beneficiary', type: 'text' },
            { key: 'renewal_date', label: 'Renewal Date', type: 'date' },
            { key: 'file_upload', label: 'Upload Policy Bond', type: 'file' },
        ]
    },
    disability_ins: { 
        key: 'disability_ins', parent: 'financial', label: 'Disability Coverage', icon: 'accessible', 
        fields: [
            { key: 'title', label: 'Provider Name', type: 'text', required: true },
            { key: 'policy_no', label: 'Policy Number', type: 'text' },
            { key: 'benefit', label: 'Monthly Benefit Amount', type: 'currency' },
            { key: 'file_upload', label: 'Upload Policy', type: 'file' }
        ] 
    },
    tax_returns: { 
        key: 'tax_returns', parent: 'financial', label: 'Tax Filings', icon: 'description', 
        fields: [
            { key: 'title', label: 'Financial Year (e.g. 2024-25)', type: 'text', required: true },
            { key: 'type', label: 'Filing Type', type: 'text' },
            { key: 'status', label: 'Status', type: 'select', options: ['Filed', 'Pending', 'Under Process'] },
            { key: 'ack_no', label: 'Acknowledgment #', type: 'text' },
            { key: 'file_upload', label: 'Upload ITR-V Ack', type: 'file' }
        ] 
    },
    social_security: { 
        key: 'social_security', parent: 'financial', label: 'Social Security Status', icon: 'security', 
        fields: [
            { key: 'title', label: 'Reference ID', type: 'text', required: true },
            { key: 'status', label: 'Current Status', type: 'text' },
            { key: 'benefit', label: 'Monthly Benefit', type: 'currency' }
        ] 
    },
    annuities: { 
        key: 'annuities', parent: 'financial', label: 'Annuities & Dividends', icon: 'payments', 
        fields: [
            { key: 'title', label: 'Benefit Source', type: 'text', required: true },
            { key: 'income', label: 'Monthly Inflow', type: 'currency' },
            { key: 'maturity', label: 'Maturity Date', type: 'date' },
            { key: 'file_upload', label: 'Upload Statement', type: 'file' }
        ] 
    },
    pensions: { 
        key: 'pensions', parent: 'financial', label: 'Retirement Pensions', icon: 'savings', 
        fields: [
            { key: 'title', label: 'Retirement Fund Name', type: 'text', required: true },
            { key: 'ppo_no', label: 'PPO Number', type: 'text' },
            { key: 'linked_bank', label: 'Linked Bank Account', type: 'text' }
        ] 
    },
    military_benefits: { 
        key: 'military_benefits', parent: 'financial', label: 'Veteran & Military Perks', icon: 'military_tech', 
        fields: [
            { key: 'title', label: 'Benefit Type', type: 'text', required: true },
            { key: 'id_no', label: 'ID Number', type: 'text' },
            { key: 'status', label: 'Status', type: 'text' }
        ] 
    },
    disability_benefits: { 
        key: 'disability_benefits', parent: 'financial', label: 'Disability Support', icon: 'wheelchair_pickup', 
        fields: [
            { key: 'title', label: 'Support Title', type: 'text', required: true },
            { key: 'ref_id', label: 'Reference ID', type: 'text' },
            { key: 'amount', label: 'Benefit Amount', type: 'currency' }
        ] 
    },
    govt_schemes: { 
        key: 'govt_schemes', parent: 'financial', label: 'Government Aid Schemes', icon: 'account_balance', 
        fields: [
            { key: 'title', label: 'Scheme Name', type: 'text', required: true },
            { key: 'benefit', label: 'Benefit Type', type: 'text' },
            { key: 'id_no', label: 'ID Number', type: 'text' }
        ] 
    },

    // ─────────────────────────────────────────────
    // 5. LEGAL MATTERS & CONTRACTS
    // ─────────────────────────────────────────────
    attorneys: { 
        key: 'attorneys', parent: 'legal', label: 'Attorneys & Legal Counsel', icon: 'gavel', 
        fields: [
            { key: 'title', label: 'Lawyer / Firm Name', type: 'text', required: true },
            { key: 'specialization', label: 'Area', type: 'text' },
            { key: 'contact', label: 'Contact details', type: 'text' },
            { key: 'file_upload', label: 'Upload Legal Proxy/Agreement', type: 'file' }
        ] 
    },
    wills: { 
        key: 'wills', parent: 'legal', label: 'Last Will & Testament', icon: 'article', 
        fields: [
            { key: 'title', label: 'Title of Document', type: 'text', required: true },
            { key: 'date', label: 'Date of Will', type: 'date', required: true },
            { key: 'executor', label: 'Executor Name', type: 'text' },
            { key: 'location', label: 'Physical Storage location', type: 'text' },
            { key: 'file_upload', label: 'Upload Scanned Will', type: 'file' }
        ] 
    },
    poa: { 
        key: 'poa', parent: 'legal', label: 'Power of Attorney Records', icon: 'verified', 
        fields: [
            { key: 'title', label: 'Document Description', type: 'text', required: true },
            { key: 'type', label: 'Type', type: 'select', options: ['General', 'Medical', 'Limited', 'Durable'] },
            { key: 'authorized', label: 'Authorized Person', type: 'text' },
            { key: 'expiry', label: 'Expiry Date', type: 'date' },
            { key: 'file_upload', label: 'Upload Notarized Scan', type: 'file' }
        ] 
    },
    trusts: { 
        key: 'trusts', parent: 'legal', label: 'Trust Distributions', icon: 'account_balance', 
        fields: [
            { key: 'title', label: 'Trust Name', type: 'text', required: true },
            { key: 'trustees', label: 'Trustees Names', type: 'textarea' },
            { key: 'beneficiaries', label: 'Beneficiaries', type: 'textarea' },
            { key: 'file_upload', label: 'Upload Trust Deed', type: 'file' }
        ] 
    },
    legal_others: { 
        key: 'legal_others', parent: 'legal', label: 'Significant Legal Papers', icon: 'source', 
        fields: [
            { key: 'title', label: 'Description', type: 'text', required: true },
            { key: 'location', label: 'Physical Location', type: 'text' },
            { key: 'file_upload', label: 'Upload Doc Scan', type: 'file' }
        ] 
    },

    // ─────────────────────────────────────────────
    // 6. HEALTH RECORDS & WELLNESS
    // ─────────────────────────────────────────────
    health_ins: {
        key: 'health_ins', parent: 'health', label: 'Medical Insurance Plans', icon: 'health_and_safety',
        fields: [
            { key: 'provider', label: 'Insurance Provider', type: 'text', required: true },
            { key: 'policy_number', label: 'Full Policy Number', type: 'text', required: true },
            { key: 'sum_assured', label: 'Coverage Amount', type: 'currency' },
            { key: 'renewal_date', label: 'Renewal Date', type: 'date' },
            { key: 'tpa_name', label: 'TPA / Helpdesk Name', type: 'text' },
            { key: 'file_upload', label: 'Upload Health Card', type: 'file' },
        ]
    },
    doctors: { 
        key: 'doctors', parent: 'health', label: 'Trusted Medical Experts', icon: 'medical_information', 
        fields: [
            { key: 'title', label: 'Doctor/Specialist Name', type: 'text', required: true },
            { key: 'specialization', label: 'Specialization', type: 'text' },
            { key: 'hospital', label: 'Hospital/Clinic', type: 'text' },
            { key: 'contact', label: 'Contact Phone/Email', type: 'text' },
            { key: 'file_upload', label: 'Upload Prescription/ID', type: 'file' }
        ] 
    },
    advance_directive: { 
        key: 'advance_directive', parent: 'health', label: 'Advance Directives', icon: 'clinical_notes', 
        fields: [
            { key: 'title', label: 'Directive Title', type: 'text', required: true },
            { key: 'preference', label: 'Health Preference (e.g. DNR)', type: 'text' },
            { key: 'rep', label: 'Medical Representative', type: 'text' },
            { key: 'file_upload', label: 'Upload Directive Scan', type: 'file' }
        ] 
    },
    medical_records: { 
        key: 'medical_records', parent: 'health', label: 'Clinical History Files', icon: 'receipt_long', 
        fields: [
            { key: 'title', label: 'Record Category (Lab/Scan)', type: 'text', required: true },
            { key: 'date', label: 'Entry Date', type: 'date' },
            { key: 'summary', label: 'Brief Summary', type: 'textarea' },
            { key: 'file_upload', label: 'Upload Lab/Scan Result', type: 'file' }
        ] 
    },
    medications: { 
        key: 'medications', parent: 'health', label: 'Prescribed Medications', icon: 'medication', 
        fields: [
            { key: 'title', label: 'Drug Name', type: 'text', required: true },
            { key: 'dosage', label: 'Dosage (e.g. 500mg)', type: 'text' },
            { key: 'frequency', label: 'Frequency (e.g. 1-0-1)', type: 'text' },
            { key: 'doctor', label: 'Prescribing Doctor', type: 'text' }
        ] 
    },
    allergies: { 
        key: 'allergies', parent: 'health', label: 'Allergy Awareness', icon: 'warning', 
        fields: [
            { key: 'title', label: 'Critical Allergy To', type: 'text', required: true },
            { key: 'severity', label: 'Severity', type: 'select', options: ['Low', 'Medium', 'High / Fatal'] },
            { key: 'reaction', label: 'Typical Reaction', type: 'text' },
            { key: 'rescue_med', label: 'Emergency Medication', type: 'text' }
        ] 
    },
    conditions: { 
        key: 'conditions', parent: 'health', label: 'Medical Condition History', icon: 'sick', 
        fields: [
            { key: 'title', label: 'Chronic Diagnosis', type: 'text', required: true },
            { key: 'start_date', label: 'Estimated Start', type: 'date' },
            { key: 'doctor', label: 'Managing Doctor', type: 'text' },
            { key: 'treatment', label: 'Ongoing Treatment', type: 'textarea' }
        ] 
    },
    med_devices: { 
        key: 'med_devices', parent: 'health', label: 'Vital Medical Equipment', icon: 'precision_manufacturing', 
        fields: [
            { key: 'title', label: 'Device/Machine Type', type: 'text', required: true },
            { key: 'brand', label: 'Brand/Serial', type: 'text' },
            { key: 'contact', label: 'Service Contact', type: 'text' }
        ] 
    },
    fitness: { 
        key: 'fitness', parent: 'health', label: 'Wellness & Fitness Goals', icon: 'fitness_center', 
        fields: [
            { key: 'title', label: 'Gym/Program Name', type: 'text', required: true },
            { key: 'goal', label: 'Current Goal', type: 'text' },
            { key: 'membership', label: 'Membership ID', type: 'text' }
        ] 
    },

    // ─────────────────────────────────────────────
    // 7. FAMILY & INNER CIRCLE
    // ─────────────────────────────────────────────
    emergency_contacts: { 
        key: 'emergency_contacts', parent: 'family', label: 'Priority Emergency Contacts', icon: 'contact_emergency', 
        fields: [
            { key: 'title', label: 'Contact Name', type: 'text', required: true },
            { key: 'relation', label: 'Relationship', type: 'text' },
            { key: 'phone', label: 'Primary Phone', type: 'phone', required: true },
            { key: 'phone_alt', label: 'Alternate Phone', type: 'phone' }
        ] 
    },
    spouse: { 
        key: 'spouse', parent: 'family', label: 'Spouse & Partner Profile', icon: 'favorite', 
        fields: [
            { key: 'title', label: 'Full Legal Name', type: 'text', required: true },
            { key: 'wedding_date', label: 'Marriage/Partnership Date', type: 'date' },
            { key: 'legal_status', label: 'Legal Status', type: 'text' }
        ] 
    },
    children: { 
        key: 'children', parent: 'family', label: 'Profiles for My Children', icon: 'child_care', 
        fields: [
            { key: 'title', label: 'Full Legal Name', type: 'text', required: true },
            { key: 'dob', label: 'Date of Birth', type: 'date' },
            { key: 'guardianship', label: 'Guardianship Info', type: 'textarea' },
            { key: 'file_upload', label: 'Upload Birth Certificate/ID', type: 'file' }
        ] 
    },
    parents: { 
        key: 'parents', parent: 'family', label: 'Parental Information', icon: 'family_restroom', 
        fields: [
            { key: 'title', label: 'Full Name', type: 'text', required: true },
            { key: 'contact', label: 'Contact info', type: 'text' },
            { key: 'address', label: 'Current Address', type: 'textarea' }
        ] 
    },
    pets: { 
        key: 'pets', parent: 'family', label: 'My Animal Companions', icon: 'pets', 
        fields: [
            { key: 'title', label: 'Pet Nickname', type: 'text', required: true },
            { key: 'species', label: 'Species / Breed', type: 'text' },
            { key: 'vet', label: 'Vet Contact Info', type: 'text' },
            { key: 'vaccination', label: 'Next Vaccination Date', type: 'date' },
            { key: 'file_upload', label: 'Upload Vaccination/ID Card', type: 'file' }
        ] 
    },
    other_fam: { 
        key: 'other_fam', parent: 'family', label: 'Extended Family & Circles', icon: 'group', 
        fields: [
            { key: 'title', label: 'Contact Name', type: 'text', required: true },
            { key: 'relation', label: 'Relationship', type: 'text' },
            { key: 'phone', label: 'Phone Number', type: 'phone' }
        ] 
    },
    genealogy: { 
        key: 'genealogy', parent: 'family', label: 'Heritage & Family Lore', icon: 'account_tree', 
        fields: [
            { key: 'title', label: 'Legacy Title', type: 'text', required: true },
            { key: 'discovery', label: 'Heritage Details', type: 'textarea' }
        ] 
    },
    antique_photos: { 
        key: 'antique_photos', parent: 'family', label: 'Archive of Special Photos', icon: 'photo_library', 
        fields: [
            { key: 'title', label: 'Album/Collection Name', type: 'text', required: true },
            { key: 'quantity', label: 'Approx Quantity', type: 'text' },
            { key: 'location', label: 'Physical Location', type: 'text' }
        ] 
    },
    recipes: { 
        key: 'recipes', parent: 'family', label: 'Secret Family Recipes', icon: 'restaurant_menu', 
        fields: [
            { key: 'title', label: 'Dish Name', type: 'text', required: true },
            { key: 'origin', label: 'Cultural Origin', type: 'text' },
            { key: 'ingredients', label: 'Key Secret Ingredients', type: 'textarea' },
            { key: 'file_upload', label: 'Upload Recipe Scan', type: 'file' }
        ] 
    },
    family_tree: { 
        key: 'family_tree', parent: 'family', label: 'Our Visual Family Tree', icon: 'hub', 
        fields: [
            { key: 'title', label: 'Visual Tree Identifier', type: 'text', required: true },
            { key: 'lineage', label: 'Key Lineage Note', type: 'textarea' },
            { key: 'file_upload', label: 'Upload Tree Diagram', type: 'file' }
        ] 
    },

    // ─────────────────────────────────────────────
    // 8. FUTURE PLANNING & CARE
    // ─────────────────────────────────────────────
    care_providers: { 
        key: 'care_providers', parent: 'aging', label: 'Eldercare Professionals', icon: 'medical_touch', 
        fields: [
            { key: 'title', label: 'Provider/Agency Name', type: 'text', required: true },
            { key: 'type', label: 'Care Type', type: 'select', options: ['Home Care', 'Respite', 'Assisted Living'] },
            { key: 'contact', label: 'Full Contact details', type: 'textarea' }
        ] 
    },
    ltc_insurance: { 
        key: 'ltc_insurance', parent: 'aging', label: 'Long-Term Care Coverage', icon: 'health_and_safety', 
        fields: [
            { key: 'title', label: 'Provider & Policy Name', type: 'text', required: true },
            { key: 'policy_no', label: 'Policy Number', type: 'text' },
            { key: 'daily_benefit', label: 'Daily Benefit Amount', type: 'currency' },
            { key: 'renewal', label: 'Renewal Date', type: 'date' },
            { key: 'file_upload', label: 'Upload Policy Document', type: 'file' }
        ] 
    },
    care_prefs: { 
        key: 'care_prefs', parent: 'aging', label: 'Senior Living Preferences', icon: 'handshake', 
        fields: [
            { key: 'title', label: 'Preference Category', type: 'text', required: true },
            { key: 'instructions', label: 'Detailed Instructions', type: 'textarea' },
            { key: 'rep', label: 'Primary Representative', type: 'text' }
        ] 
    },
    care_finances: { 
        key: 'care_finances', parent: 'aging', label: 'Allocated Care Funds', icon: 'savings', 
        fields: [
            { key: 'title', label: 'Fund Name', type: 'text', required: true },
            { key: 'amount', label: 'Allocated Amount', type: 'currency' },
            { key: 'institution', label: 'Holding Institution', type: 'text' }
        ] 
    },

    // ─────────────────────────────────────────────
    // 9. LEGACY & FINAL WISHES
    // ─────────────────────────────────────────────
    final_arrangements: { 
        key: 'final_arrangements', parent: 'after_gone', label: 'End-of-Life Arrangements', icon: 'church', 
        fields: [
            { key: 'title', label: 'Arrangement Type/Title', type: 'text', required: true },
            { key: 'status', label: 'Pre-Paid Status?', type: 'select', options: ['Yes - Fully Paid', 'Partially Paid', 'Not Paid'] },
            { key: 'location', label: 'Physical Location details', type: 'textarea' }
        ] 
    },
    funeral_prefs: { 
        key: 'funeral_prefs', parent: 'after_gone', label: 'Memorial Preferences', icon: 'open_in_new', 
        fields: [
            { key: 'title', label: 'Type (Burial/Cremation)', type: 'select', required: true, options: ['Burial', 'Cremation', 'Donation'] },
            { key: 'theme', label: 'Religious/Thematic Prefs', type: 'text' },
            { key: 'instructions', label: 'Detailed Instructions', type: 'textarea' }
        ] 
    },
    legacy_recording: { 
        key: 'legacy_recording', parent: 'after_gone', label: 'Personal Legacy Message', icon: 'mic', 
        fields: [
            { key: 'title', label: 'Message Subject', type: 'text', required: true },
            { key: 'location', label: 'Media Location (Cloud/Physical)', type: 'text' },
            { key: 'pin', label: 'Access PIN Hint', type: 'text' }
        ] 
    },
    obituary: { 
        key: 'obituary', parent: 'after_gone', label: 'Personal Obituary Draft', icon: 'notes', 
        fields: [
            { key: 'title', label: 'Draft Title', type: 'text', required: true },
            { key: 'facts', label: 'Key Facts to include', type: 'textarea' },
            { key: 'instructions', label: 'Publication Instructions', type: 'textarea' }
        ] 
    },
    letter_all: { 
        key: 'letter_all', parent: 'after_gone', label: 'Message to All Contacts', icon: 'mail_outline', 
        fields: [
            { key: 'title', label: 'Subject', type: 'text', required: true },
            { key: 'message', label: 'Letter Content', type: 'textarea' },
            { key: 'pin', label: 'Special Access PIN', type: 'text' }
        ] 
    },
    letter_family: { 
        key: 'letter_family', parent: 'after_gone', label: 'Personal Letters to Family', icon: 'contact_mail', 
        fields: [
            { key: 'title', label: 'Recipient Name/Label', type: 'text', required: true },
            { key: 'subject', label: 'Letter Subject', type: 'text' },
            { key: 'message', label: 'The actual letter / Message', type: 'textarea' },
            { key: 'pin', label: 'Access PIN', type: 'text' }
        ] 
    },
    memorialization: { 
        key: 'memorialization', parent: 'after_gone', label: 'Commemoration Wishes', icon: 'auto_stories', 
        fields: [
            { key: 'title', label: 'Memorial Detail Theme', type: 'text', required: true },
            { key: 'wishes', label: 'Specific Wishes', type: 'textarea' }
        ] 
    },
    about_life: { 
        key: 'about_life', parent: 'after_gone', label: 'Ethical Will (Life Lessons)', icon: 'history_edu', 
        fields: [
            { key: 'title', label: 'Volume/Volume Title', type: 'text', required: true },
            { key: 'lesson', label: 'Key Life Lessons Summary', type: 'textarea' },
            { key: 'date', label: 'Date Written', type: 'date' }
        ] 
    },
};

/**
 * Get all valid category keys
 */
const getValidCategories = () => Object.keys(CATEGORY_SCHEMAS);

/**
 * Get schema for a specific category
 */
const getCategorySchema = (categoryKey) => CATEGORY_SCHEMAS[categoryKey] || null;

/**
 * Validate metadata against category schema
 */
const validateMetadata = (categoryKey, metadata) => {
    const schema = CATEGORY_SCHEMAS[categoryKey];
    if (!schema) return { valid: false, errors: [`Unknown category: ${categoryKey}`] };

    const errors = [];
    for (const field of schema.fields) {
        if (field.required && (!metadata[field.key] || String(metadata[field.key]).trim() === '')) {
            errors.push(`${field.label} is required`);
        }
    }
    return { valid: errors.length === 0, errors };
};

/**
 * Extract the title field from metadata
 */
const extractTitle = (categoryKey, metadata) => {
    const schema = CATEGORY_SCHEMAS[categoryKey];
    if (!schema) return 'Untitled';

    const titleField = schema.fields.find(f => f.required && f.type === 'text');
    if (titleField && metadata[titleField.key]) {
        return metadata[titleField.key];
    }
    
    // Fallback logic for specific categories
    if (metadata.bank_name && metadata.variant) return `${metadata.bank_name} ${metadata.variant}`;
    if (metadata.bank_name) return metadata.bank_name;
    if (metadata.provider) return metadata.provider;

    return metadata.title || 'Untitled';
};

module.exports = {
    PARENT_CATEGORIES,
    CATEGORY_SCHEMAS,
    getValidCategories,
    getCategorySchema,
    validateMetadata,
    extractTitle
};
