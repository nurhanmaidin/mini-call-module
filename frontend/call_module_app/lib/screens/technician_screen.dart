import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/job_model.dart';
import '../utils/app_theme.dart';
import '../utils/app_widgets.dart';

class TechnicianScreen extends StatefulWidget {
  const TechnicianScreen({super.key});
  @override
  State<TechnicianScreen> createState() => _TechnicianScreenState();
}

class _TechnicianScreenState extends State<TechnicianScreen>
    with SingleTickerProviderStateMixin {
  List<JobModel> _jobs = [];
  bool _loading = true;
  String _userName = '';
  JobModel? _selected;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final name = await AuthService.getName();
    setState(() => _userName = name ?? '');
    await _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getJobs();
      setState(() {
        _jobs = data.map((j) => JobModel.fromJson(j)).toList();
        if (_jobs.isNotEmpty) _selected = _jobs.first;
      });
      _animCtrl.forward(from: 0);
    } catch (_) {
      _showSnack('Failed to load jobs', isError: true);
    }
    setState(() => _loading = false);
  }

  Future<void> _updateStatus(JobModel job) async {
    if (job.nextStatus == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 380,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.statusColor(
                    job.nextStatus!,
                  ).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.statusColor(
                      job.nextStatus!,
                    ).withOpacity(0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.update_rounded,
                      color: AppTheme.statusColor(job.nextStatus!),
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Update to',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          job.nextStatusLabel ?? '',
                          style: TextStyle(
                            color: AppTheme.statusColor(job.nextStatus!),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                job.title,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
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
                    child: PrimaryButton(
                      label: 'Confirm',
                      color: AppTheme.statusColor(job.nextStatus!),
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;
    try {
      final result = await ApiService.updateStatus(job.id, job.nextStatus!);
      if (result.containsKey('id')) {
        _showSnack('Status updated successfully!');
        await _loadJobs();
        // Keep selection on the same job
        setState(() {
          _selected = _jobs.firstWhere(
            (j) => j.id == job.id,
            orElse: () => _jobs.first,
          );
        });
      } else {
        _showSnack(result['error'] ?? 'Failed', isError: true);
      }
    } catch (_) {
      _showSnack('Cannot connect', isError: true);
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

  Widget _buildProgressSteps(JobModel job) {
    final steps = [
      ('assigned', 'Assigned', Icons.assignment_ind_outlined),
      ('on_the_way', 'On The Way', Icons.directions_car_outlined),
      ('on_site', 'On Site', Icons.location_on_outlined),
      ('completed', 'Completed', Icons.check_circle_outline_rounded),
    ];
    final currentIdx = steps.indexWhere((s) => s.$1 == job.status);

    return Row(
      children: steps.asMap().entries.map((e) {
        final idx = e.key;
        final step = e.value;
        final done = idx <= currentIdx;
        final color = AppTheme.statusColor(job.status);
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: done
                            ? color.withOpacity(0.1)
                            : AppTheme.surfaceLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: done ? color : AppTheme.border,
                          width: done ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        step.$3,
                        size: 18,
                        color: done ? color : AppTheme.textHint,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      step.$2,
                      style: TextStyle(
                        fontSize: 10,
                        color: done ? color : AppTheme.textHint,
                        fontWeight: done ? FontWeight.w700 : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (idx < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    color: idx < currentIdx ? color : AppTheme.border,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _jobs.where((j) => j.status != 'completed').toList();
    final completed = _jobs.where((j) => j.status == 'completed').toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // ── Sidebar ─────────────────────────────────────────────────────────
          AppSidebar(
            userName: _userName,
            role: 'Technician',
            roleIcon: Icons.engineering_rounded,
            accentColor: AppTheme.green,
            items: [
              SidebarItem(
                icon: Icons.work_outline_rounded,
                label: 'My Jobs',
                selected: true,
              ),
            ],
            bottomWidget: _jobs.isEmpty
                ? null
                : Column(
                    children: [
                      Container(height: 1, color: AppTheme.border),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _statPill(
                              'Active',
                              '${active.length}',
                              AppTheme.cyan,
                            ),
                            const SizedBox(width: 8),
                            _statPill(
                              'Done',
                              '${completed.length}',
                              AppTheme.green,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),

          // ── Job list panel ───────────────────────────────────────────────────
          Container(
            width: 320,
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(right: BorderSide(color: AppTheme.border)),
            ),
            child: Column(
              children: [
                // Panel header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.border)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'My Jobs',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                        onPressed: _loadJobs,
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                ),
                // Job list
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.cyan,
                          ),
                        )
                      : _jobs.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No jobs assigned yet',
                              style: TextStyle(color: AppTheme.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView(
                          children: [
                            if (active.isNotEmpty) ...[
                              _listSectionLabel('Active (${active.length})'),
                              ...active.map((job) => _jobListTile(job)),
                            ],
                            if (completed.isNotEmpty) ...[
                              _listSectionLabel(
                                'Completed (${completed.length})',
                              ),
                              ...completed.map((job) => _jobListTile(job)),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),

          // ── Detail panel ────────────────────────────────────────────────────
          Expanded(
            child: _selected == null
                ? const Center(
                    child: EmptyState(
                      icon: Icons.touch_app_outlined,
                      title: 'Select a job',
                      subtitle: 'Click on a job from the list to see details',
                    ),
                  )
                : _buildDetailPanel(_selected!),
          ),
        ],
      ),
    );
  }

  Widget _listSectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
    child: Text(
      text,
      style: const TextStyle(
        color: AppTheme.textHint,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    ),
  );

  Widget _jobListTile(JobModel job) {
    final isSelected = _selected?.id == job.id;
    final color = AppTheme.statusColor(job.status);
    return GestureDetector(
      onTap: () => setState(() => _selected = job),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.cyan.withOpacity(0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.cyan.withOpacity(0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  StatusBadge(status: job.status, label: job.statusLabel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPanel(JobModel job) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(status: job.status, label: job.statusLabel),
                  ],
                ),
              ),
              // Action button
              if (job.nextStatusLabel != null)
                ElevatedButton.icon(
                  onPressed: () => _updateStatus(job),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(job.nextStatusLabel!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.statusColor(job.status),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),

          // Progress tracker
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Progress'),
                const SizedBox(height: 20),
                _buildProgressSteps(job),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Job details
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Job Details'),
                const SizedBox(height: 20),
                _detailRow(
                  Icons.description_outlined,
                  'Description',
                  job.description,
                ),
                const SizedBox(height: 16),
                _detailRow(
                  Icons.location_on_outlined,
                  'Location',
                  job.location.isNotEmpty ? job.location : 'Not specified',
                ),
                if (job.latitude != null) ...[
                  const SizedBox(height: 16),
                  _detailRow(
                    Icons.gps_fixed,
                    'GPS Coordinates',
                    '${job.latitude!.toStringAsFixed(6)}, ${job.longitude!.toStringAsFixed(6)}',
                  ),
                ],
                const SizedBox(height: 16),
                _detailRow(
                  Icons.calendar_today_outlined,
                  'Created',
                  job.createdAt != null
                      ? job.createdAt!.substring(0, 16).replaceAll('T', ' ')
                      : '—',
                ),
                if (job.assignedAt != null) ...[
                  const SizedBox(height: 16),
                  _detailRow(
                    Icons.assignment_turned_in_outlined,
                    'Assigned',
                    job.assignedAt!.substring(0, 16).replaceAll('T', ' '),
                  ),
                ],
                if (job.completedAt != null) ...[
                  const SizedBox(height: 16),
                  _detailRow(
                    Icons.check_circle_outline_rounded,
                    'Completed',
                    job.completedAt!.substring(0, 16).replaceAll('T', ' '),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textHint),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
