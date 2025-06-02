import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/deal.dart';
import '../utils/globals.dart';
import '../utils/user_preferences.dart';

class BackupManager {
  static const String backupFileName = 'dealify_backup.json';
  
  // Create backup data structure
  static Future<Map<String, dynamic>> _createBackupData() async {
    final userName = await UserPreferences.getUserName();
    final welcomeCompleted = await UserPreferences.isWelcomeCompleted();
    
    return {
      'version': '1.0',
      'created_at': DateTime.now().toIso8601String(),
      'app_name': 'DealiFy',
      'user_data': {
        'user_name': userName,
        'welcome_completed': welcomeCompleted,
      },
      'deals': globalDeals.map((deal) => deal.toJson()).toList(),
      'deals_count': globalDeals.length,
    };
  }
  
  // Export backup to file
  static Future<String?> exportBackup() async {
    try {
      // Request storage permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission denied');
        }
      }
      
      final backupData = await _createBackupData();
      final jsonString = JsonEncoder.withIndent('  ').convert(backupData);
      
      // Get external storage directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
      if (directory == null) {
        throw Exception('Could not access storage directory');
      }
      
      // Create backup file with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'dealify_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(jsonString);
      
      return file.path;
    } catch (e) {
      print('Error creating backup: $e');
      return null;
    }
  }
  
  // Share backup file
  static Future<bool> shareBackup() async {
    try {
      final backupData = await _createBackupData();
      final jsonString = JsonEncoder.withIndent('  ').convert(backupData);
      
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'dealify_backup_$timestamp.json';
      final file = File('${tempDir.path}/$fileName');
      
      await file.writeAsString(jsonString);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'DealiFy App Backup - ${globalDeals.length} deals',
        subject: 'DealiFy Backup File',
      );
      
      return true;
    } catch (e) {
      print('Error sharing backup: $e');
      return false;
    }
  }
  
  // Import backup from file
  static Future<Map<String, dynamic>?> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) {
        return null;
      }
      
      final file = File(result.files.first.path!);
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return backupData;
    } catch (e) {
      print('Error importing backup: $e');
      return null;
    }
  }
  
  // Restore data from backup
  static Future<bool> restoreFromBackup(Map<String, dynamic> backupData) async {
    try {
      // Validate backup data
      if (!_validateBackupData(backupData)) {
        throw Exception('Invalid backup file format');
      }
      
      // Restore user data
      final userData = backupData['user_data'] as Map<String, dynamic>?;
      if (userData != null) {
        if (userData['user_name'] != null) {
          await UserPreferences.setUserName(userData['user_name']);
        }
        if (userData['welcome_completed'] != null) {
          await UserPreferences.setWelcomeCompleted(userData['welcome_completed']);
        }
      }
      
      // Restore deals data
      final dealsData = backupData['deals'] as List<dynamic>?;
      if (dealsData != null) {
        globalDeals.clear();
        for (final dealJson in dealsData) {
          try {
            final deal = Deal.fromJson(dealJson as Map<String, dynamic>);
            globalDeals.add(deal);
          } catch (e) {
            print('Error parsing deal: $e');
            // Continue with other deals even if one fails
          }
        }
        
        // Save restored deals
        await DealDataManager.saveDeals();
      }
      
      return true;
    } catch (e) {
      print('Error restoring backup: $e');
      return false;
    }
  }
  
  // Validate backup data structure
  static bool _validateBackupData(Map<String, dynamic> data) {
    return data.containsKey('version') &&
           data.containsKey('created_at') &&
           data.containsKey('deals') &&
           data['deals'] is List;
  }
  
  // Get backup info without restoring
  static Map<String, dynamic>? getBackupInfo(Map<String, dynamic> backupData) {
    try {
      if (!_validateBackupData(backupData)) {
        return null;
      }
      
      final dealsCount = (backupData['deals'] as List).length;
      final createdAt = DateTime.parse(backupData['created_at']);
      final userName = backupData['user_data']?['user_name'];
      
      return {
        'deals_count': dealsCount,
        'created_at': createdAt,
        'user_name': userName,
        'version': backupData['version'],
      };
    } catch (e) {
      return null;
    }
  }
}

// Backup and Restore UI Screen
class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  _BackupRestoreScreenState createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Data Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Current Data',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Total Deals: ${globalDeals.length}'),
                    const SizedBox(height: 4),
                    Text(
                      'Last Updated: ${DateTime.now().toString().split('.')[0]}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Backup Section
            const Text(
              'Backup Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.share, color: Colors.green),
                    title: const Text('Share Backup File'),
                    subtitle: const Text('Share backup via email, messaging, or cloud storage'),
                    trailing: _isLoading ? 
                      const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      ) : 
                      const Icon(Icons.arrow_forward_ios),
                    onTap: _isLoading ? null : _shareBackup,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.save, color: Colors.blue),
                    title: const Text('Save to Device'),
                    subtitle: const Text('Save backup file to your device storage'),
                    trailing: _isLoading ? 
                      const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      ) : 
                      const Icon(Icons.arrow_forward_ios),
                    onTap: _isLoading ? null : _exportBackup,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Restore Section
            const Text(
              'Restore Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Card(
              child: ListTile(
                leading: const Icon(Icons.restore, color: Colors.orange),
                title: const Text('Restore from Backup'),
                subtitle: const Text('Import backup file and restore your data'),
                trailing: _isLoading ? 
                  const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  ) : 
                  const Icon(Icons.arrow_forward_ios),
                onTap: _isLoading ? null : _importAndRestore,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Warning
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Important: Restoring from backup will replace all current data. Make sure to backup current data first.',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 14,
                      ),
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

  Future<void> _shareBackup() async {
    setState(() => _isLoading = true);
    
    try {
      final success = await BackupManager.shareBackup();
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup file ready to share!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to create backup');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportBackup() async {
    setState(() => _isLoading = true);
    
    try {
      final filePath = await BackupManager.exportBackup();
      
      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup saved to: $filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        throw Exception('Failed to save backup');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importAndRestore() async {
    setState(() => _isLoading = true);
    
    try {
      final backupData = await BackupManager.importBackup();
      
      if (backupData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected')),
        );
        return;
      }
      
      final backupInfo = BackupManager.getBackupInfo(backupData);
      
      if (backupInfo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid backup file format'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Show confirmation dialog
      final shouldRestore = await _showRestoreConfirmationDialog(backupInfo);
      
      if (shouldRestore == true) {
        final success = await BackupManager.restoreFromBackup(backupData);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data restored successfully! Restart the app to see changes.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
          
          // Optional: Navigate back to refresh the app
          Navigator.pop(context);
        } else {
          throw Exception('Failed to restore data');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error restoring backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showRestoreConfirmationDialog(Map<String, dynamic> backupInfo) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Restore'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This will replace all current data with:'),
              const SizedBox(height: 12),
              Text('• ${backupInfo['deals_count']} deals'),
              if (backupInfo['user_name'] != null)
                Text('• User: ${backupInfo['user_name']}'),
              Text('• Created: ${DateFormat('MMM dd, yyyy HH:mm').format(backupInfo['created_at'])}'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Current data will be permanently lost!',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('RESTORE'),
            ),
          ],
        );
      },
    );
  }
}