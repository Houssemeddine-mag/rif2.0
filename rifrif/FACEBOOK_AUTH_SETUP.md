# Facebook Authentication Setup Guide

## 📋 Overview

Facebook authentication is already implemented in the app! You just need to configure it in Facebook Developer Console and Firebase.

## 🔧 Current Implementation Status

✅ **Code Implementation**: Complete  
✅ **UI Integration**: Facebook button ready  
✅ **Firebase Service**: `signInWithFacebook()` method available  
❌ **Facebook App**: Needs configuration  
❌ **Firebase Console**: Needs Facebook provider setup

## 🚀 Setup Steps (10 minutes)

### Step 1: Create Facebook App

1. Go to: https://developers.facebook.com/apps/
2. Click **"Create App"**
3. Choose **"Consumer"** as app type
4. Fill in the form:
   ```
   App Display Name: RIF
   App Contact Email: [your email]
   ```
5. Click **"Create App"**
6. Navigate to **Settings** → **Basic**
7. Copy the **App ID** and **App Secret**

### Step 2: Configure Facebook Login

1. In your Facebook App dashboard, click **"Add Product"**
2. Find **"Facebook Login"** and click **"Set Up"**
3. Choose **"Web"** platform
4. Enter Site URL: `https://rifuniv.web.app`
5. Go to **Facebook Login** → **Settings**
6. Add these **Valid OAuth Redirect URIs**:
   ```
   https://rifuniv.firebaseapp.com/__/auth/handler
   https://rifuniv.web.app/__/auth/handler
   ```

### Step 3: Configure Firebase Console

1. Go to: https://console.firebase.google.com/project/rifuniv/authentication/providers
2. Click on **Facebook** in the Sign-in providers list
3. **Enable** the Facebook provider
4. Enter your Facebook credentials:
   ```
   App ID: [from Facebook App]
   App Secret: [from Facebook App]
   ```
5. Click **Save**

### Step 4: App Review (Optional for Testing)

For testing, your app works with:

- ✅ App admins/developers
- ✅ Test users you add

For public use, you need Facebook App Review:

1. Go to **App Review** in Facebook Console
2. Submit for **facebook_login** permission
3. Provide app details and privacy policy

## 🖼️ UI Implementation

The Facebook login button is already implemented:

```dart
_socialButton(
  "Continuer avec Facebook",
  loginWithFacebook,
  Icons.facebook,
  Color(0xFF1877F2), // Facebook blue
),
```

## 📱 User Flow

1. User clicks "Continuer avec Facebook"
2. App opens Facebook OAuth in web browser
3. User logs into Facebook and authorizes RIF app
4. Facebook redirects back to Firebase
5. Firebase creates/signs in the user
6. App navigates to home page

## 🔒 Security Features

✅ **OAuth 2.0**: Secure authorization flow  
✅ **Firebase Integration**: Automatic user management  
✅ **Error Handling**: Comprehensive error messages  
✅ **User Model**: Automatic profile creation  
✅ **Scopes**: Email and public profile access

## 🛠️ Technical Details

### Firebase Service Method

```dart
static Future<UserCredential> signInWithFacebook() async {
  FacebookAuthProvider facebookProvider = FacebookAuthProvider();
  facebookProvider.addScope('email');
  facebookProvider.addScope('public_profile');
  return await _auth.signInWithProvider(facebookProvider);
}
```

### Login Page Integration

```dart
Future<void> loginWithFacebook() async {
  setState(() => isLoading = true);
  try {
    final cred = await FirebaseService.signInWithFacebook();
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

When a user signs in with Facebook, you'll get:

- ✅ Facebook name
- ✅ Email address
- ✅ Profile picture
- ✅ User ID
- ✅ Public profile information

## ⚠️ Important Notes

1. **App Review**: Required for public use
2. **Test Users**: Add test users in Facebook Console for testing
3. **Privacy Policy**: Required for Facebook App Review
4. **Valid Domains**: Must match exactly in Facebook and Firebase
5. **HTTPS**: Required for OAuth callbacks

## 🔍 Troubleshooting

### Common Issues:

**"App Not Setup: This app is still in development mode"**

- Add test users in Facebook Console → Roles → Test Users

**"Invalid OAuth Redirect URI"**

- Check redirect URLs match exactly in Facebook and Firebase

**"App ID does not exist"**

- Verify App ID is correct in Firebase Console

**"User cancelled the authorization"**

- Normal behavior, app handles this gracefully

**"Given URL is not allowed by the Application configuration"**

- Check Valid OAuth Redirect URIs in Facebook Login settings

## ✅ Next Steps

1. Create Facebook App (5 minutes)
2. Configure Facebook Login (3 minutes)
3. Configure Firebase Console (2 minutes)
4. Test with your account (immediate)
5. Add test users for team testing
6. Submit for App Review (for public use)

The code is ready - you just need the Facebook OAuth configuration!

## 🎯 Project Details for Facebook App

Use these details when creating your Facebook App:

```
App Name: RIF
Category: Education
Website: https://rifuniv.web.app
Privacy Policy: [Your privacy policy URL]
Terms of Service: [Your terms URL]
```

Ready to authenticate with Facebook! 📘🚀
