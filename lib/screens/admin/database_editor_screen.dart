import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:navithesia_beta/constants/app_constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DatabaseEditorScreen extends StatefulWidget {
  const DatabaseEditorScreen({super.key});

  @override
  State<DatabaseEditorScreen> createState() => _DatabaseEditorScreenState();
}

class _DatabaseEditorScreenState extends State<DatabaseEditorScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _databaseJson;
  List<dynamic>? _parts;
  int _selectedPartIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDatabase();
  }

  Future<void> _loadDatabase() async {
    try {
      // First try to load from local storage if previously saved
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/clinical_experience_database.json');

      if (await file.exists()) {
        // If we have a local modified version, use that
        final jsonString = await file.readAsString();
        setState(() {
          _databaseJson = json.decode(jsonString);
          _parts = _databaseJson?['parts'];
          _isLoading = false;
        });
      } else {
        // Otherwise load from assets
        final jsonString = await rootBundle.loadString(
          'assets/clinical_experience_database_clean.json',
        );
        setState(() {
          _databaseJson = json.decode(jsonString);
          _parts = _databaseJson?['parts'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading database: $e')));
      }
    }
  }

  Future<void> _saveDatabase() async {
    try {
      // Save to application documents directory (local storage)
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/clinical_experience_database.json');

      await file.writeAsString(json.encode(_databaseJson));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving database: $e')));
      }
    }
  }

  Future<void> _exportDatabase() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/clinical_experience_database.json');

      if (await file.exists()) {
        await Share.shareXFiles([
          XFile(file.path),
        ], subject: 'Clinical Experience Database');
      } else {
        await _saveDatabase();
        await Share.shareXFiles([
          XFile(file.path),
        ], subject: 'Clinical Experience Database');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting database: $e')));
      }
    }
  }

  void _addNewCase() {
    if (_parts == null || _selectedPartIndex >= _parts!.length) return;

    // Ensure the 'cases' array exists
    if (!_parts![_selectedPartIndex].containsKey('cases')) {
      setState(() {
        _parts![_selectedPartIndex]['cases'] = [];
      });
    }

    final newCase = {
      "name": "New Procedure",
      "physical_status": "ASA I-II",
      "position": "Supine",
      "anatomical_category": "Unspecified",
      "anesthesia_type": "General Anesthesia",
      "anesthesia_procedures": "Unspecified",
    };

    setState(() {
      _parts![_selectedPartIndex]['cases'].add(newCase);
    });

    // Save the database first
    _saveDatabase();

    // Then open the edit dialog for the new case
    final newIndex = _parts![_selectedPartIndex]['cases'].length - 1;
    _editCase(newIndex);
  }

  void _editCase(int caseIndex) {
    if (_parts == null ||
        _selectedPartIndex >= _parts!.length ||
        caseIndex >= _parts![_selectedPartIndex]['cases'].length) {
      return;
    }

    final selectedCase = _parts![_selectedPartIndex]['cases'][caseIndex];

    showDialog(
      context: context,
      builder:
          (context) => _EditCaseDialog(
            initialCase: Map<String, dynamic>.from(selectedCase),
            onSave: (updatedCase) {
              setState(() {
                _parts![_selectedPartIndex]['cases'][caseIndex] = updatedCase;
              });
              _saveDatabase();
            },
          ),
    );
  }

  void _deleteCase(int caseIndex) {
    if (_parts == null ||
        _selectedPartIndex >= _parts!.length ||
        caseIndex >= _parts![_selectedPartIndex]['cases'].length) {
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text('Are you sure you want to delete this case?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _parts![_selectedPartIndex]['cases'].removeAt(caseIndex);
                  });
                  _saveDatabase();
                  Navigator.pop(context);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _addNewCategory() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Surgical Category'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    setState(() {
                      _parts!.add({
                        "part_name": nameController.text,
                        "cases": [],
                      });
                    });
                    _saveDatabase();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDatabase,
            tooltip: 'Save Database',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _exportDatabase,
            tooltip: 'Export Database',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _databaseJson == null
              ? const Center(child: Text('Failed to load database'))
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Surgical Category',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedPartIndex,
                            items: List.generate(
                              _parts?.length ?? 0,
                              (index) => DropdownMenuItem(
                                value: index,
                                child: Text(_parts?[index]['part_name'] ?? ''),
                              ),
                            ),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedPartIndex = value;
                                });
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: _addNewCategory,
                          tooltip: 'Add New Category',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                        _parts == null || _parts!.isEmpty
                            ? const Center(
                              child: Text('No surgical categories found'),
                            )
                            : ListView.builder(
                              itemCount:
                                  _parts![_selectedPartIndex]['cases']
                                      ?.length ??
                                  0,
                              itemBuilder: (context, index) {
                                final caseData =
                                    _parts![_selectedPartIndex]['cases'][index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      caseData['name'] ?? 'Unnamed Procedure',
                                      style: AppTextStyles.subtitle1,
                                    ),
                                    subtitle: Text(
                                      '${caseData['anesthesia_type'] ?? "Unknown"} - ${caseData['anatomical_category'] ?? "Other"}',
                                      style: AppTextStyles.bodyText2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: SizedBox(
                                      width: 100,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () => _editCase(index),
                                            tooltip: 'Edit Case',
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => _deleteCase(index),
                                            tooltip: 'Delete Case',
                                          ),
                                        ],
                                      ),
                                    ),
                                    onTap: () => _editCase(index),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewCase,
        tooltip: 'Add New Case',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EditCaseDialog extends StatefulWidget {
  final Map<String, dynamic> initialCase;
  final Function(Map<String, dynamic>) onSave;

  const _EditCaseDialog({
    super.key,
    required this.initialCase,
    required this.onSave,
  });

  @override
  _EditCaseDialogState createState() => _EditCaseDialogState();
}

