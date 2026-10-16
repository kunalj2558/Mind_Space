import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/providers/auth_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/services/v2_service.dart';
import 'package:hearme/screens/safety/crisis_resources_sheet.dart';
import 'package:hearme/screens/wallet/wallet_screen.dart';

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
  Timer? _pollTimer;
  Timer? _remoteEndPoller;

  int _elapsedSeconds = 0;
  bool _isMicMuted = false;
  bool _isCamOff = false;
  bool _isSpeakerOn = true;
  bool _isFrontCamera = true;
  bool _isEnding = false;
  bool _showChatPanel = false;
  bool _hasPromptedPayAsYouGo = false;
  bool _isPayAsYouGoAccepted = false;
  bool _isRemoteEnded = false;

  List<dynamic> _messages = [];
  double _walletBalance = 0;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
    _loadMessages();
    _loadWallet();

    // Poll in-call messages every 4s
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _loadMessages());

    // Dual-Sided Call Disconnect: Poll server status every 1.5s so when other party ends, we disconnect immediately!
    _remoteEndPoller = Timer.periodic(const Duration(milliseconds: 1500), (_) => _checkRemoteTermination());
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _pollTimer?.cancel();
    _remoteEndPoller?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    final w = await V2Service.getWalletBalance();
    if (mounted) {
      setState(() => _walletBalance = (w['balance'] as num?)?.toDouble() ?? 0.0);
    }
  }

  Future<void> _checkRemoteTermination() async {
    if (_isEnding || _isRemoteEnded) return;
    final statusData = await V2Service.getAppointmentStatus(widget.appointmentId);
    if (statusData != null && statusData['status'] == 'completed' && mounted) {
      _isRemoteEnded = true;
      _sessionTimer?.cancel();
      _pollTimer?.cancel();
      _remoteEndPoller?.cancel();

      final endedBy = statusData['endedByRole'] == 'doctor' ? 'Doctor' : 'Patient';
      final paidMins = statusData['paidMinutes'] ?? 0;
      final debited = statusData['amountDebited'] ?? 0;

      // Automatically pop completion dialog on this phone simultaneously
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.call_end_rounded, color: Colors.redAccent, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Consultation Ended by $endedBy',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The other participant has concluded this consultation session.'),
              const SizedBox(height: 12),
              Text('Paid Minutes: $paidMins min(s)'),
              Text('Settled from Wallet: ₹$debited', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryOrange)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // Exit consultation room
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange),
              child: const Text('Return to Consultations', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _checkAndRequestPermissions() async {
    final mode = widget.appointment['mode'] ?? 'video';
    if (mode == 'video') {
      await [Permission.camera, Permission.microphone].request();
    } else if (mode == 'voice') {
      await Permission.microphone.request();
    }

    if (mounted) {
      _startSessionTimer();
    }
  }

  Future<void> _startSessionTimer() async {
    await V2Service.startSession(widget.appointmentId);
    final mode = widget.appointment['mode'] ?? 'video';
    final int freeDurationSeconds = mode == 'chat' ? (5 * 60) : (3 * 60);

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);

      // Check for 30s remaining in free quota
      if (_elapsedSeconds == (freeDurationSeconds - 30)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.hourglass_bottom_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('30 seconds left in your free introductory session.'),
              ],
            ),
            backgroundColor: Color(0xFFD97706),
            duration: Duration(seconds: 4),
          ),
        );
      }

      // Check for free quota expiration (00:00)
      if (_elapsedSeconds >= freeDurationSeconds && !_hasPromptedPayAsYouGo && !_isPayAsYouGoAccepted) {
        _hasPromptedPayAsYouGo = true;
        _showPayAsYouGoTransitionDialog();
      }
    });
  }

  void _showPayAsYouGoTransitionDialog() {
    final prof = widget.appointment['professionalProfileId'] ?? {};
    final profName = prof['publicName'] ?? 'Doctor';
    final mode = widget.appointment['mode'] ?? 'video';
    final rates = prof['rates'] ?? {};

    int ratePerMin = 20;
    if (mode == 'video') ratePerMin = rates['ratePerMinuteVideo'] ?? rates['ratePerMinute'] ?? 25;
    else if (mode == 'voice') ratePerMin = rates['ratePerMinuteVoice'] ?? rates['ratePerMinute'] ?? 18;
    else if (mode == 'chat') ratePerMin = rates['ratePerMinuteChat'] ?? rates['ratePerMinute'] ?? 10;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.timer_outlined, color: AppTheme.primaryOrange, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Free Intro Completed',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your free introductory session with $profName has concluded.'),
            const SizedBox(height: 10),
            Text(
              'Doctor Rate: ₹$ratePerMin / minute (${mode.toUpperCase()})',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryOrange),
            ),
            const SizedBox(height: 6),
            Text('Your Wallet Balance: ₹${_walletBalance.toStringAsFixed(2)}'),
            if (_walletBalance < ratePerMin)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Your wallet balance is low. Please top up to continue.',
                  style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _endSession(); // End gracefully
            },
            child: const Text('End Session'),
          ),
          if (_walletBalance >= ratePerMin)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _isPayAsYouGoAccepted = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pay-as-you-go consultation extended seamlessly!'),
                    backgroundColor: Color(0xFF059669),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
              child: const Text('Continue Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          else
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())).then((_) => _loadWallet());
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange),
              child: const Text('Top Up Wallet', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Future<void> _loadMessages() async {
    final msgs = await V2Service.getAppointmentMessages(widget.appointmentId);
    if (mounted) setState(() => _messages = msgs);
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    await V2Service.sendAppointmentMessage(widget.appointmentId, text);
    _loadMessages();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _endSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('End Consultation Session?'),
        content: const Text(
          'This will disconnect the call on both sides and settle the consultation duration with your wallet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay in Session'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('End Call for Both', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isEnding = true);
      _sessionTimer?.cancel();
      _pollTimer?.cancel();
      _remoteEndPoller?.cancel();

      final summary = await V2Service.endSession(widget.appointmentId);

      if (mounted) {
        final totalMins = summary['totalMinutes'] ?? 1;
        final freeUsed = summary['freeMinutesUsed'] ?? 0;
        final paidMins = summary['paidMinutes'] ?? 0;
        final debited = summary['amountDebited'] ?? 0;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            // Flexible title row prevents horizontal pixel overflow
            title: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Consultation Complete',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your consultation has ended on both devices.'),
                const SizedBox(height: 12),
                Text('Total Duration: $totalMins minute(s)'),
                Text('Free Intro Quota: $freeUsed minute(s)', style: const TextStyle(color: Color(0xFF059669))),
                Text('Billable Paid Time: $paidMins minute(s)'),
                const Divider(height: 16),
                Text('Debited from Wallet: ₹$debited', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryOrange)),
                const SizedBox(height: 6),
                const Text('Receipt logged to your wallet & billing ledger.', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isDoctor = auth.user?.role == 'doctor';

    final patientObj = widget.appointment['patientId'];
    final patientName = (patientObj is Map ? patientObj['name'] : null) ?? 'Patient';
    final prof = widget.appointment['professionalProfileId'] ?? {};
    final doctorName = prof['publicName'] ?? widget.appointment['professionalId']?['name'] ?? 'Doctor';

    final remotePartyName = isDoctor ? patientName : doctorName;
    final remotePartyRole = isDoctor ? 'Patient' : 'Doctor';

    final mode = widget.appointment['mode'] ?? 'video';
    final int freeDurationSeconds = mode == 'chat' ? (5 * 60) : (3 * 60);
    final bool isFreePhase = _elapsedSeconds < freeDurationSeconds;
    final int freeRemainingSecs = isFreePhase ? (freeDurationSeconds - _elapsedSeconds) : 0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$remotePartyRole: $remotePartyName',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isFreePhase ? const Color(0xFF059669) : AppTheme.primaryOrange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isFreePhase
                      ? 'FREE INTRO • ${_formatTimer(freeRemainingSecs)} left'
                      : 'PAY-AS-YOU-GO • ${_formatTimer(_elapsedSeconds)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isFreePhase ? const Color(0xFF059669) : AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => setState(() => _showChatPanel = !_showChatPanel),
            icon: Icon(
              _showChatPanel ? Icons.chat_bubble : Icons.chat_bubble_outline,
              color: _showChatPanel ? AppTheme.primaryOrange : null,
            ),
            tooltip: 'In-Call Chat',
          ),
          IconButton(
            onPressed: () => CrisisResourcesSheet.show(context),
            icon: const Icon(Icons.emergency_outlined, color: Colors.redAccent),
            tooltip: 'Emergency SOS',
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
            // Main Media Area
            Expanded(
              flex: _showChatPanel ? 1 : 2,
              child: Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF16152B) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background pattern
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.08,
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6),
                                itemCount: 36,
                                itemBuilder: (_, __) => Container(margin: const EdgeInsets.all(1), color: Colors.white),
                              ),
                            ),
                          ),

                          // Doctor Visualizer & Call Status
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryOrange,
                                      isFreePhase ? const Color(0xFF059669) : const Color(0xFF3B82F6),
                                    ],
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 46,
                                  backgroundColor: const Color(0xFF2B2844),
                                  child: Text(
                                    remotePartyName.isNotEmpty ? remotePartyName[0].toUpperCase() : (isDoctor ? 'P' : 'D'),
                                    style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                remotePartyName,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    mode == 'video'
                                        ? 'Direct Live Video Connected'
                                        : 'Direct Live Voice Connected',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isDoctor ? 'Patient Direct Session' : 'Doctor Direct Session',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ),
                            ],
                          ),

                          // Top status badges
                          Positioned(
                            top: 14,
                            left: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 12),
                                  SizedBox(width: 4),
                                  Text('Doctor <-> Patient (No AI Bot)', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                ],
                              ),
                            ),
                          ),

                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                _formatTimer(_elapsedSeconds),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Floating Self-Camera Tile (Only in Video Mode)
                  if (mode == 'video')
                    Positioned(
                      bottom: 16,
                      right: 24,
                      child: Container(
                        width: 88,
                        height: 116,
                        decoration: BoxDecoration(
                          color: _isCamOff ? Colors.black87 : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white30, width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_isCamOff)
                                const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.videocam_off, color: Colors.white54, size: 24),
                                    SizedBox(height: 4),
                                    Text('Cam Off', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                  ],
                                )
                              else
                                Container(
                                  color: const Color(0xFF232B3E),
                                  child: Center(
                                    child: Icon(
                                      _isFrontCamera ? Icons.person_rounded : Icons.landscape_rounded,
                                      color: Colors.white70,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 4,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('You', style: TextStyle(color: Colors.white, fontSize: 8)),
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

            // In-Call Real-Time Chat Drawer
            if (_showChatPanel)
              Expanded(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1C33) : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppTheme.primaryOrange),
                            const SizedBox(width: 8),
                            const Text('Consultation Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () => setState(() => _showChatPanel = false),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: _messages.isEmpty
                            ? const Center(
                                child: Text('No messages yet. Send a note to clinician.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(8),
                                itemCount: _messages.length,
                                itemBuilder: (ctx, i) {
                                  final m = _messages[i];
                                  final isMe = m['senderRole'] == 'patient';
                                  return Align(
                                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isMe ? AppTheme.primaryOrange : (isDark ? Colors.white12 : Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        m['message'] ?? '',
                                        style: TextStyle(
                                          color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _msgController,
                                onSubmitted: (_) => _sendMessage(),
                                style: const TextStyle(fontSize: 12),
                                decoration: const InputDecoration(
                                  hintText: 'Type a message...',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send_rounded, size: 18, color: AppTheme.primaryOrange),
                              onPressed: _sendMessage,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Adaptive Call Controls Dock (Zero Pixel Overflow on Any Screen)
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Mic toggle
                        IconButton(
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                          icon: Icon(
                            _isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                            color: _isMicMuted ? Colors.redAccent : (isDark ? Colors.white : Colors.black87),
                            size: 22,
                          ),
                          onPressed: () => setState(() => _isMicMuted = !_isMicMuted),
                          tooltip: 'Mute / Unmute',
                        ),

                        // Video camera toggle (Only for video calls)
                        if (mode == 'video') ...[
                          IconButton(
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                            icon: Icon(
                              _isCamOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                              color: _isCamOff ? Colors.redAccent : (isDark ? Colors.white : Colors.black87),
                              size: 22,
                            ),
                            onPressed: () => setState(() => _isCamOff = !_isCamOff),
                            tooltip: 'Camera On / Off',
                          ),
                          IconButton(
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                            icon: Icon(
                              Icons.flip_camera_ios_rounded,
                              color: isDark ? Colors.white : Colors.black87,
                              size: 22,
                            ),
                            onPressed: () => setState(() => _isFrontCamera = !_isFrontCamera),
                            tooltip: 'Flip Camera',
                          ),
                        ],

                        // Speaker toggle
                        IconButton(
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                          icon: Icon(
                            _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                            color: _isSpeakerOn ? AppTheme.primaryOrange : (isDark ? Colors.white : Colors.black87),
                            size: 22,
                          ),
                          onPressed: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                          tooltip: 'Speaker / Earpiece',
                        ),

                        // Chat drawer toggle
                        IconButton(
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                          icon: Icon(
                            Icons.message_rounded,
                            color: _showChatPanel ? AppTheme.primaryOrange : (isDark ? Colors.white : Colors.black87),
                            size: 22,
                          ),
                          onPressed: () => setState(() => _showChatPanel = !_showChatPanel),
                          tooltip: 'In-Call Chat',
                        ),

                        const SizedBox(width: 6),

                        // End Call Button (Flexible constraint so it never overflows)
                        ElevatedButton(
                          onPressed: _isEnding ? null : _endSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.call_end_rounded, size: 18),
                              SizedBox(width: 4),
                              Text('End', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
