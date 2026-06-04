import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/sync/sync_controller.dart';
import '../../features/sync/sync_status.dart';
import '../../shared/layout/main_scaffold.dart';
import '../../shared/widgets/app_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final syncState = ref.watch(syncControllerProvider);
    final lastSync = ref.watch(lastSyncAtProvider);

    return MainScaffold(
      currentIndex: 2,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
          children: [
            const Center(
              child: Text(
                'Settings',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 24),
            _Card(
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.iconSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.person_outline_rounded),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.user?.name ?? 'Yumon User',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auth.user?.email ?? '-',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sync',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Status: ${syncState.label}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastSync.when(
                      data: (value) => value == null
                          ? 'Last sync: Never'
                          : 'Last sync: ${DateFormatter.dateTime(value)}',
                      loading: () => 'Last sync: Checking...',
                      error: (_, _) => 'Last sync: Unknown',
                    ),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Sync Now',
                    icon: Icons.sync_rounded,
                    isLoading: syncState == SyncState.loading,
                    onPressed: () =>
                        ref.read(syncControllerProvider.notifier).syncNow(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Yumon', style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 6),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'Logout',
              icon: Icons.logout_rounded,
              isDanger: true,
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}
