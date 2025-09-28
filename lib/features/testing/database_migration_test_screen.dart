import 'package:flutter/material.dart';
import '../../core/database/migration_helper.dart';
import '../../core/demo_data/demo_data_manager_v3.dart';

class DatabaseMigrationTestScreen extends StatefulWidget {
  const DatabaseMigrationTestScreen({super.key});

  @override
  State<DatabaseMigrationTestScreen> createState() => _DatabaseMigrationTestScreenState();
}

class _DatabaseMigrationTestScreenState extends State<DatabaseMigrationTestScreen> {
  final MigrationHelper _migrationHelper = MigrationHelper.instance;
  Map<String, dynamic> _migrationStatus = {};
  Map<String, dynamic> _performanceResults = {};
  Map<String, dynamic> _validationResults = {};
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMigrationStatus();
  }

  Future<void> _loadMigrationStatus() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading migration status...';
    });

    try {
      final status = await _migrationHelper.getMigrationStatus();
      setState(() {
        _migrationStatus = status;
        _statusMessage = 'Migration status loaded';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading migration status: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _migrateToV3() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Migrating to database-backed v3...';
    });

    try {
      final success = await _migrationHelper.migrateToV3();
      if (success) {
        setState(() {
          _statusMessage = 'Successfully migrated to v3!';
        });
        await _loadMigrationStatus();
      } else {
        setState(() {
          _statusMessage = 'Migration to v3 failed';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error during migration: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _rollbackToV2() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Rolling back to JSON-based v2...';
    });

    try {
      final success = await _migrationHelper.rollbackToV2();
      if (success) {
        setState(() {
          _statusMessage = 'Successfully rolled back to v2!';
        });
        await _loadMigrationStatus();
      } else {
        setState(() {
          _statusMessage = 'Rollback to v2 failed';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error during rollback: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runPerformanceComparison() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Running performance comparison...';
    });

    try {
      final results = await _migrationHelper.performPerformanceComparison();
      setState(() {
        _performanceResults = results;
        _statusMessage = 'Performance comparison completed';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error during performance comparison: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _validateDataConsistency() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Validating data consistency...';
    });

    try {
      final results = await _migrationHelper.validateDataConsistency();
      setState(() {
        _validationResults = results;
        _statusMessage = 'Data consistency validation completed';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error during validation: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testDatabaseOperations() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing database operations...';
    });

    try {
      final v3Manager = DemoDataManagerV3.instance;

      // Test basic operations
      final users = await v3Manager.users;
      final events = await v3Manager.enhancedEvents;
      final societies = await v3Manager.societies;

      // Test current user
      final currentUser = await v3Manager.currentUserAsync;

      // Test joining/leaving a society
      if (societies.isNotEmpty) {
        final firstSociety = societies.first;
        await v3Manager.joinSociety(firstSociety.id);
        await v3Manager.leaveSociety(firstSociety.id);
      }

      setState(() {
        _statusMessage = 'Database operations test completed successfully!\n'
                       'Users: ${users.length}, Events: ${events.length}, Societies: ${societies.length}\n'
                       'Current User: ${currentUser.name}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error during database operations test: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildStatusCard(String title, Map<String, dynamic> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (data.isEmpty)
              const Text('No data available')
            else
              ...data.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text('${entry.key}: ${entry.value}'),
              )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Migration Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Message
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: _isLoading ? Colors.orange.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: _isLoading ? Colors.orange : Colors.green,
                ),
              ),
              child: Row(
                children: [
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      Icons.info,
                      color: Colors.green.shade700,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _isLoading ? Colors.orange.shade700 : Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Control Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Migration Controls',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _loadMigrationStatus,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Status'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _migrateToV3,
                          icon: const Icon(Icons.upgrade),
                          label: const Text('Migrate to V3'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _rollbackToV2,
                          icon: const Icon(Icons.undo),
                          label: const Text('Rollback to V2'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Testing & Validation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _testDatabaseOperations,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Test Database'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _runPerformanceComparison,
                          icon: const Icon(Icons.speed),
                          label: const Text('Performance Test'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _validateDataConsistency,
                          icon: const Icon(Icons.verified),
                          label: const Text('Validate Data'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Migration Status
            _buildStatusCard('Migration Status', _migrationStatus),

            if (_performanceResults.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildStatusCard('Performance Results', _performanceResults),
            ],

            if (_validationResults.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildStatusCard('Validation Results', _validationResults),
            ],

            const SizedBox(height: 20),

            // Help Text
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Migration Guide',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• V2: JSON-based data manager (current default)\n'
                    '• V3: SQLite database-backed manager (new scalable version)\n'
                    '• Use "Migrate to V3" to upgrade to the database version\n'
                    '• Use "Rollback to V2" to revert to JSON version\n'
                    '• Run tests to verify functionality and performance',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 13,
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