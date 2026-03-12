import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';
import 'employee_profile_view.dart';

class TeamDirectoryScreen extends StatefulWidget {
  const TeamDirectoryScreen({super.key});

  @override
  State<TeamDirectoryScreen> createState() => _TeamDirectoryScreenState();
}

class _TeamDirectoryScreenState extends State<TeamDirectoryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredTeams = _allTeams.map((team) {
      if (_searchQuery.isEmpty) return team;
      final filtered = team.members
          .where((m) =>
              m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              m.jobTitle.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
      return _Team(name: team.name, members: filtered);
    }).where((team) => team.members.isNotEmpty).toList();

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: NeuCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search team members...',
                hintStyle: TextStyle(
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                icon: Icon(
                  Icons.search,
                  color:
                      isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Team Sections
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: filteredTeams.length,
            itemBuilder: (context, index) {
              final team = filteredTeams[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _TeamSection(team: team),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Data Models & Sample Data
// ---------------------------------------------------------------------------
enum _OnlineStatus { online, offline, away }

class _MemberData {
  final String name;
  final String initials;
  final Color avatarColor;
  final String jobTitle;
  final _OnlineStatus status;

  const _MemberData({
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.jobTitle,
    required this.status,
  });
}

class _Team {
  final String name;
  final List<_MemberData> members;

  const _Team({required this.name, required this.members});
}

const _allTeams = [
  _Team(
    name: 'Frontend Team',
    members: [
      _MemberData(
        name: 'Priya Sharma',
        initials: 'PS',
        avatarColor: AppColors.primary,
        jobTitle: 'Senior Frontend Developer',
        status: _OnlineStatus.online,
      ),
      _MemberData(
        name: 'Karan Mehta',
        initials: 'KM',
        avatarColor: AppColors.success,
        jobTitle: 'Frontend Developer',
        status: _OnlineStatus.online,
      ),
      _MemberData(
        name: 'Neha Gupta',
        initials: 'NG',
        avatarColor: AppColors.danger,
        jobTitle: 'UI Developer',
        status: _OnlineStatus.away,
      ),
    ],
  ),
  _Team(
    name: 'Backend Team',
    members: [
      _MemberData(
        name: 'Rahul Verma',
        initials: 'RV',
        avatarColor: AppColors.secondary,
        jobTitle: 'Senior Backend Developer',
        status: _OnlineStatus.online,
      ),
      _MemberData(
        name: 'Vikram Singh',
        initials: 'VS',
        avatarColor: AppColors.primaryDark,
        jobTitle: 'Backend Developer',
        status: _OnlineStatus.offline,
      ),
      _MemberData(
        name: 'Amit Joshi',
        initials: 'AJ',
        avatarColor: AppColors.warning,
        jobTitle: 'DevOps Engineer',
        status: _OnlineStatus.online,
      ),
    ],
  ),
  _Team(
    name: 'QA Team',
    members: [
      _MemberData(
        name: 'Anita Desai',
        initials: 'AD',
        avatarColor: AppColors.orange,
        jobTitle: 'QA Lead',
        status: _OnlineStatus.online,
      ),
      _MemberData(
        name: 'Sneha Patel',
        initials: 'SP',
        avatarColor: AppColors.pink,
        jobTitle: 'QA Engineer',
        status: _OnlineStatus.away,
      ),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Team Section
// ---------------------------------------------------------------------------
class _TeamSection extends StatelessWidget {
  final _Team team;
  const _TeamSection({required this.team});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Text(team.name, style: theme.textTheme.titleMedium),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${team.members.length}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        NeuCard(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          child: Column(
            children: List.generate(team.members.length, (index) {
              final member = team.members[index];
              return Column(
                children: [
                  if (index > 0)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                  _MemberRow(member: member),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Member Row
// ---------------------------------------------------------------------------
class _MemberRow extends StatelessWidget {
  final _MemberData member;
  const _MemberRow({required this.member});

  Color _statusIndicatorColor() {
    switch (member.status) {
      case _OnlineStatus.online:
        return AppColors.success;
      case _OnlineStatus.away:
        return AppColors.warning;
      case _OnlineStatus.offline:
        return Colors.grey;
    }
  }

  String _statusLabel() {
    switch (member.status) {
      case _OnlineStatus.online:
        return 'Online';
      case _OnlineStatus.away:
        return 'Away';
      case _OnlineStatus.offline:
        return 'Offline';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmployeeProfileView(
              name: member.name,
              initials: member.initials,
              avatarColor: member.avatarColor,
              jobTitle: member.jobTitle,
              department: _getDepartment(member),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar with status indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      member.avatarColor.withValues(alpha: 0.15),
                  child: Text(
                    member.initials,
                    style: TextStyle(
                      color: member.avatarColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _statusIndicatorColor(),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.cardColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Name and role
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(member.jobTitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),

            // Status label
            Text(
              _statusLabel(),
              style: TextStyle(
                color: _statusIndicatorColor(),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  String _getDepartment(_MemberData member) {
    for (final team in _allTeams) {
      if (team.members.contains(member)) {
        return team.name;
      }
    }
    return 'Engineering';
  }
}