class _EditCaseDialogState extends State<_EditCaseDialog> {
  late TextEditingController _nameController;
  late TextEditingController _physicalStatusController;
  late TextEditingController _positionController;
  late TextEditingController _anatomicalCategoryController;
  late TextEditingController _anesthesiaTypeController;
  late TextEditingController _anesthesiaProceduresController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialCase['name']);
    _physicalStatusController = TextEditingController(
      text: widget.initialCase['physical_status'],
    );
    _positionController = TextEditingController(
      text: widget.initialCase['position'],
    );
    _anatomicalCategoryController = TextEditingController(
      text: widget.initialCase['anatomical_category'],
    );
    _anesthesiaTypeController = TextEditingController(
      text: widget.initialCase['anesthesia_type'],
    );
    _anesthesiaProceduresController = TextEditingController(
      text: widget.initialCase['anesthesia_procedures'],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _physicalStatusController.dispose();
    _positionController.dispose();
    _anatomicalCategoryController.dispose();
    _anesthesiaTypeController.dispose();
    _anesthesiaProceduresController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Surgical Case'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Procedure Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _physicalStatusController,
              decoration: const InputDecoration(
                labelText: 'Physical Status',
                hintText: 'e.g., ASA I-II',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _positionController,
              decoration: const InputDecoration(
                labelText: 'Position',
                hintText: 'e.g., Supine, Prone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _anatomicalCategoryController,
              decoration: const InputDecoration(
                labelText: 'Anatomical Category',
                hintText: 'e.g., Intra-abdominal',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _anesthesiaTypeController,
              decoration: const InputDecoration(
                labelText: 'Anesthesia Type',
                hintText: 'e.g., General Anesthesia',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _anesthesiaProceduresController,
              decoration: const InputDecoration(
                labelText: 'Anesthesia Procedures',
                hintText: 'e.g., Endotracheal intubation',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedCase = {
              'name': _nameController.text,
              'physical_status': _physicalStatusController.text,
              'position': _positionController.text,
              'anatomical_category': _anatomicalCategoryController.text,
              'anesthesia_type': _anesthesiaTypeController.text,
              'anesthesia_procedures': _anesthesiaProceduresController.text,
            };
            widget.onSave(updatedCase);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
