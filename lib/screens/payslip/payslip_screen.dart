import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../animations/motion.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/styled_donut_chart.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'payslip_viewer_screen.dart';
import '../../services/api_service.dart';

class PayslipScreen extends StatefulWidget {
  const PayslipScreen({super.key});

  @override
  State<PayslipScreen> createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
  int _selectedMonthIndex = 2;
  int _selectedYear = 2026;

  bool _isLoading = true;
  List<dynamic> _payslips = [];
  Map<String, dynamic> _selectedPayslip = {};

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _loadPayslips();
  }

  Future<void> _loadPayslips() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/payslips/list?year=$_selectedYear');
      _payslips = response['payslips'] ?? [];
      // Auto-load details for the currently selected month
      await _loadPayslipDetails();
    } catch (e) {
      _payslips = [];
      _selectedPayslip = {};
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadPayslipDetails() async {
    try {
      final m = _selectedMonthIndex + 1;
      final response = await ApiService.get('/payslips?month=$m&year=$_selectedYear');
      _selectedPayslip = response is Map<String, dynamic> ? response : {};
    } catch (e) {
      _selectedPayslip = {};
    }
  }

  void _goToPreviousMonth() {
    setState(() {
      if (_selectedMonthIndex == 0) {
        _selectedMonthIndex = 11;
        _selectedYear--;
      } else {
        _selectedMonthIndex--;
      }
    });
    _loadPayslips();
  }

  void _goToNextMonth() {
    setState(() {
      if (_selectedMonthIndex == 11) {
        _selectedMonthIndex = 0;
        _selectedYear++;
      } else {
        _selectedMonthIndex++;
      }
    });
    _loadPayslips();
  }

  double get _grossSalary => (_selectedPayslip['gross_pay'] as num?)?.toDouble() ?? 0;
  double get _totalDeductions => (_selectedPayslip['deduction'] as num?)?.toDouble() ?? 0;
  double get _basicPay => (_selectedPayslip['basic_pay'] as num?)?.toDouble() ?? 0;

  List<_SalaryItem> get _earnings {
    if (_grossSalary == 0) return [];
    final hra = _basicPay * 0.4;
    final da = _basicPay * 0.3;
    final special = _grossSalary - _basicPay - hra - da;
    return [
      _SalaryItem('Basic', _basicPay, AppColors.primary),
      _SalaryItem('HRA', hra, AppColors.success),
      _SalaryItem('DA', da, AppColors.orange),
      if (special > 0) _SalaryItem('Special Allowance', special, AppColors.secondary),
    ];
  }

  List<_SalaryItem> get _deductions {
    if (_totalDeductions == 0) return [];
    final pf = _basicPay * 0.12;
    final esi = _grossSalary * 0.0075;
    const pt = 200.0;
    final tax = _totalDeductions - pf - esi - pt;
    return [
      _SalaryItem('Provident Fund', pf, AppColors.primary),
      _SalaryItem('ESI', esi, AppColors.warning),
      _SalaryItem('Professional Tax', pt, AppColors.secondary),
      if (tax > 0) _SalaryItem('Income Tax', tax, AppColors.danger),
    ];
  }

  double get _netPay => _grossSalary - _totalDeductions;

  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPayslips,
              color: AppColors.primary,
              child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Month/Year Selector ---
            NeuCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _goToPreviousMonth,
                  ),
                  Text(
                    '${_months[_selectedMonthIndex]} $_selectedYear',
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _goToNextMonth,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.12, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),

            const SizedBox(height: 16),

            if (_selectedPayslip.isEmpty) ...[
              const SizedBox(height: 60),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('No payslip data', style: tt.titleMedium?.copyWith(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text('Payslip for ${_months[_selectedMonthIndex]} $_selectedYear is not available.',
                      style: tt.bodyMedium?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 80),
            ] else ...[

            // --- Total Earnings Card ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3B5FE5), Color(0xFF5B7FF9)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B5FE5).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Earnings', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: _grossSalary),
                              duration: const Duration(milliseconds: 1500),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) => Text(
                                _currencyFormat.format(value),
                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildEarningsSubItem('Gross Salary', _grossSalary),
                      const SizedBox(width: 16),
                      _buildEarningsSubItem('Net Pay', _netPay),
                      const SizedBox(width: 16),
                      _buildEarningsSubItem('Deductions', _totalDeductions),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 420.ms, delay: 40.ms).slideY(begin: 0.12, end: 0, duration: 420.ms, delay: 40.ms, curve: Curves.easeOutCubic),

            const SizedBox(height: 16),

            // --- 1. Earnings Graph ---
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.trending_up_rounded, color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Text('Earnings Breakdown', style: tt.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StyledDonutChart(
                    segments: _earnings.map((e) => DonutSegment(label: e.label, value: e.amount, color: e.color)).toList(),
                    centerLabel: 'Earnings',
                    centerBuilder: (total) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_currencyFormat.format(_grossSalary), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                        Text('Earnings', style: tt.bodySmall?.copyWith(color: isDark ? Colors.white54 : Colors.black45)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 420.ms, delay: 160.ms).slideY(begin: 0.12, end: 0, duration: 420.ms, delay: 160.ms, curve: Curves.easeOutCubic),

            const SizedBox(height: 16),

            // --- 2. Deductions Graph ---
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.trending_down_rounded, color: AppColors.danger, size: 20),
                      const SizedBox(width: 8),
                      Text('Deductions Breakdown', style: tt.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StyledDonutChart(
                    segments: _deductions.map((e) => DonutSegment(label: e.label, value: e.amount, color: e.color)).toList(),
                    centerLabel: 'Deductions',
                    centerBuilder: (total) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_currencyFormat.format(_totalDeductions), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                        Text('Deductions', style: tt.bodySmall?.copyWith(color: isDark ? Colors.white54 : Colors.black45)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 420.ms, delay: 240.ms).slideY(begin: 0.12, end: 0, duration: 420.ms, delay: 240.ms, curve: Curves.easeOutCubic),

            const SizedBox(height: 16),

            // --- 3. Total Salary Breakdown Graph ---
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pie_chart_rounded, color: AppColors.secondary, size: 20),
                      const SizedBox(width: 8),
                      Text('Total Salary Breakdown', style: tt.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StyledDonutChart(
                    size: 220,
                    segments: [
                      ..._earnings.map((e) => DonutSegment(label: e.label, value: e.amount, color: e.color)),
                      ..._deductions.map((e) => DonutSegment(label: e.label, value: e.amount, color: e.color.withValues(alpha: 0.6))),
                    ],
                    centerBuilder: (total) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_currencyFormat.format(_netPay), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                        Text('Net Pay', style: tt.bodySmall?.copyWith(color: isDark ? Colors.white54 : Colors.black45)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 420.ms, delay: 320.ms).slideY(begin: 0.12, end: 0, duration: 420.ms, delay: 320.ms, curve: Curves.easeOutCubic),

            const SizedBox(height: 16),

            // --- Earnings Line Items ---
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.list_alt_rounded, color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Text('Earnings Detail', style: tt.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_earnings.length, (i) {
                    final item = _earnings[i];
                    final isLast = i == _earnings.length - 1;
                    return Column(
                      children: [
                        _buildLineItem(item.label, item.amount, tt, item.color, isDark),
                        if (!isLast) Divider(height: 20, color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100),
                      ],
                    );
                  }),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Earnings', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(_currencyFormat.format(_grossSalary), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.success)),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 420.ms, delay: 400.ms).slideY(begin: 0.12, end: 0, duration: 420.ms, delay: 400.ms, curve: Curves.easeOutCubic),

            const SizedBox(height: 16),

            // --- Deductions Line Items ---
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.list_alt_rounded, color: AppColors.danger, size: 20),
                      const SizedBox(width: 8),
                      Text('Deductions Detail', style: tt.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_deductions.length, (i) {
                    final item = _deductions[i];
                    final isLast = i == _deductions.length - 1;
                    return Column(
                      children: [
                        _buildLineItem(item.label, item.amount, tt, item.color, isDark),
                        if (!isLast) Divider(height: 20, color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100),
                      ],
                    );
                  }),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Deductions', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(_currencyFormat.format(_totalDeductions), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.danger)),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 420.ms, delay: 480.ms).slideY(begin: 0.12, end: 0, duration: 420.ms, delay: 480.ms, curve: Curves.easeOutCubic),

            const SizedBox(height: 20),

            // --- Action Buttons ---
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          Motion.pageRoute(PayslipViewerScreen(
                              month: _months[_selectedMonthIndex],
                              year: _selectedYear,
                              payslipId: _selectedPayslip['id'] is int ? _selectedPayslip['id'] : int.tryParse(_selectedPayslip['id']?.toString() ?? ''),
                          )),
                        );
                      },
                      icon: const Icon(Icons.visibility_rounded, size: 20),
                      label: const Text('View Payslip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final payslipId = _selectedPayslip['id'];
                        if (payslipId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('No payslip available for this month'),
                            backgroundColor: AppColors.warning,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ));
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('Downloading PDF...'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          duration: const Duration(seconds: 1),
                        ));
                        try {
                          final id = payslipId is int ? payslipId : int.tryParse(payslipId.toString()) ?? 0;
                          final response = await ApiService.getPayslipPdf(id);
                          if (!mounted) return;
                          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
                            final dir = await getApplicationDocumentsDirectory();
                            final file = File('${dir.path}/payslip_${_months[_selectedMonthIndex]}_$_selectedYear.pdf');
                            await file.writeAsBytes(response.bodyBytes);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('PDF saved: ${file.path.split('/').last}'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              duration: const Duration(seconds: 3),
                            ));
                          } else {
                            throw Exception('PDF not available');
                          }
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Download failed: ${e.toString().replaceAll('Exception: ', '')}'),
                            backgroundColor: AppColors.danger,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ));
                        }
                      },
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: const Text('Download PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 420.ms, delay: 560.ms).slideY(begin: 0.12, end: 0, duration: 420.ms, delay: 560.ms, curve: Curves.easeOutCubic),

            const SizedBox(height: 12),
            const SizedBox(height: 80),
            ], // end else
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildLineItem(String label, double amount, TextTheme tt, Color accentColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text(label, style: tt.bodyLarge),
            ],
          ),
          Text(_currencyFormat.format(amount), style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildEarningsSubItem(String label, double amount) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            '${_currencyFormat.format(amount)}/mo',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

}

class _SalaryItem {
  final String label;
  final double amount;
  final Color color;
  const _SalaryItem(this.label, this.amount, this.color);
}
