import 'dart:convert';
import 'package:http/http.dart' as http;

class ActionabilityResult {
  final bool actionable;
  final double confidence;
  final String reason;

  ActionabilityResult({
    required this.actionable,
    required this.confidence,
    required this.reason,
  });

  factory ActionabilityResult.fromJson(Map<String, dynamic> json) {
    return ActionabilityResult(
      actionable: json['actionable'] ?? false,
      confidence: (json['confidence'] ?? 0).toDouble(),
      reason: json['reason'] ?? '',
    );
  }

  @override
  String toString() {
    return '''
Actionable : $actionable
Confidence : $confidence
Reason     : $reason
''';
  }
}

class ActionabilityClassifier {
  static const _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  final String apiKey = "AQ.Ab8RN6Kp7glJzoqsQ6sYFZcJ-IvqtQI_OnraGylSDfXCcDRyOg";

  // Fixed constructor to properly assign apiKey
  ActionabilityClassifier(apiKey);

  Future<ActionabilityResult> classify(String message) async {
    const systemPrompt = '''
    You are an AI classification assistant. Your ONLY job is to determine whether an incoming SMS or Email is "ACTIONABLE".

### DEFINITION OF ACTIONABLE
A message is ACTIONABLE if the user MUST take a specific physical or digital action to fulfill a prior commitment, meet a critical deadline, complete an ongoing process, or prevent a negative consequence (e.g., financial loss, missed career/academic opportunity, or service disruption). 

Categories of ACTIONABLE messages:
1. Financial & Administrative Obligations: Paying due bills, EMIs, taxes, completing mandatory KYC, or renewing an actively expiring service/subscription.
2. Time-Sensitive Commitments: Checking in or confirming attendance for meetings, interviews, exams, flights/trains, or medical appointments.
3. Logistics & Security: Package deliveries requiring user presence/signature, or urgent OTPs/2FA codes for user-requested actions.
4. Critical Deadlines & Career Opportunities: Submitting assignments, registering for university placement drives/internships, enrolling for exams with a strict deadline, responding to government/legal notices, or taking the next required step in an *already initiated* application.

### DEFINITION OF NON-ACTIONABLE
A message is NON-ACTIONABLE if it is purely informational, promotional, unsolicited (commercial), or does not require the user's immediate intervention to prevent a negative consequence.

Categories of NON-ACTIONABLE messages:
1. Promotional & Marketing: Offers, discounts, upselling, brand new credit card/loan offers, or persuasion to buy/subscribe.
2. Informational (FYI): Newsletters, news updates, bank transaction alerts (e.g., "Amount debited/credited" require no action unless verifying fraud), policy updates.
3. Passive Updates: General shipping progress (e.g., "Your package has left the facility") that requires no user input.
4. Miscellaneous: Greetings, spam, motivational quotes.

### CRITICAL DISTINCTIONS (Promotions vs. Opportunities/Applications)
Pay close attention to these edge cases:
* Commercial Promotions vs. Career/Academic Opportunities: An unsolicited commercial offer ("Apply for this credit card/loan") is NON-ACTIONABLE marketing. However, an announcement for an academic, career, or placement opportunity with a specific registration deadline (e.g., "Register for Morgan Stanley internship by 6th July") is ACTIONABLE because missing it results in a severe missed career opportunity.
* Pending Applications (ACTIONABLE): "Your BOBCARD application is pending. Please complete the remaining steps here." (The user previously started this process and must act to finish it).
* Expiring Offers vs. Expiring Plans: "Get 20% off your next recharge. Offer expires today" is NON-ACTIONABLE (Promotional). However, "Your mobile plan expires today, recharge to avoid disruption" is ACTIONABLE (Administrative Obligation).
* False "Calls to Action": Just because a promotional message contains a link saying "Click here", "Buy now", or "Apply today" does NOT make it actionable if it is purely commercial marketing.

### OUTPUT INSTRUCTIONS
Return strictly valid JSON. To ensure accurate classification, you must write your `reason` FIRST before outputting the final `actionable` boolean. This allows you to think through the message before concluding.

{
  "reason": "Identify the core intent of the message and explain why it fits or does not fit the actionable criteria.",
  "confidence": 0.95,
  "actionable": true
}
''';

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'x-goog-api-key': apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "systemInstruction": {
          "parts": [
            {"text": systemPrompt}
          ]
        },
        "contents": [
          {
            "role": "user",
            "parts": [
              {"text": message}
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0,
          "responseMimeType": "application/json",
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Gemini API Error: ${response.statusCode}\n${response.body}');
    }

    final body = jsonDecode(response.body);
    final content =
    body["candidates"][0]["content"]["parts"][0]["text"] as String;
    final json = jsonDecode(content);

    return ActionabilityResult.fromJson(json);
  }
}