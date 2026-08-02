import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'sheets_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
  runApp(const LabUtilizationApp());
}

class LabUtilizationApp extends StatelessWidget {
  const LabUtilizationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lab Utilization Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF06B6D4),
          surface: Color(0xFF1E293B),
          surfaceContainer: Color(0xFF334155),
          onPrimary: Colors.white,
          onSurface: Color(0xFFF8FAFC),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF334155), width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0F172A),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
          hintStyle: const TextStyle(color: Color(0xFF64748B)),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            ),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return LabUtilizationHomePage(user: snapshot.data!);
        }
        return const GoogleSignInScreen();
      },
    );
  }
}

class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  bool _isSigningIn = false;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isSigningIn = true;
    });

    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser != null) {
          final GoogleSignInAuthentication googleAuth =
              await googleUser.authentication;
          final OAuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await FirebaseAuth.instance.signInWithCredential(credential);
        }
      }
    } catch (e) {
      debugPrint('Google sign in error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Sign-in failed: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App Icon Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withAlpha(100),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.science,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Lab Utilization Portal',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF8FAFC),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to insert & manage lab entries synchronized with Google Sheets',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Google Sign-In Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _isSigningIn ? null : _signInWithGoogle,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSigningIn
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF6366F1),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Google Logo colors icon
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                      child: const Icon(
                                        Icons.g_mobiledata,
                                        color: Color(0xFF4285F4),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Sign in with Google',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Google Sheet Reference Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.table_chart_outlined,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Connected Sheet ID: 1yLTLndwwistnZyJ12VW7cAnFsBZeh8Jf9sFAvNHZokQ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LabUtilizationHomePage extends StatefulWidget {
  final User user;
  const LabUtilizationHomePage({super.key, required this.user});

  @override
  State<LabUtilizationHomePage> createState() => _LabUtilizationHomePageState();
}

