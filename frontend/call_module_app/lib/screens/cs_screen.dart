import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/job_model.dart';
import '../utils/app_theme.dart';
import '../utils/app_widgets.dart';

class CsScreen extends StatefulWidget {
  const CsScreen({super.key});
  @override
  State<CsScreen> createState() => _CsScreenState();
}

class _CsScreenState extends State<CsScreen>
    with SingleTickerProviderStateMixin {
  List<JobModel> _jobs = [];
  bool _loading = true;
  String _userName = '';
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  File? _selectedPhoto;
  double? _latitude;
  double? _longitude;
  bool _gpsLoading = false;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _listAnimCtrl;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _listAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadData();
  }

  @override
  void dispose() {
    _listAnimCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
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
      });
      _listAnimCtrl.forward(from: 0);
    } catch (_) {
      _showSnack('Failed to load jobs', isError: true);
    }
    setState(() => _loading = false);
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
    );
    if (picked != null) setState(() => _selectedPhoto = File(picked.path));
  }

  Future<void> _getGps() async {
    setState(() => _gpsLoading = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _showSnack('GPS permission denied', isError: true);
        setState(() => _gpsLoading = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _gpsLoading = false;
      });
    } catch (_) {
      _showSnack('Failed to get GPS', isError: true);
      setState(() => _gpsLoading = false);
    }
  }

  Future<void> _createJob() async {
    if (_titleCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      _showSnack('Title and description are required', isError: true);
      return;
    }
    try {
      final result = await ApiService.createJob(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );
      if (result.containsKey('id')) {
        if (_selectedPhoto != null) {
          await ApiService.uploadPhoto(result['id'], _selectedPhoto!);
        }
        _titleCtrl.clear();
        _descCtrl.clear();
        _locationCtrl.clear();
        setState(() {
          _selectedPhoto = null;
          _latitude = null;
          _longitude = null;
        });
        if (!mounted) return;
        Navigator.pop(context);
        _showSnack('Job created successfully!');
        _loadJobs();
      } else {
        _showSnack(result['error'] ?? 'Failed to create job', isError: true);
      }
    } catch (_) {
      _showSnack('Cannot connect to server', isError: true);
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCreateDialog() {
    setState(() {
      _selectedPhoto = null;
      _latitude = null;
      _longitude = null;
      _titleCtrl.clear();
      _descCtrl.clear();
      _locationCtrl.clear();
    });
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 560,
            constraints: const BoxConstraints(maxHeight: 700),
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
                // Dialog header
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 24, 20, 20),
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
                          Icons.add_task_rounded,
                          color: AppTheme.cyan,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Create New Job',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                // Form body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _dialogLabel('Job Title *'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _titleCtrl,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'e.g. Fix generator at Site A',
                          ),
                        ),
                        const SizedBox(height: 20),

                        _dialogLabel('Description *'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descCtrl,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                          ),
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Describe the issue in detail...',
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _dialogLabel('Location Address'),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _locationCtrl,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 14,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'e.g. Jalan Ampang, KL',
                                      prefixIcon: Icon(
                                        Icons.location_on_outlined,
                                        color: AppTheme.textHint,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _dialogLabel('GPS'),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () async {
                                    await _getGps();
                                    setS(() {});
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _latitude != null
                                          ? AppTheme.green.withOpacity(0.06)
                                          : AppTheme.surfaceLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _latitude != null
                                            ? AppTheme.green.withOpacity(0.4)
                                            : AppTheme.border,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        _gpsLoading
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: AppTheme.cyan,
                                                    ),
                                              )
                                            : Icon(
                                                _latitude != null
                                                    ? Icons.gps_fixed
                                                    : Icons.gps_not_fixed,
                                                color: _latitude != null
                                                    ? AppTheme.green
                                                    : AppTheme.textHint,
                                                size: 18,
                                              ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _latitude != null
                                              ? 'Captured'
                                              : 'Get GPS',
                                          style: TextStyle(
                                            color: _latitude != null
                                                ? AppTheme.green
                                                : AppTheme.textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
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

                        if (_latitude != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.green.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 13,
                                  color: AppTheme.green,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                                  style: const TextStyle(
                                    color: AppTheme.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),
                        _dialogLabel('Attach Photo (optional)'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            await _pickPhoto();
                            setS(() {});
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: _selectedPhoto != null ? 180 : 90,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedPhoto != null
                                    ? AppTheme.cyan.withOpacity(0.4)
                                    : AppTheme.border,
                              ),
                            ),
                            child: _selectedPhoto != null
                                ? Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _selectedPhoto!,
                                          width: double.infinity,
                                          height: 180,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: GestureDetector(
                                          onTap: () =>
                                              setS(() => _selectedPhoto = null),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: AppTheme.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.add_photo_alternate_outlined,
                                        color: AppTheme.textHint,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Click to browse photo',
                                        style: TextStyle(
                                          color: AppTheme.textHint,
                                          fontSize: 13,
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

                // Footer buttons
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                          label: 'Create Job',
                          icon: Icons.check_rounded,
                          onPressed: _createJob,
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

  Widget _dialogLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: AppTheme.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  );

  List<JobModel> get _filteredJobs => _filterStatus == 'all'
      ? _jobs
      : _jobs.where((j) => j.status == _filterStatus).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────────────
          AppSidebar(
            userName: _userName,
            role: 'Customer Service',
            roleIcon: Icons.support_agent_rounded,
            accentColor: AppTheme.cyan,
            items: const [
              SidebarItem(
                icon: Icons.work_outline_rounded,
                label: 'Jobs',
                selected: true,
              ),
            ],
          ),

          // ── Main content ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top bar
                AppTopBar(
                  title: 'Job Management',
                  subtitle: 'View and create field service jobs',
                  actions: [
                    AppTopBarButton(
                      icon: Icons.refresh_rounded,
                      label: 'Refresh',
                      onPressed: _loadJobs,
                    ),
                    const SizedBox(width: 10),
                    AppTopBarButton(
                      icon: Icons.add_rounded,
                      label: 'New Job',
                      onPressed: _showCreateDialog,
                      primary: true,
                    ),
                  ],
                ),

                // Filter chips
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Row(
                    children: [
                      _filterChip('all', 'All Jobs'),
                      _filterChip('pending', 'Pending'),
                      _filterChip('assigned', 'Assigned'),
                      _filterChip('on_the_way', 'On The Way'),
                      _filterChip('on_site', 'On Site'),
                      _filterChip('completed', 'Completed'),
                    ],
                  ),
                ),

                // Jobs table
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.cyan,
                          ),
                        )
                      : _filteredJobs.isEmpty
                      ? const EmptyState(
                          icon: Icons.work_outline_rounded,
                          title: 'No jobs found',
                          subtitle:
                              'Create your first job using the button above',
                        )
                      : _buildTable(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _filterStatus == value;
    final color = value == 'all' ? AppTheme.cyan : AppTheme.statusColor(value);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filterStatus = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.1) : AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color.withOpacity(0.5) : AppTheme.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? color : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: TableHeaderCell('JOB TITLE')),
                Expanded(flex: 2, child: TableHeaderCell('LOCATION')),
                Expanded(flex: 2, child: TableHeaderCell('ASSIGNED TO')),
                Expanded(flex: 1, child: TableHeaderCell('STATUS')),
                Expanded(flex: 1, child: TableHeaderCell('DATE')),
              ],
            ),
          ),
          // Table rows
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadJobs,
              color: AppTheme.cyan,
              child: ListView.builder(
                itemCount: _filteredJobs.length,
                itemBuilder: (ctx, i) {
                  final job = _filteredJobs[i];
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
                              if (job.description.isNotEmpty)
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
                                      backgroundColor: AppTheme.cyan
                                          .withOpacity(0.1),
                                      radius: 12,
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
                                  '—',
                                  style: TextStyle(color: AppTheme.textHint),
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
                          child: Text(
                            job.createdAt != null
                                ? job.createdAt!.substring(0, 10)
                                : '—',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
