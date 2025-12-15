import 'package:flutter/material.dart';
import 'package:khmer25/login/api_service.dart';
import 'package:khmer25/login/auth_store.dart';
import 'package:khmer25/login/login_page.dart';
import 'package:khmer25/l10n/lang_store.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  AppUser? _user;
  bool _loading = false;
  String? _error;
  late final VoidCallback _authListener;

  @override
  void initState() {
    super.initState();
    _authListener = () => _loadUser(AuthStore.currentUser.value);
    AuthStore.currentUser.addListener(_authListener);
    _loadUser(AuthStore.currentUser.value);
  }

  @override
  void dispose() {
    AuthStore.currentUser.removeListener(_authListener);
    super.dispose();
  }

  Future<void> _loadUser(AppUser? base) async {
    if (!mounted) return;
    if (base == null) {
      setState(() {
        _user = null;
        _loading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _user = base;
    });

    final hasIdentifier = (base.id != 0) || base.phone.isNotEmpty;
    if (!hasIdentifier) {
      setState(() {
        _loading = false;
        _error = 'No id or phone available to fetch profile';
      });
      return;
    }

    try {
      final res = await ApiService.fetchUser(
        id: base.id != 0 ? base.id : null,
        phone: base.phone.isNotEmpty ? base.phone : null,
      );
      final fetched = AppUser.fromJson(res);
      final merged = AppUser(
        id: fetched.id != 0 ? fetched.id : base.id,
        username: fetched.username.isNotEmpty ? fetched.username : base.username,
        firstName: fetched.firstName.isNotEmpty ? fetched.firstName : base.firstName,
        lastName: fetched.lastName.isNotEmpty ? fetched.lastName : base.lastName,
        email: fetched.email.isNotEmpty ? fetched.email : base.email,
        phone: fetched.phone.isNotEmpty ? fetched.phone : base.phone,
      );
      if (!mounted) return;
      setState(() {
        _user = merged;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
        _user = base;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppUser?>(
      valueListenable: AuthStore.currentUser,
      builder: (context, authUser, _) {
        if (authUser == null) {
          return _buildLoggedOut(context);
        }
        if (_loading && _user == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildProfile(context, _user ?? authUser);
      },
    );
  }

  Widget _buildLoggedOut(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Login required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Please sign in to view your profile.',
              style: TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              child: Text(
                LangStore.t('login.button'),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, AppUser user) {
    final initials = _initialsFor(user);
    final bgColor = _colorFor(initials);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            'Account',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: bgColor,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.emailDisplay,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _infoTile(
                      label: 'Phone',
                      value: user.phoneDisplay,
                    ),
                    _infoTile(
                      label: 'Location',
                      value: 'Not Specified',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        AuthStore.logout();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logged out')),
                        );
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  String _initialsFor(AppUser user) {
    String first = user.firstName.trim();
    String last = user.lastName.trim();
    if (first.isEmpty && last.isEmpty) {
      final parts = user.displayName.split(' ');
      first = parts.isNotEmpty ? parts.first : '';
      last = parts.length > 1 ? parts.last : '';
    }
    final firstChar = first.isNotEmpty ? first[0] : '';
    final lastChar = last.isNotEmpty ? last[0] : '';
    final combined = (firstChar + lastChar).toUpperCase();
    if (combined.isNotEmpty) return combined;
    return 'US';
  }

  Color _colorFor(String key) {
    final palette = <Color>[
      Colors.green.shade600,
      Colors.blue.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
      Colors.red.shade600,
      Colors.brown.shade600,
    ];
    final index = key.codeUnits.fold<int>(0, (p, c) => p + c) % palette.length;
    return palette[index];
  }
}
