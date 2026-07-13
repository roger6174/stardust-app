# Stardust Vault - Backend Service (Phase 9 Stable)

This repository contains the backend API for the Stardust Vault Digital Succession Platform. It handles authentication, secure document management (AWS S3), and persistent data storage (AWS RDS).

## 🚀 Key Features

*   **Secure Authentication**: JWT-based login with OTP verification (Twilio/WhatsApp/Email).
*   **Asset Management**: CRUD operations for categorized user assets (Insurance, Investments, Contacts, etc.).
*   **S3 Document Integration**: Direct document scan/upload with presigned URLs for secure viewing.
*   **Direct-Strike Connectivity**: Optimized raw database drivers for stable AWS RDS communication.
*   **Security Logs**: Comprehensive audit trails for user activities.

## 🛠️ Tech Stack

*   **Runtime**: Node.js (v24+)
*   **Framework**: Express.js
*   **Database**: AWS RDS (MySQL)
*   **Storage**: AWS S3
*   **Authentication**: JWT & OTP (MSG91/Twilio)

## 📦 Setup & Installation

1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/dev09saransh/stardust_backend.git
    cd stardust_backend
    ```

2.  **Environment Configuration**:
    Create a `.env` file in the root directory (refer to `.env.example` if available) and add your AWS and DB credentials.

3.  **Local Execution**:
    ```bash
    npm install
    npm start
    ```

## 🔐 Security Notice
Credentials are never stored in the repository. Ensure your local `.env` is properly configured and ignored by git.
