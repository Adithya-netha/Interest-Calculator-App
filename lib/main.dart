// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Reusable compiled regexes to avoid recreating them during formatting.
final RegExp _digitRE = RegExp(r'\d');
final RegExp _nonDigitRE = RegExp(r'[^0-9]');

// Reuse formatter instances to avoid allocating them on every build.
final DateTextInputFormatter dateTextInputFormatter = DateTextInputFormatter();

class DateTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip non-digits using precompiled regex
    final digitsOnly = newValue.text.replaceAll(_nonDigitRE, '');
    final limited = digitsOnly.length <= 8
        ? digitsOnly
        : digitsOnly.substring(0, 8);

    // Build formatted with slashes after 2 and 4 digits
    final buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      buffer.write(limited[i]);
      if (i == 1 || i == 3) buffer.write('/');
    }
    final formatted = buffer.toString();

    // Calculate new caret position by mapping digit count
    int selectionIndex = newValue.selection.end;
    int digitsBefore = 0;
    for (int i = 0; i < selectionIndex && i < newValue.text.length; i++) {
      if (_digitRE.hasMatch(newValue.text[i])) digitsBefore++;
    }

    // Also compute digits before in old value to detect insertion vs deletion
    int oldSelectionIndex = oldValue.selection.end;
    int digitsBeforeOld = 0;
    for (int i = 0; i < oldSelectionIndex && i < oldValue.text.length; i++) {
      if (_digitRE.hasMatch(oldValue.text[i])) digitsBeforeOld++;
    }

    int caret = 0;
    int digitsSeen = 0;
    while (caret < formatted.length && digitsSeen < digitsBefore) {
      if (_digitRE.hasMatch(formatted[caret])) digitsSeen++;
      caret++;
    }

    // If user just inserted a digit (digitsBefore > digitsBeforeOld) and
    // the next char at caret is a slash, advance caret to be after the slash.
    if (digitsBefore > digitsBeforeOld &&
        caret < formatted.length &&
        formatted[caret] == '/') {
      caret++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: caret),
    );
  }
}

void main() {
  runApp(const InterestApp());
}

class InterestApp extends StatelessWidget {
  const InterestApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interest Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        fontFamily: 'Roboto',
      ),
      home: const InterestCalculatorPage(),
    );
  }
}

class InterestCalculatorPage extends StatefulWidget {
  const InterestCalculatorPage({super.key});

  @override
  State<InterestCalculatorPage> createState() => _InterestCalculatorPageState();
}

