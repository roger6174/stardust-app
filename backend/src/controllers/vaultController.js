const db = require('../config/db');
const { encrypt, decrypt } = require('../utils/crypto');
const { PARENT_CATEGORIES, CATEGORY_SCHEMAS, getValidCategories, getCategorySchema, validateMetadata, extractTitle } = require('../config/category_schemas');
const { getCardBenefits } = require('../services/aiService');

// ─────────────────────────────────────────────────────────────
// Helper: Decrypt and parse asset metadata
// ─────────────────────────────────────────────────────────────
const parseAssetRow = (asset) => {
    let metadataStr = asset.metadata;
    const isEncrypted = parseInt(asset.is_encrypted) === 1;

    try {
        let parsedMetadata = metadataStr;
        
        // Step 1: If stringified multiple times, strip extra quotes
        if (typeof metadataStr === 'string') {
            metadataStr = metadataStr.trim();
            // Handle edge case where it might be wrapped in double quotes as a string literal
            if (metadataStr.startsWith('"') && metadataStr.endsWith('"')) {
                try { metadataStr = JSON.parse(metadataStr); } catch(e) {}
            }
        }

        // Step 2: Try parsing if it's still a string
        if (typeof metadataStr === 'string') {
            const trimmed = metadataStr.trim();
            if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
                try {
                    parsedMetadata = JSON.parse(trimmed);
                } catch (e) {
                    console.warn('⚠️ [JSON PARSE FAIL]:', e.message);
                    parsedMetadata = trimmed;
                }
            } else {
                parsedMetadata = trimmed;
            }
        } else {
            parsedMetadata = metadataStr;
        }

        // Step 3: Handle Encryption logic
        if (isEncrypted) {
            let cipherText = null;

            // Scenario A: New Format (Wrapped in JSON)
            if (parsedMetadata && typeof parsedMetadata === 'object' && parsedMetadata.cipher_text) {
                cipherText = parsedMetadata.cipher_text;
            } 
            // Scenario B: Legacy Format (Raw string in DB)
            else if (typeof metadataStr === 'string' && metadataStr.includes(':')) {
                cipherText = metadataStr;
            }

            if (cipherText) {
                try {
                    const decryptedStr = decrypt(cipherText);
                    parsedMetadata = JSON.parse(decryptedStr);
                } catch (decErr) {
                    console.warn('❌ [DECRYPT/PARSE FAIL]:', decErr.message);
                    // Fallback to the object if it was already partially parsed
                }
            }
        }
        
        metadataStr = parsedMetadata;
    } catch (pErr) {
        console.warn('⚠️ [PARSE ROW WARNING]:', pErr.message);
        metadataStr = typeof metadataStr === 'string' ? { _raw: metadataStr } : metadataStr;
    }

    return {
        asset_id: asset.asset_id,
        user_id: asset.user_id,
        category: asset.category,
        title: asset.title,
        is_encrypted: asset.is_encrypted,
        created_at: asset.created_at,
        updated_at: asset.updated_at,
        metadata: metadataStr,
        ...metadataStr // Also flatten for backward compat
    };
};

// ─────────────────────────────────────────────────────────────
// GET /api/vault/schemas — Serve hierarchical schemas to frontend
// ─────────────────────────────────────────────────────────────
const getSchemas = async (req, res) => {
    try {
        // Prepare subcategories
        const categories = {};
        Object.entries(CATEGORY_SCHEMAS).forEach(([key, schema]) => {
            categories[key] = {
                key: schema.key,
                parent: schema.parent,
                label: schema.label,
                icon: schema.icon,
                fields: schema.fields.map(f => ({
                    key: f.key,
                    label: f.label,
                    type: f.type,
                    required: f.required,
                    placeholder: f.placeholder || '',
                    options: f.options || [],
                }))
            };
        });

        res.json({
            parents: PARENT_CATEGORIES,
            categories: categories
        });
    } catch (error) {
        console.error('❌ [GET SCHEMAS ERROR]:', error);
        res.status(500).json({ message: 'Error fetching schemas' });
    }
};

