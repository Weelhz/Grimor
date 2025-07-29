import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';

class OfflineBanner extends StatelessWidget {
  final Widget child;
  final bool showWhenOnline;

  const OfflineBanner({
    Key? key,
    required this.child,
    this.showWhenOnline = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        final shouldShow = !syncProvider.isConnected || 
                          (showWhenOnline && syncProvider.isConnected);
        
        return Column(
          children: [
            if (shouldShow) _buildBanner(context, syncProvider),
            Expanded(child: this.child),
          ],
        );
      },
    );
  }

  Widget _buildBanner(BuildContext context, SyncProvider syncProvider) {
    final isOffline = !syncProvider.isConnected;
    
    return Material(
      color: isOffline ? Colors.red : Colors.green,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Icon(
                isOffline ? Icons.cloud_off : Icons.cloud_done,
                color: Colors.white,
                size: 20,
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isOffline ? 'Offline Mode' : 'Online',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    
                    if (isOffline) ...[
                      const SizedBox(height: 2),
                      Text(
                        syncProvider.syncStatus,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              if (isOffline && syncProvider.hasPendingChanges) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${syncProvider.pendingChangesCount} pending',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
              ],
              
              if (isOffline) ...[
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () => syncProvider.reconnect(),
                  tooltip: 'Retry connection',
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Offline indicator for specific components
class OfflineIndicator extends StatelessWidget {
  final double? size;
  final Color? color;
  final String? tooltip;

  const OfflineIndicator({
    Key? key,
    this.size,
    this.color,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        if (syncProvider.isConnected) {
          return const SizedBox.shrink();
        }
        
        return Tooltip(
          message: tooltip ?? 'Offline - Changes will sync when reconnected',
          child: Icon(
            Icons.cloud_off,
            size: size ?? 16,
            color: color ?? Colors.orange,
          ),
        );
      },
    );
  }
}

// Sync status widget
class SyncStatusWidget extends StatelessWidget {
  final bool showIcon;
  final bool showText;
  final MainAxisAlignment alignment;

  const SyncStatusWidget({
    Key? key,
    this.showIcon = true,
    this.showText = true,
    this.alignment = MainAxisAlignment.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        return Row(
          mainAxisAlignment: alignment,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                syncProvider.isConnected ? Icons.cloud_done : Icons.cloud_off,
                size: 16,
                color: syncProvider.isConnected ? Colors.green : Colors.orange,
              ),
              
              if (showText) const SizedBox(width: 8),
            ],
            
            if (showText) ...[
              Text(
                syncProvider.syncStatus,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: syncProvider.isConnected ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// Pending changes indicator
class PendingChangesIndicator extends StatelessWidget {
  final bool showCount;
  final VoidCallback? onTap;

  const PendingChangesIndicator({
    Key? key,
    this.showCount = true,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        if (!syncProvider.hasPendingChanges) {
          return const SizedBox.shrink();
        }
        
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sync_problem,
                  size: 14,
                  color: Colors.orange,
                ),
                
                if (showCount) ...[
                  const SizedBox(width: 4),
                  Text(
                    '${syncProvider.pendingChangesCount}',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// Sync progress widget
class SyncProgressWidget extends StatelessWidget {
  final bool showPercentage;
  final double height;

  const SyncProgressWidget({
    Key? key,
    this.showPercentage = true,
    this.height = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        if (!syncProvider.isSyncing) {
          return const SizedBox.shrink();
        }
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showPercentage) ...[
              Text(
                '${(syncProvider.syncProgress * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 4),
            ],
            
            LinearProgressIndicator(
              value: syncProvider.syncProgress,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
              minHeight: height,
            ),
          ],
        );
      },
    );
  }
}

// Offline mode toggle
class OfflineModeToggle extends StatelessWidget {
  final String? title;
  final String? subtitle;

  const OfflineModeToggle({
    Key? key,
    this.title,
    this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        return SwitchListTile(
          title: Text(title ?? 'Offline Mode'),
          subtitle: Text(subtitle ?? 'Use cached content only'),
          value: syncProvider.isOfflineMode,
          onChanged: (value) {
            syncProvider.setOfflineMode(value);
          },
          secondary: Icon(
            syncProvider.isOfflineMode ? Icons.cloud_off : Icons.cloud_done,
            color: syncProvider.isOfflineMode ? Colors.orange : Colors.green,
          ),
        );
      },
    );
  }
}

// Connection status card
class ConnectionStatusCard extends StatelessWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onViewPending;

  const ConnectionStatusCard({
    Key? key,
    this.onRetry,
    this.onViewPending,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      syncProvider.isConnected ? Icons.cloud_done : Icons.cloud_off,
                      color: syncProvider.isConnected ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            syncProvider.isConnected ? 'Online' : 'Offline',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: syncProvider.isConnected ? Colors.green : Colors.orange,
                            ),
                          ),
                          Text(
                            syncProvider.syncStatus,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                if (syncProvider.hasPendingChanges) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sync_problem,
                          size: 20,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending Changes',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${syncProvider.pendingChangesCount} changes waiting to sync',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (onViewPending != null) ...[
                          TextButton(
                            onPressed: onViewPending,
                            child: const Text('View'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                
                if (!syncProvider.isConnected) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: onRetry ?? () => syncProvider.reconnect(),
                        child: const Text('Retry Connection'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}