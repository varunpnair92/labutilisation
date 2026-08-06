import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'sheets_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'firebase_options.dart';
import 'voice_parser.dart';

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
      title: 'FISAT CCF Lab Utilization',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2D328C),
          secondary: Color(0xFFF5B862),
          surface: Color(0xFF181F42),
          surfaceContainer: Color(0xFF252D59),
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
            borderSide: const BorderSide(color: Color(0xFFF5B862), width: 2),
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
              child: CircularProgressIndicator(color: Color(0xFFF5B862)),
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
                            colors: [Color(0xFF2D328C), Color(0xFF1D226A)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2D328C).withAlpha(100),
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
  static String googleAppsScriptUrl =
      'https://script.google.com/macros/s/AKfycbw2jchCBuedmA3NowqaGZ_jSxXNuXkoNjdfVy8i-UY3pvEddwNfBpPCWKYGSWOvCGy7/exec';

  // Form State
  List<String> _selectedLabs = ['L1'];
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
  String _voicePromptText = '';
  bool _isSubmitting = false;
  String _selectedFilterLab = 'All';
  DateTime? _selectedFilterDate = DateTime.now();
  DateTimeRange? _filterDateRange;
  bool _showAllDates = false;
  String _recordsSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  DateTime? _parseDateStr(String dateStr) {
    try {
      final trimmed = dateStr.trim();
      if (trimmed.startsWith('Date(') && trimmed.endsWith(')')) {
        final inner = trimmed.substring(5, trimmed.length - 1);
        final parts = inner.split(',');
        if (parts.length >= 3) {
          final year = int.parse(parts[0].trim());
          final month = int.parse(parts[1].trim()) + 1; // 0-indexed in JS Date
          final day = int.parse(parts[2].trim());
          return DateTime(year, month, day);
        }
      }
      if (trimmed.contains('-')) {
        final parts = trimmed.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            return DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          } else {
            return DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        }
      } else if (trimmed.contains('/')) {
        final parts = trimmed.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
    } catch (_) {}
    return null;
  }

  List<Map<String, dynamic>> _sheetData = [];
  bool _isLoadingSheet = true;
  String? _sheetError;

  Future<void> _fetchSheetData() async {
    setState(() {
      _isLoadingSheet = true;
      _sheetError = null;
    });

    try {
      final String sheetId = '1yLTLndwwistnZyJ12VW7cAnFsBZeh8Jf9sFAvNHZokQ';
      final List<String> sheetNames = <String>{
        ..._labs,
        'PG',
        'MP',
      }.toList();
      List<Map<String, dynamic>> allData = [];
      Set<String> seenKeys = {};

      for (final sheetName in sheetNames) {
        final url =
            'https://docs.google.com/spreadsheets/d/$sheetId/gviz/tq?tqx=out:json&sheet=$sheetName';
        try {
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            final bodyStr = response.body;
            final startIdx = bodyStr.indexOf('setResponse(') + 12;
            final endIdx = bodyStr.lastIndexOf(');');
            if (startIdx > 11 && endIdx > startIdx) {
              final jsonStr = bodyStr.substring(startIdx, endIdx);
              final json = jsonDecode(jsonStr);
              if (json['table'] != null && json['table']['rows'] != null) {
                final rows = json['table']['rows'] as List;
                final parsedNumHeaders = json['table']['parsedNumHeaders'] ?? 0;
                for (int i = 0; i < rows.length; i++) {
                  final row = rows[i];
                  final cells = row['c'] as List;
                  if (cells.isNotEmpty &&
                      cells[0] != null &&
                      cells[0]['v'] != null) {
                    String parseCell(int idx) {
                      if (cells.length > idx && cells[idx] != null) {
                        if (cells[idx]['f'] != null) {
                          return cells[idx]['f'].toString();
                        } else if (cells[idx]['v'] != null) {
                          return cells[idx]['v'].toString();
                        }
                      }
                      return '';
                    }

                    final labname = parseCell(0);
                    // Skip if this row is actually the header row
                    if (labname.toLowerCase() == 'lab_name' ||
                        labname.toLowerCase() == 'labname') {
                      continue;
                    }

                    final normLab = labname.toLowerCase().trim();
                    final normSheet = sheetName.toLowerCase().trim();
                    bool labMatches = normLab == normSheet ||
                        (normLab == 'pg' && normSheet == 'pglab') ||
                        (normLab == 'pglab' && normSheet == 'pg') ||
                        (normLab == 'mp' && normSheet == 'mp lab') ||
                        (normLab == 'mp lab' && normSheet == 'mp');

                    if (!labMatches) {
                      // gviz returns default first tab when queried tab sheetName does not exist
                      continue;
                    }

                    final dayAllotted = parseCell(1);
                    final hours = parseCell(2);
                    final subjName = parseCell(3);
                    final clsName = parseCell(4);
                    final startDate = parseCell(5);
                    final endDate = parseCell(6);
                    final userEmail = parseCell(7);
                    final ts = parseCell(8);

                    final String uniqueKey =
                        "${normLab}_${startDate}_${hours}_${subjName.toLowerCase()}_${clsName.toLowerCase()}_$ts";
                    if (seenKeys.contains(uniqueKey)) {
                      continue;
                    }
                    seenKeys.add(uniqueKey);

                    allData.add({
                      "row": i + parsedNumHeaders + 1,
                      "sheet_name": sheetName,
                      "labname": labname,
                      "day_allotted": dayAllotted,
                      "hours": hours,
                      "subject_name": subjName,
                      "classname": clsName,
                      "start_date": startDate,
                      "end_date": endDate,
                      "user_email": userEmail,
                      "timestamp": ts,
                    });
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Notice fetching $sheetName: $e');
        }
      }

      setState(() {
        _sheetData = allData.reversed.toList();
        _isLoadingSheet = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSheet = false;
        _sheetError = 'Error fetching data: $e';
      });
    }
  }

  final List<String> _suggestedClasses = [
    'S1 CSA', 'S1 CSB', 'S1 CSC', 'S1 CSD',
    'S2 CSA', 'S2 CSB', 'S2 CSC', 'S2 CSD',
    'S3 CSA', 'S3 CSB', 'S3 CSC', 'S3 CSD',
    'S4 CSA', 'S4 CSB', 'S4 CSC', 'S4 CSD',
    'S5 CSA', 'S5 CSB', 'S5 CSC', 'S5 CSD',
    'S6 CSA', 'S6 CSB', 'S6 CSC', 'S6 CSD',
    'S7 CSA', 'S7 CSB', 'S7 CSC', 'S7 CSD',
    'S8 CSA', 'S8 CSB', 'S8 CSC', 'S8 CSD',
    'S1 MCA', 'S2 MCA', 'S3 MCA', 'S4 MCA',
    'IMCA 1', 'IMCA 2', 'IMCA 3', 'IMCA 4', 'IMCA 5',
    'IMCA 6', 'IMCA 7', 'IMCA 8', 'IMCA 9', 'IMCA 10',
    'S1 ECE', 'S3 ECE', 'S5 ECE', 'S7 ECE',
    'S1 EEE', 'S3 EEE', 'S5 EEE', 'S7 EEE',
    'M.Tech CSE',
  ];

  @override
  void initState() {
    super.initState();
    _fetchSheetData();
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

  Future<void> _openVoiceBookingModal() async {
    final SpeechToText speech = SpeechToText();
    bool speechAvailable = false;
    try {
      speechAvailable = await speech.initialize(
        onError: (val) => debugPrint('Speech error: $val'),
        onStatus: (val) => debugPrint('Speech status: $val'),
      );
    } catch (e) {
      debugPrint('Speech init notice: $e');
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final promptController = TextEditingController(
              text: _voicePromptText,
            );
            ParsedBooking parsed = VoicePromptParser.parse(promptController.text);

            void updatePrompt(String text) {
              setModalState(() {
                promptController.text = text;
                promptController.selection = TextSelection.fromPosition(
                  TextPosition(offset: text.length),
                );
                parsed = VoicePromptParser.parse(text);
                _voicePromptText = text;
              });
            }

            void toggleListening() async {
              if (speech.isListening) {
                await speech.stop();
                setModalState(() {});
              } else {
                if (speechAvailable) {
                  await speech.listen(
                    onResult: (result) {
                      updatePrompt(result.recognizedWords);
                    },
                    listenOptions: SpeechListenOptions(
                      listenMode: ListenMode.confirmation,
                    ),
                  );
                  setModalState(() {});
                } else {
                  ScaffoldMessenger.of(modalCtx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Speech recognition not available on this device. You can type or paste the prompt!',
                      ),
                    ),
                  );
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.mic, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Voice & Natural Language Booking',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Order doesn't matter! Speak or type prompt.",
                                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Quick prompt presets
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPromptPresetChip(
                            'S5 CSA Hackathon hour 1 2 3 lab 2 August second',
                            updatePrompt,
                          ),
                          const SizedBox(width: 8),
                          _buildPromptPresetChip(
                            'book for hackathon s5 csa for august 20 lab 1',
                            updatePrompt,
                          ),
                          const SizedBox(width: 8),
                          _buildPromptPresetChip(
                            'lab 3 python workshop s3 ece tomorrow 2 hours',
                            updatePrompt,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mic / Input Field
                    TextField(
                      controller: promptController,
                      maxLines: 3,
                      onChanged: (text) {
                        setModalState(() {
                          parsed = VoicePromptParser.parse(text);
                          _voicePromptText = text;
                        });
                      },
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText:
                            'Tap mic or type: e.g. "book for hackathon s5 csa for august 20 lab 1"',
                        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: _HeartbeatMicButton(
                            isListening: speech.isListening,
                            onTap: toggleListening,
                          ),
                        ),
                      ),
                    ),
                    if (speech.isListening) const _VoiceListeningWaveAnimation(),

                    const SizedBox(height: 20),
                    const Text(
                      'Extracted Column Data:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Extracted Entities Cards/Grid
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        children: [
                          _buildEntityRow(
                            icon: Icons.meeting_room,
                            label: 'Lab Name',
                            value: parsed.labName ?? 'Not recognized',
                            isMatched: parsed.labName != null,
                          ),
                          const Divider(color: Color(0xFF334155), height: 16),
                          _buildEntityRow(
                            icon: Icons.school,
                            label: 'Class Name',
                            value: parsed.className ?? 'Not recognized',
                            isMatched: parsed.className != null,
                          ),
                          const Divider(color: Color(0xFF334155), height: 16),
                          _buildEntityRow(
                            icon: Icons.book,
                            label: 'Subject / Event',
                            value: parsed.subjectName ?? 'Not recognized',
                            isMatched: parsed.subjectName != null,
                          ),
                          const Divider(color: Color(0xFF334155), height: 16),
                          _buildEntityRow(
                            icon: Icons.calendar_today,
                            label: 'Date',
                            value: parsed.date != null
                                ? DateFormat('dd-MM-yyyy (EEEE)').format(parsed.date!)
                                : 'Not recognized',
                            isMatched: parsed.date != null,
                          ),
                          const Divider(color: Color(0xFF334155), height: 16),
                          _buildEntityRow(
                            icon: Icons.access_time,
                            label: 'Hours',
                            value: '${parsed.hours ?? '1'} hour(s)',
                            isMatched: parsed.hours != null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: parsed.isEmpty
                            ? null
                            : () {
                                setState(() {
                                  if (parsed.labName != null &&
                                      _labs.contains(parsed.labName)) {
                                    _selectedLabs = [parsed.labName!];
                                  }
                                  if (parsed.className != null) {
                                    _classNameController.text = parsed.className!;
                                  }
                                  if (parsed.subjectName != null) {
                                    _subjectNameController.text = parsed.subjectName!;
                                  }
                                  if (parsed.date != null) {
                                    _selectedDate = parsed.date!;
                                    _endDate = parsed.date!;
                                  }
                                  if (parsed.hours != null) {
                                    _hoursController.text = parsed.hours!;
                                  }
                                  promptController.clear();
                                });
                                Navigator.pop(modalCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF10B981),
                                    content: const Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Voice prompt extracted & applied to form columns!',
                                            style: TextStyle(fontWeight: FontWeight.bold),
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
                              },
                        icon: const Icon(Icons.playlist_add_check, color: Colors.white),
                        label: const Text(
                          'Apply Extracted Data to Form',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPromptPresetChip(String text, Function(String) onTap) {
    return ActionChip(
      backgroundColor: const Color(0xFF1E293B),
      side: const BorderSide(color: Color(0xFF334155)),
      label: Text(
        '"$text"',
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
      ),
      onPressed: () => onTap(text),
    );
  }

  Widget _buildEntityRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isMatched,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isMatched ? const Color(0xFF10B981) : const Color(0xFF64748B),
        ),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isMatched ? FontWeight.bold : FontWeight.normal,
              color: isMatched ? const Color(0xFFF8FAFC) : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
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

  Future<void> _openMultiLabDialog(BuildContext context) async {
    List<String> tempSelected = List.from(_selectedLabs);
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Labs',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setDialogState(() {
                        if (tempSelected.length == _labs.length) {
                          tempSelected = [_labs.first];
                        } else {
                          tempSelected = List.from(_labs);
                        }
                      });
                    },
                    child: Text(
                      tempSelected.length == _labs.length
                          ? 'Clear All'
                          : 'Select All',
                      style: const TextStyle(
                        color: Color(0xFFF5B862),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _labs.map((lab) {
                      final isChecked = tempSelected.contains(lab);
                      return CheckboxListTile(
                        activeColor: const Color(0xFF2D328C),
                        checkColor: const Color(0xFFF5B862),
                        title: Text(
                          lab,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: isChecked,
                        onChanged: (bool? checked) {
                          setDialogState(() {
                            if (checked == true) {
                              if (!tempSelected.contains(lab)) {
                                tempSelected.add(lab);
                              }
                            } else {
                              if (tempSelected.length > 1) {
                                tempSelected.remove(lab);
                              }
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D328C),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedLabs = tempSelected;
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _processHoursInput(String input) {
    input = input.trim();
    if (input.contains('-')) {
      final parts = input.split('-');
      if (parts.length == 2) {
        final start = int.tryParse(parts[0].trim());
        final end = int.tryParse(parts[1].trim());
        if (start != null && end != null && start <= end) {
          return List.generate(end - start + 1, (i) => start + i).join(',');
        }
      }
    }
    return input;
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

    if (_repeatType == 'None') {
      datesToProcess.add(current);
    } else {
      DateTime end = DateTime(_endDate.year, _endDate.month, _endDate.day);
      if (current.isAfter(end)) {
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
    }

    try {
      final webhookUrl = googleAppsScriptUrl.isNotEmpty
          ? googleAppsScriptUrl
          : _sheetsWebhookController.text.trim();

      final String finalHours = _processHoursInput(_hoursController.text);

      for (var lab in _selectedLabs) {
        for (var dt in datesToProcess) {
          final formattedDate = DateFormat('dd-MM-yyyy').format(dt);
          final dayAllotted = DateFormat('EEEE').format(dt);

          if (webhookUrl.isNotEmpty) {
            final payload = jsonEncode({
              'action': 'insert',
              'labname': lab,
              'sheet_name': lab,
              'classname': _classNameController.text.trim(),
              'subject_name': _subjectNameController.text.trim(),
              'start_date': formattedDate,
              'end_date': formattedDate,
              'day_allotted': dayAllotted,
              'hours': finalHours,
              'user_email': widget.user.email ?? '',
              'timestamp': DateTime.now().toIso8601String(),
            });

            debugPrint('Posting to Google Sheets URL: $webhookUrl');

            try {
              sendToGoogleSheets(webhookUrl, payload);
              debugPrint('Dispatched payload to Google Sheets Web App.');
            } catch (e) {
              debugPrint('Google Sheets dispatch notice: $e');
            }
          }
        }
      }

      // Schedule background refresh after short delay so form resets instantly
      Future.delayed(const Duration(milliseconds: 800), () {
        _fetchSheetData();
      });
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
                    'Lab Utilization record for ${_selectedLabs.join(', ')} submitted successfully!',
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
          _selectedLabs = [_labs.first];
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
          indicatorColor: const Color(0xFFF5B862),
          indicatorWeight: 3,
          labelColor: const Color(0xFFF5B862),
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF2D328C), Color(0xFF1D226A)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D328C).withValues(alpha: 0.5),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _openVoiceBookingModal,
          elevation: 0,
          highlightElevation: 0,
          backgroundColor: Colors.transparent,
          shape: const CircleBorder(),
          tooltip: 'Voice Booking',
          child: const Icon(Icons.mic, color: Colors.white, size: 26),
        ),
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
                              color: Color(0xFFF5B862),
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

                        // 1. Multi-Select Lab Dropdown Field
                        const Text(
                          'Lab Name(s) *',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _openMultiLabDialog(context),
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.door_sliding_outlined,
                                color: Color(0xFFF5B862),
                              ),
                              suffixIcon: const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFFF5B862),
                              ),
                              errorText: _selectedLabs.isEmpty
                                  ? 'Please select at least one lab'
                                  : null,
                            ),
                            child: Text(
                              _selectedLabs.isEmpty
                                  ? 'Select Labs'
                                  : _selectedLabs.join(', '),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
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
                          initialValue: TextEditingValue(text: _classNameController.text),
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
                                if (controller.text != _classNameController.text) {
                                  controller.text = _classNameController.text;
                                }
                                controller.addListener(() {
                                  _classNameController.text = controller.text;
                                });
                                return TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.school_outlined,
                                      color: Color(0xFFF5B862),
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
                              color: Color(0xFFF5B862),
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
                            color: Color(0xFFF5B862),
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
                              color: Color(0xFFF5B862),
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
                              color: Color(0xFFF5B862),
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
                              backgroundColor: const Color(0xFF2D328C),
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
                                      Text('Allocating...'),
                                    ],
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.send_rounded),
                                      SizedBox(width: 8),
                                      Text(
                                        'ALLOCATE',
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
        // Universal Search & Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1E293B),
          child: Column(
            children: [
              // 1. Search Bar Input
              TextFormField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _recordsSearchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText:
                      'Search anything (Lab, Class, Event/Subject, Date, Hours, Booked By)...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFFF5B862),
                  ),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Color(0xFF94A3B8),
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _recordsSearchQuery = '';
                              });
                            },
                          )
                          : null,
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Filter Controls (Lab Dropdown, Date Chips, Refresh)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Lab Filter
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFilterLab,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          items:
                              ['All', ..._labs].map((String lab) {
                                return DropdownMenuItem<String>(
                                  value: lab,
                                  child: Text('Lab: $lab'),
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
                    ),
                    const SizedBox(width: 8),

                    // Today Chip Filter
                    ChoiceChip(
                      label: const Text('Today'),
                      selected:
                          !_showAllDates &&
                          _selectedFilterDate != null &&
                          _filterDateRange == null,
                      selectedColor: const Color(0xFF2D328C),
                      backgroundColor: const Color(0xFF0F172A),
                      labelStyle: TextStyle(
                        color:
                            (!_showAllDates &&
                                    _selectedFilterDate != null &&
                                    _filterDateRange == null)
                                ? Colors.white
                                : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFilterDate = DateTime.now();
                            _filterDateRange = null;
                            _showAllDates = false;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 6),

                    // Custom Date / Range Filter Button
                    ActionChip(
                      avatar: const Icon(
                        Icons.date_range,
                        size: 16,
                        color: Color(0xFFF5B862),
                      ),
                      label: Text(
                        _filterDateRange != null
                            ? '${DateFormat('dd MMM').format(_filterDateRange!.start)} - ${DateFormat('dd MMM').format(_filterDateRange!.end)}'
                            : (_selectedFilterDate != null
                                ? DateFormat(
                                  'dd MMM yyyy',
                                ).format(_selectedFilterDate!)
                                : 'Select Date'),
                      ),
                      backgroundColor: const Color(0xFF0F172A),
                      labelStyle: TextStyle(
                        color:
                            (_filterDateRange != null ||
                                    (_selectedFilterDate != null &&
                                        !_showAllDates))
                                ? const Color(0xFFF5B862)
                                : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          initialDateRange:
                              _filterDateRange ??
                              DateTimeRange(
                                start: _selectedFilterDate ?? DateTime.now(),
                                end: _selectedFilterDate ?? DateTime.now(),
                              ),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFF2D328C),
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF1E293B),
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _filterDateRange = picked;
                            _selectedFilterDate = null;
                            _showAllDates = false;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 6),

                    // All Dates Chip Filter
                    ChoiceChip(
                      label: const Text('All Dates'),
                      selected: _showAllDates,
                      selectedColor: const Color(0xFF2D328C),
                      backgroundColor: const Color(0xFF0F172A),
                      labelStyle: TextStyle(
                        color:
                            _showAllDates
                                ? Colors.white
                                : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _showAllDates = true;
                            _selectedFilterDate = null;
                            _filterDateRange = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),

                    // Refresh Button
                    IconButton(
                      onPressed: () {
                        _fetchSheetData();
                      },
                      icon: const Icon(
                        Icons.refresh,
                        color: Color(0xFFF5B862),
                      ),
                      tooltip: 'Refresh Records',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Live list of records
        Expanded(
          child: Builder(
            builder: (context) {
              if (_sheetError != null) {
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
                      Text('Error loading records: $_sheetError'),
                    ],
                  ),
                );
              }

              if (_isLoadingSheet) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFF5B862)),
                );
              }

              if (_sheetData.isEmpty) {
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
                          backgroundColor: const Color(0xFF2D328C),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Add First Record'),
                      ),
                    ],
                  ),
                );
              }

              final docs =
                  _sheetData.where((item) {
                    // 1. Lab Filter
                    if (_selectedFilterLab != 'All' &&
                        (item['labname'] ?? '').toString().toLowerCase() !=
                            _selectedFilterLab.toLowerCase()) {
                      return false;
                    }

                    // 2. Date / Date Range Filter
                    if (!_showAllDates) {
                      final dateStr = (item['start_date'] ?? '').toString();
                      final itemDate = _parseDateStr(dateStr);

                      if (_filterDateRange != null) {
                        if (itemDate == null) return false;
                        final start = DateTime(
                          _filterDateRange!.start.year,
                          _filterDateRange!.start.month,
                          _filterDateRange!.start.day,
                        );
                        final end = DateTime(
                          _filterDateRange!.end.year,
                          _filterDateRange!.end.month,
                          _filterDateRange!.end.day,
                          23,
                          59,
                          59,
                        );
                        if (itemDate.isBefore(start) || itemDate.isAfter(end)) {
                          return false;
                        }
                      } else if (_selectedFilterDate != null) {
                        final targetStr = DateFormat(
                          'dd-MM-yyyy',
                        ).format(_selectedFilterDate!);
                        if (dateStr != targetStr) {
                          if (itemDate != null) {
                            final isSameDay =
                                itemDate.year == _selectedFilterDate!.year &&
                                itemDate.month == _selectedFilterDate!.month &&
                                itemDate.day == _selectedFilterDate!.day;
                            if (!isSameDay) return false;
                          } else {
                            return false;
                          }
                        }
                      }
                    }

                    // 3. Universal Search Filter (Lab, Subject, Class, Event, Hours, Booked By, Date)
                    if (_recordsSearchQuery.trim().isNotEmpty) {
                      final q = _recordsSearchQuery.toLowerCase().trim();
                      final lab = (item['labname'] ?? '').toLowerCase();
                      final subj = (item['subject_name'] ?? '').toLowerCase();
                      final cls = (item['classname'] ?? '').toLowerCase();
                      final date = (item['start_date'] ?? '').toLowerCase();
                      final dayAllotted =
                          (item['day_allotted'] ?? '').toLowerCase();
                      final hours = (item['hours'] ?? '').toLowerCase();
                      final bookedBy =
                          (item['user_email'] ?? '').toLowerCase();

                      final matchesSearch =
                          lab.contains(q) ||
                          subj.contains(q) ||
                          cls.contains(q) ||
                          date.contains(q) ||
                          dayAllotted.contains(q) ||
                          hours.contains(q) ||
                          bookedBy.contains(q);
                      if (!matchesSearch) return false;
                    }

                    return true;
                  }).toList();

              // Sort records by date descending (newest date first)
              docs.sort((a, b) {
                final dateA = _parseDateStr((a['start_date'] ?? '').toString());
                final dateB = _parseDateStr((b['start_date'] ?? '').toString());
                if (dateA != null && dateB != null) {
                  return dateB.compareTo(dateA);
                } else if (dateA != null) {
                  return -1;
                } else if (dateB != null) {
                  return 1;
                }
                return 0;
              });

              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    _selectedFilterDate != null
                        ? 'No records for ${DateFormat('dd MMM yyyy').format(_selectedFilterDate!)}'
                        : 'No records match this filter.',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final item = docs[index];
                  final rowNumber = item['row'];
                  final sheetName =
                      item['sheet_name'] ?? item['labname'] ?? 'L1';
                  final labName = item['labname'] ?? 'N/A';
                  final className = item['classname'] ?? 'N/A';
                  final subjectName = item['subject_name'] ?? 'N/A';
                  final dateStr = item['start_date'] ?? 'N/A';
                  final hours = item['hours']?.toString() ?? '1';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Side Vertical Rectangle Rounded Badge (Theme: Blue, Light Brown & White)
                          Container(
                            width: 84,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2D328C), Color(0xFF1D226A)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFF5B862).withAlpha(140),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1D226A).withAlpha(120),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Light Brown Lab Name Circle
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5B862),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(50),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    labName,
                                    style: const TextStyle(
                                      color: Color(0xFF1D226A),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Date in White & Light Brown Icon
                                const Icon(
                                  Icons.calendar_today,
                                  size: 13,
                                  color: Color(0xFFF5B862),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  dateStr,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Details Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Event / Subject Name (Single line max)
                                Text(
                                  subjectName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Hours badge directly under event name
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFF5B862,
                                    ).withAlpha(40),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFF5B862),
                                    ),
                                  ),
                                  child: Text(
                                    '$hours ${hours == '1' ? 'hr' : 'hrs'}',
                                    style: const TextStyle(
                                      color: Color(0xFFF5B862),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Class Info
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    const Icon(
                                      Icons.school,
                                      size: 16,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    Text(
                                      'Class: $className',
                                      style: const TextStyle(
                                        color: Color(0xFFCBD5E1),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Remove / Delete action
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFFEF4444),
                            ),
                            tooltip: 'Remove Record',
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
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
                                setState(() {
                                  _isLoadingSheet = true;
                                });
                                final webhookUrl =
                                    googleAppsScriptUrl.isNotEmpty
                                    ? googleAppsScriptUrl
                                    : _sheetsWebhookController.text.trim();
                                bool deleteSuccess = false;
                                if (webhookUrl.isNotEmpty) {
                                  final String bookedByValue = (item['user_email'] ?? '').toString();
                                  final String timestampValue = (item['timestamp'] ?? '').toString();
                                  final String subjectValue = (item['subject_name'] ?? '').toString();
                                  final String labValue = (item['labname'] ?? '').toString();
                                  final String classValue = (item['classname'] ?? '').toString();
                                  final String startDateValue = (item['start_date'] ?? '').toString();
                                  final String hoursValue = (item['hours'] ?? '').toString();

                                  final payload = jsonEncode({
                                    'action': 'delete',
                                    'Action': 'delete',
                                    'row': rowNumber,
                                    'row_number': rowNumber,
                                    'rowNumber': rowNumber,
                                    'rowIndex': rowNumber,
                                    'sheet_name': sheetName,
                                    'sheetName': sheetName,
                                    'sheet': sheetName,
                                    'labname': labValue,
                                    'labName': labValue,
                                    'lab': labValue,
                                    'day_allotted': item['day_allotted'] ?? '',
                                    'dayAllotted': item['day_allotted'] ?? '',
                                    'subject': subjectValue,
                                    'Subject': subjectValue,
                                    'subject_name': subjectValue,
                                    'subjectName': subjectValue,
                                    'event': subjectValue,
                                    'classname': classValue,
                                    'className': classValue,
                                    'class': classValue,
                                    'start_date': startDateValue,
                                    'startDate': startDateValue,
                                    'hours': hoursValue,
                                    'user_email': bookedByValue,
                                    'userEmail': bookedByValue,
                                    'email': bookedByValue,
                                    'booked_by': bookedByValue,
                                    'bookedBy': bookedByValue,
                                    'Booked By': bookedByValue,
                                    'BookedBy': bookedByValue,
                                    'timestamp': timestampValue,
                                    'timeStamp': timestampValue,
                                    'Timestamp': timestampValue,
                                    'time_stamp': timestampValue,
                                  });
                                  try {
                                    final String paramSep = webhookUrl.contains('?') ? '&' : '?';
                                    final String deleteUrlWithParams =
                                        '$webhookUrl${paramSep}action=delete'
                                        '&row=$rowNumber'
                                        '&sheet_name=${Uri.encodeComponent(sheetName)}'
                                        '&booked_by=${Uri.encodeComponent(bookedByValue)}'
                                        '&bookedBy=${Uri.encodeComponent(bookedByValue)}'
                                        '&user_email=${Uri.encodeComponent(bookedByValue)}'
                                        '&timestamp=${Uri.encodeComponent(timestampValue)}'
                                        '&subject=${Uri.encodeComponent(subjectValue)}'
                                        '&subject_name=${Uri.encodeComponent(subjectValue)}'
                                        '&labname=${Uri.encodeComponent(labValue)}'
                                        '&classname=${Uri.encodeComponent(classValue)}'
                                        '&start_date=${Uri.encodeComponent(startDateValue)}'
                                        '&hours=${Uri.encodeComponent(hoursValue)}';
                                    debugPrint(
                                      'Sending delete request for row $rowNumber on sheet $sheetName to $deleteUrlWithParams',
                                    );
                                    await sendToGoogleSheets(
                                      deleteUrlWithParams,
                                      payload,
                                    );
                                    deleteSuccess = true;
                                    debugPrint(
                                      'Delete request sent successfully.',
                                    );
                                  } catch (e) {
                                    debugPrint('Google Sheets delete error: $e');
                                  }
                                }
                                if (deleteSuccess) {
                                  setState(() {
                                    _sheetData.removeWhere((element) =>
                                        element['sheet_name'] == sheetName &&
                                        element['row'] == rowNumber);
                                    _isLoadingSheet = false;
                                  });
                                } else {
                                  setState(() {
                                    _isLoadingSheet = false;
                                  });
                                }
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      backgroundColor: deleteSuccess
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                      content: Text(
                                        deleteSuccess
                                            ? 'Record deleted successfully'
                                            : 'Failed to delete record. Please try again.',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
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

class _VoiceListeningWaveAnimation extends StatefulWidget {
  const _VoiceListeningWaveAnimation();

  @override
  State<_VoiceListeningWaveAnimation> createState() =>
      __VoiceListeningWaveAnimationState();
}

class __VoiceListeningWaveAnimationState
    extends State<_VoiceListeningWaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                children: List.generate(4, (index) {
                  final double factor =
                      ((index + 1) * 0.25 + _controller.value) % 1.0;
                  final double height = 8 + factor * 14;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: 4,
                    height: height,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 12),
          const Text(
            'Listening... speak your prompt naturally',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartbeatMicButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;

  const _HeartbeatMicButton({
    required this.isListening,
    required this.onTap,
  });

  @override
  State<_HeartbeatMicButton> createState() => _HeartbeatMicButtonState();
}

class _HeartbeatMicButtonState extends State<_HeartbeatMicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartbeatController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseGlowAnimation;

  @override
  void initState() {
    super.initState();
    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.25), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 1.25, end: 1.05), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 1.05, end: 1.35), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: 1.35, end: 1.0), weight: 45),
    ]).animate(CurvedAnimation(
      parent: _heartbeatController,
      curve: Curves.decelerate,
    ));

    _pulseGlowAnimation = Tween<double>(begin: 4.0, end: 20.0).animate(
      CurvedAnimation(parent: _heartbeatController, curve: Curves.easeInOut),
    );

    if (widget.isListening) {
      _heartbeatController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _HeartbeatMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_heartbeatController.isAnimating) {
      _heartbeatController.repeat();
    } else if (!widget.isListening && _heartbeatController.isAnimating) {
      _heartbeatController.stop();
      _heartbeatController.reset();
    }
  }

  @override
  void dispose() {
    _heartbeatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _heartbeatController,
        builder: (context, child) {
          final scale = widget.isListening ? _scaleAnimation.value : 1.0;
          final glowRadius = widget.isListening ? _pulseGlowAnimation.value : 4.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.isListening
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF6366F1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.isListening
                        ? const Color(0xFFEF4444).withValues(alpha: 0.8)
                        : const Color(0xFF6366F1).withValues(alpha: 0.4),
                    blurRadius: glowRadius,
                    spreadRadius: widget.isListening ? 4 : 1,
                  ),
                ],
              ),
              child: Icon(
                widget.isListening ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 22,
              ),
            ),
          );
        },
      ),
    );
  }
}
