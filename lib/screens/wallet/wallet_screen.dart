import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  int _selectedPreset = 500;
  String _selectedMethod = 'UPI (Google Pay / PhonePe)';

  final List<int> _presetAmounts = [100, 250, 500, 1000, 2000];
  final List<String> _paymentMethods = [
    'UPI (Google Pay / PhonePe)',
    'Paytm Wallet / UPI',
    'Net Banking (SBI / HDFC / ICICI)',
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

  Future<void> _processTopUp() async {
    double amount = _selectedPreset.toDouble();
    final customText = _customAmountController.text.trim();
    if (customText.isNotEmpty) {
      final parsed = double.tryParse(customText);
      if (parsed != null && parsed > 0) {
        amount = parsed;
      }
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a valid amount')),
      );
      return;
    }

    // Show simulated bank processing dialog
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
            Text('Connecting to $_selectedMethod...', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Authorizing bank payment gateway securely...', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1400));
    try {
      final res = await V2Service.topUpWallet(amount, paymentMethod: _selectedMethod);
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
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
            Text('Your new balance is ₹${_balance.toStringAsFixed(2)}. You can now use this for pay-as-you-go consultations.', style: const TextStyle(fontSize: 13)),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MindSpace Wallet'),
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
                            'Used automatically for pay-as-you-go video, voice & chat consultations after your free intro minutes.',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Add Money Section
                    Text(
                      'Add Money from Bank / UPI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Select Top-Up Amount (INR ₹)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _presetAmounts.map((amt) {
                              final isSelected = _selectedPreset == amt && _customAmountController.text.isEmpty;
                              return ChoiceChip(
                                label: Text('+₹$amt', style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87))),
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
                          const SizedBox(height: 14),
                          TextField(
                            controller: _customAmountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Or enter custom amount',
                              prefixText: '₹ ',
                              isDense: true,
                            ),
                            onChanged: (val) {
                              if (val.isNotEmpty) setState(() {});
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text('Payment Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedMethod,
                            isExpanded: true,
                            decoration: const InputDecoration(isDense: true),
                            items: _paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (v) => setState(() => _selectedMethod = v ?? _paymentMethods.first),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _processTopUp,
                              icon: const Icon(Icons.add_card_rounded, size: 20),
                              label: const Text('Add Money to Wallet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Transaction History Ledger
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
