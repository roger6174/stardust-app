const { encrypt, decrypt } = require('./src/utils/crypto');

// Mock asset row with triple-stringified metadata (very corrupted)
const corruptedAsset = {
    metadata: '"""' + encrypt(JSON.stringify({ bank_name: 'HDFC', last_4: '1234' })) + '"""',
    is_encrypted: 1
};

// Mock asset row with healthy metadata
const healthyAsset = {
    metadata: encrypt(JSON.stringify({ bank_name: 'ICICI', last_4: '5678' })),
    is_encrypted: 1
};

function parseAssetRow(asset) {
    let metadataStr = asset.metadata;
    const isEncrypted = parseInt(asset.is_encrypted) === 1;

    try {
        // Robust check: Strip all surrounding quotes if stringified multiple times
        if (typeof metadataStr === 'string') {
            metadataStr = metadataStr.trim().replace(/^"+|"+$/g, '');
        }

        if (isEncrypted && typeof metadataStr === 'string' && metadataStr.includes(':')) {
            metadataStr = decrypt(metadataStr);
        }

        return typeof metadataStr === 'string' ? JSON.parse(metadataStr) : metadataStr;
    } catch (pErr) {
        return { _parse_error: true, raw: metadataStr, err: pErr.message };
    }
}

console.log('--- Corrupted Asset Test ---');
console.log(parseAssetRow(corruptedAsset));

console.log('\n--- Healthy Asset Test ---');
console.log(parseAssetRow(healthyAsset));
