import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'payslip_viewer_screen.dart';

class PayslipScreen extends StatefulWidget {
  const PayslipScreen({super.key});

  @override
  State<PayslipScreen> createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
  int _selectedMonthIndex = 2;
  int _touchedEarningsIndex = -1;
  int _touchedDeductionsIndex = -1;
  int _touchedTotalIndex = -1;
  int _selectedYear = 2026;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  void _goToPreviousMonth() {
    setState(() {
      if (_selectedMonthIndex == 0) {
        _selectedMonthIndex = 11;
        _selectedYear--;
      } else {
        _selectedMonthIndex--;
      }
    });
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
  }

  final double _grossSalary = 85000;
  final double _totalDeductions = 18350;

  final List<_SalaryItem> _earnings = [
    _SalaryItem('Basic', 42500, AppColors.primary),
    _SalaryItem('HRA', 17000, AppColors.success),
    _SalaryItem('DA', 12750, AppColors.orange),
    _SalaryItem('Special Allowance', 12750, AppColors.secondary),
  ];

  final List<_SalaryItem> _deductions = [
    _SalaryItem('Provident Fund', 5100, AppColors.primary),
    _SalaryItem('ESI', 637, AppColors.warning),
    _SalaryItem('Professional Tax', 200, AppColors.secondary),
    _SalaryItem('Income Tax', 12413, AppColors.danger),
  ];

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
      body: SingleChildScrollView(
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
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),

            const SizedBox(height: 16),

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
                              duration: const Duration(milliseconds: 3500),
                              curve: Curves.easeOutExpo,
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
            ).animate().fadeIn(duration: 400.ms, delay: 40.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 40.ms, curve: Curves.easeOut),

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
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                                      _touchedEarningsIndex = -1;
                                      return;
                                    }
                                    _touchedEarningsIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              sectionsSpace: 3,
                              centerSpaceRadius: 36,
                              sections: List.generate(_earnings.length, (i) {
                                final item = _earnings[i];
                                final isTouched = i == _touchedEarningsIndex;
                                return PieChartSectionData(
                                  value: item.amount,
                                  color: item.color,
                                  title: isTouched ? '${item.label}\n${_currencyFormat.format(item.amount)}' : '${(item.amount / _grossSalary * 100).toStringAsFixed(0)}%',
                                  titleStyle: TextStyle(
                                    fontSize: isTouched ? 11 : 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  radius: isTouched ? 60.0 : 48.0,
                                  titlePositionPercentageOffset: isTouched ? 0.55 : 0.5,
                                );
                              }),
                            ),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutCubic,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _earnings.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildChartLegend(e.label, e.color, tt),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                  if (_touchedEarningsIndex >= 0 && _touchedEarningsIndex < _earnings.length) ...[
                    const SizedBox(height: 12),
                    _buildTouchedValueBanner(_earnings[_touchedEarningsIndex], isDark),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 160.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 160.ms, curve: Curves.easeOut),

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
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                                      _touchedDeductionsIndex = -1;
                                      return;
                                    }
                                    _touchedDeductionsIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              sectionsSpace: 3,
                              centerSpaceRadius: 36,
                              sections: List.generate(_deductions.length, (i) {
                                final item = _deductions[i];
                                final isTouched = i == _touchedDeductionsIndex;
                                return PieChartSectionData(
                                  value: item.amount,
                                  color: item.color,
                                  title: isTouched ? '${item.label}\n${_currencyFormat.format(item.amount)}' : '${(item.amount / _totalDeductions * 100).toStringAsFixed(0)}%',
                                  titleStyle: TextStyle(
                                    fontSize: isTouched ? 11 : 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  radius: isTouched ? 60.0 : 48.0,
                                  titlePositionPercentageOffset: isTouched ? 0.55 : 0.5,
                                );
                              }),
                            ),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutCubic,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _deductions.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildChartLegend(e.label, e.color, tt),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                  if (_touchedDeductionsIndex >= 0 && _touchedDeductionsIndex < _deductions.length) ...[
                    const SizedBox(height: 12),
                    _buildTouchedValueBanner(_deductions[_touchedDeductionsIndex], isDark),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 240.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 240.ms, curve: Curves.easeOut),

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
                  SizedBox(
                    height: 220,
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                                      _touchedTotalIndex = -1;
                                      return;
                                    }
                                    _touchedTotalIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: _buildTotalBreakdownSections(),
                            ),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutCubic,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ..._earnings.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _buildChartLegend(e.label, e.color, tt),
                            )),
                            const SizedBox(height: 4),
                            ..._deductions.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _buildChartLegend(e.label, e.color.withValues(alpha: 0.6), tt),
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_touchedTotalIndex >= 0) ...[
                    const SizedBox(height: 12),
                    Builder(builder: (context) {
                      final allItems = [..._earnings, ..._deductions];
                      if (_touchedTotalIndex < allItems.length) {
                        return _buildTouchedValueBanner(allItems[_touchedTotalIndex], isDark);
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 320.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 320.ms, curve: Curves.easeOut),

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
            ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 400.ms, curve: Curves.easeOut),

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
            ).animate().fadeIn(duration: 400.ms, delay: 480.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 480.ms, curve: Curves.easeOut),

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
                          MaterialPageRoute(
                            builder: (_) => PayslipViewerScreen(
                              month: _months[_selectedMonthIndex],
                              year: _selectedYear,
                            ),
                          ),
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Downloading ${_months[_selectedMonthIndex]} $_selectedYear payslip PDF...'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            duration: const Duration(seconds: 1),
                          ),
                        );
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
            ).animate().fadeIn(duration: 400.ms, delay: 560.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 560.ms, curve: Curves.easeOut),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildTotalBreakdownSections() {
    final allItems = [..._earnings, ..._deductions];
    final total = _grossSalary + _totalDeductions;

    return List.generate(allItems.length, (i) {
      final item = allItems[i];
      final isTouched = i == _touchedTotalIndex;
      final isDeduction = i >= _earnings.length;

      return PieChartSectionData(
        value: item.amount,
        color: isDeduction ? item.color.withValues(alpha: 0.6) : item.color,
        title: isTouched
            ? '${item.label}\n${_currencyFormat.format(item.amount)}'
            : '${(item.amount / total * 100).toStringAsFixed(0)}%',
        titleStyle: TextStyle(
          fontSize: isTouched ? 10 : 9,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        radius: isTouched ? 58.0 : 45.0,
        titlePositionPercentageOffset: isTouched ? 0.55 : 0.5,
      );
    });
  }

  Widget _buildTouchedValueBanner(_SalaryItem item, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(item.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkText : AppColors.lightText)),
          ),
          Text(
            _currencyFormat.format(item.amount),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: item.color),
          ),
        ],
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

  Widget _buildChartLegend(String label, Color color, TextTheme tt) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: tt.bodySmall?.copyWith(fontSize: 11)),
      ],
    );
  }
}

class _SalaryItem {
  final String label;
  final double amount;
  final Color color;
  const _SalaryItem(this.label, this.amount, this.color);
}
