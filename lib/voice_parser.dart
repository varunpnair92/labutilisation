class ParsedBooking {
  final List<String> labs;
  final String? labName;
  final String? className;
  final String? subjectName;
  final DateTime? date;
  final String? hours;

  ParsedBooking({
    List<String>? labs,
    String? labName,
    this.className,
    this.subjectName,
    this.date,
    this.hours,
  })  : labs = labs ?? (labName != null ? [labName] : []),
        labName = labName ?? (labs != null && labs.isNotEmpty ? labs.first : null);

  bool get isEmpty =>
      labs.isEmpty &&
      labName == null &&
      className == null &&
      (subjectName == null || subjectName!.isEmpty) &&
      date == null &&
      hours == null;

  @override
  String toString() {
    return 'ParsedBooking(labs: $labs, className: $className, subjectName: $subjectName, date: $date, hours: $hours)';
  }
}

class VoicePromptParser {
  static const List<String> availableLabs = [
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

  static const List<String> targetClasses = [
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

  static final Map<String, int> _months = {
    'jan': 1, 'january': 1,
    'feb': 2, 'february': 2,
    'mar': 3, 'march': 3,
    'apr': 4, 'april': 4,
    'may': 5,
    'jun': 6, 'june': 6,
    'jul': 7, 'july': 7,
    'aug': 8, 'august': 8,
    'sep': 9, 'september': 9,
    'oct': 10, 'october': 10,
    'nov': 11, 'november': 11,
    'dec': 12, 'december': 12,
  };

  static final Map<String, String> _numberWords = {
    '1': '1', 'one': '1',
    '2': '2', 'two': '2',
    '3': '3', 'three': '3',
    '4': '4', 'four': '4',
    '5': '5', 'five': '5',
    '6': '6', 'six': '6',
    '7': '7', 'seven': '7',
    '8': '8', 'eight': '8',
    '9': '9', 'nine': '9',
    '10': '10', 'ten': '10',
  };

  static final Map<String, int> _dayWords = {
    'first': 1, '1st': 1,
    'second': 2, '2nd': 2,
    'third': 3, '3rd': 3,
    'fourth': 4, '4th': 4,
    'fifth': 5, '5th': 5,
    'sixth': 6, '6th': 6,
    'seventh': 7, '7th': 7,
    'eighth': 8, '8th': 8,
    'ninth': 9, '9th': 9,
    'tenth': 10, '10th': 10,
    'eleventh': 11, '11th': 11,
    'twelfth': 12, '12th': 12,
    'thirteenth': 13, '13th': 13,
    'fourteenth': 14, '14th': 14,
    'fifteenth': 15, '15th': 15,
    'sixteenth': 16, '16th': 16,
    'seventeenth': 17, '17th': 17,
    'eighteenth': 18, '18th': 18,
    'nineteenth': 19, '19th': 19,
    'twentieth': 20, '20th': 20,
    'twenty first': 21, '21st': 21,
    'twenty second': 22, '22nd': 22,
    'twenty third': 23, '23rd': 23,
    'twenty fourth': 24, '24th': 24,
    'twenty fifth': 25, '25th': 25,
    'twenty sixth': 26, '26th': 26,
    'twenty seventh': 27, '27th': 27,
    'twenty eighth': 28, '28th': 28,
    'twenty ninth': 29, '29th': 29,
    'thirtieth': 30, '30th': 30,
    'thirty first': 31, '31st': 31,
  };

  /// Parses multiple natural language or WhatsApp pasted bookings into a list.
  static List<ParsedBooking> parseMultiple(String text) {
    if (text.trim().isEmpty) return [];

    // Header regex for WhatsApp messages: [06/08, 2:34 pm] Sender Name:
    final headerRegex = RegExp(
      r'\[\d{1,2}/\d{1,2}(?:/\d{2,4})?,\s*\d{1,2}:\d{2}(?:\u202f|\s)*(?:am|pm|AM|PM)?\][^:\n]*:',
    );

    List<String> blocks = [];
    final matches = headerRegex.allMatches(text).toList();
    if (matches.length > 1) {
      for (int i = 0; i < matches.length; i++) {
        int start = matches[i].end;
        int end = (i + 1 < matches.length) ? matches[i + 1].start : text.length;
        String chunk = text.substring(start, end).trim();
        if (chunk.isNotEmpty) {
          blocks.add(chunk);
        }
      }
    } else {
      // Split by double newlines or date lines
      final splitBlocks = text.split(RegExp(r'\n\s*\n'));
      for (var b in splitBlocks) {
        if (b.trim().isNotEmpty) {
          blocks.add(b.trim());
        }
      }
    }

    if (blocks.isEmpty) {
      blocks.add(text);
    }

    List<ParsedBooking> results = [];
    for (var b in blocks) {
      final parsed = parse(b);
      if (!parsed.isEmpty) {
        results.add(parsed);
      }
    }

    return results;
  }

  /// Parses natural language spoken or pasted prompts in any order.
  static ParsedBooking parse(String text) {
    if (text.trim().isEmpty) return ParsedBooking();

    // Clean WhatsApp header prefix if present: [06/08, 2:34 pm] Name:
    String workingText = text.replaceAll(
      RegExp(
        r'^\[\d{1,2}/\d{1,2}(?:/\d{2,4})?,\s*\d{1,2}:\d{2}(?:\u202f|\s)*(?:am|pm|AM|PM)?\][^:\n]*:',
      ),
      '',
    ).toLowerCase();

    // Comprehensive STT Phonetic & Letter Spacing Normalizations
    workingText = workingText
        .replaceAll('sycsa', 's5 csa')
        .replaceAll('sy csa', 's5 csa')
        .replaceAll('sy cs a', 's5 csa')
        .replaceAll('sycsb', 's5 csb')
        .replaceAll('sy cse', 's5 cse')
        .replaceAll('sy mca', 's5 mca')
        .replaceAll('symca', 's5 mca')
        .replaceAll(RegExp(r'\bc\s+s\s+a\b'), 'csa')
        .replaceAll(RegExp(r'\bc\s+s\s+b\b'), 'csb')
        .replaceAll(RegExp(r'\bc\s+s\s+c\b'), 'csc')
        .replaceAll(RegExp(r'\bc\s+s\s+d\b'), 'csd')
        .replaceAll(RegExp(r'\bm\s+c\s+a\b'), 'mca')
        .replaceAll(RegExp(r'\bl\s+([1-9])\b'), r'l$1')
        .replaceAll(RegExp(r'\blab\s+l\s*([1-9])\b'), r'lab l$1');

    List<String> matchedLabs = [];
    String? matchedClass;
    DateTime? matchedDate;
    String? matchedHours;
    String? matchedSubject;

    // 0. EXPLICIT SUBJECT / EVENT PREFIX PARSING
    final eventPrefixReg = RegExp(
      r'\b(?:event\s*/\s*subject|event|subject)\s+(?:is\s*)?([a-z0-9\s]+?)(?=\b(?:lab|class|branch|date|hours?|hrs?)\b|$)',
    );
    final eventMatch = eventPrefixReg.firstMatch(workingText);
    if (eventMatch != null) {
      final rawSubj = eventMatch.group(1)!.trim();
      if (rawSubj.isNotEmpty) {
        matchedSubject = rawSubj;
        workingText = workingText.replaceRange(
          eventMatch.start,
          eventMatch.end,
          ' ',
        );
      }
    }

    // 1. EXTRACT MULTI LAB NAMES
    final rangeReg = RegExp(
      r'\b(?:lab|l)\s*([1-9])\s*(?:to|-|till)\s*(?:lab|l)?\s*([1-9])\b',
      caseSensitive: false,
    );
    final rangeMatch = rangeReg.firstMatch(workingText);
    if (rangeMatch != null) {
      int start = int.parse(rangeMatch.group(1)!);
      int end = int.parse(rangeMatch.group(2)!);
      if (start <= end) {
        for (int i = start; i <= end; i++) {
          matchedLabs.add('L$i');
        }
        workingText = workingText.replaceRange(
          rangeMatch.start,
          rangeMatch.end,
          ' ',
        );
      }
    } else {
      final allLabsReg = RegExp(
        r'\b(l\s*[1-9]|pg\s*lab|pglab|mp\s*lab|mplab|microprocessor\s*lab|pg|mp)\b',
        caseSensitive: false,
      );
      final matches = allLabsReg.allMatches(workingText).toList();
      for (final m in matches) {
        String token = m.group(0)!.toLowerCase().replaceAll(' ', '');
        String norm = 'L1';
        if (token.startsWith('l') && token.length == 2) {
          norm = 'L${token[1]}';
        } else if (token.contains('pg')) {
          norm = 'pglab';
        } else if (token.contains('mp') || token.contains('micro')) {
          norm = 'MP lab';
        }
        if (!matchedLabs.contains(norm)) {
          matchedLabs.add(norm);
        }
      }
      if (matches.isNotEmpty) {
        workingText = workingText.replaceAll(allLabsReg, ' ');
      }
    }

    // 2. EXTRACT HOURS / TIME RANGES
    final timeRangeReg = RegExp(
      r'\(?\s*(\d{1,2}(?:\.\d{2})?)\s*(?:to|-|till)\s*(\d{1,2}(?:\.\d{2})?)\s*\)?',
      caseSensitive: false,
    );
    final timeMatch = timeRangeReg.firstMatch(workingText);
    if (timeMatch != null) {
      matchedHours = '${timeMatch.group(1)} to ${timeMatch.group(2)}';
      workingText = workingText.replaceRange(
        timeMatch.start,
        timeMatch.end,
        ' ',
      );
    } else {
      final hoursReg = RegExp(
        r'\b(?:hours?|hrs?)\s*[:=]?\s*([\d\s,]+)\b|\b([\d\s,]+)\s*(?:hours?|hrs?)\b',
      );
      final hoursMatch = hoursReg.firstMatch(workingText);
      if (hoursMatch != null) {
        final rawNums = (hoursMatch.group(1) ?? hoursMatch.group(2))!.trim();
        final numMatches = RegExp(r'\d+')
            .allMatches(rawNums)
            .map((m) => m.group(0)!)
            .where((n) {
              final val = int.tryParse(n);
              return val != null && val >= 1 && val <= 10;
            })
            .toList();
        if (numMatches.isNotEmpty) {
          matchedHours = numMatches.join(',');
          workingText = workingText.replaceRange(
            hoursMatch.start,
            hoursMatch.end,
            ' ',
          );
        }
      }
    }

    // 3. EXTRACT DATE (Unified date matcher)
    final dateResult = _extractDateAndRange(workingText);
    if (dateResult != null) {
      matchedDate = dateResult.date;
      workingText = workingText.replaceRange(
        dateResult.startIndex,
        dateResult.endIndex,
        ' ',
      );
    }

    // 4. EXTRACT CLASS NAME (with Levenshtein Fuzzy Matching >= 50%)
    final classResult = _extractClassWithFuzzy(workingText);
    if (classResult != null) {
      matchedClass = classResult.className;
      workingText = workingText.replaceRange(
        classResult.startIndex,
        classResult.endIndex,
        ' ',
      );
    }

    // 5. CLEAN REMAINING TEXT FOR SUBJECT / EVENT NAME
    if (matchedSubject == null) {
      final stopWords = {
        'book',
        'booking',
        'for',
        'lab',
        'on',
        'at',
        'the',
        'in',
        'a',
        'an',
        'slot',
        'utilization',
        'please',
        'schedule',
        'reserve',
        'need',
        'want',
        'hour',
        'hours',
        'hrs',
        'class',
        'is',
        'batch',
        'event',
        'subject',
        'date',
      };

      final words = workingText.split(RegExp(r'\s+'));
      final filteredWords = words.where((w) {
        final clean = w.replaceAll(RegExp(r'[^\w]'), '');
        return clean.isNotEmpty && !stopWords.contains(clean);
      }).toList();

      if (filteredWords.isNotEmpty) {
        matchedSubject = filteredWords.join(' ');
      }
    }

    return ParsedBooking(
      labs: matchedLabs,
      className: matchedClass,
      subjectName: matchedSubject,
      date: matchedDate,
      hours: matchedHours,
    );
  }

  static _DateMatchResult? _extractDateAndRange(String text) {
    final now = DateTime.now();

    final tomMatch = RegExp(r'\btomorrow\b').firstMatch(text);
    if (tomMatch != null) {
      return _DateMatchResult(
        date: now.add(const Duration(days: 1)),
        startIndex: tomMatch.start,
        endIndex: tomMatch.end,
      );
    }

    final todayMatch = RegExp(r'\btoday\b').firstMatch(text);
    if (todayMatch != null) {
      return _DateMatchResult(
        date: now,
        startIndex: todayMatch.start,
        endIndex: todayMatch.end,
      );
    }

    for (final entry in _dayWords.entries) {
      final pattern = RegExp(
        r'\b(?:(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(?:of\s+)?' +
            RegExp.escape(entry.key) +
            r'|' +
            RegExp.escape(entry.key) +
            r'\s+(?:of\s+)?(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec))\b',
      );
      final match = pattern.firstMatch(text);
      if (match != null) {
        String monthStr = (match.group(1) ?? match.group(2))!;
        int day = entry.value;
        int month = _months[monthStr] ?? now.month;

        int year = now.year;
        DateTime testDate = DateTime(year, month, day);
        if (testDate.isBefore(now.subtract(const Duration(days: 30)))) {
          year++;
        }
        return _DateMatchResult(
          date: DateTime(year, month, day),
          startIndex: match.start,
          endIndex: match.end,
        );
      }
    }

    final monthDayReg = RegExp(
      r'\b(?:date\s+)?(?:(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s*(\d{1,2})(?:st|nd|rd|th)?|(\d{1,2})(?:st|nd|rd|th)?\s*(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec))\b',
    );
    final dateMatch = monthDayReg.firstMatch(text);
    if (dateMatch != null) {
      String monthStr = (dateMatch.group(1) ?? dateMatch.group(4))!;
      int day = int.parse((dateMatch.group(2) ?? dateMatch.group(3))!);
      int month = _months[monthStr] ?? now.month;

      int year = now.year;
      DateTime testDate = DateTime(year, month, day);
      if (testDate.isBefore(now.subtract(const Duration(days: 30)))) {
        year++;
      }
      return _DateMatchResult(
        date: DateTime(year, month, day),
        startIndex: dateMatch.start,
        endIndex: dateMatch.end,
      );
    }

    final numDateReg = RegExp(
      r'\b(\d{4})[-/](\d{1,2})[-/](\d{1,2})\b|\b(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})\b',
    );
    final numMatch = numDateReg.firstMatch(text);
    if (numMatch != null) {
      DateTime dt;
      if (numMatch.group(1) != null) {
        dt = DateTime(
          int.parse(numMatch.group(1)!),
          int.parse(numMatch.group(2)!),
          int.parse(numMatch.group(3)!),
        );
      } else {
        int year = int.parse(numMatch.group(6)!);
        if (year < 100) year += 2000;
        dt = DateTime(
          year,
          int.parse(numMatch.group(5)!),
          int.parse(numMatch.group(4)!),
        );
      }
      return _DateMatchResult(
        date: dt,
        startIndex: numMatch.start,
        endIndex: numMatch.end,
      );
    }

    return null;
  }

  /// Extracts class name using exact regex followed by Fuzzy Matching (Levenshtein Similarity >= 50%)
  static _ClassMatchResult? _extractClassWithFuzzy(String text) {
    String clean = text.toLowerCase();

    // 1. Direct Regex Matchers
    final classReg = RegExp(
      r'\b(?:class\s*(?:is\s*)?)?(?:s\s*|semester\s*|sem\s*)?([1-8]|one|two|three|four|five|six|seven|eight)\s*(?:st|nd|rd|th)?\s*(?:sem\s*|semester\s*)?\s*([a-z0-9]+)\b|\b(?:imca|integrated\s*mca)\s*(?:s\s*)?([1-9]|10|one|two|three|four|five|six|seven|eight|nine|ten)\b|\b(?:s\s*)?([1-8]|one|two|three|four|five|six|seven|eight)\s*mca\b|\bmca\s*(?:s\s*)?([1-8]|one|two|three|four|five|six|seven|eight)?\b',
    );
    final match = classReg.firstMatch(clean);
    if (match != null) {
      if (match.group(1) != null && match.group(2) != null) {
        final semStr = match.group(1)!;
        final semDigit = _numberWords[semStr] ?? semStr;
        final branch = match.group(2)!.toUpperCase();
        final candidate = 'S$semDigit $branch';
        final bestFuzzy = _findBestFuzzyMatch(candidate);
        return _ClassMatchResult(
          className: bestFuzzy ?? candidate,
          startIndex: match.start,
          endIndex: match.end,
        );
      } else if (match.group(3) != null) {
        final numStr = match.group(3)!;
        final digit = _numberWords[numStr] ?? numStr;
        return _ClassMatchResult(
          className: 'IMCA $digit',
          startIndex: match.start,
          endIndex: match.end,
        );
      } else if (match.group(4) != null) {
        final numStr = match.group(4)!;
        final digit = _numberWords[numStr] ?? numStr;
        return _ClassMatchResult(
          className: 'S$digit MCA',
          startIndex: match.start,
          endIndex: match.end,
        );
      } else if (match.group(5) != null) {
        final numStr = match.group(5)!;
        final digit = _numberWords[numStr] ?? numStr;
        return _ClassMatchResult(
          className: 'S$digit MCA',
          startIndex: match.start,
          endIndex: match.end,
        );
      }
    }

    // 2. Fuzzy Token Scanning (>= 50% similarity threshold)
    final tokens = clean.split(RegExp(r'\s+'));
    for (int len = 3; len >= 1; len--) {
      for (int i = 0; i <= tokens.length - len; i++) {
        final phrase = tokens.sublist(i, i + len).join(' ');
        final matchedClass = _findBestFuzzyMatch(phrase);
        if (matchedClass != null) {
          final start = clean.indexOf(phrase);
          return _ClassMatchResult(
            className: matchedClass,
            startIndex: start,
            endIndex: start + phrase.length,
          );
        }
      }
    }

    return null;
  }

  /// Calculates Levenshtein Similarity (0.0 to 1.0) and picks best matching class if similarity >= 0.50 (50%)
  static String? _findBestFuzzyMatch(String candidate) {
    final candClean = candidate.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (candClean.length < 2) return null;

    String? bestClass;
    double highestScore = 0.0;

    for (final target in targetClasses) {
      final targClean = target.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      double score = _calculateSimilarity(candClean, targClean);
      if (score > highestScore) {
        highestScore = score;
        bestClass = target;
      }
    }

    if (highestScore >= 0.50) {
      return bestClass;
    }
    return null;
  }

  static double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.contains(s2) || s2.contains(s1)) return 0.85;

    int distance = _levenshteinDistance(s1, s2);
    int maxLen = s1.length > s2.length ? s1.length : s2.length;
    if (maxLen == 0) return 1.0;
    return 1.0 - (distance / maxLen);
  }

  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = s1[i] == s2[j] ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }
}

class _DateMatchResult {
  final DateTime date;
  final int startIndex;
  final int endIndex;

  _DateMatchResult({
    required this.date,
    required this.startIndex,
    required this.endIndex,
  });
}

class _ClassMatchResult {
  final String className;
  final int startIndex;
  final int endIndex;

  _ClassMatchResult({
    required this.className,
    required this.startIndex,
    required this.endIndex,
  });
}
