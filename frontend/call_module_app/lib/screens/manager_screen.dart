import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/job_model.dart';
import '../utils/app_theme.dart';
import '../utils/app_widgets.dart';

class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key});
  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen>
    with SingleTickerProviderStateMixin {
  int _selectedNav = 0;
  List<JobModel> _jobs = [];
  List<dynamic> _techs = [];
  Map<String, dynamic> _dash = {};
  bool _loading = true;
  String _userName = '';
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadAll();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final name = await AuthService.getName();
    setState(() => _userName = name ?? '');
    try {
      final results = await Future.wait([
        ApiService.getJobs(),
        ApiService.getTechnicians(),
        ApiService.getDashboard(),
      ]);
      setState(() {
        _jobs = (results[0] as List).map((j) => JobModel.fromJson(j)).toList();
        _techs = results[1] as List;
        _dash = results[2] as Map<String, dynamic>;
      });
      _animCtrl.forward(from: 0);
    } catch (_) {
      _showSnack('Failed to load data', isError: true);
    }
    setState(() => _loading = false);
  }

  Future<void> _assignJob(int jobId) async {
    if (_techs.isEmpty) {
      _showSnack('No technicians', isError: true);
      return;
    }
    int? selectedId = _techs[0]['id'];

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 440,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.border)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.cyan.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: AppTheme.cyan,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Assign Technician',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Technician list
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: _techs.map((t) {
                      final selected = t['id'] == selectedId;
                      return GestureDetector(
                        onTap: () => setS(() => selectedId = t['id']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.cyan.withOpacity(0.06)
                                : AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.cyan.withOpacity(0.5)
                                  : AppTheme.border,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: selected
                                    ? AppTheme.cyan.withOpacity(0.15)
                                    : AppTheme.border,
                                radius: 18,
                                child: Text(
                                  (t['name'] as String)[0].toUpperCase(),
                                  style: TextStyle(
                                    color: selected
                                        ? AppTheme.cyan
                                        : AppTheme.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  t['name'],
                                  style: TextStyle(
                                    color: selected
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (selected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.cyan,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppTheme.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: const BorderSide(color: AppTheme.border),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: PrimaryButton(
                          label: 'Confirm Assignment',
                          icon: Icons.check_rounded,
                          onPressed: () async {
                            Navigator.pop(ctx);
                            try {
                              final r = await ApiService.assignJob(
                                jobId,
                                selectedId!,
                              );
                              if (r.containsKey('id')) {
                                _showSnack('Job assigned!');
                                _loadAll();
                              } else {
                                _showSnack(
                                  r['error'] ?? 'Failed',
                                  isError: true,
                                );
                              }
                            } catch (_) {
                              _showSnack('Cannot connect', isError: true);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    try {
      _showSnack('Preparing CSV export...');
      await ApiService.downloadCsv();
    } catch (_) {
      _showSnack('Export failed', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError ? AppTheme.red : AppTheme.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  // ── Dashboard view ─────────────────────────────────────────────────────────
  Widget _buildDashboard() {
    final byTech = _dash['by_technician'] as List? ?? [];
    final recentJobs = _jobs.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stat cards
              Row(
                children: [
                  StatCard(
                    label: 'Total Jobs',
                    value: '${_dash['total'] ?? 0}',
                    color: AppTheme.cyan,
                    icon: Icons.work_outline_rounded,
                  ),
                  const SizedBox(width: 16),
                  StatCard(
                    label: 'Pending',
                    value: '${_dash['pending'] ?? 0}',
                    color: AppTheme.amber,
                    icon: Icons.hourglass_empty_rounded,
                  ),
                  const SizedBox(width: 16),
                  StatCard(
                    label: 'Assigned',
                    value: '${_dash['assigned'] ?? 0}',
                    color: AppTheme.purple,
                    icon: Icons.assignment_ind_outlined,
                  ),
                  const SizedBox(width: 16),
                  StatCard(
                    label: 'Completed',
                    value: '${_dash['completed'] ?? 0}',
                    color: AppTheme.green,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Bottom row: technician workload + recent jobs
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Technician workload
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(title: 'Technician Workload'),
                          const SizedBox(height: 20),
                          if (byTech.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'No assignments yet',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            )
                          else
                            ...byTech.map((t) {
                              final count = t['job_count'] as int? ?? 0;
                              final max = byTech
                                  .map((x) => x['job_count'] as int? ?? 0)
                                  .reduce((a, b) => a > b ? a : b);
                              final pct = max == 0 ? 0.0 : count / max;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: AppTheme.cyan
                                              .withOpacity(0.1),
                                          radius: 14,
                                          child: Text(
                                            (t['technician'] as String)[0]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              color: AppTheme.cyan,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            t['technician'],
                                            style: const TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '$count jobs',
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        backgroundColor: AppTheme.border,
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                              AppTheme.cyan,
                                            ),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Recent jobs
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: SectionHeader(title: 'Recent Jobs'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _selectedNav = 1),
                                child: const Text(
                                  'View all',
                                  style: TextStyle(
                                    color: AppTheme.cyan,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (recentJobs.isEmpty)
                            const Text(
                              'No jobs yet',
                              style: TextStyle(color: AppTheme.textSecondary),
                            )
                          else
                            ...recentJobs.map(
                              (job) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            job.title,
                                            style: const TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            job.location.isNotEmpty
                                                ? job.location
                                                : 'No location',
                                            style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: StatusBadge(
                                        status: job.status,
                                        label: job.statusLabel,
                                      ),
                                    ),
                                    if (job.status != 'completed')
                                      TextButton(
                                        onPressed: () => _assignJob(job.id),
                                        child: Text(
                                          job.assignedTo != null
                                              ? 'Reassign'
                                              : 'Assign',
                                          style: const TextStyle(
                                            color: AppTheme.cyan,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Jobs table view ────────────────────────────────────────────────────────
  Widget _buildJobsTable() {
    if (_jobs.isEmpty)
      return const EmptyState(
        icon: Icons.work_outline_rounded,
        title: 'No jobs yet',
        subtitle: 'Jobs created by CS will appear here',
      );

    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: TableHeaderCell('JOB')),
                Expanded(flex: 2, child: TableHeaderCell('LOCATION')),
                Expanded(flex: 2, child: TableHeaderCell('TECHNICIAN')),
                Expanded(flex: 1, child: TableHeaderCell('STATUS')),
                Expanded(flex: 1, child: TableHeaderCell('ACTION')),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _jobs.length,
              itemBuilder: (ctx, i) {
                final job = _jobs[i];
                final isEven = i % 2 == 0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isEven ? AppTheme.surface : AppTheme.background,
                    border: const Border(
                      bottom: BorderSide(color: AppTheme.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.title,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              job.description,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          job.location.isNotEmpty ? job.location : '—',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: job.assignedTo != null
                            ? Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppTheme.cyan.withOpacity(
                                      0.1,
                                    ),
                                    radius: 13,
                                    child: Text(
                                      (job.assignedTo!['name'] as String)[0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: AppTheme.cyan,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      job.assignedTo!['name'],
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Unassigned',
                                style: TextStyle(
                                  color: AppTheme.textHint,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                      Expanded(
                        flex: 1,
                        child: StatusBadge(
                          status: job.status,
                          label: job.statusLabel,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: job.status != 'completed'
                            ? TextButton(
                                onPressed: () => _assignJob(job.id),
                                style: TextButton.styleFrom(
                                  backgroundColor: AppTheme.cyan.withOpacity(
                                    0.08,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                child: Text(
                                  job.assignedTo != null
                                      ? 'Reassign'
                                      : 'Assign',
                                  style: const TextStyle(
                                    color: AppTheme.cyan,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            : const Text(
                                '—',
                                style: TextStyle(color: AppTheme.textHint),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // ── Sidebar ─────────────────────────────────────────────────────────
          AppSidebar(
            userName: _userName,
            role: 'Manager',
            roleIcon: Icons.admin_panel_settings_outlined,
            accentColor: AppTheme.purple,
            items: [
              SidebarItem(
                icon: Icons.dashboard_outlined,
                label: 'Overview',
                selected: _selectedNav == 0,
                onTap: () => setState(() => _selectedNav = 0),
              ),
              SidebarItem(
                icon: Icons.work_outline_rounded,
                label: 'All Jobs',
                selected: _selectedNav == 1,
                onTap: () => setState(() => _selectedNav = 1),
              ),
            ],
          ),

          // ── Main content ────────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                AppTopBar(
                  title: _selectedNav == 0 ? 'Overview' : 'All Jobs',
                  subtitle: _selectedNav == 0
                      ? 'Dashboard summary and technician workload'
                      : 'Manage and assign all field jobs',
                  actions: [
                    AppTopBarButton(
                      icon: Icons.download_rounded,
                      label: 'Export CSV',
                      onPressed: _exportCsv,
                    ),
                    const SizedBox(width: 10),
                    AppTopBarButton(
                      icon: Icons.refresh_rounded,
                      label: 'Refresh',
                      onPressed: _loadAll,
                    ),
                  ],
                ),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.cyan,
                          ),
                        )
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _selectedNav == 0
                              ? _buildDashboard()
                              : _buildJobsTable(),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