// ─────────────────────────────────────────────────────────────
// GET /api/vault/summary — Dashboard counts per category & parent
// ─────────────────────────────────────────────────────────────
const getSummary = async (req, res) => {
    const userId = req.user.id;

    try {
        const [rows] = await db.execute(
            'SELECT category, COUNT(*) as count FROM assets WHERE user_id = ? GROUP BY category',
            [userId]
        );

        const subcategory_counts = {};
        const parent_counts = {};

        // Init parent counts
        Object.keys(PARENT_CATEGORIES).forEach(pk => parent_counts[pk] = 0);
        
        // Init subcategory counts
        getValidCategories().forEach(ck => subcategory_counts[ck] = 0);

        // Fill data
        for (const row of rows) {
            const catKey = (row.category || '').toLowerCase();
            const count = parseInt(row.count);

            if (subcategory_counts.hasOwnProperty(catKey)) {
                subcategory_counts[catKey] = count;
                
                // Aggregate to parent
                const schema = CATEGORY_SCHEMAS[catKey];
                if (schema && schema.parent && parent_counts.hasOwnProperty(schema.parent)) {
                    parent_counts[schema.parent] += count;
                }
            }
        }

        const total = Object.values(subcategory_counts).reduce((a, b) => a + b, 0);

        res.json({ 
            total, 
            parent_counts, 
            subcategory_counts 
        });
    } catch (error) {
        console.error('❌ [GET SUMMARY ERROR]:', error);
        res.status(500).json({ message: 'Error fetching summary' });
    }
};

// ─────────────────────────────────────────────────────────────
// GET /api/vault/search?q= — Cross-category search
// ─────────────────────────────────────────────────────────────
const searchItems = async (req, res) => {
    const userId = req.user.id;
    const query = req.query.q;

    if (!query || query.trim().length < 2) {
        return res.status(400).json({ message: 'Search query must be at least 2 characters' });
    }

    try {
        const searchTerm = `%${query.trim()}%`;
        const [rows] = await db.execute(
            'SELECT * FROM assets WHERE user_id = ? AND (title LIKE ? OR metadata LIKE ?) ORDER BY updated_at DESC LIMIT 50',
            [userId, searchTerm, searchTerm]
        );

        const results = rows.map(parseAssetRow);
        res.json(results);
    } catch (error) {
        console.error('❌ [SEARCH ERROR]:', error);
        res.status(500).json({ message: 'Error searching vault' });
    }
};

// ─────────────────────────────────────────────────────────────
// GET /api/vault/:category — List items in a category
// ─────────────────────────────────────────────────────────────
const getItems = async (req, res) => {
    const userId = req.user.id;
    const { category } = req.params;
    const vaultContext = req.header('x-vault-context');

    // Validate category
    if (!getValidCategories().includes(category)) {
        return res.status(400).json({ message: `Invalid category: ${category}` });
    }

    try {
        let targetUserId = userId;

        // Nominee access logic (ported from web)
        if (vaultContext && vaultContext !== 'null') {
            const vaultOwnerId = parseInt(vaultContext);
            const [accessRows] = await db.execute(
                'SELECT nominee_id FROM nominees WHERE user_id = ? AND linked_user_id = ? AND is_verified = 1',
                [vaultOwnerId, userId]
            );

            if (accessRows.length > 0) {
                targetUserId = vaultOwnerId;
            } else if (vaultOwnerId !== userId) {
                return res.status(403).json({ message: 'Unauthorized access to this vault' });
            }
        }

        const [rows] = await db.execute(
            'SELECT * FROM assets WHERE user_id = ? AND category = ? ORDER BY created_at DESC',
            [targetUserId, category]
        );

        const items = rows.map(parseAssetRow);
        res.json(items);
    } catch (error) {
        console.error(`❌ [GET ${category.toUpperCase()} ERROR]:`, error);
        res.status(500).json({ message: `Error fetching ${category}` });
    }
};

// ─────────────────────────────────────────────────────────────
// GET /api/vault/:category/:id — Get single item detail
// ─────────────────────────────────────────────────────────────
const getItem = async (req, res) => {
    const userId = req.user.id;
    const { category, id } = req.params;

    if (!getValidCategories().includes(category)) {
        return res.status(400).json({ message: `Invalid category: ${category}` });
    }

    try {
        const [rows] = await db.execute(
            'SELECT * FROM assets WHERE asset_id = ? AND user_id = ? AND category = ?',
            [id, userId, category]
        );

        if (rows.length === 0) {
            return res.status(404).json({ message: 'Item not found' });
        }

        const item = parseAssetRow(rows[0]);

        // Attach schema for frontend rendering
        const schema = getCategorySchema(category);
        item._schema = schema ? schema.fields.map(f => ({
            key: f.key,
            label: f.label,
            type: f.type,
        })) : [];

        res.json(item);
    } catch (error) {
        console.error(`❌ [GET ITEM ERROR]:`, error);
        res.status(500).json({ message: 'Error fetching item' });
    }
};

