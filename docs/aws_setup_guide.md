# AWS Backend Verification & API Key Troubleshooting Guide

We have successfully deployed the AWS backend for your application using the automated provisioning script. Your local `.env` has been updated with these endpoints:
* **Cognito User Pool ID**: `ap-south-1_eifJBis0e`
* **Cognito Client ID**: `49jhjjoom9iplq6afsgeu9ir81`
* **API Base URL**: `https://l7y2wo2525.execute-api.ap-south-1.amazonaws.com/dev`

Below is the guide on how to verify these in the AWS Console, set up email OTPs, and troubleshoot API key validation issues.

---

## 1. Verifying Resources in the AWS Management Console

Log into the [AWS Management Console](https://console.aws.amazon.com) (Region: **Mumbai / ap-south-1**) and confirm the following configurations:

### A. Amazon Cognito (User Authentication)
1. Go to **Cognito** > **User Pools**.
2. Select **WealthAdvisorUserPool** (`ap-south-1_eifJBis0e`).
3. Under the **User pool properties** tab:
   * Scroll down to **Lambda triggers**.
   * Verify that **Define auth challenge**, **Create auth challenge**, and **Verify auth challenge response** are active and point to the corresponding Lambda triggers.
4. Under the **App integration** tab:
   * Scroll to the bottom to **App clients**.
   * Confirm **WealthAdvisorAppClient** (`49jhjjoom9iplq6afsgeu9ir81`) is listed with **ALLOW_CUSTOM_AUTH** allowed.

### B. AWS Lambda (Serverless Backends)
1. Go to **Lambda** > **Functions**.
2. Verify you see these four functions listed:
   * `define-auth-challenge`
   * `create-auth-challenge`
   * `verify-auth-challenge-response`
   * `wealth-advisor-backend` (main monolithic handler)
3. Select `wealth-advisor-backend` > **Configuration** > **Environment variables**:
   * Confirm `TABLE_NAME` is set to `WealthData`.

### C. Amazon DynamoDB (NoSQL Storage)
1. Go to **DynamoDB** > **Tables**.
2. Select **WealthData**.
3. Under the **Structure** tab, confirm:
   * **Partition Key (PK)**: `S` (String)
   * **Sort Key (SK)**: `S` (String)
4. Use **Explore table items** to see transaction, account, and goal data once they are posted.

### D. Amazon API Gateway (API Routing)
1. Go to **API Gateway** > **APIs**.
2. Select **WealthAdvisorAPI** (`l7y2wo2525`).
3. Under **Resources**, verify:
   * `/` has an `ANY` method pointing to the `wealth-advisor-backend` Lambda.
   * `/{proxy+}` has an `ANY` method pointing to the `wealth-advisor-backend` Lambda.
4. Go to **Stages** and confirm the `dev` stage has been deployed.

---

## 2. Amazon SES Email OTP Setup

The `create-auth-challenge` Lambda uses Amazon SES (Simple Email Service) to send passwordless login OTP verification codes.

### Option A: Demo / Developer Mode (Fastest & Easiest)
In new AWS accounts, your SES is in a "Sandbox" environment. Instead of going through domain/email verification to send real emails:
1. Try logging in inside the app.
2. Go to **AWS Lambda** > **Functions** > **create-auth-challenge**.
3. Select the **Monitor** tab, and click **View CloudWatch logs**.
4. Click on the latest log stream. You will see an entry printing the generated OTP:
   ```text
   [ALERT] Passwordless Login Verification Code for user@example.com is: 582914
   ```
5. Use this code to log into the app. This is perfect for local testing and hackathon demo presentations!

### Option B: Production Email Mode (Real Emails)
If you want to send real emails to your users:
1. Go to **Amazon SES** > **Verified identities**.
2. Click **Create identity**, select **Email address**, enter the email you want to send emails from (e.g., `noreply@yourdomain.com` or your personal email), and verify it by clicking the link AWS sends to that inbox.
3. Go to **AWS Lambda** > **Functions** > **create-auth-challenge**.
4. Under **Configuration** > **Environment variables**, add a new variable:
   * **Key**: `SES_FROM_EMAIL`
   * **Value**: Your verified sender email address.
5. If your SES account is still in sandbox mode, you must also add and verify the **recipient email addresses** under Verified identities, or request AWS to move your account out of SES Sandbox.

---

## 3. Troubleshooting Gemini API Key Verification Failures

If you paste a valid Gemini API key in the app and the verification snackbar says **"Invalid API Key. Please verify and try again"**, follow these diagnostic steps:

### A. Run and Monitor the Logs
We added verbose print statements to [gemini_key_service.dart](file:///data/data/com.termux/files/home/summer-hacks-v2/lib/services/gemini_key_service.dart). Run the application in debug mode using your terminal:
```bash
flutter run
```
When you tap **Verify & Save**, look at your terminal output. You will see one of two logs:

1. **`[GeminiKeyService] API Key verification failed. Status code: <CODE>, Body: <BODY>`**
   * **403/400 (Bad API Key / API Key Invalid)**: The key was typed incorrectly, is disabled, or does not have access to the `gemini-2.0-flash` model.
   * **429 (Resource Exhausted)**: Your AI Studio account has hit rate/quota limits.
2. **`[GeminiKeyService] API Key verification encountered exception: <ERROR>`**
   * **SocketException**: Your emulator or mobile device has no internet access, or the network is blocking requests to Google's servers.

### B. Manually Test the Key Using `curl`
To confirm the API key is functional separate from the Flutter app/environment, run this command from your terminal:
```bash
curl -H 'Content-Type: application/json' \
     -d '{"contents": [{"parts": [{"text": "Say ok"}]}]}' \
     "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=YOUR_API_KEY"
```
* If this command fails or returns an error, the issue lies with the API key itself (generate a new one at [Google AI Studio](https://aistudio.google.com/)).
* If this command succeeds, check the Android device network connection (make sure the emulator isn't on airplane mode and has cellular data enabled).
