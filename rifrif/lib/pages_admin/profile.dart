import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../services/firebase_service.dart';
import '../models/user_profile_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _schoolLevelController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isCompleting = false;
  bool _isEditing = false;
  DateTime? _selectedBirthday;
  String? _selectedGender;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUpdatingProfilePicture = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _schoolController.dispose();
    _schoolLevelController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final profile = await _firebaseService.getUserProfile(user.uid);

        if (profile == null) {
          // Create initial profile from Firebase Auth data
          final newProfile = await _firebaseService.createOrUpdateUserProfile(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
            photoURL: user.photoURL,
          );
          setState(() {
            _userProfile = newProfile;
          });
        } else {
          setState(() {
            _userProfile = profile;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF614f96),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  Future<void> _updateProfilePicture() async {
    // Show options to pick from camera or gallery
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Update Profile Picture',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E2E2E),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Color(0xFF614f96).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 30,
                          color: Color(0xFF614f96),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Camera',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2E2E2E),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Color(0xFF614f96).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.photo_library,
                          size: 30,
                          color: Color(0xFF614f96),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Gallery',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2E2E2E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (source != null) {
      setState(() => _isUpdatingProfilePicture = true);

      try {
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: source,
          maxWidth: 500,
          maxHeight: 500,
          imageQuality: 80,
        );

        if (pickedFile != null) {
          // Convert image to base64
          final bytes = await pickedFile.readAsBytes();
          final base64Image = base64Encode(bytes);

          // Update profile picture in Firebase
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await _firebaseService.updateProfilePicture(
              uid: user.uid,
              base64Image: base64Image,
            );

            // Reload profile to get updated photoURL
            await _loadUserProfile();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isUpdatingProfilePicture = false);
      }
    }
  }

  Future<void> _completeProfile() async {
    if (_schoolController.text.trim().isEmpty ||
        _schoolLevelController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _selectedBirthday == null ||
        _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isCompleting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (_isEditing) {
          // Update existing profile
          await _firebaseService.updateUserProfile(user.uid, {
            'school': _schoolController.text.trim(),
            'schoolLevel': _schoolLevelController.text.trim(),
            'gender': _selectedGender!,
            'birthday': Timestamp.fromDate(_selectedBirthday!),
            'location': _locationController.text.trim(),
          });

          setState(() {
            _isEditing = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Complete profile for the first time
          await _firebaseService.completeUserProfile(
            uid: user.uid,
            school: _schoolController.text.trim(),
            schoolLevel: _schoolLevelController.text.trim(),
            gender: _selectedGender!,
            birthday: _selectedBirthday!,
            location: _locationController.text.trim(),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Clear form and reload profile
        _schoolController.clear();
        _schoolLevelController.clear();
        _locationController.clear();
        _selectedBirthday = null;
        _selectedGender = null;

        await _loadUserProfile();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isCompleting = false);
    }
  }

  Widget _buildProfileInfo() {
    if (_userProfile == null) return const SizedBox();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Picture
            GestureDetector(
              onTap: _updateProfilePicture,
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _userProfile!.profileCircleColor.withOpacity(0.1),
                      border: Border.all(
                          color: _userProfile!.profileCircleColor, width: 3),
                    ),
                    child: _isUpdatingProfilePicture
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF614f96)),
                              strokeWidth: 2,
                            ),
                          )
                        : _userProfile!.photoURL != null &&
                                _userProfile!.photoURL!.isNotEmpty
                            ? ClipOval(
                                child: _isBase64Image(_userProfile!.photoURL!)
                                    ? Image.memory(
                                        base64Decode(_userProfile!.photoURL!),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _buildInitialsAvatar(),
                                      )
                                    : Image.network(
                                        _userProfile!.photoURL!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _buildInitialsAvatar(),
                                      ),
                              )
                            : _buildInitialsAvatar(),
                  ),
                  if (!_isUpdatingProfilePicture)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Color(0xFF614f96),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Display Name
            Text(
              _userProfile!.displayEmailOrName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E2E2E),
              ),
            ),
            const SizedBox(height: 8),

            // Email
            Text(
              _userProfile!.email,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            // Profile Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _userProfile!.isProfileComplete
                    ? Colors.green
                    : Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _userProfile!.isProfileComplete
                    ? 'Profile Complete'
                    : 'Profile Incomplete',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _userProfile!.profileCircleColor,
      ),
      child: Center(
        child: Text(
          _userProfile!.initials,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    if (_userProfile == null) return const SizedBox();

    bool hasAdditionalInfo = (_userProfile!.school != null &&
            _userProfile!.school!.isNotEmpty) ||
        (_userProfile!.schoolLevel != null &&
            _userProfile!.schoolLevel!.isNotEmpty) ||
        (_userProfile!.gender != null && _userProfile!.gender!.isNotEmpty) ||
        (_userProfile!.birthday != null) ||
        (_userProfile!.location != null && _userProfile!.location!.isNotEmpty);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Additional Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E2E2E),
                  ),
                ),
                if (_userProfile!.isProfileComplete)
                  TextButton.icon(
                    onPressed: () {
                      // Populate form with current values
                      _schoolController.text = _userProfile!.school ?? '';
                      _schoolLevelController.text =
                          _userProfile!.schoolLevel ?? '';
                      _locationController.text = _userProfile!.location ?? '';
                      _selectedBirthday = _userProfile!.birthday;
                      _selectedGender = _userProfile!.gender;

                      setState(() {
                        _isEditing = true;
                      });
                    },
                    icon: const Icon(Icons.edit,
                        size: 16, color: Color(0xFF614f96)),
                    label: const Text(
                      'Update',
                      style: TextStyle(color: Color(0xFF614f96)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (hasAdditionalInfo) ...[
              if (_userProfile!.school != null &&
                  _userProfile!.school!.isNotEmpty) ...[
                _buildInfoRow('School/University', _userProfile!.school!),
                const SizedBox(height: 12),
              ],
              if (_userProfile!.schoolLevel != null &&
                  _userProfile!.schoolLevel!.isNotEmpty) ...[
                _buildInfoRow('Level', _userProfile!.schoolLevel!),
                const SizedBox(height: 12),
              ],
              if (_userProfile!.gender != null &&
                  _userProfile!.gender!.isNotEmpty) ...[
                _buildInfoRow(
                    'Gender',
                    _userProfile!.gender![0].toUpperCase() +
                        _userProfile!.gender!.substring(1)),
                const SizedBox(height: 12),
              ],
              if (_userProfile!.birthday != null) ...[
                _buildInfoRow('Birthday', _formatDate(_userProfile!.birthday!)),
                const SizedBox(height: 12),
              ],
              if (_userProfile!.location != null &&
                  _userProfile!.location!.isNotEmpty) ...[
                _buildInfoRow('Location', _userProfile!.location!),
              ],
            ] else ...[
              Center(
                child: Text(
                  'Complete your profile to unlock additional features',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2E2E2E),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteProfileForm() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Update Your Profile' : 'Complete Your Profile',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E2E2E),
              ),
            ),
            const SizedBox(height: 20),

            // School/University Field
            TextField(
              controller: _schoolController,
              decoration: InputDecoration(
                labelText: 'School or University',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF614f96)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // School Level Field
            TextField(
              controller: _schoolLevelController,
              decoration: InputDecoration(
                labelText: 'School or University Level',
                hintText: 'e.g., Bachelor, Master, PhD, High School',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF614f96)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Gender Field
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedGender,
                  hint: Text(
                    'Select Gender',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  items: ['Male', 'Female'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value.toLowerCase(),
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGender = newValue;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Birthday Field
            GestureDetector(
              onTap: _selectBirthday,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedBirthday != null
                          ? _formatDate(_selectedBirthday!)
                          : 'Select Birthday',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedBirthday != null
                            ? Color(0xFF2E2E2E)
                            : Colors.grey[600],
                      ),
                    ),
                    Icon(
                      Icons.calendar_today,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location Field
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                hintText: 'e.g., City, Country',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF614f96)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons Row
            if (_isEditing) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isCompleting
                          ? null
                          : () {
                              setState(() {
                                _isEditing = false;
                                // Clear form
                                _schoolController.clear();
                                _schoolLevelController.clear();
                                _locationController.clear();
                                _selectedBirthday = null;
                                _selectedGender = null;
                              });
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF614f96),
                        side: const BorderSide(color: Color(0xFF614f96)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCompleting ? null : _completeProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF614f96),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isCompleting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Update Profile',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Complete Profile Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCompleting ? null : _completeProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF614f96),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isCompleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Complete Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _isBase64Image(String imageString) {
    // Check if the string is a valid base64 image
    // Base64 images don't start with http/https
    if (imageString.startsWith('http://') ||
        imageString.startsWith('https://')) {
      return false;
    }

    // Check if it looks like a base64 string (basic validation)
    if (imageString.length < 100) {
      return false; // Base64 images are typically much longer
    }

    try {
      // Try to decode as base64
      base64Decode(imageString);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF614f96),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF614f96)),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileInfo(),
                  const SizedBox(height: 16),
                  _buildAdditionalInfo(),
                  if (_userProfile != null &&
                      (!_userProfile!.isProfileComplete || _isEditing)) ...[
                    const SizedBox(height: 24),
                    _buildCompleteProfileForm(),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