// ─────────────────────────────────────────────────────────────
// POST /api/vault/:category — Add new item
// ─────────────────────────────────────────────────────────────
const addItem = async (req, res) => {
    const userId = req.user.id;
    const { category } = req.params;
    const { metadata, is_encrypted = 1 } = req.body;

    // Validate category exists
    if (!getValidCategories().includes(category)) {
        return res.status(400).json({ message: `Invalid category: ${category}` });
    }

    if (!metadata || typeof metadata !== 'object') {
        return res.status(400).json({ message: 'metadata object is required' });
    }

    // Validate metadata against schema
    const validation = validateMetadata(category, metadata);
    if (!validation.valid) {
        console.error(`❌ [VALIDATION FAILED] ${category}:`, validation.errors);
        return res.status(400).json({ 
            message: 'Validation failed', 
            errors: validation.errors,
            details: `Missing or invalid fields: ${validation.errors.map(e => e.field).join(', ')}`
        });
    }

    try {
        // Extract title from the first required text field
        const title = extractTitle(category, metadata);

        let metadataValue;
        if (parseInt(is_encrypted) === 1) {
            const encryptedStr = encrypt(JSON.stringify(metadata));
            // WRAP IN JSON for MySQL JSON column compatibility
            metadataValue = JSON.stringify({ cipher_text: encryptedStr });
        } else {
            metadataValue = JSON.stringify(metadata);
        }

        const [result] = await db.execute(
            'INSERT INTO assets (user_id, category, title, metadata, is_encrypted) VALUES (?, ?, ?, ?, ?)',
            [userId, category, title, metadataValue, is_encrypted]
        );

        // Audit log
        try {
            await db.execute(
                'INSERT INTO audit_logs (user_id, action, ip_address, device_info) VALUES (?, ?, ?, ?)',
                [userId, `VAULT_ADD:${category}:${result.insertId}`, req.ip || 'unknown', req.get('user-agent') || 'unknown']
            );
        } catch (auditErr) {
            console.warn('⚠️ Audit log failed:', auditErr.message);
        }

        // AI Card Benefit Discovery (Background)
        if (category === 'cards' && metadata.bank_name && metadata.variant) {
            setImmediate(async () => {
                console.log(`[AI]: Triggering benefit discovery for Card ${result.insertId}`);
                const benefits = await getCardBenefits(metadata.bank_name, metadata.variant, metadata.network || '');
                if (benefits && benefits.length > 0) {
                    const updatedMetadata = { ...metadata, benefits };
                    const finalOutput = parseInt(is_encrypted) === 1 
                        ? JSON.stringify({ cipher_text: encrypt(JSON.stringify(updatedMetadata)) })
                        : JSON.stringify(updatedMetadata);
                    
                    await db.execute(
                        'UPDATE assets SET metadata = ? WHERE asset_id = ?',
                        [finalOutput, result.insertId]
                    );
                    console.log(`[AI]: Stored ${benefits.length} benefits for Card ${result.insertId}`);
                }
            });
        }

        res.status(201).json({
            message: 'Item added successfully',
            assetId: result.insertId,
            category,
            title
        });
    } catch (error) {
        console.error(`❌ [ADD ${category.toUpperCase()} ERROR]:`, error);
        res.status(500).json({ message: 'Error adding item' });
    }
};

