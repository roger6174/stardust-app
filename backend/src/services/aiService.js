const { GoogleGenerativeAI } = require('@google/generative-ai');
require('dotenv').config();

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

/**
 * Fetches structured credit card benefits using Gemini AI.
 * Ported from the web team's Python service logic.
 * 
 * @param {string} bank E.g., 'HDFC'
 * @param {string} variant E.g., 'Infinia'
 * @param {string} network E.g., 'Visa'
 * @returns {Promise<Array>} List of 5 benefits
 */
const getCardBenefits = async (bank, variant, network) => {
    try {
        const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

        const prompt = `
You are a professional financial assistant.

Explain the benefits of the ${bank} ${variant} credit card on the ${network} network.

- Provide exactly 5 concise, one-sentence bullet points.
- Do not use asterisks or any other special characters for emphasis.
- Keep language simple and clear.
- Mentions who it is best suited for in one of the points.
- If unsure, give typical category benefits.

Return the response as a JSON array of strings. 
Example format: ["Point 1", "Point 2", "Point 3", "Point 4", "Point 5"]
`;

        const result = await model.generateContent(prompt);
        const response = await result.response;
        const text = response.text();
        
        // Extract JSON array from text (Gemini sometimes wraps in markdown code blocks)
        const jsonMatch = text.match(/\[.*\]/s);
        if (jsonMatch) {
            return JSON.parse(jsonMatch[0]);
        }
        
        // Fallback for non-JSON response
        return text.split('\n').filter(l => l.trim().length > 0).slice(0, 5);
    } catch (error) {
        console.error('❌ [AI SERVICE ERROR]:', error.message);
        return [
            "Reward points on every spend",
            "Contactless payments enabled",
            "Fuel surcharge waiver",
            "Dining discounts at partner restaurants",
            "Best suited for general daily spending"
        ];
    }
};

module.exports = { getCardBenefits };
