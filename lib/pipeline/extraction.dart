
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Structured record produced by the extraction step.
class ExtractedRecord {
  final String type;
  final String? billerOrSender;
  final double? amount;
  final String? currency;
  final String? dueDate;
  final String? accountRef;

  // NEW
  final List<String>? links;

  final String rawSnippet;
  final double confidence;

  ExtractedRecord({
    required this.type,
    this.billerOrSender,
    this.amount,
    this.currency,
    this.dueDate,
    this.accountRef,
    this.links,
    required this.rawSnippet,
    required this.confidence,
  });

  factory ExtractedRecord.fromJson(Map<String, dynamic> json) {
    return ExtractedRecord(
      type: json['type'] as String? ?? 'other',
      billerOrSender: json['biller_or_sender'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      dueDate: json['due_date'] as String?,
      accountRef: json['account_ref'] as String?,

      links: (json['links'] as List?)
          ?.map((e) => e.toString())
          .toList(),

      rawSnippet: json['raw_snippet'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'biller_or_sender': billerOrSender,
    'amount': amount,
    'currency': currency,
    'due_date': dueDate,
    'account_ref': accountRef,

    'links': links,

    'raw_snippet': rawSnippet,
    'confidence': confidence,
  };
}

/// Thrown when the model output couldn't be parsed as valid JSON matching
/// the expected schema. Callers should log these separately to build an
/// eval set from real failures instead of silently dropping them.
class ExtractionParseException implements Exception {
  final String message;
  final String rawResponse;
  ExtractionParseException(this.message, this.rawResponse);

  @override
  String toString() => 'ExtractionParseException: $message';
}

class ExtractionService {
  final String apiKey = "";
  final String model;
  final http.Client _client;

  ExtractionService({
    this.model = 'gemini-3.5-flash',
    http.Client? client,
  }) : _client = client ?? http.Client();

  static const _systemInstruction = '''
You are a structured-data extraction engine for an Indian personal life-admin
assistant. You will be given a SMS or email. Extract actionable financial
or scheduling information into JSON matching the schema exactly.

Rules:
- Output ONLY valid JSON. No markdown fences, no prose, no preamble.
- If a field cannot be determined confidently, use null. Never invent values.
- "type" must be one of the following. Use "other" only when nothing else fits:
  - bill              (utility, mobile/DTH recharge, credit card statement due)
  - renewal           (insurance, domain, subscription, warranty, AMC)
  - appointment        (doctor, salon, service technician visit, interview)
  - govt_notice        (tax deadline, passport/Aadhaar/PAN update, court notice, GST filing)
  - emi_loan           (loan/EMI due date, credit card minimum due)
  - subscription       (OTT, SaaS, gym membership, recurring auto-debit)
  - delivery           (parcel/order arriving, delivery attempt failed, OTP for delivery)
  - travel_booking     (flight/train/bus ticket, hotel booking, PNR/ticket confirmation)
  - exam_result        (exam admit card, result declared, registration deadline)
  - medical            (lab report ready, prescription refill reminder, vaccination due)
  - kyc_verification   (bank/mutual fund/demat KYC update required)
  - other
- Dates must be normalized to ISO 8601 (YYYY-MM-DD). Indian SMS often uses
  DD/MM/YYYY or DD-MM-YY -- convert carefully, do not assume US MM/DD order.
- A "Reference date" will be provided representing when the message was
  received. Use it to resolve any relative date language in the message
  ("tomorrow", "day after tomorrow", "next Monday", "in 3 days", "this
  weekend", "by EOD", "within 48 hours").
- Compute the resolved date yourself and output it as an absolute ISO 8601
  date in "due_date". Do not output the relative phrase itself.
- If the relative expression is genuinely ambiguous (e.g. "next Friday"
  sent on a Friday could mean today or in 7 days), resolve to the nearer
  future date and lower "confidence" accordingly rather than returning null.
- If there is truly no date or time reference of any kind (relative or
  absolute) in the message, only then return null for "due_date".
- "amount" is a plain number (no currency symbols, no commas).
- "confidence" is your own estimate (0.0-1.0) of extraction correctness.
- "raw_snippet" should be the short portion of the original text that
  justifies the extraction (not the entire message).
- Extract every URL present in the message into "links".
- Include shortened URLs (bit.ly, tinyurl, t.ly, etc.), payment links,
tracking links, meeting links, Google Forms, websites, and app links.
- If no URL exists, return an empty array.
- Do not modify or normalize URLs.
''';

  static const _jsonSchema = {
    "type": "OBJECT",
    "properties": {
      "type": {
        "type": "STRING",
        "enum": [
          "bill",
          "renewal",
          "appointment",
          "govt_notice",
          "emi_loan",
          "subscription",
          "delivery",
          "travel_booking",
          "exam_result",
          "medical",
          "kyc_verification",
          "other"
        ]
      },
      "biller_or_sender": {
        "type": "STRING",
        "nullable": true
      },
      "amount": {
        "type": "NUMBER",
        "nullable": true
      },
      "currency": {
        "type": "STRING",
        "nullable": true
      },
      "due_date": {
        "type": "STRING",
        "nullable": true
      },
      "account_ref": {
        "type": "STRING",
        "nullable": true
      },

      "links": {
        "type": "ARRAY",
        "items": {
          "type": "STRING"
        }
      },

      "raw_snippet": {
        "type": "STRING"
      },
      "confidence": {
        "type": "NUMBER"
      }
    },
    "required": [
      "type",
      "links",
      "raw_snippet",
      "confidence"
    ]
  };

  /// Extracts a structured record from a single raw message.
  ///
  /// [rawText] is the SMS/email body. [source] is a free-form tag like
  /// 'sms' or 'email', included for logging/debugging only.
  Future<ExtractedRecord> extract({
    required String rawText,
    String source = 'sms',
    DateTime? receivedAt, // NEW: when the SMS/email actually arrived
  }) async {
    final referenceDate = receivedAt ?? DateTime.now();
    final referenceDateStr = referenceDate.toIso8601String().split('T')[0];
    final weekday = _weekdayName(referenceDate.weekday);
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final body = {
      "system_instruction": {
        "parts": [
          {"text": _systemInstruction}
        ]
      },
      "contents": [
        {
          "role": "user",
          "parts": [{
            "text": "Reference date (when this message was received): $referenceDateStr ($weekday)\n\n"
                "Source: $source\n\nMessage:\n$rawText"
          }]
        }
      ],
      "generationConfig": {
        "temperature": 0.1,
        "responseMimeType": "application/json",
        "responseSchema": _jsonSchema,
      }
    };

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw ExtractionParseException(
        'API returned status ${response.statusCode}',
        response.body,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    try {
      final candidates = decoded['candidates'] as List<dynamic>;
      final content = candidates[0]['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List<dynamic>;
      final text = parts[0]['text'] as String;

      final parsedJson = jsonDecode(text) as Map<String, dynamic>;
      final record = ExtractedRecord.fromJson(parsedJson);

      // Guard rail: raw_snippet should never be empty for a real extraction.
      if (record.rawSnippet.trim().isEmpty) {
        throw ExtractionParseException(
          'Model returned empty raw_snippet',
          response.body,
        );
      }

      return record;
    } catch (e) {
      throw ExtractionParseException(
        'Failed to parse model output: $e',
        response.body,
      );
    }
  }

  void dispose() => _client.close();
}

class BatchExtractionResult {
  final List<ExtractedRecord> successes;
  final Map<String, String> failures; // raw message -> error reason

  BatchExtractionResult({required this.successes, required this.failures});

  @override
  String toString() =>
      'Extracted ${successes.length} record(s), ${failures.length} failure(s)';
}

String _weekdayName(int weekday) {
  const names = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
  return names[weekday - 1];
}
