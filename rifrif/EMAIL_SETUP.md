# Email Verification Setup Guide

This app supports multiple email services for sending verification codes. Here are the options from easiest to setup:

## Option 1: Web3Forms (Easiest - 2 minutes setup)

### Steps:

1. Go to https://web3forms.com/
2. Click "Get Free Access Key"
3. Enter your email and get the access key
4. In `lib/services/firebase_service.dart`, replace:
   ```dart
   const String accessKey = 'YOUR_WEB3FORMS_KEY';
   ```
   with your actual access key:
   ```dart
   const String accessKey = 'your-actual-access-key-here';
   ```

**That's it!** Web3Forms will send emails directly to the user's email address.

## Option 2: Formspree (Easy - 5 minutes setup)

### Steps:

1. Go to https://formspree.io/
2. Sign up for free account
3. Create a new form
4. Get your form ID (looks like: `abc123def`)
5. In `lib/services/firebase_service.dart`, replace:
   ```dart
   const String formId = 'YOUR_FORM_ID';
   ```
   with your form ID:
   ```dart
   const String formId = 'abc123def';
   ```

## Option 3: EmailJS (More complex - 10 minutes setup)

### Steps:

1. Go to https://www.emailjs.com/
2. Sign up and verify email
3. Create email service (Gmail/Outlook)
4. Create email template with these variables:
   - `{{to_email}}`
   - `{{verification_code}}`
   - `{{app_name}}`
5. Get Service ID, Template ID, and Public Key
6. Replace in code:
   ```dart
   const String serviceId = 'your_service_id';
   const String templateId = 'your_template_id';
   const String publicKey = 'your_public_key';
   ```

## Quick Test Instructions

1. Configure one of the services above
2. Run the app: `flutter run`
3. Try to sign up with your real email
4. Check your email for the verification code
5. Enter the code in the app

## Current Status

Right now, the app will show verification codes in the console (terminal output) since no email service is configured. The verification flow works perfectly - you just need to set up one email service to receive actual emails.

## Troubleshooting

- **Not receiving emails?** Check spam/junk folder
- **Still no emails?** Make sure you configured the service correctly
- **App crashes?** Check terminal/console for error messages
- **Console shows code?** This means email service isn't configured yet

## Development Note

The app will always work even if email services fail - it shows the verification code in the console so you can continue testing the verification flow.
