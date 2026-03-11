import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/status_chip.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        // Tab Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: NeuCard(
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor:
                  isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              labelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              dividerHeight: 0,
              tabs: const [
                Tab(text: 'Leave'),
                Tab(text: 'Claims'),
                Tab(text: 'Tickets'),
                Tab(text: 'Work Type'),
                Tab(text: 'Regularization'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _LeaveTab(),
              _ClaimsTab(),
              _TicketsTab(),
              _WorkTypeTab(),
              _RegularizationTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sample Data Models
// ---------------------------------------------------------------------------
class _ApprovalRequest {
  final String employeeName;
  final String initials;
  final Color avatarColor;
  final String requestType;
  final String dateRange;
  final String reason;

  const _ApprovalRequest({
    required this.employeeName,
    required this.initials,
    required this.avatarColor,
    required this.requestType,
    required this.dateRange,
    required this.reason,
  });
}

class _ClaimRequest {
  final String employeeName;
  final String initials;
  final Color avatarColor;
  final String category;
  final String amount;
  final String date;
  final String description;
  final bool hasReceipt;

  const _ClaimRequest({
    required this.employeeName,
    required this.initials,
    required this.avatarColor,
    required this.category,
    required this.amount,
    required this.date,
    required this.description,
    required this.hasReceipt,
  });
}

class _TicketItem {
  final String employeeName;
  final String initials;
  final Color avatarColor;
  final String title;
  final String description;
  final String priority;
  final String date;
  final String ticketType;

  const _TicketItem({
    required this.employeeName,
    required this.initials,
    required this.avatarColor,
    required this.title,
    required this.description,
    required this.priority,
    required this.date,
    required this.ticketType,
  });
}

class _WorkTypeRequest {
  final String employeeName;
  final String initials;
  final Color avatarColor;
  final String workType;
  final String dateRange;
  final String reason;
  final String currentType;

  const _WorkTypeRequest({
    required this.employeeName,
    required this.initials,
    required this.avatarColor,
    required this.workType,
    required this.dateRange,
    required this.reason,
    required this.currentType,
  });
}

class _RegularizationRequest {
  final String employeeName;
  final String initials;
  final Color avatarColor;
  final String date;
  final String originalPunchIn;
  final String originalPunchOut;
  final String requestedPunchIn;
  final String requestedPunchOut;
  final String reason;

  const _RegularizationRequest({
    required this.employeeName,
    required this.initials,
    required this.avatarColor,
    required this.date,
    required this.originalPunchIn,
    required this.originalPunchOut,
    required this.requestedPunchIn,
    required this.requestedPunchOut,
    required this.reason,
  });
}

// ---------------------------------------------------------------------------
// Sample Data
// ---------------------------------------------------------------------------
const _sampleLeaveApprovals = [
  _ApprovalRequest(
    employeeName: 'Priya Sharma',
    initials: 'PS',
    avatarColor: AppColors.primary,
    requestType: 'Sick Leave',
    dateRange: 'Mar 12 - Mar 14, 2026',
    reason: 'Family function - sister\'s wedding ceremony',
  ),
  _ApprovalRequest(
    employeeName: 'Rahul Verma',
    initials: 'RV',
    avatarColor: AppColors.secondary,
    requestType: 'Casual Leave',
    dateRange: 'Mar 10 - Mar 11, 2026',
    reason: 'Need to attend parent-teacher meeting at school',
  ),
  _ApprovalRequest(
    employeeName: 'Karan Mehta',
    initials: 'KM',
    avatarColor: AppColors.success,
    requestType: 'Earned Leave',
    dateRange: 'Mar 18 - Mar 20, 2026',
    reason: 'Personal medical appointment and recovery',
  ),
  _ApprovalRequest(
    employeeName: 'Sneha Patel',
    initials: 'SP',
    avatarColor: AppColors.pink,
    requestType: 'Sick Leave',
    dateRange: 'Mar 16, 2026',
    reason: 'Dental surgery scheduled with post-op rest',
  ),
];

const _sampleClaims = [
  _ClaimRequest(
    employeeName: 'Anita Desai',
    initials: 'AD',
    avatarColor: AppColors.orange,
    category: 'Travel',
    amount: '₹34,500',
    date: 'Mar 8, 2026',
    description: 'Round-trip cab fare for client site visit in Bangalore',
    hasReceipt: true,
  ),
  _ClaimRequest(
    employeeName: 'Rahul Verma',
    initials: 'RV',
    avatarColor: AppColors.secondary,
    category: 'Laptop Repair',
    amount: '₹21,500',
    date: 'Mar 6, 2026',
    description: 'Screen replacement for work laptop after accidental damage',
    hasReceipt: true,
  ),
  _ClaimRequest(
    employeeName: 'Priya Sharma',
    initials: 'PS',
    avatarColor: AppColors.primary,
    category: 'Client Dinner',
    amount: '₹9,200',
    date: 'Mar 5, 2026',
    description: 'Dinner with prospective client at The Grand Hotel',
    hasReceipt: false,
  ),
];

const _sampleTickets = [
  _TicketItem(
    employeeName: 'Karan Mehta',
    initials: 'KM',
    avatarColor: AppColors.success,
    title: 'VPN Access Not Working',
    description:
        'Unable to connect to corporate VPN from home network. Tried reinstalling the client.',
    priority: 'High',
    date: 'Mar 9, 2026',
    ticketType: 'IT',
  ),
  _TicketItem(
    employeeName: 'Sneha Patel',
    initials: 'SP',
    avatarColor: AppColors.pink,
    title: 'Email Setup on New Device',
    description:
        'Need help configuring Outlook on the newly issued MacBook Pro.',
    priority: 'Medium',
    date: 'Mar 8, 2026',
    ticketType: 'IT',
  ),
  _TicketItem(
    employeeName: 'Vikram Singh',
    initials: 'VS',
    avatarColor: AppColors.orange,
    title: 'Software License Request',
    description:
        'Requesting Figma Pro license for upcoming UI/UX project deliverables.',
    priority: 'Low',
    date: 'Mar 7, 2026',
    ticketType: 'HR',
  ),
];

const _sampleWorkType = [
  _WorkTypeRequest(
    employeeName: 'Priya Sharma',
    initials: 'PS',
    avatarColor: AppColors.primary,
    workType: 'Work From Home',
    dateRange: 'Mar 11 - Mar 13, 2026',
    reason: 'Plumber visit and home renovation scheduled',
    currentType: 'Office',
  ),
  _WorkTypeRequest(
    employeeName: 'Anita Desai',
    initials: 'AD',
    avatarColor: AppColors.orange,
    workType: 'Work From Home',
    dateRange: 'Mar 14 - Mar 15, 2026',
    reason: 'Child unwell, need to be at home for care',
    currentType: 'Office',
  ),
  _WorkTypeRequest(
    employeeName: 'Rahul Verma',
    initials: 'RV',
    avatarColor: AppColors.secondary,
    workType: 'Shift Swap',
    dateRange: 'Mar 16, 2026',
    reason: 'Swap morning shift to evening for dentist appointment',
    currentType: 'Morning Shift',
  ),
];

const _sampleRegularization = [
  _RegularizationRequest(
    employeeName: 'Vikram Singh',
    initials: 'VS',
    avatarColor: AppColors.orange,
    date: 'Mar 7, 2026',
    originalPunchIn: '--:--',
    originalPunchOut: '06:15 PM',
    requestedPunchIn: '09:05 AM',
    requestedPunchOut: '06:15 PM',
    reason: 'Biometric did not register morning punch-in',
  ),
  _RegularizationRequest(
    employeeName: 'Sneha Patel',
    initials: 'SP',
    avatarColor: AppColors.pink,
    date: 'Mar 6, 2026',
    originalPunchIn: '09:30 AM',
    originalPunchOut: '--:--',
    requestedPunchIn: '09:30 AM',
    requestedPunchOut: '06:45 PM',
    reason: 'Forgot to punch out, was in a client call until late',
  ),
  _RegularizationRequest(
    employeeName: 'Karan Mehta',
    initials: 'KM',
    avatarColor: AppColors.success,
    date: 'Mar 5, 2026',
    originalPunchIn: '10:45 AM',
    originalPunchOut: '06:00 PM',
    requestedPunchIn: '09:00 AM',
    requestedPunchOut: '06:00 PM',
    reason: 'Was working from lobby; biometric logged late entry',
  ),
];

// ---------------------------------------------------------------------------
// Leave Tab
// ---------------------------------------------------------------------------
class _LeaveTab extends StatelessWidget {
  const _LeaveTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _sampleLeaveApprovals.length,
      itemBuilder: (context, index) {
        final req = _sampleLeaveApprovals[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _ApprovalCard(request: req),
        );
      },
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final _ApprovalRequest request;
  const _ApprovalCard({required this.request});

  Color _typeColor() {
    switch (request.requestType) {
      case 'Sick Leave':
        return AppColors.danger;
      case 'Casual Leave':
        return AppColors.primary;
      case 'Earned Leave':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  IconData _typeIcon() {
    switch (request.requestType) {
      case 'Sick Leave':
        return Icons.local_hospital;
      case 'Casual Leave':
        return Icons.event_busy;
      case 'Earned Leave':
        return Icons.beach_access;
      default:
        return Icons.event_busy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _typeColor();

    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: request.avatarColor.withValues(alpha: 0.15),
                child: Text(
                  request.initials,
                  style: TextStyle(
                    color: request.avatarColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.employeeName,
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(_typeIcon(), size: 14, color: color),
                        const SizedBox(width: 4),
                        Text(
                          request.requestType,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              StatusChip.pending(),
            ],
          ),
          const SizedBox(height: 14),

          // Date range
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(request.dateRange, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),

          // Reason
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.notes, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(request.reason, style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Claims Tab
// ---------------------------------------------------------------------------
class _ClaimsTab extends StatelessWidget {
  const _ClaimsTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _sampleClaims.length,
      itemBuilder: (context, index) {
        final claim = _sampleClaims[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _ClaimCard(claim: claim),
        );
      },
    );
  }
}

class _ClaimCard extends StatelessWidget {
  final _ClaimRequest claim;
  const _ClaimCard({required this.claim});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: claim.avatarColor.withValues(alpha: 0.15),
                child: Text(
                  claim.initials,
                  style: TextStyle(
                    color: claim.avatarColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(claim.employeeName,
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.receipt_long,
                            size: 14, color: AppColors.orange),
                        const SizedBox(width: 4),
                        Text(
                          claim.category,
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              StatusChip.pending(),
            ],
          ),
          const SizedBox(height: 14),

          // Amount row
          Row(
            children: [
              const Icon(Icons.attach_money, size: 16, color: AppColors.success),
              const SizedBox(width: 4),
              Text(
                claim.amount,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(claim.date, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),

          // Description
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.notes, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child:
                    Text(claim.description, style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Receipt info
          Row(
            children: [
              Icon(
                claim.hasReceipt ? Icons.check_circle : Icons.warning_amber,
                size: 14,
                color: claim.hasReceipt ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 6),
              Text(
                claim.hasReceipt ? 'Receipt attached' : 'No receipt attached',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color:
                      claim.hasReceipt ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tickets Tab
// ---------------------------------------------------------------------------
class _TicketsTab extends StatelessWidget {
  const _TicketsTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _sampleTickets.length,
      itemBuilder: (context, index) {
        final ticket = _sampleTickets[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _TicketCard(ticket: ticket),
        );
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  final _TicketItem ticket;
  const _TicketCard({required this.ticket});

  Color _priorityColor() {
    switch (ticket.priority) {
      case 'High':
        return AppColors.danger;
      case 'Medium':
        return AppColors.warning;
      case 'Low':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  IconData _priorityIcon() {
    switch (ticket.priority) {
      case 'High':
        return Icons.priority_high;
      case 'Medium':
        return Icons.remove;
      case 'Low':
        return Icons.arrow_downward;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prioColor = _priorityColor();

    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: ticket.avatarColor.withValues(alpha: 0.15),
                child: Text(
                  ticket.initials,
                  style: TextStyle(
                    color: ticket.avatarColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          ticket.employeeName,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ticket.ticketType,
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: ticket.priority,
                color: prioColor,
                icon: _priorityIcon(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(ticket.date, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            ticket.description,
            style: theme.textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              _TicketActionButton(
                icon: Icons.person_add_alt,
                label: 'Assign',
                color: AppColors.primary,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _TicketActionButton(
                icon: Icons.check_circle_outline,
                label: 'Resolve',
                color: AppColors.success,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _TicketActionButton(
                icon: Icons.arrow_upward,
                label: 'Escalate',
                color: AppColors.orange,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TicketActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TicketActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Work Type Tab
// ---------------------------------------------------------------------------
class _WorkTypeTab extends StatelessWidget {
  const _WorkTypeTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _sampleWorkType.length,
      itemBuilder: (context, index) {
        final req = _sampleWorkType[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _WorkTypeCard(request: req),
        );
      },
    );
  }
}

class _WorkTypeCard extends StatelessWidget {
  final _WorkTypeRequest request;
  const _WorkTypeCard({required this.request});

  Color _typeColor() {
    return request.workType == 'Work From Home'
        ? AppColors.primary
        : AppColors.secondary;
  }

  IconData _typeIcon() {
    return request.workType == 'Work From Home'
        ? Icons.home_work
        : Icons.swap_horiz;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _typeColor();

    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: request.avatarColor.withValues(alpha: 0.15),
                child: Text(
                  request.initials,
                  style: TextStyle(
                    color: request.avatarColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.employeeName,
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(_typeIcon(), size: 14, color: color),
                        const SizedBox(width: 4),
                        Text(
                          request.workType,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              StatusChip.pending(),
            ],
          ),
          const SizedBox(height: 14),

          // Current type -> Requested type
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  request.currentType,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward, size: 16, color: color),
                ),
                Text(
                  request.workType,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Date range
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(request.dateRange, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),

          // Reason
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.notes, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(request.reason, style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Regularization Tab
// ---------------------------------------------------------------------------
class _RegularizationTab extends StatelessWidget {
  const _RegularizationTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _sampleRegularization.length,
      itemBuilder: (context, index) {
        final req = _sampleRegularization[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _RegularizationCard(request: req),
        );
      },
    );
  }
}

class _RegularizationCard extends StatelessWidget {
  final _RegularizationRequest request;
  const _RegularizationCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: request.avatarColor.withValues(alpha: 0.15),
                child: Text(
                  request.initials,
                  style: TextStyle(
                    color: request.avatarColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.employeeName,
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 14, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(
                          'Attendance Regularization',
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              StatusChip.pending(),
            ],
          ),
          const SizedBox(height: 14),

          // Date
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(request.date, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),

          // Punch time comparison
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                // Header row
                Row(
                  children: [
                    const SizedBox(width: 80),
                    Expanded(
                      child: Text(
                        'Punch In',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Punch Out',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Original row
                Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        'Original',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        request.originalPunchIn,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: request.originalPunchIn == '--:--'
                              ? AppColors.danger
                              : (isDark
                                  ? AppColors.darkSubtext
                                  : AppColors.lightSubtext),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        request.originalPunchOut,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: request.originalPunchOut == '--:--'
                              ? AppColors.danger
                              : (isDark
                                  ? AppColors.darkSubtext
                                  : AppColors.lightSubtext),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade300,
                  ),
                ),
                // Requested row
                Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        'Requested',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        request.requestedPunchIn,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        request.requestedPunchOut,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Reason
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.notes, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(request.reason, style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
