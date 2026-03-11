import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';

class HrClaimsOverview extends StatefulWidget {
  const HrClaimsOverview({super.key});

  @override
  State<HrClaimsOverview> createState() => _HrClaimsOverviewState();
}

class _HrClaimsOverviewState extends State<HrClaimsOverview> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Stats Row
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              Expanded(child: _ClaimStatCard(label: 'Pending', value: '23', amount: '₹9,58,000', color: AppColors.warning)),
              const SizedBox(width: 10),
              Expanded(child: _ClaimStatCard(label: 'Approved', value: '156', amount: '₹65,42,000', color: AppColors.success)),
              const SizedBox(width: 10),
              Expanded(child: _ClaimStatCard(label: 'Disbursed', value: '142', amount: '₹60,78,000', color: AppColors.primary)),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),
        ),
        const SizedBox(height: 16),

        // Tab Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: NeuCard(
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Approved'),
                Tab(text: 'Disbursed'),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 80.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 80.ms, curve: Curves.easeOut),
        ),
        const SizedBox(height: 12),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildClaimsList(_pendingClaims, theme, isDark, showActions: true),
              _buildClaimsList(_approvedClaims, theme, isDark),
              _buildClaimsList(_disbursedClaims, theme, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClaimsList(List<_ClaimItem> claims, ThemeData theme, bool isDark, {bool showActions = false}) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: claims.length + 1, // +1 for the chart
      itemBuilder: (context, index) {
        if (index == 0) {
          // Claims by Category Chart
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: NeuCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Claims by Category', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 35,
                        sections: [
                          PieChartSectionData(value: 45, title: '45%', color: AppColors.primary, radius: 35, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                          PieChartSectionData(value: 25, title: '25%', color: AppColors.success, radius: 35, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                          PieChartSectionData(value: 20, title: '20%', color: AppColors.orange, radius: 35, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                          PieChartSectionData(value: 10, title: '10%', color: AppColors.secondary, radius: 35, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                        ],
                      ),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeInOutCubic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: const [
                      _Legend(label: 'Travel', color: AppColors.primary),
                      _Legend(label: 'Medical', color: AppColors.success),
                      _Legend(label: 'Equipment', color: AppColors.orange),
                      _Legend(label: 'Other', color: AppColors.secondary),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 160.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 160.ms, curve: Curves.easeOut),
          );
        }

        final claim = claims[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ClaimCard(claim: claim, showActions: showActions)
              .animate()
              .fadeIn(duration: 400.ms, delay: (240 + (index < 6 ? index : 6) * 60).ms)
              .slideY(begin: 0.06, end: 0, duration: 400.ms, delay: (240 + (index < 6 ? index : 6) * 60).ms, curve: Curves.easeOut),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------
class _ClaimItem {
  final String employeeName;
  final String initials;
  final String empId;
  final String category;
  final String description;
  final String amount;
  final String date;
  final bool hasReceipt;

  const _ClaimItem({
    required this.employeeName,
    required this.initials,
    required this.empId,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    this.hasReceipt = true,
  });
}

const _pendingClaims = [
  _ClaimItem(employeeName: 'Arjun Patel', initials: 'AP', empId: 'EMP-001', category: 'Travel', description: 'Client visit - Mumbai', amount: '₹34,500', date: 'Mar 8, 2026'),
  _ClaimItem(employeeName: 'Priya Sharma', initials: 'PS', empId: 'EMP-002', category: 'Medical', description: 'Annual health checkup', amount: '₹21,500', date: 'Mar 7, 2026'),
  _ClaimItem(employeeName: 'Rahul Verma', initials: 'RV', empId: 'EMP-003', category: 'Equipment', description: 'Laptop repair', amount: '₹13,800', date: 'Mar 6, 2026', hasReceipt: false),
  _ClaimItem(employeeName: 'Sneha Gupta', initials: 'SG', empId: 'EMP-004', category: 'Travel', description: 'Conference registration', amount: '₹26,800', date: 'Mar 5, 2026'),
  _ClaimItem(employeeName: 'Neha Singh', initials: 'NS', empId: 'EMP-006', category: 'Other', description: 'Client dinner', amount: '₹9,200', date: 'Mar 4, 2026'),
];

const _approvedClaims = [
  _ClaimItem(employeeName: 'Vikram Singh', initials: 'VS', empId: 'EMP-009', category: 'Travel', description: 'Team outing transport', amount: '₹15,400', date: 'Mar 3, 2026'),
  _ClaimItem(employeeName: 'Karan Mehta', initials: 'KM', empId: 'EMP-007', category: 'Medical', description: 'Eye checkup', amount: '₹11,500', date: 'Mar 2, 2026'),
  _ClaimItem(employeeName: 'Amit Kumar', initials: 'AK', empId: 'EMP-005', category: 'Equipment', description: 'Monitor purchase', amount: '₹32,200', date: 'Mar 1, 2026'),
  _ClaimItem(employeeName: 'Meera Nair', initials: 'MN', empId: 'EMP-012', category: 'Travel', description: 'Airport taxi', amount: '₹6,500', date: 'Feb 28, 2026'),
];

const _disbursedClaims = [
  _ClaimItem(employeeName: 'Deepak Shah', initials: 'DS', empId: 'EMP-015', category: 'Travel', description: 'Delhi site visit', amount: '₹52,200', date: 'Feb 25, 2026'),
  _ClaimItem(employeeName: 'Ravi Menon', initials: 'RM', empId: 'EMP-013', category: 'Medical', description: 'Dental treatment', amount: '₹24,500', date: 'Feb 22, 2026'),
  _ClaimItem(employeeName: 'Anita Desai', initials: 'AD', empId: 'EMP-008', category: 'Other', description: 'Training materials', amount: '₹7,300', date: 'Feb 20, 2026'),
];

// ---------------------------------------------------------------------------
// Claim Stat Card
// ---------------------------------------------------------------------------
class _ClaimStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String amount;
  final Color color;

  const _ClaimStatCard({
    required this.label,
    required this.value,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSubtext : AppColors.lightSubtext)),
          const SizedBox(height: 4),
          Text(amount, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Claim Card
// ---------------------------------------------------------------------------
class _ClaimCard extends StatelessWidget {
  final _ClaimItem claim;
  final bool showActions;

  const _ClaimCard({required this.claim, this.showActions = false});

  Color _categoryColor() {
    switch (claim.category) {
      case 'Travel':
        return AppColors.primary;
      case 'Medical':
        return AppColors.success;
      case 'Equipment':
        return AppColors.orange;
      default:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catColor = _categoryColor();

    return NeuCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: catColor.withValues(alpha: 0.15),
                child: Text(claim.initials, style: TextStyle(color: catColor, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(claim.employeeName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? AppColors.darkText : AppColors.lightText)),
                        const SizedBox(width: 6),
                        Text(claim.empId, style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(claim.description, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(claim.amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? AppColors.darkText : AppColors.lightText)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(claim.category, style: TextStyle(color: catColor, fontWeight: FontWeight.w600, fontSize: 10)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              const SizedBox(width: 4),
              Text(claim.date, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
              const SizedBox(width: 14),
              Icon(
                claim.hasReceipt ? Icons.receipt_long : Icons.receipt_long_outlined,
                size: 12,
                color: claim.hasReceipt ? AppColors.success : AppColors.danger,
              ),
              const SizedBox(width: 4),
              Text(
                claim.hasReceipt ? 'Receipt attached' : 'No receipt',
                style: TextStyle(fontSize: 11, color: claim.hasReceipt ? AppColors.success : AppColors.danger, fontWeight: FontWeight.w500),
              ),
              if (showActions) ...[
                const Spacer(),
                _ActionBtn(icon: Icons.close, color: AppColors.danger, label: 'Reject'),
                const SizedBox(width: 8),
                _ActionBtn(icon: Icons.check, color: AppColors.success, label: 'Approve'),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action Button
// ---------------------------------------------------------------------------
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _ActionBtn({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Legend
// ---------------------------------------------------------------------------
class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  const _Legend({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSubtext : AppColors.lightSubtext)),
      ],
    );
  }
}
