import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/sync_provider.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // User section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.user;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            user?.username.substring(0, 1).toUpperCase() ?? '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.username ?? 'Unknown',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            if (user?.fullName != null)
                              Text(
                                user!.fullName!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Appearance settings
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                
                Consumer<SettingsProvider>(
                  builder: (context, settingsProvider, child) {
                    return SwitchListTile(
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Use dark theme'),
                      value: settingsProvider.isDarkMode,
                      onChanged: (value) {
                        settingsProvider.isDarkMode = value;
                      },
                    );
                  },
                ),
                
                Consumer<SettingsProvider>(
                  builder: (context, settingsProvider, child) {
                    return SwitchListTile(
                      title: const Text('Dynamic Background'),
                      subtitle: const Text('Change background based on mood'),
                      value: settingsProvider.dynamicBackground,
                      onChanged: (value) {
                        settingsProvider.dynamicBackground = value;
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Audio settings
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audio',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                
                Consumer<SettingsProvider>(
                  builder: (context, settingsProvider, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Music Volume: ${settingsProvider.musicVolume}%'),
                        Slider(
                          value: settingsProvider.musicVolume.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 100,
                          onChanged: (value) {
                            settingsProvider.musicVolume = value.toInt();
                          },
                        ),
                      ],
                    );
                  },
                ),
                
                Consumer<SettingsProvider>(
                  builder: (context, settingsProvider, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mood Sensitivity: ${settingsProvider.moodSensitivity.toStringAsFixed(1)}x'),
                        Slider(
                          value: settingsProvider.moodSensitivity,
                          min: 0.1,
                          max: 2.0,
                          divisions: 19,
                          onChanged: (value) {
                            settingsProvider.moodSensitivity = value;
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Sync settings
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sync & Storage',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                
                Consumer<SyncProvider>(
                  builder: (context, syncProvider, child) {
                    return ListTile(
                      title: const Text('Sync Status'),
                      subtitle: Text(syncProvider.syncStatus),
                      trailing: Icon(
                        syncProvider.isConnected
                            ? Icons.cloud_done
                            : Icons.cloud_off,
                        color: syncProvider.isConnected
                            ? Colors.green
                            : Colors.red,
                      ),
                    );
                  },
                ),
                
                Consumer<SettingsProvider>(
                  builder: (context, settingsProvider, child) {
                    return SwitchListTile(
                      title: const Text('Offline Mode'),
                      subtitle: const Text('Use cached content only'),
                      value: settingsProvider.isOfflineMode,
                      onChanged: (value) {
                        settingsProvider.isOfflineMode = value;
                      },
                    );
                  },
                ),
                
                ListTile(
                  title: const Text('Clear Cache'),
                  subtitle: const Text('Free up storage space'),
                  trailing: const Icon(Icons.delete),
                  onTap: () => _showClearCacheDialog(context),
                ),
                
                FutureBuilder<int>(
                  future: Provider.of<SyncProvider>(context, listen: false).getCacheSize(),
                  builder: (context, snapshot) {
                    return ListTile(
                      title: const Text('Cache Size'),
                      subtitle: Text(
                        snapshot.hasData 
                            ? '${(snapshot.data! / 1024 / 1024).toStringAsFixed(1)} MB'
                            : 'Calculating...',
                      ),
                      trailing: const Icon(Icons.storage),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // About section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                
                ListTile(
                  title: const Text('Version'),
                  subtitle: const Text('1.0.0'),
                  trailing: const Icon(Icons.info),
                ),
                
                ListTile(
                  title: const Text('Help & Support'),
                  subtitle: const Text('Get help with Book Sphere'),
                  trailing: const Icon(Icons.help),
                  onTap: () {
                    // Would show help dialog
                  },
                ),
                
                ListTile(
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('View our privacy policy'),
                  trailing: const Icon(Icons.privacy_tip),
                  onTap: () {
                    // Would show privacy policy
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Logout button
        ElevatedButton(
          onPressed: () => _showLogoutDialog(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Logout'),
        ),
      ],
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will remove all cached books, music, and backgrounds. '
          'You can re-download them later when needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final syncProvider = Provider.of<SyncProvider>(context, listen: false);
              await syncProvider.clearCache();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final syncProvider = Provider.of<SyncProvider>(context, listen: false);
              
              // Disconnect sync
              syncProvider.disconnect();
              
              // Logout user
              await authProvider.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}