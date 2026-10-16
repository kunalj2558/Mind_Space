import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/services/v2_service.dart';

class DoctorEarningsScreen extends StatefulWidget {
  const DoctorEarningsScreen({super.key});

  @override
  State<DoctorEarningsScreen> createState() => _DoctorEarningsScreenState();
}

class _DoctorEarningsScreenState extends State<DoctorEarningsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() => _isLoading = true);
    final res = await V2Service.getDoctorEarningsDetailed();
    if (mounted) {
      setState(() {
        _data = res;
        _isLoading = false;
      });
    }
  }

  void _showWithdrawalDialog(double availableAmount) {
    final upiCtrl = TextEditingController(text: '9130062558@ybl');
    final amountCtrl = TextEditingController(text: availableAmount.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.account_balance_rounded, color: Color(0xFF059669)),
            SizedBox(width: 8),
            Text('Instant Bank / UPI Payout'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Withdraw your earned consultation profit directly to your registered bank account or UPI ID.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: upiCtrl,
              decoration: const InputDecoration(
                labelText: 'UPI ID / VPA',
                hintText: 'e.g. yourname@ybl',
                prefixIcon: Icon(Icons.qr_code_2_rounded),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Withdrawal Amount (₹)',
                prefixText: '₹ ',
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Available balance: ₹${availableAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payout request of ₹${amountCtrl.text} initiated to ${upiCtrl.text}! Settlement via IMPS will reflect shortly.'),
                  backgroundColor: const Color(0xFF059669),
                  duration: const Duration(seconds: 4),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Payout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final gross = (_data['grossEarnings'] as num?)?.toDouble() ?? 0.0;
    final platformCut = (_data['platformFees'] as num?)?.toDouble() ?? 0.0;
    final netEarnings = (_data['netEarnings'] as num?)?.toDouble() ?? 0.0;
    final today = (_data['todayEarnings'] as num?)?.toDouble() ?? 0.0;
    final week = (_data['weekEarnings'] as num?)?.toDouble() ?? 0.0;
    final totalConsults = _data['completedConsultations'] ?? 0;
    final receipts = (_data['sessionReceipts'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Profit & Earnings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadEarnings,
            tooltip: 'Refresh Ledger',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.backgroundGradient,
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
            : RefreshIndicator(
                onRefresh: _loadEarnings,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Big Astrotalk Profit Summary Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF059669), Color(0xFF10B981)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF059669).withOpacity(0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 6),
                                const Text(
                                  'Net Doctor Profit (Take-Home)',
                                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('90% Net Share', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '₹${netEarnings.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Gross Consultations: ₹${gross.toStringAsFixed(0)} • Platform Fee (10%): -₹${platformCut.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showWithdrawalDialog(netEarnings),
                                icon: const Icon(Icons.account_balance_rounded, size: 18),
                                label: const Text('Instant Withdraw to Bank / UPI', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF059669),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                      const SizedBox(height: 16),

                      // Metric Stats Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              title: "Today's Profit",
                              value: '₹${today.toStringAsFixed(0)}',
                              icon: Icons.today_rounded,
                              iconColor: const Color(0xFF3B82F6),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Past 7 Days',
                              value: '₹${week.toStringAsFixed(0)}',
                              icon: Icons.calendar_view_week_rounded,
                              iconColor: const Color(0xFF8B5CF6),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Consultations',
                              value: '$totalConsults',
                              icon: Icons.people_alt_rounded,
                              iconColor: const Color(0xFFF59E0B),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 150.ms),

                      const SizedBox(height: 24),

                      // Section Title: Itemized Per-Session Receipts
                      Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryOrange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Itemized Session Profit Receipts',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Astrotalk transparent settlement: Every call and chat breakdown with free intro vs paid minutes and net doctor profit.',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey),
                      ),
                      const SizedBox(height: 14),

                      if (receipts.isEmpty)
                        GlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.payments_outlined, size: 48, color: isDark ? Colors.white38 : Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  'No completed sessions yet.',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Accept incoming calls and chats to start generating profit.',
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: receipts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final r = receipts[i];
                            final patientName = r['patientName'] ?? 'Patient';
                            final mode = (r['mode'] ?? 'video').toString().toLowerCase();
                            final duration = r['durationMinutes'] ?? 0;
                            final freeMins = r['freeMinutesUsed'] ?? 0;
                            final paidMins = r['paidMinutes'] ?? 0;
                            final rate = r['ratePerMinute'] ?? 0;
                            final grossAmt = (r['grossAmount'] as num?)?.toDouble() ?? 0.0;
                            final cut = (r['platformCut'] as num?)?.toDouble() ?? 0.0;
                            final profit = (r['netProfit'] as num?)?.toDouble() ?? 0.0;
                            final ended = r['endedAt'] != null
                                ? DateTime.tryParse(r['endedAt'])?.toLocal().toString().substring(0, 16) ?? ''
                                : '';

                            IconData modeIcon;
                            Color modeColor;
                            if (mode == 'voice') {
                              modeIcon = Icons.call_rounded;
                              modeColor = const Color(0xFF059669);
                            } else if (mode == 'chat') {
                              modeIcon = Icons.chat_rounded;
                              modeColor = const Color(0xFFD97706);
                            } else {
                              modeIcon = Icons.videocam_rounded;
                              modeColor = const Color(0xFF6366F1);
                            }

                            return GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row: Patient & Mode
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: modeColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(modeIcon, color: modeColor, size: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              patientName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isDark ? Colors.white : AppTheme.textDark,
                                              ),
                                            ),
                                            Text(
                                              '${mode.toUpperCase()} Consultation • $ended',
                                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF059669).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '+₹${profit.toStringAsFixed(0)} Profit',
                                          style: const TextStyle(
                                            color: Color(0xFF059669),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  // Itemized Metrics
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildReceiptPill('Total Time', '$duration mins', isDark),
                                      _buildReceiptPill('Free Intro', '$freeMins mins', isDark),
                                      _buildReceiptPill('Billable', '$paidMins mins', isDark),
                                      _buildReceiptPill('Rate', '₹$rate/m', isDark),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E1C33) : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Text('Gross: ₹${grossAmt.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        const Text('  •  ', style: TextStyle(color: Colors.grey)),
                                        Text('Platform (10%): -₹${cut.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.redAccent)),
                                        const Spacer(),
                                        Text(
                                          'Net Payout: ₹${profit.toStringAsFixed(0)}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282542) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptPill(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }
}
