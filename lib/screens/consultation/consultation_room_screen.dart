import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/services/v2_service.dart';
import 'package:hearme/screens/safety/crisis_resources_sheet.dart';

class ConsultationRoomScreen extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> appointment;

  const ConsultationRoomScreen({
    super.key,
    required this.appointmentId,
    required this.appointment,
  });

  @override
  State<ConsultationRoomScreen> createState() => _ConsultationRoomScreenState();
}

class _ConsultationRoomScreenState extends State<ConsultationRoomScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _sessionTimer;
  int _elapsedSeconds = 0;
  bool _isMicMuted = false;
  bool _isCamOff = false;
  bool _isEnding = false;

  List<dynamic> _messages = [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _startSessionTimer();
    _loadMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _pollTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startSessionTimer() async {
    // Notify server of session start
    await V2Service.startSession(widget.appointmentId);
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  Future<void> _loadMessages() async {
    final msgs = await V2Service.getAppointmentMessages(widget.appointmentId);
    if (mounted) {
      setState(() => _messages = msgs);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    await V2Service.sendAppointmentMessage(widget.appointmentId, text);
    _loadMessages();
  }

  Future<void> _endSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Consultation Session?'),
        content: const Text(
          'This will disconnect the call and settle the session duration with the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay in Session'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('End Session', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isEnding = true);
      _sessionTimer?.cancel();
      _pollTimer?.cancel();

      final summary = await V2Service.endSession(widget.appointmentId);

      if (mounted) {
        final billableMins = summary['billableMinutes'] ?? 1;
        final total = summary['itemizedSummary']?['totalCharged'] ??
            widget.appointment['rateSnapshot']?['totalAmount'] ?? 600;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF059669)),
                SizedBox(width: 8),
                Text('Consultation Complete'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your consultation has ended successfully.'),
                const SizedBox(height: 12),
                Text('Duration: $billableMins minute(s)'),
                Text('Total Settled: ₹$total'),
                const SizedBox(height: 8),
                const Text(
                  'Itemized receipt has been logged to your billing history.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Exit room
                },
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }

  String _formatTimer(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final prof = widget.appointment['professionalProfileId'] ?? {};
    final profName = prof['publicName'] ?? 'Specialist';
    final mode = widget.appointment['mode'] ?? 'video';
    final duration = widget.appointment['durationMinutes'] ?? 30;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF059669),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Active ${mode.toUpperCase()} Session • ${_formatTimer(_elapsedSeconds)} / ${duration}m',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF059669)),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => CrisisResourcesSheet.show(context),
            icon: const Icon(Icons.emergency_outlined, color: Colors.redAccent),
            tooltip: 'Emergency Resources',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.backgroundGradient,
        ),
        child: Column(
          children: [
            // Media Stream Preview Container
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: mode == 'chat' ? 90 : 160,
              decoration: BoxDecoration(
                color: isDark ? Colors.black54 : Colors.grey.shade900,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.3),
                        child: Icon(
                          mode == 'video'
                              ? (_isCamOff ? Icons.videocam_off : Icons.videocam)
                              : Icons.mic,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$profName (Connected)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  // Mode & Timer Badge
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatTimer(_elapsedSeconds),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Controls Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: () => setState(() => _isMicMuted = !_isMicMuted),
                    icon: Icon(_isMicMuted ? Icons.mic_off : Icons.mic),
                    tooltip: _isMicMuted ? 'Unmute' : 'Mute',
                  ),
                  if (mode == 'video') const SizedBox(width: 14),
                  if (mode == 'video')
                    IconButton.filledTonal(
                      onPressed: () => setState(() => _isCamOff = !_isCamOff),
                      icon: Icon(_isCamOff ? Icons.videocam_off : Icons.videocam),
                      tooltip: _isCamOff ? 'Turn on Camera' : 'Turn off Camera',
                    ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    onPressed: _isEnding ? null : _endSession,
                    icon: const Icon(Icons.call_end, size: 18),
                    label: const Text('End Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 16),

            // Consultation Messaging Area
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        'Direct consultation chat is active.\nMessages are confidential between you and $profName.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : AppTheme.textLight,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMe = msg['senderRole'] == 'patient';
                        final text = msg['message'] ?? '';

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? AppTheme.primaryColor
                                  : (isDark ? const Color(0xFF2B2844) : Colors.white),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              text,
                              style: TextStyle(
                                color: isMe ? Colors.white : (isDark ? Colors.white : AppTheme.textDark),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Message Input
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Type message to clinician...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppTheme.primaryColor),
                      onPressed: _sendMessage,
                    ),
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
