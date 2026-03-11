import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';

class HrEmployeeDirectory extends StatefulWidget {
  const HrEmployeeDirectory({super.key});

  @override
  State<HrEmployeeDirectory> createState() => _HrEmployeeDirectoryState();
}

class _HrEmployeeDirectoryState extends State<HrEmployeeDirectory> {
  String _searchQuery = '';
  String _selectedDepartment = 'All';
  String _selectedStatus = 'All';

  final _departments = ['All', 'Engineering', 'Design', 'Marketing', 'HR', 'Finance', 'Operations'];
  final _statuses = ['All', 'Active', 'On Leave', 'Notice Period', 'Inactive'];

  final _employees = const [
    _Employee('Arjun Patel', 'AP', 'Sr. Engineer', 'Engineering', 'EMP-001', 'Active'),
    _Employee('Priya Sharma', 'PS', 'UI Designer', 'Design', 'EMP-002', 'Active'),
    _Employee('Rahul Verma', 'RV', 'Backend Dev', 'Engineering', 'EMP-003', 'On Leave'),
    _Employee('Sneha Gupta', 'SG', 'QA Lead', 'Engineering', 'EMP-004', 'Active'),
    _Employee('Amit Kumar', 'AK', 'DevOps Engineer', 'Engineering', 'EMP-005', 'Notice Period'),
    _Employee('Neha Singh', 'NS', 'Product Manager', 'Marketing', 'EMP-006', 'Active'),
    _Employee('Karan Mehta', 'KM', 'HR Executive', 'HR', 'EMP-007', 'Active'),
    _Employee('Anita Desai', 'AD', 'Marketing Lead', 'Marketing', 'EMP-008', 'Active'),
    _Employee('Vikram Singh', 'VS', 'Finance Analyst', 'Finance', 'EMP-009', 'Active'),
    _Employee('Kavita Das', 'KD', 'UI/UX Designer', 'Design', 'EMP-010', 'On Leave'),
    _Employee('Sunil Reddy', 'SR', 'Full Stack Dev', 'Engineering', 'EMP-011', 'Active'),
    _Employee('Meera Nair', 'MN', 'Ops Manager', 'Operations', 'EMP-012', 'Active'),
    _Employee('Ravi Menon', 'RM', 'Frontend Dev', 'Engineering', 'EMP-013', 'Active'),
    _Employee('Pooja Iyer', 'PI', 'Content Writer', 'Marketing', 'EMP-014', 'Inactive'),
    _Employee('Deepak Shah', 'DS', 'Data Analyst', 'Engineering', 'EMP-015', 'Active'),
  ];

  List<_Employee> get _filteredEmployees {
    return _employees.where((e) {
      final matchesSearch = _searchQuery.isEmpty ||
          e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.empId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.designation.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDept = _selectedDepartment == 'All' || e.department == _selectedDepartment;
      final matchesStatus = _selectedStatus == 'All' || e.status == _selectedStatus;
      return matchesSearch && matchesDept && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filtered = _filteredEmployees;

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: NeuCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(color: isDark ? Colors.white : AppColors.lightText),
              decoration: InputDecoration(
                hintText: 'Search by name, ID, or designation...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
                border: InputBorder.none,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),
        ),
        const SizedBox(height: 12),

        // Filter Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(child: _buildFilterDropdown('Department', _selectedDepartment, _departments, (v) => setState(() => _selectedDepartment = v), isDark)),
              const SizedBox(width: 10),
              Expanded(child: _buildFilterDropdown('Status', _selectedStatus, _statuses, (v) => setState(() => _selectedStatus = v), isDark)),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 80.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 80.ms, curve: Curves.easeOut),
        ),
        const SizedBox(height: 8),

        // Results count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                '${filtered.length} employees found',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
              const Spacer(),
              Icon(Icons.download_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 4),
              Text('Export', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Employee List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final emp = filtered[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _EmployeeCard(employee: emp)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: ((index < 8 ? index : 8) * 60).ms)
                    .slideY(begin: 0.06, end: 0, duration: 400.ms, delay: ((index < 8 ? index : 8) * 60).ms, curve: Curves.easeOut),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> options, ValueChanged<String> onChanged, bool isDark) {
    return NeuCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext, size: 20),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? AppColors.darkText : AppColors.lightText),
          dropdownColor: isDark ? const Color(0xFF1E2030) : Colors.white,
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Employee Data
// ---------------------------------------------------------------------------
class _Employee {
  final String name;
  final String initials;
  final String designation;
  final String department;
  final String empId;
  final String status;

  const _Employee(this.name, this.initials, this.designation, this.department, this.empId, this.status);
}

// ---------------------------------------------------------------------------
// Employee Card
// ---------------------------------------------------------------------------
class _EmployeeCard extends StatelessWidget {
  final _Employee employee;
  const _EmployeeCard({required this.employee});

  Color _statusColor() {
    switch (employee.status) {
      case 'Active':
        return AppColors.success;
      case 'On Leave':
        return AppColors.warning;
      case 'Notice Period':
        return AppColors.orange;
      case 'Inactive':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _statusColor();

    return NeuCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              employee.initials,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? AppColors.darkText : AppColors.lightText)),
                const SizedBox(height: 2),
                Text('${employee.designation} • ${employee.department}', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                const SizedBox(height: 2),
                Text(employee.empId, style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(employee.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 10)),
              ),
              const SizedBox(height: 6),
              Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}