class _LabUtilizationHomePageState extends State<LabUtilizationHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Lab options requested: L1 to L9, pglab, MP lab
  final List<String> _labs = [
    'L1',
    'L2',
    'L3',
    'L4',
    'L5',
    'L6',
    'L7',
    'L8',
    'L9',
    'pglab',
    'MP lab',
  ];

  final String _sheetUrl =
      'https://docs.google.com/spreadsheets/d/1yLTLndwwistnZyJ12VW7cAnFsBZeh8Jf9sFAvNHZokQ/edit?usp=sharing';

  // Predefined static Google Apps Script Web App URL
  static String googleAppsScriptUrl = 'https://script.google.com/macros/s/AKfycbxXH6ntj69gPSlsgxEt44GsLrRvYzgdDWDN10rycR_w6HOYtZvSlzq84D1nD374XYYg/exec';

  // Form State
  String? _selectedLab = 'L1';
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _subjectNameController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController(
    text: '1',
  );
  final TextEditingController _sheetsWebhookController =
      TextEditingController();

  DateTime _selectedDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _repeatType = 'None';
  bool _isSubmitting = false;
  String _selectedFilterLab = 'All';

  final List<String> _suggestedClasses = [
    'S1 CSE',
    'S3 CSE',
    'S5 CSE',
    'S7 CSE',
    'S1 ECE',
    'S3 ECE',
    'S5 ECE',
    'S7 ECE',
    'S1 EEE',
    'S3 EEE',
    'S5 EEE',
    'S7 EEE',
    'M.Tech CSE',
    'MCA S1',
    'MCA S3',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedWebhookUrl();
  }

  Future<void> _loadSavedWebhookUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('webhook_url');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        setState(() {
          googleAppsScriptUrl = savedUrl;
          _sheetsWebhookController.text = savedUrl;
        });
      }
    } catch (_) {}
  }

  void _showWebhookSettingsDialog() {
    final controller = TextEditingController(
      text: googleAppsScriptUrl.isNotEmpty
          ? googleAppsScriptUrl
          : _sheetsWebhookController.text,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.link, color: Color(0xFF10B981)),
            SizedBox(width: 10),
            Text(
              'Google Apps Script Web App URL',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paste your Google Apps Script Web App URL to automatically insert rows into your Google Sheet tabs (L1–L9, PG, MP).',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'https://script.google.com/macros/s/.../exec',
                hintStyle: TextStyle(color: Color(0xFF64748B)),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF10B981)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = controller.text.trim();
              setState(() {
                googleAppsScriptUrl = newUrl;
                _sheetsWebhookController.text = newUrl;
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('webhook_url', newUrl);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text(
              'Save URL',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _classNameController.dispose();
    _subjectNameController.dispose();
    _hoursController.dispose();
    _sheetsWebhookController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        if (_endDate.isBefore(_selectedDate)) {
          _endDate = _selectedDate;
        }
      });
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_selectedDate) ? _selectedDate : _endDate,
      firstDate: _selectedDate,
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    List<DateTime> datesToProcess = [];
    DateTime current = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    DateTime end = DateTime(_endDate.year, _endDate.month, _endDate.day);

    if (_repeatType == 'None' || current.isAfter(end)) {
      datesToProcess.add(current);
    } else if (_repeatType == 'Daily') {
      while (!current.isAfter(end)) {
        datesToProcess.add(current);
        current = current.add(const Duration(days: 1));
      }
    } else if (_repeatType == 'Weekly') {
      while (!current.isAfter(end)) {
        datesToProcess.add(current);
        current = current.add(const Duration(days: 7));
      }
    }

    try {
      final webhookUrl = googleAppsScriptUrl.isNotEmpty
          ? googleAppsScriptUrl
          : _sheetsWebhookController.text.trim();

      for (var dt in datesToProcess) {
        final formattedDate = DateFormat('dd-MM-yyyy').format(dt);
        final dayAllotted = DateFormat('EEEE').format(dt);

        final data = {
          'labname': _selectedLab,
          'classname': _classNameController.text.trim(),
          'subject_name': _subjectNameController.text.trim(),
          'start_date': formattedDate,
          'end_date': formattedDate,
          'day_allotted': dayAllotted,
          'hours': _hoursController.text.trim(),
          'user_email': widget.user.email ?? 'Unknown',
          'user_name': widget.user.displayName ?? 'Faculty/Staff',
          'sheet_link': _sheetUrl,
          'timestamp': FieldValue.serverTimestamp(),
        };

        // 1. Try Save to Firebase Firestore with 2s timeout
        try {
          await FirebaseFirestore.instance
              .collection('lab_utilization')
              .add(data)
              .timeout(const Duration(seconds: 2));
          debugPrint('Firestore saved successfully.');
        } catch (e) {
          debugPrint('Firestore notice: $e');
        }

        // 2. Save to Google Sheets Webhook
        if (webhookUrl.isNotEmpty) {
          final payload = jsonEncode({
            'labname': _selectedLab,
            'sheet_name': _selectedLab,
            'classname': _classNameController.text.trim(),
            'subject_name': _subjectNameController.text.trim(),
            'start_date': formattedDate,
            'end_date': formattedDate,
            'day_allotted': dayAllotted,
            'hours': _hoursController.text.trim(),
            'user_email': widget.user.email ?? '',
          });

          debugPrint('Posting to Google Sheets URL: $webhookUrl');

          try {
            await sendToGoogleSheets(webhookUrl, payload);
            debugPrint('Dispatched payload to Google Sheets Web App.');
          } catch (e) {
            debugPrint('Google Sheets dispatch notice: $e');
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Lab Utilization record for $_selectedLab submitted successfully!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        _classNameController.clear();
        _subjectNameController.clear();
        _hoursController.text = '1';
        setState(() {
          _selectedLab = _labs.first;
          _selectedDate = DateTime.now();
          _endDate = DateTime.now();
          _repeatType = 'None';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.science, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lab Utilization',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Google Sheets & Firebase Sync',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.link,
              color: googleAppsScriptUrl.isNotEmpty
                  ? const Color(0xFF10B981)
                  : Colors.orangeAccent,
            ),
            tooltip: 'Configure Google Apps Script Web App URL',
            onPressed: _showWebhookSettingsDialog,
          ),
          // User profile & Logout
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'logout') {
                  if (!kIsWeb) {
                    try {
                      await GoogleSignIn().signOut();
                    } catch (_) {}
                  }
                  await FirebaseAuth.instance.signOut();
                }
              },
              color: const Color(0xFF1E293B),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF6366F1),
                      backgroundImage: widget.user.photoURL != null
                          ? NetworkImage(widget.user.photoURL!)
                          : null,
                      child: widget.user.photoURL == null
                          ? Text(
                              (widget.user.email ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        widget.user.displayName ?? widget.user.email ?? 'User',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.displayName ?? 'Signed In User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.user.email ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Color(0xFFEF4444), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Sign Out',
                        style: TextStyle(color: Color(0xFFEF4444)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        backgroundColor: const Color(0xFF1E293B),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          indicatorWeight: 3,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: const [
            Tab(icon: Icon(Icons.add_task), text: 'New Entry'),
            Tab(icon: Icon(Icons.table_chart), text: 'View Sheet Records'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFormTab(), _buildRecordsTab()],
      ),
    );
  }

  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.edit_note,
                              color: Color(0xFF6366F1),
                              size: 28,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Insert Lab Utilization Data',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF8FAFC),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Target Google Sheet Info Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.description_outlined,
                                color: Color(0xFF10B981),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Target Google Sheet: $_sheetUrl',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (googleAppsScriptUrl.isEmpty) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _showWebhookSettingsDialog,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFF59E0B,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFF59E0B),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Color(0xFFF59E0B),
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Click here to set your Apps Script Web App URL to sync with Google Sheet tabs.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFFBBF24),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Color(0xFFFBBF24),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const Divider(height: 32, color: Color(0xFF334155)),

                        // 1. Lab Name Dropdown (L1 to L9, pglab, MP lab)
                        const Text(
                          'Lab Name *',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedLab,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(
                              Icons.door_sliding_outlined,
                              color: Color(0xFF6366F1),
                            ),
                            hintText: 'Select Lab Name',
                          ),
                          dropdownColor: const Color(0xFF1E293B),
                          items: _labs.map((String lab) {
                            return DropdownMenuItem<String>(
                              value: lab,
                              child: Text(
                                lab,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedLab = newValue;
                            });
                          },
                          validator: (val) =>
                              val == null ? 'Please select a lab' : null,
                        ),
                        const SizedBox(height: 20),

                        // 2. Class Name
                        const Text(
                          'Class Name *',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return _suggestedClasses;
                            }
                            return _suggestedClasses.where((String option) {
                              return option.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              );
                            });
                          },
                          fieldViewBuilder:
                              (
                                context,
                                controller,
                                focusNode,
                                onEditingComplete,
                              ) {
                                controller.addListener(() {
                                  _classNameController.text = controller.text;
                                });
                                return TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.school_outlined,
                                      color: Color(0xFF06B6D4),
                                    ),
                                    hintText: 'e.g., S5 CSE, S7 ECE, MCA S1',
                                  ),
                                  validator: (val) =>
                                      (val == null || val.trim().isEmpty)
                                      ? 'Please enter Class Name'
                                      : null,
                                );
                              },
                          onSelected: (String selection) {
                            _classNameController.text = selection;
                          },
                        ),
                        const SizedBox(height: 20),

                        // 3. Subject Name
                        const Text(
                          'Subject Name *',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _subjectNameController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(
                              Icons.menu_book_outlined,
                              color: Color(0xFF10B981),
                            ),
                            hintText: 'e.g., Data Structures Lab, Project',
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                              ? 'Please enter Subject Name'
                              : null,
                        ),
                        const SizedBox(height: 20),

                        // 4. Start Date & End Date
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Start Date *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => _pickStartDate(context),
                                    borderRadius: BorderRadius.circular(12),
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(
                                          Icons.calendar_today,
                                          color: Color(0xFFF59E0B),
                                        ),
                                      ),
                                      child: Text(
                                        DateFormat(
                                          'dd MMM yyyy',
                                        ).format(_selectedDate),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'End Date *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => _pickEndDate(context),
                                    borderRadius: BorderRadius.circular(12),
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(
                                          Icons.event_available,
                                          color: Color(0xFFF59E0B),
                                        ),
                                      ),
                                      child: Text(
                                        DateFormat(
                                          'dd MMM yyyy',
                                        ).format(_endDate),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Day Allotted: ${DateFormat('EEEE').format(_selectedDate)}',
                          style: const TextStyle(
                            color: Color(0xFF06B6D4),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 5. Repeat
                        const Text(
                          'Repeat *',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _repeatType,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(
                              Icons.repeat,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                          dropdownColor: const Color(0xFF1E293B),
                          items: ['None', 'Daily', 'Weekly'].map((String val) {
                            return DropdownMenuItem<String>(
                              value: val,
                              child: Text(val),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() {
                                _repeatType = newValue;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        // 6. Hours Allotted
                        const Text(
                          'Hours Allotted *',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _hoursController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(
                              Icons.access_time_outlined,
                              color: Color(0xFFEC4899),
                            ),
                            hintText: 'e.g., 5,6,7 or 1,2,3,4',
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                              ? 'Please enter Hours Allotted'
                              : null,
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Submitting to Database...'),
                                    ],
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.send_rounded),
                                      SizedBox(width: 8),
                                      Text(
                                        'INSERT DATA TO SHEET & DATABASE',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordsTab() {
    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1E293B),
          child: Row(
            children: [
              const Icon(Icons.filter_alt, color: Color(0xFF6366F1)),
              const SizedBox(width: 8),
              const Text(
                'Filter Lab:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: DropdownButton<String>(
                  value: _selectedFilterLab,
                  underline: const SizedBox(),
                  dropdownColor: const Color(0xFF1E293B),
                  items: ['All', ..._labs].map((String lab) {
                    return DropdownMenuItem<String>(
                      value: lab,
                      child: Text(lab),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedFilterLab = value;
                      });
                    }
                  },
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() {});
                },
                icon: const Icon(Icons.refresh, color: Color(0xFF06B6D4)),
                label: const Text(
                  'Refresh',
                  style: TextStyle(color: Color(0xFF06B6D4)),
                ),
              ),
            ],
          ),
        ),

        // Live stream of records
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _selectedFilterLab == 'All'
                ? FirebaseFirestore.instance
                      .collection('lab_utilization')
                      .orderBy('timestamp', descending: true)
                      .snapshots()
                : FirebaseFirestore.instance
                      .collection('lab_utilization')
                      .where('labname', isEqualTo: _selectedFilterLab)
                      .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_off,
                        size: 48,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(height: 12),
                      Text('Error loading records: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedFilterLab == 'All'
                            ? 'No lab utilization records inserted yet.'
                            : 'No records found for lab $_selectedFilterLab.',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          _tabController.animateTo(0);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Add First Record'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final item = docs[index].data() as Map<String, dynamic>;
                  final docId = docs[index].id;
                  final labName = item['labname'] ?? 'N/A';
                  final className = item['classname'] ?? 'N/A';
                  final eventName = item['eventname'] ?? 'N/A';
                  final dateStr = item['date'] ?? 'N/A';
                  final hours = item['hours']?.toString() ?? '1';
                  final remarks = item['remarks'] ?? '';
                  final userEmail = item['user_email'] ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Lab badge
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              labName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      eventName,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF06B6D4,
                                        ).withAlpha(40),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFF06B6D4),
                                        ),
                                      ),
                                      child: Text(
                                        '$hours hrs',
                                        style: const TextStyle(
                                          color: Color(0xFF06B6D4),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.school,
                                      size: 16,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Class: $className',
                                      style: const TextStyle(
                                        color: Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      dateStr,
                                      style: const TextStyle(
                                        color: Color(0xFFCBD5E1),
                                      ),
                                    ),
                                  ],
                                ),
                                if (userEmail.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.person_outline,
                                        size: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Inserted by: $userEmail',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (remarks.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Remarks: $remarks',
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFF94A3B8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Delete action
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFFEF4444),
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFF1E293B),
                                  title: const Text('Delete Entry'),
                                  content: const Text(
                                    'Are you sure you want to delete this record?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFEF4444,
                                        ),
                                      ),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await FirebaseFirestore.instance
                                    .collection('lab_utilization')
                                    .doc(docId)
                                    .delete();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
