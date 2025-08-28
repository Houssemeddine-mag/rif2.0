# Apple Sign-In Setup Guide

## 📋 Overview

Apple Sign-In is already implemented in the app! You just need to configure it in Apple Developer Console and Firebase.

## 🔧 Current Implementation Status

✅ **Code Implementation**: Complete  
✅ **UI Integration**: Apple button ready  
✅ **Firebase Service**: `signInWithApple()` method available  
❌ **Apple Developer**: Needs configuration  
❌ **Firebase Console**: Needs Apple provider setup

## 🚀 Setup Steps (15 minutes)

### Step 1: Apple Developer Account Setup

1. **Requirement**: You need an Apple Developer account ($99/year)
2. Go to: https://developer.apple.com/account/
3. Sign in with your Apple ID

### Step 2: Configure App ID

1. Go to **Certificates, Identifiers & Profiles**
2. Click **Identifiers** → **App IDs**
3. Select your app ID or create new one:
   ```
   Bundle ID: com.example.rifrif
   Description: RIF University Platform
   ```
4. **Enable "Sign In with Apple"** capability
5. Click **Save**

### Step 3: Create Service ID

1. In **Identifiers**, click **+** → **Services IDs**
2. Fill in details:
   ```
   Description: RIF Web Auth
   Identifier: com.example.rifrif.signin
   ```
3. **Enable "Sign In with Apple"**
4. Click **Configure** next to "Sign In with Apple"
5. Select your App ID as Primary App ID
6. Add Web Domain: `rifuniv.firebaseapp.com`
7. Add Return URL: `https://rifuniv.firebaseapp.com/__/auth/handler`
8. Click **Save** → **Continue** → **Register**

### Step 4: Create Private Key

1. Go to **Keys** section
2. Click **+** to create new key
3. Fill in:
   ```
   Key Name: RIF Apple Auth Key
   ```
4. **Enable "Sign In with Apple"**
5. Click **Configure** → Select your App ID → **Save**
6. Click **Continue** → **Register**
7. **Download the key file** (.p8 file)
8. **Note the Key ID** (10 characters)

### Step 5: Configure Firebase Console

1. Go to: https://console.firebase.google.com/project/rifuniv/authentication/providers
2. Click **Apple** in Sign-in providers
3. **Enable** Apple provider
4. Fill in the configuration:
   ```
   Service ID: com.example.rifrif.signin
   Apple Team ID: [Your 10-character team ID]
   Key ID: [From step 4]
   Private Key: [Content of .p8 file]
   ```
5. Click **Save**

### Step 6: iOS Configuration (if building for iOS)

1. In Xcode, open `ios/Runner.xcworkspace`
2. Select **Runner** → **Signing & Capabilities**
3. Click **+ Capability** → **Sign In with Apple**
4. Ensure Bundle ID matches your Apple Developer setup

## 🖼️ UI Implementation

The Apple Sign-In button is already implemented:

```dart
_socialButton(
  "Continuer avec Apple",
  loginWithApple,
  Icons.apple,
  Color(0xFF000000), // Apple black
),
```

## 📱 User Flow

1. User clicks "Continuer avec Apple"
2. Apple authentication popup appears
3. User authenticates with Face ID/Touch ID/Password
4. User authorizes the RIF app
5. Apple redirects back to Firebase
6. Firebase creates/signs in the user
7. App navigates to home page

## 🔒 Security Features

✅ **OAuth 2.0**: Secure authorization flow  
✅ **Firebase Integration**: Automatic user management  
✅ **Privacy Protection**: Users can hide their email  
✅ **Error Handling**: Comprehensive error messages  
✅ **User Model**: Automatic profile creation

## 🛠️ Technical Details

### Firebase Service Method

```dart
static Future<UserCredential> signInWithApple() async {
  AppleAuthProvider appleProvider = AppleAuthProvider();
  appleProvider.addScope('email');
  appleProvider.addScope('name');
  return await _auth.signInWithProvider(appleProvider);
}
```

### Login Page Integration

```dart
Future<void> loginWithApple() async {
  setState(() => isLoading = true);
  try {
    final cred = await FirebaseService.signInWithApple();
    if (cred.user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  } catch (e) {
    // Error handling
  } finally {
    setState(() => isLoading = false);
  }
}
```

## 🎯 Expected User Data

When a user signs in with Apple, you'll get:

- ✅ Apple ID (unique identifier)
- ⚠️ Email address (may be private relay)
- ⚠️ Name (only on first sign-in)
- ✅ Authentication token

**Note**: Apple prioritizes privacy, so email may be a private relay address.

## ⚠️ Important Notes

1. **Apple Developer Account**: Required ($99/year)
2. **Privacy**: Apple may provide private relay emails
3. **Name Data**: Only provided on first authentication
4. **Web Domain**: Must be verified in Apple Developer
5. **Testing**: Works on iOS devices and Safari

## 🔍 Troubleshooting

### Common Issues:

**"Invalid client"**

- Check Service ID matches in Apple Developer and Firebase

**"Invalid redirect URI"**

- Verify return URL exactly matches in both systems

**"Team ID not found"**

- Check Team ID is correct (found in Apple Developer account)

**"Invalid private key"**

- Ensure .p8 file content is copied correctly

**"Domain not verified"**

- Verify domain ownership in Apple Developer console

## ✅ Next Steps

1. Get Apple Developer account (if needed)
2. Configure App ID and Service ID (10 minutes)
3. Create private key (2 minutes)
4. Configure Firebase Console (3 minutes)
5. Test Apple Sign-In
6. Enjoy secure Apple authentication! 🍎

## 🎯 Configuration Summary

Use these exact values:

```
Bundle ID: com.example.rifrif
Service ID: com.example.rifrif.signin
Web Domain: rifuniv.firebaseapp.com
Return URL: https://rifuniv.firebaseapp.com/__/auth/handler
Team ID: [Your 10-char team ID]
Key ID: [Your 10-char key ID]
```

Ready to authenticate with Apple! 🍎🚀

## 💡 Alternative: Test Mode

For testing without Apple Developer account, you can:

1. Comment out Apple button temporarily
2. Focus on Google + GitHub (both working)
3. Add Apple when ready for App Store

The code is ready - just needs Apple Developer setup!
