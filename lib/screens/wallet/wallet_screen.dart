import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/services/v2_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _balance = 0;
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  final TextEditingController _customAmountController = TextEditingController();
  final TextEditingController _utrController = TextEditingController();
  int _selectedPreset = 500;
  String _selectedMethod = 'PhonePe UPI';

  static const String upiId = '9130062558@ybl';
  static const String upiName = 'MindSpace Health';
  static const String bankInfo = 'State Bank of India - 7593';

  final List<int> _presetAmounts = [100, 250, 500, 1000, 2000];
  final List<String> _paymentMethods = [
    'PhonePe UPI',
    'Google Pay (GPay)',
    'Paytm UPI',
    'State Bank of India (NetBanking)',
    'Debit / Credit Card',
  ];

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    _utrController.dispose();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    setState(() => _isLoading = true);
    final data = await V2Service.getWalletBalance();
    if (mounted) {
      setState(() {
        _balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
        _transactions = (data['transactions'] as List?) ?? [];
        _isLoading = false;
      });
    }
  }

  double _getEffectiveAmount() {
    final customText = _customAmountController.text.trim();
    if (customText.isNotEmpty) {
      final parsed = double.tryParse(customText);
      if (parsed != null && parsed > 0) return parsed;
    }
    return _selectedPreset.toDouble();
  }

  Future<void> _launchUpiIntent() async {
    final amount = _getEffectiveAmount();
    final upiUrl = 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(upiName)}&cu=INR&am=${amount.toStringAsFixed(0)}';
    final uri = Uri.parse(upiUrl);

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: Copy UPI ID and notify user
        Clipboard.setData(const ClipboardData(text: upiId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('UPI ID $upiId copied to clipboard! Open PhonePe / GPay to pay, then enter the UTR below.'),
              backgroundColor: AppTheme.primaryOrange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (_) {
      Clipboard.setData(const ClipboardData(text: upiId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UPI ID copied! Open your UPI app and paste the ID to pay.'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    }
  }

  Future<void> _verifyUtrAndTopUp() async {
    final utr = _utrController.text.trim();
    final amount = _getEffectiveAmount();

    if (utr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 12-digit UPI Reference / UTR number from your payment receipt.')),
      );
      return;
    }

    _showProcessingDialog('Verifying UPI Payment (UTR: $utr)...');

    await Future.delayed(const Duration(milliseconds: 1200));
    try {
      final res = await V2Service.topUpWallet(
        amount,
        paymentMethod: 'PhonePe UPI ($bankInfo)',
        utr: utr,
      );
      if (mounted) {
        Navigator.pop(context); // close loading
        _utrController.clear();
        _customAmountController.clear();
        await _loadWallet();
        _showSuccessDialog(amount, res['message'] ?? 'UPI Top-Up Verified & Credited!');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _processTopUpSimulated() async {
    final amount = _getEffectiveAmount();
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a valid amount')),
      );
      return;
    }

    _showProcessingDialog('Connecting to $_selectedMethod...');

    await Future.delayed(const Duration(milliseconds: 1200));
    try {
      final res = await V2Service.topUpWallet(
        amount,
        paymentMethod: _selectedMethod,
        utr: 'SIM-${DateTime.now().millisecondsSinceEpoch}',
      );
      if (mounted) {
        Navigator.pop(context);
        _customAmountController.clear();
        await _loadWallet();
        _showSuccessDialog(amount, res['message'] ?? 'Funds added successfully!');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Top-up failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showProcessingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryOrange),
            const SizedBox(height: 18),
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            const Text('Authorizing bank payment gateway securely...', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(double amount, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 28),
            SizedBox(width: 8),
            Text('Payment Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('₹${amount.toStringAsFixed(0)} added to your MindSpace Wallet.', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Your new balance is ₹${_balance.toStringAsFixed(2)}. You can now connect for pay-as-you-go video, voice & chat consultations.', style: const TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
            child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showQrExpandedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('PhonePe Official QR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/payment_qr.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2_rounded, size: 200, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Scan using PhonePe, GPay, Paytm, or BHIM',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final currentAmt = _getEffectiveAmount();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MindSpace Wallet & UPI'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadWallet,
            tooltip: 'Refresh Balance',
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
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF8C61)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withOpacity(0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Available In-App Balance',
                                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '₹${_balance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Astrotalk Model: Used automatically for pay-as-you-go video, voice & chat consultations after your free intro minutes (3m call / 5m chat).',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Amount Selector Card
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Select Recharge Amount (INR ₹)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _presetAmounts.map((amt) {
                              final isSelected = _selectedPreset == amt && _customAmountController.text.isEmpty;
                              return ChoiceChip(
                                label: Text('₹$amt', style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87))),
                                selected: isSelected,
                                selectedColor: AppTheme.primaryOrange,
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() {
                                      _selectedPreset = amt;
                                      _customAmountController.clear();
                                    });
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _customAmountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Or enter custom recharge amount',
                              prefixText: '₹ ',
                              isDense: true,
                            ),
                            onChanged: (val) {
                              if (val.isNotEmpty) setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section 1: Official PhonePe QR & UPI Pay Card
                    Text(
                      'Pay via PhonePe / UPI QR Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),

                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // QR Image with Tap to Expand
                          GestureDetector(
                            onTap: _showQrExpandedDialog,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 190,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF6739B7).withOpacity(0.3), width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.asset(
                                      'assets/images/payment_qr.jpg',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Center(
                                        child: Icon(Icons.qr_code_2_rounded, size: 120, color: Color(0xFF6739B7)),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.all(6),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap QR to zoom full-screen',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 14),

                          // UPI ID Details Card
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1C33) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.account_balance_rounded, size: 20, color: Color(0xFF059669)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        upiId,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const Text(
                                        bankInfo,
                                        style: TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.primaryOrange),
                                  tooltip: 'Copy UPI ID',
                                  onPressed: () {
                                    Clipboard.setData(const ClipboardData(text: upiId));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('UPI ID copied: $upiId'),
                                        backgroundColor: Color(0xFF059669),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Direct UPI App Launcher Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _launchUpiIntent,
                              icon: const Icon(Icons.open_in_new_rounded, size: 18),
                              label: Text(
                                'Pay ₹${currentAmt.toStringAsFixed(0)} via PhonePe / UPI App',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5F259F), // PhonePe Purple
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Step 2: UTR Reference Verification
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF282542) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.verified_outlined, size: 16, color: AppTheme.primaryOrange),
                                    SizedBox(width: 6),
                                    Text('Step 2: Enter 12-Digit UTR / Ref No.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _utrController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. 428901234567',
                                    labelText: 'UPI Reference (UTR)',
                                    isDense: true,
                                    prefixIcon: Icon(Icons.tag_rounded, size: 18),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _verifyUtrAndTopUp,
                                    icon: const Icon(Icons.check_circle_outline, size: 18),
                                    label: const Text('Verify & Credit to Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF059669),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 11),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section 2: Alternative Bank Payment Methods
                    Text(
                      'Instant Bank Gateway / Cards',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),

                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedMethod,
                            isExpanded: true,
                            decoration: const InputDecoration(isDense: true, labelText: 'Gateway Provider'),
                            items: _paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (v) => setState(() => _selectedMethod = v ?? _paymentMethods.first),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _processTopUpSimulated,
                              icon: const Icon(Icons.flash_on_rounded, size: 18),
                              label: Text('Instant Credit ₹${currentAmt.toStringAsFixed(0)} (Demo Mode)', style: const TextStyle(fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryOrange,
                                side: const BorderSide(color: AppTheme.primaryOrange),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section 3: Transaction History Ledger
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 20, color: AppTheme.primaryOrange),
                        const SizedBox(width: 8),
                        Text(
                          'Transaction History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_transactions.isEmpty)
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No wallet transactions recorded yet.',
                            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _transactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final tx = _transactions[i];
                          final isCredit = tx['type'] == 'topup' || tx['type'] == 'refund' || tx['type'] == 'doctor_payout';
                          final amount = tx['amount'] ?? 0;
                          final desc = tx['description'] ?? 'Transaction';
                          final dateStr = tx['createdAt'] != null
                              ? DateTime.tryParse(tx['createdAt'])?.toLocal().toString().substring(0, 16) ?? ''
                              : '';

                          return GlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (isCredit ? const Color(0xFF059669) : Colors.redAccent).withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                    color: isCredit ? const Color(0xFF059669) : Colors.redAccent,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        desc,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: isDark ? Colors.white : AppTheme.textDark,
                                        ),
                                      ),
                                      if (dateStr.isNotEmpty)
                                        Text(
                                          dateStr,
                                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isCredit ? '+' : '-'}₹$amount',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isCredit ? const Color(0xFF059669) : Colors.redAccent,
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
    );
  }
}
