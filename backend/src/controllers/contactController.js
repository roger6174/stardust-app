const db = require('../config/db');
const { encrypt, decrypt } = require('../utils/crypto');

/**
 * Add a new contact
 */
const addContact = async (req, res) => {
    const { name, relation, phone, email, id_type, id_number, notes, is_encrypted = 1 } = req.body;
    const userId = req.user.id;

    if (!name) {
        return res.status(400).json({ message: 'Name is required' });
    }

    try {
        const metadata = {
            relation,
            phone,
            email,
            id_type,
            id_number,
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
            [userId, 'CONTACT', name, metadataValue, is_encrypted]
        );

        res.status(201).json({
            message: 'Contact added successfully',
            assetId: result.insertId
        });
    } catch (error) {
        console.error('❌ [ADD CONTACT ERROR]:', error);
        res.status(500).json({ message: 'Error adding contact' });
    }
};

/**
 * Get all contacts for the authenticated user
 */
const getContacts = async (req, res) => {
    const userId = req.user.id;

    try {
        const [rows] = await db.execute(
            'SELECT * FROM assets WHERE user_id = ? AND category = ? ORDER BY created_at DESC', 
            [userId, 'CONTACT']
        );

        const contacts = rows.map(asset => {
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
                name: asset.title,
                is_encrypted: asset.is_encrypted,
                created_at: asset.created_at,
                updated_at: asset.updated_at,
                ...parsedMetadata // Flatten metadata for mobile frontend compatibility
            };
        });

        res.json(contacts);
    } catch (error) {
        console.error('❌ [GET CONTACTS ERROR]:', error);
        res.status(500).json({ message: 'Error fetching contacts' });
    }
};

/**
 * Update an existing contact
 */
const updateContact = async (req, res) => {
    const assetId = req.params.id;
    const { name, relation, phone, email, id_type, id_number, notes, is_encrypted } = req.body;
    const userId = req.user.id;

    try {
        const metadata = {
            relation,
            phone,
            email,
            id_type,
            id_number,
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
            [name, metadataValue, is_encrypted, assetId, userId, 'CONTACT']
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Contact not found or unauthorized' });
        }

        res.json({ message: 'Contact updated successfully' });
    } catch (error) {
        console.error('❌ [UPDATE CONTACT ERROR]:', error);
        res.status(500).json({ message: 'Error updating contact' });
    }
};

/**
 * Delete a contact
 */
const deleteContact = async (req, res) => {
    const assetId = req.params.id;
    const userId = req.user.id;

    try {
        const [result] = await db.execute(
            'DELETE FROM assets WHERE asset_id = ? AND user_id = ? AND category = ?',
            [assetId, userId, 'CONTACT']
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Contact not found or unauthorized' });
        }

        res.json({ message: 'Contact deleted successfully' });
    } catch (error) {
        console.error('❌ [DELETE CONTACT ERROR]:', error);
        res.status(500).json({ message: 'Error deleting contact' });
    }
};

module.exports = { addContact, getContacts, updateContact, deleteContact };

