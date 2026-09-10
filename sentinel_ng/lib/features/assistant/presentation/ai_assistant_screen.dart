import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/formatting.dart';
import '../../../core/utils/safety_score.dart';
import '../../../data/models/crime_report_model.dart';

/// A chat-style assistant that answers safety questions using live report data.
///
/// The logic is rule-based (keyword matching) so it works fully offline of any
/// LLM service — responses are grounded in the reports fetched from the API.
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class ChatMessage {
  final bool isUser;
  final String text;
  final String? actionRoute; // optional "do something" button (e.g. open SOS)
  final String? actionLabel;

  const ChatMessage({required this.isUser, required this.text, this.actionRoute, this.actionLabel});
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _thinking = false;
  bool _dataLoaded = false;
  String? _dataError;
  List<CrimeReportModel> _nearbyReports = const [];
  double? _centerLat;
  double? _centerLng;

  static const List<String> _suggestions = [
    'Is my area safe right now?',
    'What incidents were reported recently?',
    'Give me safety tips',
    'How do I report a crime?',
  ];

  @override
  void initState() {
    super.initState();
    _messages = [
      const ChatMessage(
        isUser: false,
        text: "Hi! I'm the Sentinel assistant. Ask me about safety in your area, recent incidents, or how to use the app.",
      ),
    ];
    _loadReportData();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    try {
      // Use a broad radius so the assistant has context even without GPS.
      final response = await _api.getReports(radiusKm: 50, limit: 100);
      if (!mounted) return;
      final parsed = ReportsResponse.fromJson(response);
      setState(() {
        _nearbyReports = [...parsed.verified]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _dataLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _dataError = 'Live report data is unavailable right now.');
    }
  }

  Future<void> _send(String text) async {
    final question = text.trim();
    if (question.isEmpty || _thinking) return;

    _inputController.clear();
    setState(() {
      _messages.add(ChatMessage(isUser: true, text: question));
      _thinking = true;
    });
    _scrollToBottom();

    // Small delay so the "typing" state is perceivable.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    final reply = _buildReply(question);
    setState(() {
      _messages.add(reply);
      _thinking = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---------- Rule-based response engine ----------

  ChatMessage _buildReply(String question) {
    final q = question.toLowerCase();

    if (q.contains('sos') || q.contains('emergency') || q.contains('help me now') || q.contains('danger')) {
      return const ChatMessage(
        isUser: false,
        text: 'If you are in immediate danger, trigger an SOS alert — it notifies your emergency contacts with your live location. You can also call 112 (police) or 767 (emergency line).',
        actionRoute: '/sos-emergency',
        actionLabel: 'Trigger SOS Alert',
      );
    }

    if (q.contains('safe') && (q.contains('area') || q.contains('here') || q.contains('now') || q.contains('right'))) {
      return _safetySummaryReply();
    }

    if (q.contains('recent') || q.contains('incident') || q.contains('crime') || q.contains('robber') || q.contains('theft') || q.contains('happen')) {
      return _recentIncidentsReply();
    }

    if (q.contains('police') || q.contains('hospital') || q.contains('pharmacy') || q.contains('safe place')) {
      return const ChatMessage(
        isUser: false,
        text: 'I can point you to nearby police stations, hospitals and pharmacies. Open "Find Safe Places" from the + menu on the home screen — it shows them on a live map with your location.',
      );
    }

    if (q.contains('report') || q.contains('submit')) {
      return const ChatMessage(
        isUser: false,
        text: 'To report a crime: tap the green + button and choose "Report a Crime". Pick the type, drop a pin on the map (or use your current location), describe what happened, add photos or video if you have them, then submit. You can also submit anonymously.',
      );
    }

    if (q.contains('tip') || q.contains('advice') || q.contains('protect')) {
      return const ChatMessage(
        isUser: false,
        text: 'Quick safety tips:\n• Avoid isolated routes at night — use the Safe Route planner.\n• Keep your phone charged and share your location with someone you trust.\n• Trust your instincts; if a place feels wrong, leave it.\n• Report suspicious activity early — community reports help everyone.',
      );
    }

    if (q.contains('route') || q.contains('travel')) {
      return const ChatMessage(
        isUser: false,
        text: 'Use the Safe Route planner to get a route that avoids high-risk areas. It geocodes your start and destination, draws the driving route on the map and scores its safety against nearby incidents.',
      );
    }

    if (q.contains('hello') || q.contains('hi ') || q == 'hi' || q.contains('good morning') || q.contains('good evening')) {
      return const ChatMessage(
        isUser: false,
        text: "Hello! How can I help you stay safe today? Try asking about your area's safety or recent incidents.",
      );
    }

    // Default fallback.
    return ChatMessage(
      isUser: false,
      text: _dataLoaded
          ? 'I can help with:\n• "Is my area safe right now?"\n• "What incidents were reported recently?"\n• "Give me safety tips"\n• "How do I report a crime?"'
          : 'I\'m still loading live data. Try asking: "Is my area safe right now?" or "What incidents were reported recently?"',
    );
  }

  ChatMessage _safetySummaryReply() {
    if (!_dataLoaded) {
      return const ChatMessage(
        isUser: false,
        text: 'I couldn\'t load live report data right now. Please check your connection and try again.',
      );
    }

    final score = SafetyScore.compute(_nearbyReports);
    final highRisk = _nearbyReports.where((r) => r.riskLevel == 'HIGH').length;
    final recent7d = _nearbyReports.where((r) => DateTime.now().difference(r.createdAt).inDays < 7).length;

    String summary;
    switch (score.label) {
      case 'Very Safe':
        summary = 'Your area looks very safe right now (score ${score.score}/100).';
        break;
      case 'Safe':
        summary = 'Your area is generally safe (score ${score.score}/100), but stay aware of your surroundings.';
        break;
      case 'Moderate Risk':
        summary = 'There is a moderate level of activity in your area (score ${score.score}/100). Take normal precautions and avoid risky shortcuts.';
        break;
      default:
        summary = 'Your area currently shows elevated risk (score ${score.score}/100). Consider using the Safe Route planner and travelling with company where possible.';
    }

    final details = [
      '$recent7d incident(s) reported in the last 7 days.',
      if (highRisk > 0) '$highRisk classified as high risk — check the Map tab to see where they are.',
      if (_nearbyReports.isNotEmpty)
        'Most recent: ${_nearbyReports.first.type} · ${timeAgo(_nearbyReports.first.createdAt)}.',
    ].where((s) => s.isNotEmpty).join('\n');

    return ChatMessage(isUser: false, text: '$summary\n$details');
  }

  ChatMessage _recentIncidentsReply() {
    if (!_dataLoaded || _nearbyReports.isEmpty) {
      return const ChatMessage(
        isUser: false,
        text: 'No verified incidents are currently on record nearby. That\'s a good sign — keep it that way by reporting anything suspicious.',
      );
    }

    final lines = <String>[];
    for (final report in _nearbyReports.take(4)) {
      lines.add('• ${report.type} (${report.riskLevelDisplay}) · ${timeAgo(report.createdAt)}');
    }
    return ChatMessage(
      isUser: false,
      text: 'Here are the most recent verified incidents nearby:\n${lines.join('\n')}\n\nTap any alert on the home screen or Map tab for full details.',
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.smart_toy_outlined, size: 20, color: AppColors.primaryGreen),
          ),
          SizedBox(width: 10),
          Text('AI Safety Assistant'),
        ]),
      ),
      body: Column(children: [
        // Suggestion chips
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final suggestion in _suggestions) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(suggestion, style: const TextStyle(fontSize: 12)),
                    selected: false,
                    onSelected: (_) => _send(suggestion),
                    selectedColor: AppColors.primaryGreen.withOpacity(0.15),
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),

        if (_dataError != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade300)),
            child: Row(children: [
              Icon(Icons.cloud_off, size: 14, color: Colors.amber.shade800),
              const SizedBox(width: 6),
              Expanded(child: Text(_dataError!, style: TextStyle(fontSize: 11, color: Colors.amber.shade900))),
            ]),
          ),

        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_thinking ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length && _thinking) return const _TypingIndicator();
              final message = _messages[index];
              return _MessageBubble(message: message);
            },
          ),
        ),

        // Input bar
        Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))]),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (value) => _send(value),
                  decoration: InputDecoration(
                    hintText: 'Ask about safety in your area…',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                mini: true,
                backgroundColor: AppColors.primaryGreen,
                onPressed: () => _send(_inputController.text),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Container(
      margin: EdgeInsets.only(bottom: 12, left: isUser ? 60 : 0, right: isUser ? 0 : 60),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(radius: 14, backgroundColor: AppColors.primaryGreen.withOpacity(0.15), child: Icon(Icons.smart_toy_outlined, size: 16, color: AppColors.primaryGreen)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primaryGreen : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(message.text, style: TextStyle(fontSize: 14, height: 1.45, color: isUser ? Colors.white : const Color(0xFF333333))),
                if (message.actionRoute != null) ...[
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => context.push(message.actionRoute!),
                    icon: const Icon(Icons.warning_amber_rounded, size: 16),
                    label: Text(message.actionLabel ?? 'Open'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      CircleAvatar(radius: 14, backgroundColor: AppColors.primaryGreen.withOpacity(0.15), child: Icon(Icons.smart_toy_outlined, size: 16, color: AppColors.primaryGreen)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: SizedBox(
                width: 7,
                height: 7,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.grey[400]),
              ),
            ),
        ]),
      ),
    ]);
  }
}
