enum SyncState { idle, loading, success, failed, offline }

extension SyncStateLabel on SyncState {
  String get label {
    switch (this) {
      case SyncState.loading:
        return 'Syncing';
      case SyncState.success:
        return 'Synced';
      case SyncState.failed:
        return 'Sync Failed';
      case SyncState.offline:
        return 'Pending Sync';
      case SyncState.idle:
        return 'Ready';
    }
  }
}
