class ActionableFilterResult {
  final bool keyword;
  final bool date;
  final bool relativeDate;
  final bool amountRef;
  final bool senderBiller;
  final bool govt;
  final bool meeting;
  final bool isExcluded; // OTP / promo
  final bool isCandidate;

  ActionableFilterResult({
    required this.keyword,
    required this.date,
    required this.relativeDate,
    required this.amountRef,
    required this.senderBiller,
    required this.govt,
    required this.meeting,
    required this.isExcluded,
  }) : isCandidate = !isExcluded &&
      (keyword ||
          date ||
          relativeDate ||
          amountRef ||
          senderBiller ||
          govt ||
          meeting);

  @override
  String toString() =>
      'candidate=$isCandidate (excluded=$isExcluded, keyword=$keyword, date=$date, '
          'relativeDate=$relativeDate, amountRef=$amountRef, sender=$senderBiller, '
          'govt=$govt, meeting=$meeting)';
}

class ActionableFilter {
  // --- Category 1: Actionable keywords ---
  static final RegExp actionKeywords = RegExp(
    r'\b('
    r'due|overdue|pending|payment|pay ?now|bill|invoice|recharge|'
    r'renew(al)?|expir(e|y|ing)|reminder|appointment|scheduled|'
    r'meeting|deadline|last ?date|submit|apply ?by|book(ed)?|'
    r'confirm(ed|ation)?|kyc|premium|emi|installment|subscription|'
    r'maturity|e-?challan|fine|penalty'
    r')\b',
    caseSensitive: false,
  );

  // --- Category 2: Date / deadline patterns (absolute) ---
  static final RegExp datePatterns = RegExp(
    r'(\b\d{1,2}[-/]\d{1,2}[-/]\d{2,4}\b)|'
    r'(\b\d{1,2}(st|nd|rd|th)?\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\b)|'
    r'(\bby\s+\d{1,2}[-/]?\d{0,4}\b)|'
    r'(\b\d{1,2}\s?(am|pm)\b)',
    caseSensitive: false,
  );

  // --- Category 2b: Relative date words ---
  static final RegExp relativeDatePatterns = RegExp(
    r'\b(today|tomorrow|tonight|next (week|month)|in \d+ days?)\b',
    caseSensitive: false,
  );

  // --- Category 3: Amount / reference number patterns ---
  static final RegExp amountRefPatterns = RegExp(
    r'(₹\s?[\d,]+(\.\d+)?)|'
    r'(rs\.?\s?[\d,]+(\.\d+)?)|'
    r'(inr\s?[\d,]+)|'
    r'(\b(a/c|acc(ount)?|ref|txn|order)\s?(no\.?|#)?\s?[:\-]?\s?\w+\b)',
    caseSensitive: false,
  );

  // --- Category 4: Sender-based hints (DLT-registered biller SMS senders) ---
  static final RegExp billerSender = RegExp(r'^[A-Z]{2}-[A-Z]{4,10}$');

  // --- Category 5: Government / document-related keywords ---
  static final RegExp govtKeywords = RegExp(
    r'\b(aadhaar|pan card|passport|digilocker|voter id|e-?challan|court notice|'
    r'income tax|itr|gst|epfo|pf withdrawal|dl renewal|rc renewal)\b',
    caseSensitive: false,
  );

  // --- Category 6: Meeting-specific patterns (video call links) ---
  static final RegExp meetingLinks = RegExp(
    r'(meet\.google\.com|zoom\.us/j|teams\.microsoft\.com|calendly\.com)',
    caseSensitive: false,
  );

  // --- Negative filters: exclude OTPs and promos ---
  static final RegExp otpPattern = RegExp(
    r'\b(otp|one.?time.?password|verification code|do not share)\b',
    caseSensitive: false,
  );

  static final RegExp promoPattern = RegExp(
    r'\b(discount|sale|cashback|win|lottery|congratulations|limited time)\b',
    caseSensitive: false,
  );

  static ActionableFilterResult check(String text, {String sender = ''}) {
    final excluded = otpPattern.hasMatch(text) || promoPattern.hasMatch(text);

    return ActionableFilterResult(
      keyword: actionKeywords.hasMatch(text),
      date: datePatterns.hasMatch(text),
      relativeDate: relativeDatePatterns.hasMatch(text),
      amountRef: amountRefPatterns.hasMatch(text),
      senderBiller: sender.isNotEmpty ? billerSender.hasMatch(sender) : false,
      govt: govtKeywords.hasMatch(text),
      meeting: meetingLinks.hasMatch(text),
      isExcluded: excluded,
    );
  }
}