// ─────────────────────────────────────────────────────────────
// POST /api/vault/cards/:id/benefits — Manually trigger AI benefits
// ─────────────────────────────────────────────────────────────
const fetchItemBenefits = async (req, res) => {
    const userId = req.user.id;
    const { id } = req.params;

    try {
        const [rows] = await db.execute(
            'SELECT * FROM assets WHERE asset_id = ? AND user_id = ? AND category = "cards"',
            [id, userId]
        );

        if (rows.length === 0) {
            return res.status(404).json({ message: 'Card not found' });
        }

        const asset = parseAssetRow(rows[0]);
        const metadata = asset.metadata;

        if (!metadata.bank_name || !metadata.variant) {
            return res.status(400).json({ message: 'Missing bank_name or variant for AI discovery' });
        }

        const benefits = await getCardBenefits(metadata.bank_name, metadata.variant, metadata.network || '');
        
        // Update DB
        const updatedMetadata = { ...metadata, benefits };
        let metadataValue;
        if (parseInt(asset.is_encrypted) === 1) {
            const encryptedStr = encrypt(JSON.stringify(updatedMetadata));
            metadataValue = JSON.stringify({ cipher_text: encryptedStr });
        } else {
            metadataValue = JSON.stringify(updatedMetadata);
        }

        await db.execute(
            'UPDATE assets SET metadata = ? WHERE asset_id = ?',
            [metadataValue, id]
        );

        res.json({ benefits });
    } catch (error) {
        console.error('❌ [FETCH BENEFITS ERROR]:', error);
        res.status(500).json({ message: 'Error fetching AI benefits' });
    }
};

// ─────────────────────────────────────────────────────────────
// PUT /api/vault/:category/:id — Update item
// ─────────────────────────────────────────────────────────────
const updateItem = async (req, res) => {
    const userId = req.user.id;
    const { category, id } = req.params;
    const { metadata, is_encrypted = 1 } = req.body;

    if (!getValidCategories().includes(category)) {
        return res.status(400).json({ message: `Invalid category: ${category}` });
    }

    if (!metadata || typeof metadata !== 'object') {
        return res.status(400).json({ message: 'metadata object is required' });
    }

    // Validate (allow partial updates — don't enforce required on update)
    const schema = getCategorySchema(category);
    if (!schema) {
        return res.status(400).json({ message: `Unknown category: ${category}` });
    }

    try {
        const title = extractTitle(category, metadata);

        let metadataValue;
        if (parseInt(is_encrypted) === 1) {
            const encryptedStr = encrypt(JSON.stringify(metadata));
            metadataValue = JSON.stringify({ cipher_text: encryptedStr });
        } else {
            metadataValue = JSON.stringify(metadata);
        }

        const [result] = await db.execute(
            'UPDATE assets SET title = ?, metadata = ?, is_encrypted = ? WHERE asset_id = ? AND user_id = ? AND category = ?',
            [title, metadataValue, is_encrypted, id, userId, category]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Item not found or unauthorized' });
        }

        // Audit log
        try {
            await db.execute(
                'INSERT INTO audit_logs (user_id, action, ip_address, device_info) VALUES (?, ?, ?, ?)',
                [userId, `VAULT_UPDATE:${category}:${id}`, req.ip || 'unknown', req.get('user-agent') || 'unknown']
            );
        } catch (auditErr) {
            console.warn('⚠️ Audit log failed:', auditErr.message);
        }

        res.json({ message: 'Item updated successfully' });
    } catch (error) {
        console.error(`❌ [UPDATE ${category.toUpperCase()} ERROR]:`, error);
        res.status(500).json({ message: 'Error updating item' });
    }
};

// ─────────────────────────────────────────────────────────────
// DELETE /api/vault/:category/:id — Delete item
// ─────────────────────────────────────────────────────────────
const deleteItem = async (req, res) => {
    const userId = req.user.id;
    const { category, id } = req.params;

    if (!getValidCategories().includes(category)) {
        return res.status(400).json({ message: `Invalid category: ${category}` });
    }

    try {
        const [result] = await db.execute(
            'DELETE FROM assets WHERE asset_id = ? AND user_id = ? AND category = ?',
            [id, userId, category]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Item not found or unauthorized' });
        }

        // Audit log
        try {
            await db.execute(
                'INSERT INTO audit_logs (user_id, action, ip_address, device_info) VALUES (?, ?, ?, ?)',
                [userId, `VAULT_DELETE:${category}:${id}`, req.ip || 'unknown', req.get('user-agent') || 'unknown']
            );
        } catch (auditErr) {
            console.warn('⚠️ Audit log failed:', auditErr.message);
        }

        res.json({ message: 'Item deleted successfully' });
    } catch (error) {
        console.error(`❌ [DELETE ${category.toUpperCase()} ERROR]:`, error);
        res.status(500).json({ message: 'Error deleting item' });
    }
};

module.exports = {
    getSchemas,
    getSummary,
    searchItems,
    getItems,
    getItem,
    addItem,
    updateItem,
    deleteItem,
    fetchItemBenefits
};
