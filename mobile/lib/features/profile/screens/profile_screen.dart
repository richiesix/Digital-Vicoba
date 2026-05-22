import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/network/media_url.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/language_picker_sheet.dart';
import '../../../l10n/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _voiceOn = true;
  bool _biometricOn = false;
  int _pendingSync = 0;
  String? _phone;
  String? _groupName;
  String? _profilePhotoUrl;
  double _savings = 0;
  int _shares = 0;
  bool _loading = true;
  bool _uploadingPhoto = false;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final session = ref.read(authSessionProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    setState(() {
      _voiceOn = prefs.getBool('voice_enabled') ?? true;
      _biometricOn = prefs.getBool('biometric_enabled') ?? false;
    });

    _pendingSync = await ref.read(syncServiceProvider).pendingCount();

    if (session?.groupId != null) {
      try {
        final api = ref.read(apiClientProvider);
        final dash = await api.get('/dashboard', queryParameters: {
          'group_id': session!.groupId,
        });
        final w = dash.data['widgets'] as Map<String, dynamic>?;
        var groupName = w?['group_name'] as String?;
        if (groupName == null) {
          final gRes = await api.get('/groups/${session.groupId}');
          final g = gRes.data['group'] as Map<String, dynamic>?;
          groupName = g?['name'] as String?;
        }
        setState(() {
          _groupName = groupName;
          _savings = (w?['current_savings'] as num?)?.toDouble() ??
              (w?['savings_total'] as num?)?.toDouble() ??
              0;
          _shares = (w?['total_shares'] as num?)?.toInt() ?? 0;
        });
      } catch (_) {}
    }

    try {
      final me = await ref.read(apiClientProvider).get('/auth/me');
      final user = me.data['user'] as Map<String, dynamic>?;
      _phone = user?['phone_number'] as String?;
      _profilePhotoUrl = user?['profile_photo_url'] as String?;
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _showPhotoOptions() async {
    final l10n = context.l10n;
    final hasPhoto = _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty;

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.uploadFromGallery),
              onTap: () {
                Navigator.pop(ctx);
                _uploadPhoto(ImageSource.gallery);
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.takePhoto),
                onTap: () {
                  Navigator.pop(ctx);
                  _uploadPhoto(ImageSource.camera);
                },
              ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.overdue),
                title: Text(
                  l10n.removeProfilePhoto,
                  style: const TextStyle(color: AppColors.overdue),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _removePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  String _mimeFromFilename(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<({Uint8List bytes, String filename, String mime})?> _pickImageBytes(
    ImageSource source,
  ) async {
    if (kIsWeb) {
      if (source == ImageSource.camera) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.cameraNotAvailableOnWeb)),
          );
        }
        return null;
      }
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return null;
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) return null;
      final name = file.name.isNotEmpty
          ? file.name
          : 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      return (bytes: bytes, filename: name, mime: _mimeFromFilename(name));
    }

    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return null;
    final mime = picked.mimeType ?? 'image/jpeg';
    var filename = picked.name;
    if (filename.isEmpty || !filename.contains('.')) {
      final ext = mime.contains('png')
          ? 'png'
          : mime.contains('webp')
              ? 'webp'
              : 'jpg';
      filename = 'profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
    }
    return (bytes: await picked.readAsBytes(), filename: filename, mime: mime);
  }

  Future<void> _uploadPhoto(ImageSource source) async {
    try {
      final picked = await _pickImageBytes(source);
      if (picked == null || !mounted) return;

      setState(() => _uploadingPhoto = true);
      HapticFeedback.lightImpact();

      final bytes = picked.bytes;
      final mime = picked.mime;
      final filename = picked.filename;

      final formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(mime),
        ),
      });

      final res = await ref.read(apiClientProvider).postMultipart(
        '/auth/profile/photo',
        formData: formData,
      );

      if (!mounted) return;
      setState(() {
        _profilePhotoUrl = res.data['profile_photo_url'] as String?;
        _uploadingPhoto = false;
      });
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.profilePhotoUpdated),
          backgroundColor: AppColors.savings,
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      final data = e.response?.data;
      String message = context.l10n.profilePhotoUploadFailed;
      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      } else if (data is Map && data['errors'] is Map) {
        final errors = data['errors'] as Map;
        final photo = errors['photo'];
        if (photo is List && photo.isNotEmpty) {
          message = photo.first.toString();
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.overdue,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.profilePhotoUploadFailed}: $e'),
          backgroundColor: AppColors.overdue,
        ),
      );
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _uploadingPhoto = true);
    try {
      await ref.read(apiClientProvider).delete('/auth/profile/photo');
      if (!mounted) return;
      setState(() {
        _profilePhotoUrl = null;
        _uploadingPhoto = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profilePhotoRemoved)),
      );
    } catch (_) {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  List<Color> _headerGradient(AuthSession? session) {
    if (session?.isChairperson == true) {
      return [const Color(0xFF1B5E20), const Color(0xFF33691E)];
    }
    if (session?.isTreasurer == true) {
      return [const Color(0xFF2E7D32), const Color(0xFF43A047)];
    }
    return [const Color(0xFF388E3C), const Color(0xFF66BB6A)];
  }

  String _roleLabel(AppLocalizations l10n, String? role) => switch (role) {
        'treasurer' => l10n.roleTreasurer,
        'member' => l10n.roleMember,
        'provisional_chair' => l10n.roleProvisionalChair,
        'chairperson' => l10n.roleChairperson,
        'secretary' => l10n.roleSecretary,
        'money_counter' => l10n.roleMoneyCounter,
        'key_holder' => l10n.roleKeyHolder,
        _ => role ?? l10n.roleMember,
      };

  IconData _roleIcon(String? role) => switch (role) {
        'treasurer' => Icons.account_balance,
        'provisional_chair' => Icons.hourglass_top,
        'chairperson' => Icons.star,
        'secretary' => Icons.description,
        'money_counter' => Icons.payments,
        'key_holder' => Icons.key,
        _ => Icons.person,
      };

  Future<void> _toggleVoice(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('voice_enabled', value);
    setState(() => _voiceOn = value);
    HapticFeedback.lightImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value ? context.l10n.voiceEnabled : context.l10n.voiceDisabled)),
    );
  }

  Future<void> _toggleBiometric(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('biometric_enabled', value);
    setState(() => _biometricOn = value);
    HapticFeedback.lightImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? context.l10n.biometricEnabled : context.l10n.biometricDisabled),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.logout, color: AppColors.overdue, size: 40),
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.overdue),
            child: Text(l10n.confirmLogout),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(apiClientProvider).clearTokens();
      await ref.read(authSessionProvider.notifier).clear();
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(authSessionProvider);
    final locale = ref.watch(localeProvider);
    final languageLabel = locale.languageCode == 'en' ? l10n.english : l10n.swahili;
    final localeCode = locale.languageCode;
    final currency = NumberFormat.currency(
      locale: localeCode == 'en' ? 'en_TZ' : 'sw_TZ',
      symbol: 'TZS ',
      decimalDigits: 0,
    );

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: _loadProfileData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _ProfileHeader(
              name: session?.userName ?? l10n.user,
              roleLabel: _roleLabel(l10n, session?.primaryRole),
              roleIcon: _roleIcon(session?.primaryRole),
              phone: _phone,
              groupName: _groupName,
              memberId: session?.memberId,
              profilePhotoUrl: _profilePhotoUrl,
              isUploadingPhoto: _uploadingPhoto,
              onPhotoTap: _showPhotoOptions,
              gradient: _headerGradient(session),
              l10n: l10n,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (session != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _StatChip(
                            icon: Icons.savings,
                            label: l10n.mySavings,
                            value: currency.format(_savings),
                            color: AppColors.savings,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatChip(
                            icon: Icons.pie_chart,
                            label: l10n.shares,
                            value: '$_shares',
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    l10n.accountSettings,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    icon: Icons.language,
                    iconColor: const Color(0xFF1565C0),
                    title: l10n.language,
                    subtitle: languageLabel,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => LanguagePickerSheet.show(context),
                  ),
                  _SettingsCard(
                    icon: Icons.sync,
                    iconColor: AppColors.pending,
                    title: l10n.syncStatus,
                    subtitle: _pendingSync > 0
                        ? l10n.pendingSyncCount(_pendingSync)
                        : l10n.allSynced,
                    trailing: _pendingSync > 0
                        ? CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.pending,
                            child: Text(
                              '$_pendingSync',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          )
                        : const Icon(Icons.check_circle, color: AppColors.savings),
                    onTap: () async {
                      await context.push(AppRoutes.sync);
                      _loadProfileData();
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.preferences,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    icon: Icons.volume_up,
                    iconColor: AppColors.savings,
                    title: l10n.voiceSwahili,
                    trailing: Switch(
                      value: _voiceOn,
                      onChanged: _toggleVoice,
                    ),
                  ),
                  _SettingsCard(
                    icon: Icons.fingerprint,
                    iconColor: AppColors.primary,
                    title: l10n.biometric,
                    trailing: Switch(
                      value: _biometricOn,
                      onChanged: _toggleBiometric,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.securityPrivacy,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    icon: Icons.help_outline,
                    iconColor: Colors.blueGrey,
                    title: l10n.helpSupport,
                    subtitle: l10n.digitalVicobaMember,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('support@vikoba.tz')),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  OutlinedButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout, color: AppColors.overdue),
                    label: Text(
                      l10n.logout,
                      style: const TextStyle(
                        color: AppColors.overdue,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      side: const BorderSide(color: AppColors.overdue, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends ConsumerStatefulWidget {
  const _ProfileAvatar({
    required this.photoUrl,
    required this.roleIcon,
    required this.radius,
  });

  final String? photoUrl;
  final IconData roleIcon;
  final double radius;

  @override
  ConsumerState<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends ConsumerState<_ProfileAvatar> {
  Map<String, String>? _authHeaders;

  @override
  void initState() {
    super.initState();
    _loadHeaders();
  }

  @override
  void didUpdateWidget(covariant _ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl) {
      _loadHeaders();
    }
  }

  Future<void> _loadHeaders() async {
    final headers = await ref.read(apiClientProvider).profilePhotoHeaders();
    if (mounted) setState(() => _authHeaders = headers);
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveProfilePhotoUrl(widget.photoUrl);
    final hasAuth = _authHeaders != null && _authHeaders!.isNotEmpty;

    if (resolved != null && hasAuth) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: Colors.white.withValues(alpha: 0.25),
        child: ClipOval(
          child: CachedNetworkImage(
            key: ValueKey('${resolved}_${widget.photoUrl}'),
            imageUrl: resolved,
            httpHeaders: _authHeaders,
            width: widget.radius * 2,
            height: widget.radius * 2,
            fit: BoxFit.cover,
            placeholder: (_, _) => Icon(widget.roleIcon, size: widget.radius, color: Colors.white),
            errorWidget: (_, _, _) => Icon(widget.roleIcon, size: widget.radius, color: Colors.white),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: Colors.white.withValues(alpha: 0.25),
      child: Icon(widget.roleIcon, size: widget.radius, color: Colors.white),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.roleLabel,
    required this.roleIcon,
    required this.gradient,
    required this.l10n,
    required this.onPhotoTap,
    this.phone,
    this.groupName,
    this.memberId,
    this.profilePhotoUrl,
    this.isUploadingPhoto = false,
  });

  final String name;
  final String roleLabel;
  final IconData roleIcon;
  final String? phone;
  final String? groupName;
  final int? memberId;
  final String? profilePhotoUrl;
  final bool isUploadingPhoto;
  final VoidCallback onPhotoTap;
  final List<Color> gradient;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            children: [
              Text(
                l10n.profile,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: isUploadingPhoto ? null : onPhotoTap,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: _ProfileAvatar(
                        photoUrl: profilePhotoUrl,
                        roleIcon: roleIcon,
                        radius: 44,
                      ),
                    ),
                    if (isUploadingPhoto)
                      const Positioned.fill(
                        child: Center(
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.changeProfilePhoto,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(roleIcon, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      roleLabel,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (groupName != null) ...[
                const SizedBox(height: 10),
                Text(
                  groupName!,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                ),
              ],
              if (phone != null) ...[
                const SizedBox(height: 4),
                Text(
                  phone!,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                ),
              ],
              if (memberId != null) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.memberIdLabel('#$memberId'),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  Text(
                    value,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