class _InterestCalculatorPageState extends State<InterestCalculatorPage>
    with SingleTickerProviderStateMixin {
  // Controllers
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _principalController = TextEditingController();
  final _interestController = TextEditingController();

  // (formatting handled by input formatter)

  double? _resultInterest;
  // totalDays removed; storing breakdown in _years/_months/_days
  int? _years;
  int? _months;
  int? _days;
  String? _errorMessage;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim, _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    // use input formatters on the TextFields for auto-slash formatting
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _principalController.dispose();
    _interestController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // Date auto-formatting is handled by the top-level DateTextInputFormatter

  // no-op: slash counting removed (formatter handles positions)

  // parse dd/mm/yyyy with simple checks
  List<int>? _parseDMY(String s) {
    final parts = s.split('/');
    if (parts.length != 3) return null;
    try {
      final d = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final y = int.parse(parts[2]);
      if (d < 1 || d > 31) return null;
      if (m < 1 || m > 12) return null;
      if (y < 1) return null;
      return [d, m, y];
    } catch (_) {
      return null;
    }
  }

  void _setError(String? msg) {
    setState(() => _errorMessage = msg);
    if (msg != null) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _errorMessage = null);
      });
    }
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    _setError(null);

    final fromText = _fromController.text.trim();
    final toText = _toController.text.trim();

    if (fromText.isEmpty || toText.isEmpty) {
      _setError('Enter both From and To dates (dd/mm/yyyy).');
      return;
    }

    final fromParts = _parseDMY(fromText);
    final toParts = _parseDMY(toText);
    if (fromParts == null || toParts == null) {
      _setError('Dates must be valid and in dd/mm/yyyy format.');
      return;
    }

    final principal = int.tryParse(_principalController.text.trim());
    if (principal == null || principal < 0) {
      _setError('Enter a valid principal amount (money ₹).');
      return;
    }

    final interest = double.tryParse(_interestController.text.trim());
    if (interest == null || interest < 0) {
      _setError('Enter a valid interest  (e.g., 1.5).');
      return;
    }

    // Use your calculation logic: days = abs(day diff), months = abs(month diff)*30, years=abs(year diff)*360
    final fromDay = fromParts[0],
        fromMonth = fromParts[1],
        fromYear = fromParts[2];
    final toDay = toParts[0], toMonth = toParts[1], toYear = toParts[2];

    final dayDiff = (fromDay - toDay).abs();
    final monthDiff = (fromMonth - toMonth).abs();
    final yearDiff = (fromYear - toYear).abs();

    final totalDays = dayDiff + (monthDiff * 30) + (yearDiff * 360);

    // Decompose totalDays into years, months, days using 360/30 rule
    int remaining = totalDays;
    final calcYears = remaining ~/ 360;
    remaining = remaining % 360;
    final calcMonths = remaining ~/ 30;
    final calcDays = remaining % 30;

    final computed = ((principal * interest * (totalDays / 30.0)) / 100.0)
        .roundToDouble();

    setState(() {
      // _totalDays = totalDays; // replaced by breakdown
      _years = calcYears;
      _months = calcMonths;
      _days = calcDays;
      _resultInterest = computed;
    });

    _animController.forward(from: 0);
  }

  Widget _inputField({
    required String hint,
    required TextEditingController controller,
    Widget? prefix,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    // Make date fields lighter by checking the hint
    final isDateField = hint == 'dd/mm/yyyy';
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color.fromARGB(
            255,
            181,
            181,
            181,
          ), // even lighter gray for all fields
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: prefix,
        filled: true,
        fillColor: isDateField
            ? Color.fromARGB(255, 255, 255, 255)
            : const Color.fromARGB(255, 255, 255, 255),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gap = const SizedBox(height: 14);

    // Soft gradient using requested colors blue -> violet -> pink
    final headerGradient = LinearGradient(
      colors: [
        Colors.blue.shade600,
        Colors.deepPurple.shade600,
        Colors.pink.shade400,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            // Top center credit (bigger)
            Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 12),
              child: Text(
                'made by Adithya',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.deepPurple.shade700,
                ),
              ),
            ),

            // subtle header bar with gradient accent (clean & modern)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              height: 78,
              decoration: BoxDecoration(
                gradient: headerGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(blurRadius: 10, offset: const Offset(0, 6)),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                  const Center(
                    child: Text(
                      'Interest Calculator',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    // Input card (clean)
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Two date fields with "TO" between them
                            Row(
                              children: [
                                Expanded(
                                  child: _inputField(
                                    hint: 'dd/mm/yyyy',
                                    controller: _fromController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                      dateTextInputFormatter,
                                    ],
                                  ),
                                ),

                                // TO label
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'TO',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),

                                Expanded(
                                  child: _inputField(
                                    hint: 'dd/mm/yyyy',
                                    controller: _toController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                      dateTextInputFormatter,
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            gap,

                            // Principal and interest row
                            Row(
                              children: [
                                Expanded(
                                  child: _inputField(
                                    hint: 'Amount',
                                    controller: _principalController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    prefix: const Padding(
                                      padding: EdgeInsets.only(
                                        left: 12,
                                        right: 8,
                                      ),
                                      child: Text(
                                        '₹',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _inputField(
                                    hint: 'Interest',
                                    controller: _interestController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,6}'),
                                      ),
                                    ],
                                    prefix: const Padding(
                                      padding: EdgeInsets.only(
                                        left: 12,
                                        right: 8,
                                      ),
                                      child: Icon(Icons.percent, size: 18),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            gap,

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _calculate,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: Colors.deepPurple.shade700,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                ),
                                child: const Text(
                                  'Calculate',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),

                            if (_errorMessage != null) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Result card / placeholder
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: _resultInterest == null
                            ? Container(
                                padding: const EdgeInsets.all(18),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Ready to calculate',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Type both dates as dd/mm/yyyy, fill Amount and interest %, then press Calculate.',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  ],
                                ),
                              )
                            : Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            'Result',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              color: Colors.green.shade50,
                                            ),
                                            child: Text(
                                              'Years: ${_years ?? 0}  Months: ${_months ?? 0}  Days: ${_days ?? 0}',
                                              style: const TextStyle(
                                                color: Colors.green,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'From: ${_fromController.text}  →  To: ${_toController.text}',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'Total interest',
                                            style: TextStyle(
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '₹',
                                            style: TextStyle(
                                              fontSize: 20,
                                              color: Colors.deepPurple.shade700,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _resultInterest!.toStringAsFixed(0),
                                            style: const TextStyle(
                                              fontSize: 30,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              final text =
                                                  'Total interest: ₹${_resultInterest!.toStringAsFixed(0)} '
                                                  'from ${_fromController.text} to ${_toController.text}';
                                              Clipboard.setData(
                                                ClipboardData(text: text),
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Result copied',
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.copy),
                                            label: const Text('Copy'),
                                            style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _resultInterest = null;
                                                _years = null;
                                                _months = null;
                                                _days = null;
                                              });
                                            },
                                            icon: const Icon(Icons.refresh),
                                            label: const Text('Reset'),
                                            style: OutlinedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Note
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Note: Enter dates exactly as "dd/mm/yyyy" format.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
