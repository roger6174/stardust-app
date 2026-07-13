const axios = require('axios');
const API_URL = 'http://localhost:5000/api';

async function testAdd() {
    try {
        // 1. Login
        console.log('Logging in...');
        const loginRes = await axios.post(`${API_URL}/auth/login`, {
            email: 'test@example.com',
            password: 'Password123!'
        });
        const token = loginRes.data.token;
        console.log('Login successful');

        const categories = ['banking', 'cards', 'passwords'];
        
        for (const cat of categories) {
            console.log(`Testing category: ${cat}`);
            const payload = {
                metadata: {
                    bank_name: 'Test Bank',
                    account_type: 'Savings',
                    last_4_digits: '1234',
                    title: `Test ${cat}`, // generic
                    username: 'testuser',
                    password: 'testpassword',
                    variant: 'Platinum',
                    number: '4111222233334444'
                },
                is_encrypted: 1
            };

            try {
                const res = await axios.post(`${API_URL}/vault/${cat}`, payload, {
                    headers: { Authorization: `Bearer ${token}` }
                });
                console.log(`✅ Success for ${cat}:`, res.data.asset_id);
            } catch (err) {
                console.error(`❌ Failed for ${cat}:`, err.response ? err.response.data : err.message);
            }
        }
    } catch (err) {
        console.error('Fatal error:', err.message);
    }
}

testAdd();
