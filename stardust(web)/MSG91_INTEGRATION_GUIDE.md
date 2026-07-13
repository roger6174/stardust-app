# 🛠️ MSG91 WhatsApp Integration Architecture: Technical Guide

This document provides an exhaustive technical breakdown of the MSG91 WhatsApp integration for the **Stardust Financial Vault** project. It is designed to be shared with **MSG91 / Meta Technical Support** to resolve delivery failures, authentication errors, or template validation issues.

---

## 1. Core Integration Specs
Our platform utilizes the **MSG91 v5 WhatsApp Outbound (Bulk) API** for all automated notifications. All communication is centered around a centralized service layer.

| Component | Technical Detail |
| :--- | :--- |
| **API Endpoint** | `https://api.msg91.com/api/v5/whatsapp/whatsapp-outbound-message/bulk/` |
| **Request Method** | `POST` |
| **Payload Format** | `JSON` (Strictly validated) |
| **Integrated Number** | `917204342233` (India Country Code provided) |
| **WABA Namespace** | `b05d09f6_1d90_4a1b_8d0a_d5d650046fb0` |
| **Auth Mechanism** | Header `authkey` |

---

## 2. Environment Configuration (.env)
The system retrieves these values from a secured environment file to maintain flexibility between development and production.

```bash
MSG91_AUTH_KEY=YOUR_AUTH_KEY          # Primary API Authentication
MSG91_WHATSAPP_NUMBER=917204342233    # Integrated sender number
MSG91_WHATSAPP_NAMESPACE=b05d09f6_...  # Verified WABA Namespace
```

---

## 3. Template-to-Component Logic Mapping
Our backend code (`msg91Service.js`) dynamically maps project variables to specific **Component Keys** and **Parameter Names** required by your system. This mapping is vital for template calibration.

### 📋 MAPPING TABLE: CODE VARIABLE → COMPONENT KEY

| Code Variable | MSG91 Component Key | Template Association |
| :--- | :--- | :--- |
| `variables.verification_url` | `body_verification_url` | `stardust_succession_notice` |
| `variables.owner_name` | `body_owner_name` | All core templates |
| `variables.nominee_name` | `body_nominee_name` | `stardust_succession_notice` |
| `variables.app_url` | `body_app_url` | `stardust_security_pulse_v2` |
| `variables.otp` / `variables.security_code` | `body_1` | `otp_verification_stardust` |
| `variables.url` / `variables.button_1` | `button_1` | `otp_verification_stardust` |

---

## 4. Full JSON Payload Examples (All 5 Templates)
These examples represent the **exact JSON payload** sent to your API for each template.

### 1. Template: `stardust_succession_notice` (Succession Invitation)
```json
{
  "integrated_number": "917204342233",
  "content_type": "template",
  "payload": {
    "messaging_product": "whatsapp",
    "type": "template",
    "template": {
      "name": "stardust_succession_notice",
      "language": { "code": "en", "policy": "deterministic" },
      "namespace": "b05d09f6_1d90_4a1b_8d0a_d5d650046fb0",
      "to_and_components": [{
        "to": ["9198XXXXXXXX"],
        "components": {
          "body_verification_url": { "type": "text", "value": "https://stardustvault.com/verify?token=XYZ", "parameter_name": "verification_url" },
          "body_owner_name": { "type": "text", "value": "Customer Name", "parameter_name": "owner_name" },
          "body_nominee_name": { "type": "text", "value": "Nominee Name", "parameter_name": "nominee_name" }
        }
      }]
    }
  }
}
```

### 2. Template: `stardust_security_pulse_v2` (Security Reminder)
```json
{
  "integrated_number": "917204342233",
  "content_type": "template",
  "payload": {
    "messaging_product": "whatsapp",
    "type": "template",
    "template": {
      "name": "stardust_security_pulse_v2",
      "language": { "code": "en", "policy": "deterministic" },
      "namespace": "b05d09f6_1d90_4a1b_8d0a_d5d650046fb0",
      "to_and_components": [{
        "to": ["9198XXXXXXXX"],
        "components": {
          "body_owner_name": { "type": "text", "value": "Customer Name", "parameter_name": "owner_name" },
          "body_app_url": { "type": "text", "value": "https://stardustvault.com/login", "parameter_name": "app_url" }
        }
      }]
    }
  }
}
```

### 3. Template: `succession_guide_final_v1` (Onboarding Guide)
```json
{
  "integrated_number": "917204342233",
  "content_type": "template",
  "payload": {
    "messaging_product": "whatsapp",
    "type": "template",
    "template": {
      "name": "succession_guide_final_v1",
      "language": { "code": "en", "policy": "deterministic" },
      "namespace": "b05d09f6_1d90_4a1b_8d0a_d5d650046fb0",
      "to_and_components": [{
        "to": ["9198XXXXXXXX"],
        "components": {
            "body_owner_name": { "type": "text", "value": "Original Owner Name", "parameter_name": "owner_name" }
        }
      }]
    }
  }
}
```

### 4. Template: `otp_verification_stardust` (Auth / OTP)
```json
{
  "integrated_number": "917204342233",
  "content_type": "template",
  "payload": {
    "messaging_product": "whatsapp",
    "type": "template",
    "template": {
      "name": "otp_verification_stardust",
      "language": { "code": "en", "policy": "deterministic" },
      "namespace": "b05d09f6_1d90_4a1b_8d0a_d5d650046fb0",
      "to_and_components": [{
        "to": ["9198XXXXXXXX"],
        "components": {
          "body_1": { "type": "text", "value": "123456" },
          "button_1": { "subtype": "url", "type": "text", "value": "verify/123456" }
        }
      }]
    }
  }
}
```

---

## 5. Developer Guide: Logical Implementation
The core function `sendWhatsAppTemplate(to, templateName, variables)` in `msg91Service.js` performs the following steps:

1.  **Phone Number Sanitization**: Automatically strips characters like `+`, `-`, and spaces to ensure compatibility (e.g., `+91 91234 56789` → `919123456789`).
2.  **Explicit Mapping Engine**: Before sending, the code checks the `templateName`. It populates the `components` object with keys like `body_verification_url` for some templates, while defaulting to standard `body_1` for others (OTP/Auth). 
3.  **Error Handling**: All responses from your API (including successful transactions and errors like `Failed by Meta`) are logged to the server's console for debugging.

---

## 6. Known Support Troubleshooting Steps

### 🔍 Error: "Failed by Meta" or "Component Mismatch"
**The System Diagnosis**: This occurs when we send a `bodyComponents` key that is not registered in the Meta Developer Portal for that template.
**The Fix**: We ensure that for templates like `stardust_succession_notice`, we use the literal key strings `body_verification_url`, `body_owner_name`, etc., instead of generic indexes.

### 🔍 Error: "Account Not Registered"
**The System Diagnosis**: This happens if the `integrated_number` in the JSON payload does not match the WhatsApp number linked to the project under the provided `authkey`.
**The Fix**: Our code explicitly constants the number to `917204342233` to prevent injection of incorrect numbers.

---
**Document Version**: 2.0 (High Detail)
**Author**: Integration Support Team
**Project Site**: Stardust Vault
