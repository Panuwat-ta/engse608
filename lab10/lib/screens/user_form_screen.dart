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

class UserFormScreenState extends State<UserFormScreen> {
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

  @override
  void initState() {
    super.initState();
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
      appBar: AppBar(title: Text(isEdit ? 'Edit User' : 'Add User')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _sectionTitle('Account'),
              _textField(emailCtrl, 'Email', validator: _required),
              _textField(usernameCtrl, 'Username', validator: _required),
              _textField(
                passwordCtrl,
                'Password',
                validator: _required,
                obscure: true,
              ),
              _textField(phoneCtrl, 'Phone', validator: _required),
              const SizedBox(height: 16),
              _sectionTitle('Name'),
              _textField(firstCtrl, 'First name', validator: _required),
              _textField(lastCtrl, 'Last name', validator: _required),
              const SizedBox(height: 16),
              _sectionTitle('Address'),
              _textField(cityCtrl, 'City', validator: _required),
              _textField(streetCtrl, 'Street', validator: _required),
              _textField(
                numberCtrl,
                'Number',
                keyboardType: TextInputType.number,
              ),
              _textField(zipCtrl, 'Zipcode'),
              const SizedBox(height: 16),
              _sectionTitle('Geolocation'),
              _textField(latCtrl, 'Lat'),
              _textField(longCtrl, 'Long'),
              const SizedBox(height: 24),
              if (provider.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          final user = buildUser();
                          final provider = context.read<UserProvider>();
                          if (isEdit) {
                            final id = widget.editUser!.id!;
                            await provider.editUser(id, user);
                          } else {
                            await provider.addUser(user);
                          }
                          if (!mounted) return;
                          final err = provider.error;
                          if (context.mounted) {
                            if (err == null) {
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(err)));
                            }
                          }
                        },
                  icon: provider.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(isEdit ? 'Save changes' : 'Create user'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Widget _sectionTitle(String t) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        t,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
  );

  Widget _textField(
    TextEditingController c,
    String label, {
    String? Function(String?)? validator,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        validator: validator,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
