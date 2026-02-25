import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';

class UserFormScreen extends StatefulWidget {
  final UserModel? editUser; // ถ้าไม่ null = โหมดแก้ไข

  const UserFormScreen({super.key, this.editUser});

  @override
  State<UserFormScreen> createState() => UserFormScreenState();
}

class UserFormScreenState extends State<UserFormScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController emailCtrl;
  late final TextEditingController usernameCtrl;
  late final TextEditingController passwordCtrl;
  late final TextEditingController phoneCtrl;
  late final TextEditingController firstCtrl;
  late final TextEditingController lastCtrl;
  late final TextEditingController cityCtrl;
  late final TextEditingController streetCtrl;
  late final TextEditingController numberCtrl;
  late final TextEditingController zipCtrl;
  late final TextEditingController latCtrl;
  late final TextEditingController longCtrl;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _animationController.forward();

    final u = widget.editUser;
    emailCtrl = TextEditingController(text: u?.email ?? '');
    usernameCtrl = TextEditingController(text: u?.username ?? '');
    passwordCtrl = TextEditingController(text: u?.password ?? '');
    phoneCtrl = TextEditingController(text: u?.phone ?? '');
    firstCtrl = TextEditingController(text: u?.name.firstname ?? '');
    lastCtrl = TextEditingController(text: u?.name.lastname ?? '');
    cityCtrl = TextEditingController(text: u?.address.city ?? '');
    streetCtrl = TextEditingController(text: u?.address.street ?? '');
    numberCtrl = TextEditingController(
      text: (u?.address.number ?? 0).toString(),
    );
    zipCtrl = TextEditingController(text: u?.address.zipcode ?? '');
    latCtrl = TextEditingController(text: u?.address.geolocation.lat ?? '');
    longCtrl = TextEditingController(text: u?.address.geolocation.long ?? '');
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailCtrl.dispose();
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    phoneCtrl.dispose();
    firstCtrl.dispose();
    lastCtrl.dispose();
    cityCtrl.dispose();
    streetCtrl.dispose();
    numberCtrl.dispose();
    zipCtrl.dispose();
    latCtrl.dispose();
    longCtrl.dispose();
    super.dispose();
  }

  UserModel buildUser() {
    return UserModel(
      id: widget.editUser?.id,
      email: emailCtrl.text.trim(),
      username: usernameCtrl.text.trim(),
      password: passwordCtrl.text,
      phone: phoneCtrl.text.trim(),
      name: NameModel(
        firstname: firstCtrl.text.trim(),
        lastname: lastCtrl.text.trim(),
      ),
      address: AddressModel(
        city: cityCtrl.text.trim(),
        street: streetCtrl.text.trim(),
        number: int.tryParse(numberCtrl.text.trim()) ?? 0,
        zipcode: zipCtrl.text.trim(),
        geolocation: GeoLocationModel(
          lat: latCtrl.text.trim(),
          long: longCtrl.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editUser != null;
    final provider = context.watch<UserProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit User' : 'Add New User'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: FadeTransition(
        opacity: _animation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                if (!isEdit)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create User',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fill in the details below to create a new user account.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                
                // Account Section
                _buildSection(
                  title: 'Account Information',
                  icon: Icons.account_circle,
                  children: [
                    _buildTextField(
                      controller: emailCtrl,
                      label: 'Email Address',
                      hintText: 'Enter user email',
                      prefixIcon: Icons.email,
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: usernameCtrl,
                      label: 'Username',
                      hintText: 'Enter username',
                      prefixIcon: Icons.person,
                      validator: _validateRequired,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: passwordCtrl,
                      label: 'Password',
                      hintText: 'Enter password',
                      prefixIcon: Icons.lock,
                      suffixIcon: Icons.visibility_off,
                      validator: _validatePassword,
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: phoneCtrl,
                      label: 'Phone Number',
                      hintText: 'Enter phone number',
                      prefixIcon: Icons.phone,
                      validator: _validatePhone,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Personal Info Section
                _buildSection(
                  title: 'Personal Information',
                  icon: Icons.person_outline,
                  children: [
                    _buildTextField(
                      controller: firstCtrl,
                      label: 'First Name',
                      hintText: 'Enter first name',
                      prefixIcon: Icons.person,
                      validator: _validateRequired,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: lastCtrl,
                      label: 'Last Name',
                      hintText: 'Enter last name',
                      prefixIcon: Icons.person,
                      validator: _validateRequired,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Address Section
                _buildSection(
                  title: 'Address Information',
                  icon: Icons.location_on,
                  children: [
                    _buildTextField(
                      controller: cityCtrl,
                      label: 'City',
                      hintText: 'Enter city',
                      prefixIcon: Icons.location_city,
                      validator: _validateRequired,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: streetCtrl,
                      label: 'Street Address',
                      hintText: 'Enter street address',
                      prefixIcon: Icons.streetview,
                      validator: _validateRequired,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: numberCtrl,
                      label: 'House Number',
                      hintText: 'Enter house number',
                      prefixIcon: Icons.home,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: zipCtrl,
                      label: 'Zip Code',
                      hintText: 'Enter zip code',
                      prefixIcon: Icons.local_post_office,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Location Section
                _buildSection(
                  title: 'Location Coordinates',
                  icon: Icons.gps_fixed,
                  children: [
                    _buildTextField(
                      controller: latCtrl,
                      label: 'Latitude',
                      hintText: 'Enter latitude',
                      prefixIcon: Icons.gps_fixed,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: longCtrl,
                      label: 'Longitude',
                      hintText: 'Enter longitude',
                      prefixIcon: Icons.gps_fixed,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Error Display
                if (provider.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isEdit ? 'Save Changes' : 'Create User',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    IconData? suffixIcon,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon),
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!value.contains('@')) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^[\+]?[1-9][\d]{0,15}$').hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = buildUser();
    final provider = context.read<UserProvider>();
    
    if (widget.editUser != null) {
      final id = widget.editUser!.id!;
      await provider.editUser(id, user);
    } else {
      await provider.addUser(user);
    }
    
    if (!mounted) return;
    
    final error = provider.error;
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.editUser != null ? 'User updated successfully!' : 'User created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }
}
