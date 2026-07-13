const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

async function debugConnection() {
    console.log('--- DB DEBUG START ---');
    console.log('Host:', process.env.DB_HOST);
    console.log('User:', process.env.DB_USER);
    console.log('DB:', process.env.DB_NAME);
    console.log('SSL:', process.env.DB_SSL);

    const possibleCertPaths = [
        path.join(__dirname, 'global-bundle.pem'),
        path.join(__dirname, 'src/config', '../../global-bundle.pem'),
        '/home/ubuntu/global-bundle.pem'
    ];

    let ca = null;
    for (const p of possibleCertPaths) {
        if (fs.existsSync(p)) {
            console.log('Found cert at:', p);
            ca = fs.readFileSync(p);
            break;
        }
    }

    const config = {
        host: process.env.DB_HOST,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME,
        connectTimeout: 10000, // Reduced to 10s for faster debug
        ssl: process.env.DB_SSL === 'true' ? { ca } : null
    };

    console.log('Attempting connection...');
    const start = Date.now();
    try {
        const conn = await mysql.createConnection(config);
        console.log(`Connected successfully in ${Date.now() - start}ms`);
        const [rows] = await conn.execute('SELECT 1 as result');
        console.log('Query result:', rows);
        await conn.end();
    } catch (err) {
        console.error(`Failed after ${Date.now() - start}ms`);
        console.error('Error Code:', err.code);
        console.error('Error Message:', err.message);
        if (err.code === 'ETIMEDOUT') {
            console.error('DIAGNOSIS: The database port (3306) is unreachable. Check Security Groups or Firewalls.');
        }
    }
}

debugConnection();
