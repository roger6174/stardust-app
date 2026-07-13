/**
 * Compresses an image buffer using sharp and converts it to PNG.
 * @param {Buffer} buffer - The image buffer to compress.
 * @returns {Promise<Buffer>} - The compressed PNG image buffer.
 */
const compressImage = async (buffer) => {
    try {
        let sharp;
        try {
            sharp = require('sharp');
        } catch (e) {
            console.warn('⚠️ [COMPRESSION]: sharp module not found. Skipping image compression.');
            return buffer;
        }

        const metadata = await sharp(buffer).metadata();
        let pipeline = sharp(buffer);

        // If it's a large image, resize it to a maximum of 2000px width/height while maintaining aspect ratio
        if (metadata.width > 2000 || metadata.height > 2000) {
            pipeline = pipeline.resize(2000, 2000, {
                fit: 'inside',
                withoutEnlargement: true
            });
        }

        // Convert any image format to PNG as requested by user
        // We use some compression for PNG to keep size small
        return await pipeline
            .png({ 
                compressionLevel: 9, // Highest compression
                adaptiveFiltering: true,
                force: true // Ensure output is PNG
            })
            .toBuffer();
    } catch (error) {
        console.error('❌ [COMPRESSION ERROR]:', error);
        // Fallback to original buffer if sharp fails or processing errors occur
        return buffer;
    }
};

/**
 * Generic file compression placeholder.
 * For now, it returns the buffer, but can be extended with zlib for text files.
 */
const compressGenericFile = async (buffer, mimetype) => {
    // For text-based files, we could use zlib, but most modern browsers/servers 
    // already use GZIP/Brotli for transfer. 
    // Here we just ensure we don't break the flow.
    return buffer;
};

/**
 * Checks if a file is an image based on its mimetype.
 * @param {string} mimetype - The file's mimetype.
 * @returns {boolean}
 */
const isImage = (mimetype) => {
    return mimetype && mimetype.startsWith('image/');
};

module.exports = {
    compressImage,
    compressGenericFile,
    isImage
};
