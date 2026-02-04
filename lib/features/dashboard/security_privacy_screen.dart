import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../services/auth_service.dart';
import '../../auth_wrapper.dart';

class SecurityPrivacyScreen extends ConsumerStatefulWidget {
  const SecurityPrivacyScreen({super.key});

  @override
  ConsumerState<SecurityPrivacyScreen> createState() => _SecurityPrivacyScreenState();
}

class _SecurityPrivacyScreenState extends ConsumerState<SecurityPrivacyScreen> {
  bool _analyticsEnabled = true;
  late TextEditingController _nameController;
  late TextEditingController _pinController;
  late TextEditingController _collegeController;
  late TextEditingController _degreeController;
  late TextEditingController _currentYearController;
  late TextEditingController _passedOutYearController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isSaving = false;
  bool _isEditingPin = false;
  String _currentPin = "****";
  bool _obscurePin = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authServiceProvider).currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _pinController = TextEditingController();
    _collegeController = TextEditingController();
    _degreeController = TextEditingController();
    _currentYearController = TextEditingController();
    _passedOutYearController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ref.read(authServiceProvider).getFullProfile();
    if (profile != null && mounted) {
      setState(() {
        _nameController.text = profile['fullName'] ?? _nameController.text;
        _pinController.text = profile['recoveryPin'] ?? '';
        _currentPin = profile['recoveryPin'] ?? "****";
        _collegeController.text = profile['college'] ?? '';
        _degreeController.text = profile['degree'] ?? '';
        _currentYearController.text = profile['currentYear'] ?? '';
        _passedOutYearController.text = profile['passedOutYear'] ?? '';
        _phoneController.text = profile['phoneNumber'] ?? '';
        _addressController.text = profile['address'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _collegeController.dispose();
    _degreeController.dispose();
    _currentYearController.dispose();
    _passedOutYearController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(authServiceProvider).updateProfile(
        displayName: _nameController.text.trim(),
        recoveryPin: _pinController.text.trim(),
        college: _collegeController.text.trim(),
        degree: _degreeController.text.trim(),
        currentYear: _currentYearController.text.trim(),
        passedOutYear: _passedOutYearController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _currentPin = _pinController.text.trim();
          _isEditingPin = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Security & Privacy', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Profile Information'),
            const SizedBox(height: 16),
            _buildSecurityCard([
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 32),
            _buildSectionHeader('Professional Information'),
            const SizedBox(height: 16),
            _buildSecurityCard([
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildProfileField(controller: _collegeController, label: 'College Name', icon: Icons.school_outlined),
                    const SizedBox(height: 16),
                    _buildProfileField(controller: _degreeController, label: 'Degree', icon: Icons.history_edu_outlined),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildProfileField(
                          controller: _currentYearController, 
                          label: 'Current Year', 
                          icon: Icons.calendar_today_outlined,
                          readOnly: true,
                          onTap: () => _selectAcademicYear(context),
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: _buildProfileField(
                          controller: _passedOutYearController, 
                          label: 'Pass-out Year', 
                          icon: Icons.history_outlined,
                          readOnly: true,
                          onTap: () => _selectYear(context, _passedOutYearController),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 32),
            _buildSectionHeader('Contact Details'),
            const SizedBox(height: 16),
            _buildSecurityCard([
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildProfileField(controller: _phoneController, label: 'Mobile Number', icon: Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _buildProfileField(controller: _addressController, label: 'Address', icon: Icons.location_on_outlined, maxLines: 3),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 32),
            _buildSectionHeader('Security Recovery'),
            const SizedBox(height: 16),
            _buildSecurityCard([
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.security, color: Colors.orange, size: 20),
                ),
                title: Text('Recovery PIN', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                subtitle: Text(_isEditingPin ? 'Set a new 4-digit PIN' : 'Active PIN: ${_currentPin.replaceAll(RegExp(r'.'), '*')}', style: GoogleFonts.outfit(fontSize: 12)),
                trailing: IconButton(
                  icon: Icon(_isEditingPin ? Icons.close : Icons.edit, color: AppColors.primary),
                  onPressed: () => setState(() => _isEditingPin = !_isEditingPin),
                ),
              ),
              if (_isEditingPin)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _pinController,
                        obscureText: _obscurePin,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        decoration: InputDecoration(
                          labelText: 'New 4-Digit PIN',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          counterText: '',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePin ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => setState(() => _obscurePin = !_obscurePin),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ]),
            const SizedBox(height: 48),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Update All Profile Changes', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 48),
            _buildSectionHeader('Account Security'),
            const SizedBox(height: 16),
            _buildSecurityCard([
              _buildActionTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: () => _showChangePasswordOptions(user),
                color: Colors.blue,
              ),
            ]),
            const SizedBox(height: 32),
            _buildSectionHeader('Privacy Settings'),
            const SizedBox(height: 16),
            _buildSecurityCard([
              _buildSwitchTile(
                icon: Icons.analytics_outlined,
                title: 'Usage Analytics',
                subtitle: 'Help us improve IntelliTrain',
                value: _analyticsEnabled,
                onChanged: (val) => setState(() => _analyticsEnabled = val),
                color: Colors.purple,
              ),
            ]),
            const SizedBox(height: 32),
            _buildSectionHeader('Danger Zone'),
            const SizedBox(height: 16),
            _buildSecurityCard([
              _buildActionTile(
                icon: Icons.delete_forever_outlined,
                title: 'Delete Account',
                subtitle: 'Permanently remove all your data',
                onTap: () => _showDeleteConfirmation(),
                color: AppColors.error,
                isDanger: true,
              ),
            ]),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'IntelliTrain v1.0.0',
                style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Future<void> _selectYear(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'SELECT YEAR',
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.year.toString();
      });
    }
  }

  void _selectAcademicYear(BuildContext context) {
    final List<String> years = ['I', 'II', 'III', 'IV', 'V'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Current Year', 
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)
              ),
              const SizedBox(height: 16),
              ...years.map((year) => ListTile(
                title: Text(
                  year, 
                  textAlign: TextAlign.center, 
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w500)
                ),
                onTap: () {
                  setState(() => _currentYearController.text = year);
                  Navigator.pop(context);
                },
              )).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      style: GoogleFonts.outfit(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1);
  }

  Widget _buildSecurityCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(children: children),
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.98, 0.98));
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    bool isDanger = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDanger ? color : AppColors.textPrimary)),
      subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Future<void> _showChangePasswordOptions(auth.User? user) async {
    final isGoogleUser = user?.providerData.any((p) => p.providerId == 'google.com') ?? false;

    if (isGoogleUser) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Google Account', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: const Text('Your account is linked with Google. Please manage your password through your Google Account settings.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
          ],
        ),
      );
      return;
    }

    _showInAppChangePasswordDialog();
  }

  Future<void> _showInAppChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Update Password', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: obscureOld,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  hintText: 'Enter current password',
                  labelStyle: GoogleFonts.outfit(),
                  suffixIcon: IconButton(
                    icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setDialogState(() => obscureOld = !obscureOld),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  hintText: 'Minimum 6 characters',
                  labelStyle: GoogleFonts.outfit(),
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter new password',
                  labelStyle: GoogleFonts.outfit(),
                  suffixIcon: IconButton(
                    icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                  return;
                }
                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));
                  return;
                }

                setDialogState(() => isLoading = true);
                try {
                  await ref.read(authServiceProvider).updatePassword(
                    currentPasswordController.text,
                    newPasswordController.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  setDialogState(() => isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text('This action is permanent and cannot be undone. All your progress will be lost.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(authServiceProvider).deleteAccount();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthWrapper()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}
