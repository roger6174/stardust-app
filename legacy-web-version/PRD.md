# Stardust Financial Vault - Product Requirement Document (PRD)

## 1. Core Feature Set (Existing & Operational)
These features comprise the current Stardust Financial Vault application, focusing on security, asset management, and succession planning.

| Feature Category | Feature Name | Description | Status |
| :--- | :--- | :--- | :--- |
| **Authentication** | Secure Multi-Factor Login | JWT-based authentication with mandatory 6-digit OTP verification via WhatsApp/Email. | Live |
| **Authentication** | Role-Based Access (RBAC) | Distinct workflows and dashboards for Customers and System Administrators. | Live |
| **Asset Management** | Financial Vault | Secure storage for Bank Accounts, Insurance, Real Estate, and Digital Assets. | Live |
| **Asset Management** | Card Benefits AI | Gemini-powered OCR and analysis to extract benefits from credit card statements. | Live |
| **Succession** | Inactivity Monitor | Automated "Pulse Check" system that tracks user activity over months. | Live |
| **Succession** | Automated Trigger | Multi-stage escalation protocol (Yellow/Red) that initiates when inactivity thresholds are met. | Live |
| **Nominee System** | Trusted Contact Management | Ability to register, verify, and link multiple nominees with specific relationship settings. | Live |
| **Nominee System** | Identity Verification | Secure portal for nominees to upload ID proof and claim vault access post-succession. | Live |
| **Security** | Zero-Knowledge Pattern | Sensitive vault metadata is protected using industry-standard encryption protocols. | Live |
| **Security** | Audit Logging | Comprehensive tracking of all logins, IP addresses, and device information for security audits. | Live |
| **Security** | Multi-Method Recovery | Account recovery via registered security questions or WhatsApp-based identity proofing. | Live |
| **Workflow** | Onboarding Tour | Step-by-step interactive guide to help users complete their vault setup and policy configuration. | Live |

---

## 2. Specialized API Services (Core Focus & Planned)
These are the technical service offerings developed for enterprise integration and standalone utility.

| Service Name | Feature | Technical Specification | Category |
| :--- | :--- | :--- | :--- |
| **OTP API Service** | Global Delivery | Multi-channel delivery of 6-digit codes via WhatsApp (via MSG91/Twilio), SMS, and Email. | Current/Planned |
| **OTP API Service** | Secure Hashing | Automated bcrypt hashing of codes; never stored in plaintext on the database. | Current/Planned |
| **OTP API Service** | Custom Expiry | Configurable TTL (Time-To-Live) for codes, defaulting to 5-10 minutes. | Current/Planned |
| **OTP API Service** | Rate Limiting | Intelligent throttling to prevent brute-force attacks on specific mobile numbers. | Current/Planned |
| **OTP API Service** | Verification API | Direct endpoint for third-party apps to validate user-submitted codes against active sessions. | Planned |
| **Message Forwarding** | SMS-to-WhatsApp | Automated redirection of incoming SMS messages to a designated WhatsApp number. | Planned |
| **Message Forwarding** | Webhook Forwarding | Real-time forwarding of incoming messages to a specified URL for external automation. | Planned |
| **Message Forwarding** | Routing Logic | Keyword-based routing to direct messages to different teams or endpoints. | Planned |
| **Message Forwarding** | Centralized Logs | Unified dashboard to view, search, and audit all forwarded message history. | Planned |
| **Message Forwarding** | Notification API | Push notifications to mobile apps when a message is successfully forwarded. | Planned |

---

## 3. Technical Roadmap (Future Enhancements)
Features aimed at scaling the platform into a broader fintech infrastructure.

| Roadmap Item | Description | Intent |
| :--- | :--- | :--- |
| **Account Aggregator** | Deep integration with Setu AA for automated financial data fetching. | Automation |
| **Biometric Bypass** | FaceID/Fingerprint support for secondary authentication on mobile devices. | UX |
| **Smart Portfolio AI** | AI-driven insights on asset diversification and recovery potential. | Intelligence |
| **Enterprise White-Label** | Providing the OTP and Vault infrastructure to other banks and legacy firms. | B2B |
