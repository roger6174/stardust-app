const db = require('../config/db');
const { encrypt, decrypt } = require('../utils/crypto');

/**
 * Add a new insurance entry
 */
const addInsurance = async (req, res) => {
    const { policy_name, provider, type, policy_number, premium, coverage, expiry_date, notes, is_encrypted = 1 } = req.body;
    const userId = req.user.id;

    if (!policy_name) {
        return res.status(400).json({ message: 'Policy name is required' });
    }

    try {
        const metadata = {
            provider,
            type,
            policy_number,
            premium,
            coverage,
            expiry_date,
            notes
        };

        let metadataValue;
        if (parseInt(is_encrypted) === 1) {
            const encrypted = encrypt(JSON.stringify(metadata));
            metadataValue = JSON.stringify(encrypted);
        } else {
            metadataValue = JSON.stringify(metadata);
        }

        const [result] = await db.execute(
            'INSERT INTO assets (user_id, category, title, metadata, is_encrypted) VALUES (?, ?, ?, ?, ?)',
            [userId, 'INSURANCE', policy_name, metadataValue, is_encrypted]
        );

        res.status(201).json({
            message: 'Insurance saved successfully',
            assetId: result.insertId
        });
    } catch (error) {
        console.error('❌ [ADD INSURANCE ERROR]:', error);
        res.status(500).json({ message: 'Error saving insurance' });
    }
};

/**
 * Get all insurance policies for the authenticated user
 */
const getInsurance = async (req, res) => {
    const userId = req.user.id;

    try {
        const [rows] = await db.execute(
            'SELECT * FROM assets WHERE user_id = ? AND category = ? ORDER BY created_at DESC', 
            [userId, 'INSURANCE']
        );

        const insurance = rows.map(asset => {
            let metadataStr = asset.metadata;
            const isEncrypted = parseInt(asset.is_encrypted) === 1;

            if (isEncrypted && typeof metadataStr === 'string' && metadataStr.includes(':')) {
                metadataStr = decrypt(metadataStr);
            }
            
            let parsedMetadata = {};
            try {
                parsedMetadata = typeof metadataStr === 'string' ? JSON.parse(metadataStr) : metadataStr;
            } catch (pErr) {
                parsedMetadata = { error: 'Failed to parse metadata', raw: metadataStr };
            }

            return {
                asset_id: asset.asset_id,
                user_id: asset.user_id,
                category: asset.category,
                title: asset.title,
                is_encrypted: asset.is_encrypted,
                created_at: asset.created_at,
                updated_at: asset.updated_at,
                ...parsedMetadata // Flatten metadata for mobile frontend compatibility
            };
        });

        res.json(insurance);
    } catch (error) {
        console.error('❌ [GET INSURANCE ERROR]:', error);
        res.status(500).json({ message: 'Error fetching insurance' });
    }
};

/**
 * Update an existing insurance entry
 */
const updateInsurance = async (req, res) => {
    const assetId = req.params.id;
    const { policy_name, provider, type, policy_number, premium, coverage, expiry_date, notes, is_encrypted } = req.body;
    const userId = req.user.id;

    try {
        const metadata = {
            provider,
            type,
            policy_number,
            premium,
            coverage,
            expiry_date,
            notes
        };

        let metadataValue;
        if (parseInt(is_encrypted) === 1) {
            const encrypted = encrypt(JSON.stringify(metadata));
            metadataValue = JSON.stringify(encrypted);
        } else {
            metadataValue = JSON.stringify(metadata);
        }

        const [result] = await db.execute(
            'UPDATE assets SET title = ?, metadata = ?, is_encrypted = ? WHERE asset_id = ? AND user_id = ? AND category = ?',
            [policy_name, metadataValue, is_encrypted, assetId, userId, 'INSURANCE']
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Insurance entry not found or unauthorized' });
        }

        res.json({ message: 'Insurance updated successfully' });
    } catch (error) {
        console.error('❌ [UPDATE INSURANCE ERROR]:', error);
        res.status(500).json({ message: 'Error updating insurance' });
    }
};

/**
 * Delete an insurance entry
 */
const deleteInsurance = async (req, res) => {
    const assetId = req.params.id;
    const userId = req.user.id;

    try {
        const [result] = await db.execute(
            'DELETE FROM assets WHERE asset_id = ? AND user_id = ? AND category = ?',
            [assetId, userId, 'INSURANCE']
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Insurance entry not found or unauthorized' });
        }

        res.json({ message: 'Insurance deleted successfully' });
    } catch (error) {
        console.error('❌ [DELETE INSURANCE ERROR]:', error);
        res.status(500).json({ message: 'Error deleting insurance' });
    }
};

module.exports = { addInsurance, getInsurance, updateInsurance, deleteInsurance };


module.exports = { addInsurance, getInsurance, updateInsurance, deleteInsurance };
