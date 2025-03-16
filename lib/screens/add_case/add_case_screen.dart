import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:navithesia_beta/constants/app_constants.dart';
import 'package:navithesia_beta/providers/case_provider.dart';
import 'package:navithesia_beta/models/clinical_case_model.dart';
import 'package:navithesia_beta/constants/coa_constants.dart';
import 'package:navithesia_beta/models/coa_category_model.dart' as cat;
import 'package:uuid/uuid.dart';
import 'package:navithesia_beta/providers/theme_provider.dart';
import 'package:navithesia_beta/providers/category_provider.dart';
import 'package:navithesia_beta/constants/app_text_styles.dart' as styles;
import 'package:navithesia_beta/constants/app_colors.dart' as colors;
import 'package:navithesia_beta/services/ocr_service.dart';

// Add a simple Logger class to fix issues
class Logger {
  static void debug(String message) {
    print('DEBUG: $message');
  }

  static void info(String message) {
    print('INFO: $message');
  }

  static void warn(String message) {
    print('WARN: $message');
  }

  static void error(String message) {
    print('ERROR: $message');
  }
}

// Extension to capitalize first letter of a string
extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  }
}

class AddCaseScreen extends StatefulWidget {
  final ClinicalCase? existingCase;

  const AddCaseScreen({super.key, this.existingCase});

  @override
  State<AddCaseScreen> createState() => _AddCaseScreenState();
}

class _AddCaseScreenState extends State<AddCaseScreen> {
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  final _formKey = GlobalKey<FormState>();
  final _procedureController = TextEditingController();
  final _locationController = TextEditingController();
  final _patientAgeController = TextEditingController(text: '50');
  final _notesController = TextEditingController();
  final _durationController = TextEditingController();
  final _searchController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // OCR service
  final OcrService _ocrService = OcrService();

  DateTime _selectedDate = DateTime.now();
  String _selectedGender = 'Male';
  String _selectedASAClass = 'ASA I';
  final Set<String> _selectedAnesthesiaTypes = {'general_anesthesia'};
  bool _isEmergency = false;
  bool _didPreanesthesiaAssessment = false;
  bool _didPostanesthesiaAssessment = false;
  bool _isSimulatedCase = false; // Flag to indicate if this is a simulated case

  // Anesthesia Procedure state variables
  bool _isAnesthesiaProcedure = false;
  String _selectedAnesthesiaProcedureCategory = '';
  String _selectedAnesthesiaProcedure = '';

  // Anesthesia procedure categories and procedures
  final Map<String, List<String>> _anesthesiaProcedures = {
    'Neuraxial Blocks': ['Thoracic Epidural', 'Lumbar Epidural'],
    'Peripheral Nerve Blocks': [
      'Regional Anesthesia Upper',
      'Regional Anesthesia Lower',
      'Regional Anesthesia Other',
    ],
    'Point of Care Ultrasound': [
      'Gastric Ultrasound',
      'Transthoracic Echocardiogram (TTE)',
      'Transesophageal Echocardiogram (TEE)',
    ],
    'Imaging Assessments': ['Assessment of Chest X-Ray'],
    'Line Placements': ['Central Line Placement', 'Arterial Line Placement'],
    'Airway Management': ['Tracheal Intubation'],
  };

  // For procedures autocomplete
  List<Map<String, dynamic>> _allProcedures = [];
  List<Map<String, dynamic>> _filteredProcedures = [];
  List<String> _procedureSuggestions = [];
  bool _isLoadingProcedures = true;
  String _procedureCountLabel = '';

  // COA Categories selection
  final List<String> _genderOptions = const ['Male', 'Female', 'Other'];

  // ASA class options
  final List<String> _asaOptions = const [
    'ASA I',
    'ASA II',
    'ASA III',
    'ASA IV',
    'ASA V',
    'ASA VI',
  ];

  // Selected categories
  final Set<cat.CoaCategory> _selectedCategories = {};

  // Map of common abbreviations to category names
  final Map<String, String> _categoryAbbreviations = {
    'ETT': 'Tracheal Intubation',
    'LMA': 'Supraglottic Airway Device',
    'A-line': 'Arterial puncture/catheter insertion',
    'CVC': 'Central Venous Catheter',
    'CVL': 'Central Venous Catheter',
    'PICC': 'Central Venous Catheter',
    'PA': 'Pulmonary Artery Catheter',
    'CSE': 'Combined Spinal-Epidural',
    'MAC': 'Monitored Anesthesia Care',
    'GA': 'General Anesthesia',
    'ICU': 'Critical Care',
    'PACU': 'Postanesthetic Assessment',
  };

  // Store the selected procedure for reference
  Map<String, dynamic>? _selectedProcedure;

  @override
  void initState() {
    super.initState();
    _loadProcedures();
    _loadClinicalSites();
    _loadSettings();

    // Add this to debug available categories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logAvailableCategories();
    });

    // Allow editing if widget has a case
    if (widget.existingCase != null) {
      _populateExistingCaseData(widget.existingCase!);
    }

    // Debug
    if (widget.existingCase == null) {
      Logger.debug('DEBUG: AddCaseScreen.initState - caseToEdit: NULL');
    } else {
      Logger.debug(
        'DEBUG: AddCaseScreen.initState - caseToEdit: ${widget.existingCase!.id}',
      );
    }

    // Log visit for analytics
    Logger.info('Screen view: add_case_screen');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateProcedureCountLabel();
    });
  }

  // Helper method to log available categories for debugging
  void _logAvailableCategories() {
    try {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      final categories = categoryProvider.categories;

      Logger.debug('Available categories (${categories.length}):');
      for (int i = 0; i < categories.length; i++) {
        Logger.debug(
          '${i + 1}. "${categories[i].name}" (ID: ${categories[i].id})',
        );
      }
    } catch (e) {
      Logger.warn('Error logging categories: $e');
    }
  }

  void _populateExistingCaseData(ClinicalCase existingCase) {
    _selectedDate = existingCase.date;
    _procedureController.text = existingCase.procedure;
    _patientAgeController.text = existingCase.patientAge.toString();
    _selectedGender = existingCase.patientGender;
    _selectedASAClass = existingCase.patientASA;
    _selectedAnesthesiaTypes.clear();
    _selectedAnesthesiaTypes.addAll(existingCase.anesthesiaTypes);
    _durationController.text = existingCase.duration.toString();
    _isEmergency = existingCase.isEmergency;
    _isSimulatedCase = existingCase.isSimulated; // Set the simulated flag

    // Clear and then add all categories from the case
    _selectedCategories.clear();
    _selectedCategories.addAll(existingCase.categories);

    // Check if pre/post anesthesia assessments are in the categories
    _didPreanesthesiaAssessment = existingCase.categories.any(
      (category) => category.id == 'preanesthetic_assessment',
    );

    _didPostanesthesiaAssessment = existingCase.categories.any(
      (category) => category.id == 'postanesthetic_assessment',
    );

    // Add additional anesthesia types based on selected categories
    for (final category in existingCase.categories) {
      if (category.group == 'anesthesia_types') {
        _selectedAnesthesiaTypes.add(category.id);
      }
    }

    // Update age category based on patient age
    _updateAgeCategory(existingCase.patientAge);
  }

  Future<void> _loadProcedures() async {
    try {
      setState(() {
        _isLoadingProcedures = true;
        _hasError = false;
        _errorMessage = '';
      });

      // Load the JSON file from assets
      final String jsonString = await rootBundle.loadString(
        'assets/clinical_experience_database_clean_updated.json',
      );

      // Try to decode the JSON
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      List<Map<String, dynamic>> procedures = [];

      // Check if 'parts' key exists
      if (!jsonData.containsKey('parts')) {
        setState(() {
          _isLoadingProcedures = false;
          _hasError = true;
          _errorMessage = 'Invalid JSON format: missing "parts" key';
        });
        throw Exception('Invalid JSON format: missing "parts" key');
      }

      // Parse the new JSON structure with "parts" array
      final List<dynamic> parts = jsonData['parts'];

      for (var part in parts) {
        if (!part.containsKey('part_name')) {
          Logger.warn('AddCaseScreen - Part missing "part_name", skipping');
          continue;
        }

        final String partName = part['part_name'];
        Logger.debug('AddCaseScreen - Processing part: $partName');

        // Handle both "cases" and "procedures" arrays in the JSON
        List<dynamic> proceduresList = [];
        if (part.containsKey('cases')) {
          proceduresList = part['cases'];
          Logger.debug(
            'AddCaseScreen - Found ${proceduresList.length} cases in $partName',
          );
        } else if (part.containsKey('procedures')) {
          proceduresList = part['procedures'];
          Logger.debug(
            'AddCaseScreen - Found ${proceduresList.length} procedures in $partName',
          );
        } else {
          Logger.warn(
            'AddCaseScreen - Part "$partName" has no cases or procedures, skipping',
          );
          continue;
        }

        for (var procedure in proceduresList) {
          if (!procedure.containsKey('name')) {
            Logger.warn('AddCaseScreen - Procedure missing "name", skipping');
            continue;
          }

          // Create a standardized procedure object with safe getters
          final Map<String, dynamic> standardizedProcedure = {
            'procedureName': procedure['name'],
            'category': partName,
            'physical_status': procedure['physical_status'] ?? 'Unknown',
            'position': procedure['position'] ?? 'Not specified',
            'anatomical_category': procedure['anatomical_category'] ?? 'Other',
            'anesthesia_type':
                procedure['anesthesia_type'] ?? 'General Anesthesia',
            'anesthesia_procedures':
                procedure['anesthesia_procedures'] ?? 'Not specified',
          };

          procedures.add(standardizedProcedure);
        }
      }

      Logger.info(
        'AddCaseScreen - Total procedures loaded: ${procedures.length}',
      );

      if (procedures.isEmpty) {
        Logger.warn('AddCaseScreen - No procedures were loaded!');
      }

      setState(() {
        _allProcedures = procedures;
        _filteredProcedures = procedures;
        _procedureSuggestions =
            []; // Initialize variable to avoid undefined error
        _isLoadingProcedures = false;
      });
      Logger.debug(
        'AddCaseScreen - _allProcedures updated with ${_allProcedures.length} procedures',
      );
    } catch (e, stackTrace) {
      setState(() {
        _allProcedures = [];
        _filteredProcedures = [];
        _procedureSuggestions =
            []; // Initialize variable to avoid undefined error
        _isLoadingProcedures = false;
        _hasError = true;
        _errorMessage = 'Error loading procedures: $e';
      });
      Logger.error(
        'AddCaseScreen - Failed to load procedures: $e\n$stackTrace',
      );
    }
  }

  // Generate procedure suggestions based on input
  void _updateProcedureSuggestions(String query) {
    Logger.debug('_updateProcedureSuggestions called with query: "$query"');
    Logger.debug('Current _allProcedures length: ${_allProcedures.length}');

    if (_allProcedures.isEmpty) {
      Logger.warn('No procedures loaded, cannot search');
      // Don't show an empty suggestion box if there are no procedures
      setState(() {
        _procedureSuggestions = [];
      });
      return;
    }

    if (query.isEmpty) {
      setState(() {
        _procedureSuggestions = [];
      });
      Logger.debug('Query is empty, cleared suggestions');
      return;
    }

    // Check for c-section alias
    bool isCSection = false;
    if (query.toLowerCase() == 'c-section' ||
        query.toLowerCase() == 'c section' ||
        query.toLowerCase() == 'csection') {
      isCSection = true;
    }

    // Split query into individual words for better matching
    final List<String> queryWords =
        query
            .toLowerCase()
            .split(' ')
            .where((word) => word.isNotEmpty)
            .toList();

    if (queryWords.isEmpty) {
      setState(() {
        _procedureSuggestions = [];
      });
      return;
    }

    Logger.debug('Searching for words: $queryWords');

    // Map to hold procedure names with their score (for sorting)
    Map<String, int> matchScores = {};

    for (var procedure in _allProcedures) {
      final String procedureName = procedure['procedureName'] as String;
      if (procedureName.isEmpty) continue;

      final String lowerProcedureName = procedureName.toLowerCase();
      final List<String> procedureWords = lowerProcedureName.split(' ');

      // Special case for c-section alias
      if (isCSection && lowerProcedureName.contains('cesarean section')) {
        matchScores[procedureName] = 200; // Give it highest priority
        continue;
      }

      // Calculate match score
      int score = 0;

      // For each word in the query
      for (final queryWord in queryWords) {
        // Skip very short words (less than 2 chars) unless it's the only word
        if (queryWord.length < 2 && queryWords.length > 1) continue;

        // Exact match for the entire name gets highest score
        if (lowerProcedureName == queryWord) {
          score += 100;
          continue;
        }

        // Procedure starts with the query word
        if (lowerProcedureName.startsWith(queryWord)) {
          score += 75;
          continue;
        }

        // Any word in procedure starts with the query word
        bool anyWordStartsWith = false;
        for (final word in procedureWords) {
          if (word.startsWith(queryWord)) {
            anyWordStartsWith = true;
            break;
          }
        }

        if (anyWordStartsWith) {
          score += 50;
          continue;
        }

        // Procedure contains the query word
        if (lowerProcedureName.contains(queryWord)) {
          score += 25;
          continue;
        }

        // Check if all letters in the query word appear in order
        bool allLettersMatch = true;
        int lastIndex = -1;

        for (int i = 0; i < queryWord.length; i++) {
          final int index = lowerProcedureName.indexOf(
            queryWord[i],
            lastIndex + 1,
          );
          if (index == -1) {
            allLettersMatch = false;
            break;
          }
          lastIndex = index;
        }

        if (allLettersMatch) {
          score += 10;
        }
      }

      // Add to map if there's a match with minimum threshold score
      // Higher threshold for single-letter searches to avoid too many matches
      final int threshold =
          queryWords.length == 1 && queryWords[0].length == 1 ? 50 : 10;

      if (score > threshold) {
        matchScores[procedureName] = score;
      }
    }

    Logger.debug('Number of matches found: ${matchScores.length}');

    // Sort by score (highest first) and take top results
    final List<String> suggestions =
        matchScores.keys.toList()
          ..sort((a, b) => matchScores[b]!.compareTo(matchScores[a]!));

    setState(() {
      _procedureSuggestions =
          suggestions.take(10).toList(); // Show up to 10 suggestions
    });

    Logger.debug(
      'Updated _procedureSuggestions with ${_procedureSuggestions.length} suggestions',
    );
    if (_procedureSuggestions.isNotEmpty) {
      Logger.debug(
        'Top suggestions: ${_procedureSuggestions.take(3).join(', ')}',
      );
    }
  }

  // Auto-fill procedure details when selecting a procedure
  void _selectProcedure(Map<String, dynamic> procedure) {
    Logger.debug('Selecting procedure: ${procedure['procedureName']}');

    // Clear previous suggestions
    _procedureSuggestions.clear();

    // Temporarily store the current selected categories count
    final int previousCategoriesCount = _selectedCategories.length;

    // Clear existing categories
    _selectedCategories.clear();

    // Set the procedure name in the controller and update the selected procedure
    _procedureController.text = procedure['procedureName'];
    _selectedProcedure = procedure;

    // Parse procedure details to add relevant categories
    _parseProcedureDetails(procedure);

    // Debug logging to track category changes
    Logger.debug('Categories after selection: ${_selectedCategories.length}');
    _selectedCategories.forEach((category) {
      Logger.debug('Selected category: ${category.name} (ID: ${category.id})');
    });

    // Perform a double setState update to ensure UI refreshes properly
    // First update to ensure categories are added to the state
    setState(() {});

    // Use post-frame callback for a second update after the first render cycle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check that categories are now visible in the UI
      Logger.debug(
        'Post-frame categories count: ${_selectedCategories.length}',
      );

      // If we had categories before but now showing empty, force a refresh
      if (_selectedCategories.isNotEmpty && previousCategoriesCount == 0) {
        Logger.debug('Forcing additional UI refresh to show categories');
        setState(() {});
      }

      // Show a brief notification to the user about categories being added
      if (_selectedCategories.length > previousCategoriesCount) {
        final snackBar = SnackBar(
          content: Text(
            'Added ${_selectedCategories.length} COA categories for ${procedure['procedureName']}',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: colors.AppColors.primaryColor,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    });
  }

  // New method for comprehensive procedure detail parsing
  void _parseProcedureDetails(Map<String, dynamic> procedure) {
    final String procedureName = procedure['procedureName'] as String;
    final String category =
        procedure['category']?.toString().toLowerCase() ?? '';
    final String procedureLower = procedureName.toLowerCase();

    Logger.debug(
      'Parsing procedure details for: $procedureName (${procedure["category"]})',
    );

    // Handle breast cases - set gender to Female
    if (procedureLower.contains('mastectomy') ||
        procedureLower.contains('lumpectomy') ||
        procedureLower.contains('breast biopsy') ||
        (procedureLower.contains('breast') &&
            (procedureLower.contains('reconstruction') ||
                procedureLower.contains('surgery') ||
                procedureLower.contains('procedure')))) {
      Logger.debug(
        'Special case: Breast procedure detected, setting gender to Female',
      );
      _selectedGender = 'Female';
    }

    // SPECIAL CASES - Handle specific procedures with known requirements
    // These override the standard mappings

    // Special case for Labor Analgesia
    if (procedureLower.contains('labor analgesia') ||
        procedureLower.contains('epidural for labor') ||
        procedureLower.contains('labor pain') ||
        procedureLower.contains('labour analgesia') ||
        (procedureLower.contains('labor') && procedureLower.contains('pain'))) {
      Logger.debug('Special case: Labor analgesia procedure detected');

      // For labor analgesia, default to epidural
      _selectedAnesthesiaTypes.clear();
      _selectedAnesthesiaTypes.add('epidural');
      _addCategoryByName('Epidural');
      // Use exact COA requirement names
      _addCategoryByName('Pain Management');

      // Add obstetrical management and labor analgesia
      _addCategoryByName('Obstetrical Management');
      _addCategoryByName('Analgesia for Labor');

      // Set gender to female for labor analgesia
      _selectedGender = 'Female';

      // Set default age to 30 for labor analgesia patients
      _patientAgeController.text = '30';
      _updateAgeCategory(30);

      return; // Skip remaining procedure parsing since we've handled labor analgesia specifically
    }

    // Special case for C-section
    if (procedureLower.contains('cesarean') ||
        procedureLower.contains('c-section') ||
        procedureLower.contains('c section') ||
        (procedureLower.contains('c/s') && !procedureLower.contains('gc/s')) ||
        (procedureLower.contains('section') &&
            (procedureLower.contains('cesarean') ||
                procedureLower.contains('c ')))) {
      Logger.debug('Special case: Cesarean section procedure detected');

      // For C-sections, default to spinal only
      _selectedAnesthesiaTypes.clear();
      _selectedAnesthesiaTypes.add('spinal');
      _addCategoryByName('Spinal');

      // Add obstetrical management using exact COA requirement names
      _addCategoryByName('Obstetrical Management');
      _addCategoryByName('Cesarean Delivery');
      _addCategoryByName('Intraabdominal'); // Add Intraabdominal for C-section

      // Set gender to female for C-section
      _selectedGender = 'Female';

      return; // Skip remaining procedure parsing since we've handled C-section specifically
    }

    // Handle neurosurgical procedures
    if ((procedureLower.contains('craniec') ||
            procedureLower.contains('craniot') ||
            procedureLower.contains('brain') ||
            procedureLower.contains('intracranial')) &&
        // Exclude spine procedures from being classified as intracranial
        !procedureLower.contains('disc') &&
        !procedureLower.contains('lumbar') &&
        !procedureLower.contains('cervical') &&
        !procedureLower.contains('thoracic') &&
        !procedureLower.contains('spine') &&
        !procedureLower.contains('spinal') &&
        !(category.toLowerCase().contains('spine'))) {
      Logger.debug('Special case: Neurosurgical procedure detected');

      // Ensure general anesthesia is selected
      _selectedAnesthesiaTypes.clear();
      _selectedAnesthesiaTypes.add('general_anesthesia');
      _addCategoryByName('General Anesthesia');
      _addCategoryByName('Tracheal intubation (ETT)');
      _addCategoryByName('Oral Tracheal intubation (ETT)');

      // Arterial line is standard for craniotomies/craniectomies
      _addCategoryByName('Arterial puncture/catheter insertion (A-line)');
      _addCategoryByName('Intra-arterial blood pressure monitoring');

      // Add neurosurgery-specific categories
      _addCategoryByName('Intracranial');

      return;
    }

    // Separate handling for spine cases
    if (procedureLower.contains('spine') ||
        procedureLower.contains('spinal') ||
        procedureLower.contains('disc') ||
        procedureLower.contains('discectomy') ||
        procedureLower.contains('laminectomy') ||
        procedureLower.contains('lumbar') ||
        procedureLower.contains('cervical') ||
        procedureLower.contains('thoracic') ||
        (category.toLowerCase().contains('spine'))) {
      Logger.debug('Special case: Spine procedure detected');

      // Ensure general anesthesia is selected
      _selectedAnesthesiaTypes.clear();
      _selectedAnesthesiaTypes.add('general_anesthesia');
      _addCategoryByName('General Anesthesia');
      _addCategoryByName('Tracheal intubation (ETT)');
      _addCategoryByName('Oral Tracheal intubation (ETT)');

      // Add spine-specific categories
      _addCategoryByName('Neuroskeletal (spine)');

      return;
    }

    // Special handling for endoscopy procedures - SPECIFICALLY NOT adding intraabdominal
    if (procedureLower.contains('endoscop') ||
        procedureLower.contains('colonoscop') ||
        procedureLower.contains('egd') ||
        procedureLower.contains('esophagogastroduodenoscop')) {
      Logger.debug('Special case: Endoscopy procedure detected');

      // Default to MAC for endoscopies
      _selectedAnesthesiaTypes.clear();
      _selectedAnesthesiaTypes.add('mac');
      _addCategoryByName('Monitored Anesthesia Care (MAC)');
      _addCategoryByName('Endoscopy');

      return;
    }

    // STANDARD MAPPINGS - Process normal procedures
    Logger.debug('Processing standard mappings for procedure');

    // Default to general anesthesia for most surgical procedures
    bool isSurgicalProcedure = _isSurgicalProcedure(procedureName, category);
    if (isSurgicalProcedure) {
      Logger.debug(
        'Detected surgical procedure, adding General Anesthesia by default',
      );
      _selectedAnesthesiaTypes.clear();
      _selectedAnesthesiaTypes.add('general_anesthesia');
      _addCategoryByName('General Anesthesia');
      _addCategoryByName('Tracheal intubation (ETT)');
      _addCategoryByName('Oral Tracheal intubation (ETT)');
    }

    // Handle anesthesia type from the database
    String anesthesiaType =
        procedure['anesthesia_type']?.toString().toLowerCase() ?? '';
    if (anesthesiaType.isNotEmpty && anesthesiaType != 'not specified') {
      Logger.debug('Processing anesthesia type from database: $anesthesiaType');

      // Clear previous selections if explicitly provided
      if (!isSurgicalProcedure) {
        _selectedAnesthesiaTypes.clear();
      }

      // Process specific anesthesia types
      if (anesthesiaType.contains('general')) {
        _selectedAnesthesiaTypes.add('general_anesthesia');
        _addCategoryByName('General Anesthesia');
        _addCategoryByName('Tracheal intubation (ETT)');
        _addCategoryByName('Oral Tracheal intubation (ETT)');
      }

      if (anesthesiaType.contains('spinal')) {
        _selectedAnesthesiaTypes.add('spinal');
        _addCategoryByName('Spinal');
      }

      if (anesthesiaType.contains('epidural')) {
        _selectedAnesthesiaTypes.add('epidural');
        _addCategoryByName('Epidural');
      }

      if (anesthesiaType.contains('mac') ||
          anesthesiaType.contains('monitored anesthesia')) {
        _selectedAnesthesiaTypes.add('mac');
        _addCategoryByName('Monitored Anesthesia Care (MAC)');
      }

      if (anesthesiaType.contains('regional')) {
        if (anesthesiaType.contains('upper')) {
          _selectedAnesthesiaTypes.add('regional_upper');
          _addCategoryByName('Peripheral Nerve Block');
        } else if (anesthesiaType.contains('lower')) {
          _selectedAnesthesiaTypes.add('regional_lower');
          _addCategoryByName('Peripheral Nerve Block');
        } else {
          _addCategoryByName('Regional Anesthesia Other');
        }
      }
    }

    // Map anatomical categories to add appropriate categories
    String anatomicalCategory =
        procedure['anatomical_category']?.toString() ?? '';
    if (anatomicalCategory.isNotEmpty &&
        anatomicalCategory != 'Other' &&
        anatomicalCategory != 'Not specified') {
      Logger.debug('Mapping anatomical category: $anatomicalCategory');
      _mapAnatomicalCategories(anatomicalCategory);
    }

    // Handle mentions of specific procedures or techniques
    if (procedureLower.contains('laparoscop') ||
        procedureLower.contains('robotic')) {
      if (!procedureLower.contains('colonoscop') &&
          !procedureLower.contains('egd') &&
          !procedureLower.contains('endoscop')) {
        Logger.debug('Detected laparoscopic/robotic procedure');
        _addCategoryByName('Intraabdominal');
      }
    }

    // Add emergency category if mentioned
    if (procedureLower.contains('emergency') ||
        procedureLower.contains('trauma') ||
        procedure['physical_status']?.toString().toLowerCase().contains(
              'emergency',
            ) ==
            true) {
      Logger.debug('Detected emergency/trauma procedure');
      _isEmergency = true;
      _addCategoryByName('Trauma/Emergency (E)');
    }

    // Final pass for specific surgical procedures that need intraabdominal
    if (procedureLower.contains('laparotomy') ||
        procedureLower.contains('bowel') ||
        procedureLower.contains('colectomy') ||
        procedureLower.contains('appendectomy') ||
        procedureLower.contains('hernia') ||
        procedureLower.contains('cholecystectomy') ||
        procedureLower.contains('splenectomy') ||
        procedureLower.contains('nephrectomy') ||
        (procedureLower.contains('liver') &&
            (procedureLower.contains('resection') ||
                procedureLower.contains('transplant')))) {
      Logger.debug('Detected intraabdominal procedure');
      _addCategoryByName('Intraabdominal');
    }

    // Final check - ensure surgical cases have at least one anesthesia type
    if (_isSurgicalProcedure(procedureName, category) &&
        _selectedAnesthesiaTypes.isEmpty) {
      Logger.debug(
        'Surgical case detected but no anesthesia type selected, defaulting to General Anesthesia',
      );
      _selectedAnesthesiaTypes.add('general_anesthesia');
      _addCategoryByName('General Anesthesia');
      _addCategoryByName('Tracheal intubation (ETT)');
      _addCategoryByName('Oral Tracheal intubation (ETT)');
    }

    Logger.debug('Finished parsing procedure details');
  }

  // Helper method to determine if a procedure is likely a surgical case
  bool _isSurgicalProcedure(String procedureName, String category) {
    final String procedureLower = procedureName.toLowerCase();
    final String categoryLower = category.toLowerCase();

    // Keywords that strongly indicate a surgical procedure
    List<String> surgicalKeywords = [
      'surgery',
      'surgical',
      'resection',
      'ectomy',
      'otomy',
      'repair',
      'excision',
      'removal',
      'transplant',
      'implant',
      'bypass',
      'replacement',
      'laparotomy',
      'laparoscopic',
      'robotic',
      'open',
      'reduction',
      'fixation',
      'arthroscopy',
      'craniotomy',
      'craniectomy',
      'laminectomy',
      'discectomy',
    ];

    // Categories that typically involve surgery
    List<String> surgicalCategories = [
      'general surgery',
      'orthopedic',
      'neurosurgery',
      'cardiac',
      'thoracic',
      'vascular',
      'plastic',
      'urologic',
      'transplant',
      'gynecological',
      'ent',
      'ophthalmology',
    ];

    // Check keywords in procedure name
    for (String keyword in surgicalKeywords) {
      if (procedureLower.contains(keyword)) {
        return true;
      }
    }

    // Check if category is surgical
    for (String surgicalCategory in surgicalCategories) {
      if (categoryLower.contains(surgicalCategory)) {
        return true;
      }
    }

    // Exclude procedures that are typically not surgical
    List<String> nonSurgicalKeywords = [
      'consultation',
      'examination',
      'imaging',
      'scan',
      'mri',
      'ct',
      'ultrasound',
      'xray',
      'x-ray',
      'evaluation',
      'assessment',
      'follow-up',
      'followup',
      'check',
    ];

    for (String keyword in nonSurgicalKeywords) {
      if (procedureLower.contains(keyword)) {
        return false;
      }
    }

    // Default to true if none of the above rules matched but contains certain procedural terms
    return procedureLower.contains('procedure') ||
        procedureLower.contains('operation') ||
        procedureLower.contains('intervention');
  }

  @override
  void dispose() {
    _procedureController.dispose();
    _locationController.dispose();
    _patientAgeController.dispose();
    _notesController.dispose();
    _durationController.dispose();
    _searchController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitCase() {
    if (_procedureController.text.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please enter a procedure';
      });
      return;
    }

    if (_durationController.text.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please enter a duration in hours';
      });
      return;
    }

    double duration = 0;
    try {
      duration = double.parse(_durationController.text);
      if (duration <= 0) {
        throw const FormatException('Duration must be greater than 0');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please enter a valid duration in hours (e.g. 2.5)';
      });
      return;
    }

    int patientAge = 0;
    try {
      patientAge = int.parse(_patientAgeController.text);
      if (patientAge < 0 || patientAge > 120) {
        throw const FormatException('Age must be between 0 and 120');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please enter a valid patient age (0-120)';
      });
      return;
    }

    // Create the case
    ClinicalCase updatedCase = ClinicalCase(
      id: widget.existingCase?.id ?? const Uuid().v4(),
      date: _selectedDate,
      procedure: _procedureController.text,
      patientAge: patientAge,
      patientGender: _selectedGender,
      patientASA: _selectedASAClass,
      isEmergency: _isEmergency,
      anesthesiaTypes: _selectedAnesthesiaTypes.toList(),
      categories: _selectedCategories.toList(),
      duration: duration,
      notes: _notesController.text,
      uniqueCategories: _selectedCategories.map((c) => c.id).toSet().toList(),
      isSimulated:
          _isSimulatedCase, // Set the simulated flag based on the toggle
    );

    // Save the case
    if (widget.existingCase != null) {
      final navigationContext = context;
      Provider.of<CaseProvider>(context, listen: false)
          .updateCase(updatedCase)
          .then((_) {
            ScaffoldMessenger.of(navigationContext).showSnackBar(
              const SnackBar(content: Text('Case updated successfully')),
            );
            Navigator.pop(navigationContext, true);
          })
          .catchError((error) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Error updating case: ${error.toString()}';
            });
          });
    } else {
      final navigationContext = context;
      Provider.of<CaseProvider>(context, listen: false)
          .addCase(updatedCase)
          .then((_) {
            ScaffoldMessenger.of(navigationContext).showSnackBar(
              const SnackBar(content: Text('Case added successfully')),
            );
            Navigator.pop(navigationContext, true);
          })
          .catchError((error) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Error adding case: ${error.toString()}';
            });
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingCase != null
              ? 'Edit Clinical Case'
              : 'Add Clinical Case',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // OCR scan button
          IconButton(
            icon: const Icon(Icons.document_scanner),
            tooltip: 'Scan procedure',
            onPressed: _showOcrOptions,
          ),
          // Simulation toggle icon - made more prominent
          Container(
            margin: const EdgeInsets.only(right: 8.0),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color:
                  _isSimulatedCase
                      ? Colors.amber.withOpacity(0.8)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color:
                    _isSimulatedCase
                        ? Colors.amber
                        : Colors.white.withOpacity(0.5),
                width: 1.0,
              ),
            ),
            child: Tooltip(
              message:
                  _isSimulatedCase
                      ? 'Switch to Actual Case'
                      : 'Switch to Simulated Case',
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isSimulatedCase = !_isSimulatedCase;
                    // Clear selected categories when switching between actual and simulated
                    _selectedCategories.clear();
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isSimulatedCase ? Icons.science : Icons.person,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isSimulatedCase ? 'Simulation' : 'Actual',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            _isSimulatedCase
                                ? FontWeight.bold
                                : FontWeight.normal,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Processing image...'),
                  ],
                ),
              )
              : _isLoadingProcedures
              ? const Center(child: CircularProgressIndicator())
              : _hasError
              ? _buildErrorDisplay()
              : _buildMainContent(),
    );
  }

  Widget _buildErrorDisplay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48.0),
            const SizedBox(height: 16.0),
            Text(
              'Error Loading Data',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              _errorMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _loadProcedures,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Show error message if there is one
          if (_hasError)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date Selection
                _buildDatePicker(),
                const SizedBox(height: 16),

                // Anesthesia Procedure Toggle - MOVED HERE
                _buildAnesthesiaProcedureToggle(),
                const SizedBox(height: 16),

                // Surgical Procedure - RENAMED
                _buildSurgicalProcedureField(),
                const SizedBox(height: 16),

                // Patient Info Card
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPatientAgeField(),
                        const SizedBox(height: 16),
                        _buildGenderDropdown(),
                        const SizedBox(height: 16),
                        _buildASAClassification(),
                        const SizedBox(height: 16),
                        _buildEmergencyToggle(),
                        const SizedBox(height: 16),
                        _buildPreanesthesiaAssessmentToggle(),
                      ],
                    ),
                  ),
                ),

                // Anesthesia Information Card
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Anesthesia Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildAnesthesiaTypeDropdown(),
                        const SizedBox(height: 16),
                        _buildDurationField(),
                        const SizedBox(height: 16),
                        _buildPostanesthesiaAssessmentToggle(),
                      ],
                    ),
                  ),
                ),

                // COA Categories section
                _buildCategorySection(),

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Enter additional notes (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitCase,
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            widget.existingCase != null
                                ? 'Update Case'
                                : 'Save Case',
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build the Categories section with category chips (bubbles)
  Widget _buildCategorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Use LayoutBuilder to ensure the row fits within constraints
            LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          flex: 3,
                          child: Text(
                            'COA Requirements',
                            style: styles.AppTextStyles.subtitle1.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Use IntrinsicWidth to only take the space needed
                        IntrinsicWidth(
                          child: TextButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text(
                              'Add',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _showCategoriesDialog,
                          ),
                        ),
                      ],
                    ),
                    // Simulation status indicator
                    if (_isSimulatedCase)
                      Container(
                        margin: const EdgeInsets.only(top: 8.0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: Colors.amber, width: 1.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.science,
                              size: 16,
                              color: Colors.amber[800],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Simulation Mode',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            const Divider(),
            _buildSelectedCategories(),
          ],
        ),
      ),
    );
  }

  // Build selected categories with chips (bubbles)
  Widget _buildSelectedCategories() {
    // Make sure we have a unique list of categories to display
    final uniqueCategories =
        Set<cat.CoaCategory>.from(_selectedCategories).toList();
    // Sort categories for consistent display
    uniqueCategories.sort((a, b) => a.name.compareTo(b.name));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _selectedCategories.isEmpty
            ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'No categories selected yet. Add relevant categories for this case.',
                style: TextStyle(
                  color: colors.AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
            : Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 10,
                children:
                    uniqueCategories.map((category) {
                      // Group the categories by their group
                      final groupName = category.group
                          .split('_')
                          .map((word) => word.capitalize())
                          .join(' ');

                      // Create a more attractive chip with group indicator
                      return Chip(
                        label: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: styles.AppTextStyles.bodyText2.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (category.group.isNotEmpty)
                              Text(
                                groupName,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colors.AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                        backgroundColor:
                            _isSimulatedCase
                                ? Colors.amber.withOpacity(0.2)
                                : colors.AppColors.background,
                        deleteIcon: const Icon(Icons.cancel, size: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color:
                                _isSimulatedCase
                                    ? Colors.amber
                                    : colors.AppColors.primaryColor.withOpacity(
                                      0.3,
                                    ),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        onDeleted: () {
                          setState(() {
                            _selectedCategories.remove(category);
                          });
                        },
                      );
                    }).toList(),
              ),
            ),
      ],
    );
  }

  // Show dialog to select categories
  void _showCategoriesDialog() {
    // Get the category provider
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );

    // Get available categories
    final List<cat.CoaCategory> availableCategories = _getAvailableCategories();

    // Organize categories by group for better presentation
    final Map<String, List<cat.CoaCategory>> categoriesByGroup = {};

    for (var category in availableCategories) {
      if (!categoriesByGroup.containsKey(category.group)) {
        categoriesByGroup[category.group] = [];
      }
      categoriesByGroup[category.group]!.add(category);
    }

    // Order of priority for display
    final List<String> priorityGroups = [
      'vascular_access', // Placement categories
      'other_procedures', // Ultrasound and POCUS
      'anesthesia_types',
      'regional_anesthesia',
      'airway_management',
    ];

    // Sort groups by priority
    final sortedGroups =
        categoriesByGroup.keys.toList()..sort((a, b) {
          final indexA = priorityGroups.indexOf(a);
          final indexB = priorityGroups.indexOf(b);
          if (indexA >= 0 && indexB >= 0) {
            return indexA.compareTo(indexB);
          } else if (indexA >= 0) {
            return -1;
          } else if (indexB >= 0) {
            return 1;
          } else {
            return a.compareTo(b);
          }
        });

    String searchQuery = '';
    List<cat.CoaCategory> filteredCategories = List.from(availableCategories);
    Map<String, List<cat.CoaCategory>> filteredCategoriesByGroup = Map.from(
      categoriesByGroup,
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Get the device screen size to calculate appropriate dialog heights
        final size = MediaQuery.of(dialogContext).size;
        final keyboardVisible =
            MediaQuery.of(dialogContext).viewInsets.bottom > 0;

        // Calculate appropriate height based on screen size and keyboard visibility
        final maxDialogHeight = size.height * (keyboardVisible ? 0.5 : 0.7);

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            // Get updated keyboard visibility status
            final updatedKeyboardVisible =
                MediaQuery.of(context).viewInsets.bottom > 0;

            // Filter categories based on search, including abbreviations
            if (searchQuery.isEmpty) {
              filteredCategories = List.from(availableCategories);
              filteredCategoriesByGroup = Map.from(categoriesByGroup);
            } else {
              final lowerQuery = searchQuery.toLowerCase();

              // Check for abbreviations first
              String? expandedSearch;
              for (final entry in _categoryAbbreviations.entries) {
                if (entry.key.toLowerCase() == lowerQuery) {
                  expandedSearch = entry.value.toLowerCase();
                  break;
                }
              }

              filteredCategories =
                  availableCategories.where((category) {
                    final lowerCatName = category.name.toLowerCase();

                    // Match direct name
                    if (lowerCatName.contains(lowerQuery)) {
                      return true;
                    }

                    // Match expanded abbreviation if found
                    if (expandedSearch != null &&
                        lowerCatName.contains(expandedSearch)) {
                      return true;
                    }

                    // Match keywords
                    for (final keyword in category.keywords) {
                      if (keyword.toLowerCase().contains(lowerQuery)) {
                        return true;
                      }
                    }

                    return false;
                  }).toList();

              // Rebuild the filtered groups
              filteredCategoriesByGroup = {};
              for (var category in filteredCategories) {
                if (!filteredCategoriesByGroup.containsKey(category.group)) {
                  filteredCategoriesByGroup[category.group] = [];
                }
                filteredCategoriesByGroup[category.group]!.add(category);
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: maxDialogHeight,
                  maxWidth: size.width * 0.9,
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isSimulatedCase
                          ? 'SIMULATED CATEGORIES'
                          : 'ACTUAL CATEGORIES',
                      style: styles.AppTextStyles.headline1,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText:
                            'Search categories or abbreviations (e.g., ETT)...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    // Category list grouped by category type - Expanded takes remaining space
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: sortedGroups.length,
                        itemBuilder: (context, groupIndex) {
                          final groupId = sortedGroups[groupIndex];
                          // Skip groups with no categories after filtering
                          if (!filteredCategoriesByGroup.containsKey(groupId) ||
                              filteredCategoriesByGroup[groupId]!.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          // Get categories for this group
                          final groupCategories =
                              filteredCategoriesByGroup[groupId]!;

                          // Generate a readable group name
                          String groupName = groupId
                              .split('_')
                              .map((word) => word.capitalize())
                              .join(' ');

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Group header with improved styling
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10.0,
                                  horizontal: 12.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  groupName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              // Categories in this group with improved styling
                              ...groupCategories.map((category) {
                                final isSelected = _selectedCategories.contains(
                                  category,
                                );

                                return Card(
                                  elevation: 0,
                                  color:
                                      isSelected
                                          ? Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.1)
                                          : null,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 2.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    side: BorderSide(
                                      color:
                                          isSelected
                                              ? Theme.of(context).primaryColor
                                              : Colors.transparent,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    title: Text(
                                      category.name,
                                      style: TextStyle(
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle:
                                        category.description.isNotEmpty
                                            ? Text(
                                              category.description,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12.0,
                                                color: Colors.grey[600],
                                              ),
                                            )
                                            : null,
                                    trailing:
                                        isSelected
                                            ? const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                            )
                                            : const Icon(
                                              Icons.add_circle_outline,
                                            ),
                                    onTap: () {
                                      setDialogState(() {
                                        if (isSelected) {
                                          setState(() {
                                            _selectedCategories.remove(
                                              category,
                                            );
                                          });
                                        } else {
                                          setState(() {
                                            _selectedCategories.add(category);

                                            // Special handling for Labor Analgesia
                                            if (category.name ==
                                                'Analgesia for Labor') {
                                              // For labor analgesia, set epidural as the anesthesia type
                                              _selectedAnesthesiaTypes.clear();
                                              _selectedAnesthesiaTypes.add(
                                                'epidural',
                                              );
                                              _addCategoryByName(
                                                'Epidural Anesthesia',
                                              );
                                              _addCategoryByName(
                                                'Obstetrical Management',
                                              );

                                              // Set gender to female
                                              _selectedGender = 'Female';

                                              // Set default age to 30
                                              _patientAgeController.text = '30';
                                              _updateAgeCategory(30);
                                            }
                                          });
                                        }
                                      });
                                    },
                                  ),
                                );
                              }).toList(),
                              const Divider(),
                            ],
                          );
                        },
                      ),
                    ),

                    // Buttons at the bottom
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<cat.CoaCategory> _getAvailableCategories() {
    // Get the category provider to access helper methods
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );

    // Use the built-in provider methods that already handle simulation vs actual correctly
    List<cat.CoaCategory> availableCategories =
        _isSimulatedCase
            ? categoryProvider.selectableSimulatedCategories
            : categoryProvider.selectableActualCategories;

    return availableCategories;
  }

  // Build date picker
  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMM dd, yyyy').format(_selectedDate),
              style: const TextStyle(fontSize: 16),
            ),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  // New method to build the anesthesia procedure toggle section
  Widget _buildAnesthesiaProcedureToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with toggle
        Row(
          children: [
            const Expanded(
              child: Text(
                'Anesthesia Procedure',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            _buildThemeAwareSwitch(
              value: _isAnesthesiaProcedure,
              onChanged: (value) {
                setState(() {
                  _isAnesthesiaProcedure = value;
                  if (value) {
                    // Clear procedure suggestions when toggling to anesthesia procedure
                    _procedureSuggestions = [];
                    // Clear selected procedure categories
                    _selectedAnesthesiaProcedureCategory = '';
                    _selectedAnesthesiaProcedure = '';
                  }
                });
              },
            ),
          ],
        ),

        // Show procedure selection when toggle is ON
        if (_isAnesthesiaProcedure) ...[
          const SizedBox(height: 16),
          // Category dropdown with updated placeholder
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Procedure Category',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            isExpanded: true,
            hint: const Text(
              "Select Anesthesia Procedure", // Updated from "Select Procedure"
              style: TextStyle(color: Colors.grey),
            ),
            value:
                _selectedAnesthesiaProcedureCategory.isNotEmpty
                    ? _selectedAnesthesiaProcedureCategory
                    : null,
            items:
                _anesthesiaProcedures.keys.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedAnesthesiaProcedureCategory = value;
                  // Reset the selected procedure when category changes
                  _selectedAnesthesiaProcedure = '';
                  // Update categories based on selected procedure
                  _updateCategoriesBasedOnAnesthesiaProcedure();
                });
              }
            },
          ),

          // Show specific procedure dropdown only when a category is selected
          if (_selectedAnesthesiaProcedureCategory.isNotEmpty) ...[
            const SizedBox(height: 16),
            // Specific procedure dropdown with proper placeholder
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Specific Procedure',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              isExpanded: true,
              hint: const Text(
                "Select Specific Procedure",
                style: TextStyle(color: Colors.grey),
              ),
              value:
                  _selectedAnesthesiaProcedure.isNotEmpty
                      ? _selectedAnesthesiaProcedure
                      : null,
              items:
                  _anesthesiaProcedures[_selectedAnesthesiaProcedureCategory]!
                      .map((procedure) {
                        return DropdownMenuItem(
                          value: procedure,
                          child: Text(
                            procedure,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      })
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedAnesthesiaProcedure = value;
                    // Don't update the procedure text field anymore
                    // Instead just update the categories
                    _updateCategoriesBasedOnAnesthesiaProcedure();
                  });
                }
              },
            ),
          ],
        ],
      ],
    );
  }

  // Renamed from _buildProcedureField to _buildSurgicalProcedureField for clarity
  Widget _buildSurgicalProcedureField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Added header above the Surgical Procedure field
        const Text(
          'Surgical Procedure',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _procedureController,
          decoration: const InputDecoration(
            labelText: 'Surgical Procedure',
            hintText:
                'Start typing to search for surgical cases (including breast cases)',
            hintStyle: TextStyle(color: Colors.grey),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            // Removed the condition to allow search regardless of anesthesia procedure toggle
            _updateProcedureSuggestions(value);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a procedure';
            }
            return null;
          },
        ),
        // Removed the condition to show suggestions regardless of anesthesia procedure toggle
        if (_procedureSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _procedureSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _procedureSuggestions[index];
                return ListTile(
                  title: _highlightMatchedText(
                    suggestion,
                    _procedureController.text,
                  ),
                  onTap: () {
                    // Find the full procedure object from the suggestion string
                    final selectedProcedure = _allProcedures.firstWhere(
                      (procedure) => procedure['procedureName'] == suggestion,
                      orElse: () => <String, dynamic>{},
                    );

                    if (selectedProcedure.isNotEmpty) {
                      _selectProcedure(selectedProcedure);
                    } else {
                      Logger.debug(
                        'Could not find procedure for suggestion: $suggestion',
                      );
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  // Build anesthesia type dropdown
  Widget _buildAnesthesiaTypeDropdown() {
    // Don't show the anesthesia type dropdown if we're in anesthesia procedure mode
    if (_isAnesthesiaProcedure) {
      return const SizedBox.shrink();
    }

    final anesthesiaTypes = [
      {'value': 'general_anesthesia', 'label': 'General Anesthesia'},
      {'value': 'spinal', 'label': 'Spinal'},
      {'value': 'epidural', 'label': 'Epidural'},
      {'value': 'mac', 'label': 'MAC'},
      {'value': 'regional_upper', 'label': 'Upper Extremity Block'},
      {'value': 'regional_lower', 'label': 'Lower Extremity Block'},
      {
        'value': 'combined_spinal_epidural',
        'label': 'Combined Spinal-Epidural',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Primary Anesthetic'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _showAnesthesiaTypesDialog,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedAnesthesiaTypes.isEmpty
                            ? 'Select primary anesthetic'
                            : anesthesiaTypes.firstWhere(
                                  (type) =>
                                      type['value'] ==
                                      _selectedAnesthesiaTypes.first,
                                  orElse: () => {'label': 'Unknown'},
                                )['label']
                                as String,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Show dialog to select anesthesia type
  void _showAnesthesiaTypesDialog() {
    final anesthesiaTypes = [
      {'value': 'general_anesthesia', 'label': 'General Anesthesia'},
      {'value': 'spinal', 'label': 'Spinal'},
      {'value': 'epidural', 'label': 'Epidural'},
      {'value': 'mac', 'label': 'MAC'},
      {'value': 'regional_upper', 'label': 'Upper Extremity Block'},
      {'value': 'regional_lower', 'label': 'Lower Extremity Block'},
      {
        'value': 'combined_spinal_epidural',
        'label': 'Combined Spinal-Epidural',
      },
    ];

    // Initialize selected type
    String selectedType =
        _selectedAnesthesiaTypes.isNotEmpty
            ? _selectedAnesthesiaTypes.first
            : anesthesiaTypes.first['value'] as String;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Select Primary Anesthetic'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      anesthesiaTypes.map((type) {
                        return RadioListTile<String>(
                          title: Text(type['label'] as String),
                          value: type['value'] as String,
                          groupValue: selectedType,
                          onChanged: (String? value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedType = value;
                              });
                            }
                          },
                        );
                      }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Update with single selection
                    setState(() {
                      _selectedAnesthesiaTypes.clear();
                      _selectedAnesthesiaTypes.add(selectedType);
                      _updateCategoriesBasedOnAnesthesiaTypes();
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Build duration field
  Widget _buildDurationField() {
    return TextFormField(
      controller: _durationController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Duration (hours)',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the duration';
        }
        final duration = double.tryParse(value);
        if (duration == null || duration <= 0) {
          return 'Please enter a valid duration greater than 0';
        }
        return null;
      },
    );
  }

  // Helper method to remove a category by name
  void _removeCategoryByName(String categoryName) {
    setState(() {
      _selectedCategories.removeWhere(
        (category) => category.name == categoryName,
      );
      Logger.debug('Removed category (if existed): $categoryName');
    });
  }

  // Helper method to add a category by ID
  void _addCategoryById(String categoryId) {
    final category = CoaConstants.categories.firstWhere(
      (c) => c.id == categoryId,
      orElse:
          () => cat.CoaCategory(
            id: categoryId,
            name: categoryId
                .split('_')
                .map((word) => word.capitalize())
                .join(' '),
            description: 'Category added by ID',
            parentId: null,
            requiredCount: 0,
            isRequired: false,
            group: 'other',
          ),
    );

    if (!_selectedCategories.contains(category)) {
      _selectedCategories.add(category);
    }
  }

  // Helper method to remove a category by ID
  void _removeCategoryById(String categoryId) {
    _selectedCategories.removeWhere((c) => c.id == categoryId);
  }

  // Method to update categories based on anesthesia types
  void _updateCategoriesBasedOnAnesthesiaTypes() {
    // Remove all existing anesthesia type categories
    _selectedCategories.removeWhere(
      (category) => category.group == 'anesthesia_types',
    );

    // Remove tracheal intubation if general anesthesia is not selected
    if (!_selectedAnesthesiaTypes.contains('general_anesthesia')) {
      _selectedCategories.removeWhere(
        (category) => category.id == 'tracheal_intubation',
      );
    }

    // Add categories for each selected anesthesia type
    for (final typeId in _selectedAnesthesiaTypes) {
      final category = CoaConstants.categories.firstWhere(
        (category) => category.id == typeId,
        orElse:
            () => cat.CoaCategory(
              id: typeId,
              name: 'Unknown',
              requiredCount: 0,
              description: 'Unknown category',
              group: 'unknown',
              isRequired: false,
            ),
      );
      _selectedCategories.add(category);

      // Add Tracheal Intubation for General Anesthesia
      if (typeId == 'general_anesthesia') {
        final trachealIntubation = CoaConstants.categories.firstWhere(
          (category) => category.id == 'tracheal_intubation',
          orElse:
              () => CoaConstants.categories.firstWhere(
                (category) =>
                    category.name.toLowerCase() == 'tracheal intubation',
                orElse:
                    () => cat.CoaCategory(
                      id: 'tracheal_intubation',
                      name: 'Tracheal Intubation',
                      requiredCount: 0,
                      description: 'Endotracheal intubation (ETT)',
                      group: 'airway_management',
                      isRequired: false,
                    ),
              ),
        );
        if (!_selectedCategories.contains(trachealIntubation)) {
          _selectedCategories.add(trachealIntubation);
        }
      } else if (typeId == 'regional_upper' ||
          typeId == 'regional_lower' ||
          typeId == 'regional_other' ||
          typeId.contains('pain_management')) {
        // Add ultrasound guided regional for any regional anesthesia or pain management
        _addCategoryByName('Ultrasound Guided Regional');
      }
    }
  }

  // Add stubs for required methods
  void _loadClinicalSites() {
    // Stub implementation
    Logger.debug("Clinical sites loading not implemented yet");
  }

  void _loadSettings() {
    // Stub implementation
    Logger.debug("Settings loading not implemented yet");
  }

  void _updateProcedureCountLabel() {
    // Stub implementation
    setState(() {
      _procedureCountLabel = 'Found ${_allProcedures.length} procedures';
    });
  }

  // Build a theme-aware switch that's visible in both light and dark mode
  Widget _buildThemeAwareSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: isDarkMode ? Colors.lightBlueAccent : null,
      activeTrackColor: isDarkMode ? Colors.blue[700] : null,
      inactiveThumbColor: isDarkMode ? Colors.grey[300] : null,
      inactiveTrackColor: isDarkMode ? Colors.grey[700] : null,
    );
  }

  // Build emergency toggle
  Widget _buildEmergencyToggle() {
    return Row(
      children: [
        Expanded(child: Text('Emergency')),
        Switch(
          value: _isEmergency,
          onChanged: (value) {
            setState(() {
              _isEmergency = value;
              Logger.debug('Emergency toggle: $_isEmergency');

              // When toggling emergency status, add or remove the emergency category
              if (_isEmergency) {
                // Try multiple variations of the emergency category name to ensure it's found
                _addCategoryByName('Trauma/Emergency (E)');
                if (!_selectedCategories.any(
                  (c) =>
                      c.name.contains('Trauma') && c.name.contains('Emergency'),
                )) {
                  _addCategoryByName('Trauma / Emergency (E)');
                }
                if (!_selectedCategories.any(
                  (c) =>
                      c.name.contains('Trauma') && c.name.contains('Emergency'),
                )) {
                  _addCategoryByName('Trauma / Emergency');
                }
              } else {
                // Remove emergency categories
                _selectedCategories.removeWhere(
                  (category) =>
                      category.name.contains('Trauma') &&
                      category.name.contains('Emergency'),
                );
              }
            });
          },
          activeColor: AppColors.primaryColor,
        ),
      ],
    );
  }

  // Build preanesthesia assessment toggle
  Widget _buildPreanesthesiaAssessmentToggle() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Preanesthesia Assessment',
            style: TextStyle(fontSize: 16),
          ),
        ),
        _buildThemeAwareSwitch(
          value: _didPreanesthesiaAssessment,
          onChanged: (value) {
            setState(() {
              _didPreanesthesiaAssessment = value;
              if (value) {
                // Add the preanesthesia assessment category
                _addCategoryById('preanesthesia_assessment');
              } else {
                // Remove the preanesthesia assessment category
                _removeCategoryById('preanesthesia_assessment');
              }
            });
          },
        ),
      ],
    );
  }

  // Build postanesthesia assessment toggle
  Widget _buildPostanesthesiaAssessmentToggle() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Postanesthesia Assessment',
            style: TextStyle(fontSize: 16),
          ),
        ),
        _buildThemeAwareSwitch(
          value: _didPostanesthesiaAssessment,
          onChanged: (value) {
            setState(() {
              _didPostanesthesiaAssessment = value;
              if (value) {
                // Add the postanesthesia assessment category
                _addCategoryById('postanesthesia_assessment');
              } else {
                // Remove the postanesthesia assessment category
                _removeCategoryById('postanesthesia_assessment');
              }
            });
          },
        ),
      ],
    );
  }

  // Build patient age field
  Widget _buildPatientAgeField() {
    return TextFormField(
      controller: _patientAgeController,
      decoration: const InputDecoration(
        labelText: 'Patient Age',
        hintText: 'Enter patient age',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter patient age';
        }
        final age = int.tryParse(value);
        if (age == null || age < 0 || age > 120) {
          return 'Please enter a valid age between 0 and 120';
        }
        return null;
      },
      onChanged: (value) {
        final age = int.tryParse(value);
        if (age != null && age >= 0 && age <= 120) {
          _updateAgeCategory(age);
        }
      },
    );
  }

  // Update age category based on patient age
  void _updateAgeCategory(int age) {
    setState(() {
      // Remove all existing age categories
      _selectedCategories.removeWhere(
        (category) =>
            category.id == 'geriatric' ||
            category.id == 'pediatric_2_12' ||
            category.id == 'pediatric_under_2' ||
            category.id == 'neonate',
      );

      // Add the appropriate age category based on age
      String? categoryId;
      if (age < 1) {
        categoryId = 'neonate';
      } else if (age < 2) {
        categoryId = 'pediatric_under_2';
      } else if (age < 13) {
        categoryId = 'pediatric_2_12';
      } else if (age >= 65) {
        categoryId = 'geriatric';
      }

      // If a category was selected, add it
      if (categoryId != null) {
        try {
          final ageCategory = CoaConstants.categories.firstWhere(
            (category) => category.id == categoryId,
          );
          _selectedCategories.add(ageCategory);
        } catch (e) {
          debugPrint('Error adding age category: $e');
        }
      }
    });
  }

  // Build gender dropdown
  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Patient Gender',
        border: OutlineInputBorder(),
      ),
      value: _selectedGender,
      items:
          _genderOptions.map((gender) {
            return DropdownMenuItem(value: gender, child: Text(gender));
          }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() {
            _selectedGender = newValue;
          });
        }
      },
    );
  }

  // Build ASA classification dropdown
  Widget _buildASAClassification() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'ASA Classification',
        border: OutlineInputBorder(),
      ),
      value: _selectedASAClass,
      items:
          _asaOptions.map((asaClass) {
            return DropdownMenuItem(value: asaClass, child: Text(asaClass));
          }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() {
            _selectedASAClass = newValue;
            _updateASAStatus(newValue);
          });
        }
      },
    );
  }

  void _updateASAStatus(String asaClass) {
    setState(() {
      // Remove all existing ASA categories
      _selectedCategories.removeWhere(
        (category) =>
            category.id == 'asa_3' ||
            category.id == 'asa_4' ||
            category.id == 'asa_5',
      );

      // Add the new ASA category if applicable
      String? categoryId;
      switch (asaClass) {
        case 'ASA III':
          categoryId = 'asa_3';
          break;
        case 'ASA IV':
          categoryId = 'asa_4';
          break;
        case 'ASA V':
          categoryId = 'asa_5';
          break;
        default:
          return;
      }

      final asaCategory = CoaConstants.categories.firstWhere(
        (category) => category.id == categoryId,
      );
      _selectedCategories.add(asaCategory);
    });
  }

  // Helper method to get category ID by name
  String _getCategoryId(String categoryName) {
    return CoaConstants.categories
        .firstWhere(
          (cat) => cat.name == categoryName,
          orElse: () => CoaConstants.categories.first,
        )
        .id;
  }

  // Helper method to add a category by name
  void _addCategoryByName(String categoryName) {
    // Get the category provider
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );

    // Log the exact name we're searching for
    Logger.debug('Attempting to add category: "$categoryName"');

    // First try exact match
    cat.CoaCategory? category = categoryProvider.getCategoryByName(
      categoryName,
    );

    // If not found, try case-insensitive match
    if (category == null) {
      Logger.debug('Exact match not found, trying case-insensitive match');
      try {
        final allCategories =
            categoryProvider
                .categories; // Use categories property instead of getAllCategories
        for (var c in allCategories) {
          if (c.name.toLowerCase() == categoryName.toLowerCase()) {
            category = c;
            break;
          }
        }
      } catch (e) {
        // If there's an error, category will remain null
        Logger.debug('Error in case-insensitive match: $e');
      }
    }

    // If still not found, try contains match
    if (category == null) {
      Logger.debug('Case-insensitive match not found, trying contains match');
      try {
        final allCategories =
            categoryProvider
                .categories; // Use categories property instead of getAllCategories
        final possibleMatches = <cat.CoaCategory>[];

        for (var c in allCategories) {
          if (c.name.toLowerCase().contains(categoryName.toLowerCase()) ||
              categoryName.toLowerCase().contains(c.name.toLowerCase())) {
            possibleMatches.add(c);
          }
        }

        if (possibleMatches.isNotEmpty) {
          // Use the shortest match as it's likely the most specific
          possibleMatches.sort(
            (a, b) => a.name.length.compareTo(b.name.length),
          );
          category = possibleMatches.first;
          Logger.debug('Found partial match: ${category.name}');
        }
      } catch (e) {
        // If there's an error, category will remain null
        Logger.debug('Error in contains match: $e');
      }
    }

    // If found and not already selected, add it
    if (category != null) {
      setState(() {
        // Check if category is already in the list to avoid duplicates
        // Use null assertion (!) since we've already checked category isn't null
        if (!_selectedCategories.any((c) => c.id == category!.id)) {
          // Use null assertion (!) since we've already checked category isn't null
          _selectedCategories.add(category!);
          // Log for debugging with null assertion
          Logger.debug(
            'Added category: ${category!.name} (ID: ${category!.id})',
          );
        } else {
          Logger.debug('Category already selected: ${category!.name}');
        }
      });
      return; // Exit early if we found and added the category
    }

    // If we get here, we couldn't find a match, so try common name variants
    Logger.warn('Could not find category: "$categoryName"');

    // Try some common name variants as fallback
    final Map<String, String> alternateNames = {
      'General Anesthesia': 'General Anesthesia (GA)',
      'Tracheal intubation (ETT)': 'Oral Intubation (ETT)',
      'Trauma/Emergency (E)': 'Trauma / Emergency (E)',
      'Oral': 'Oral tracheal',
      'Intraabdominal': 'Intra-abdominal',
      'Obstetrical management': 'Obstetrical Management',
      'Analgesia for labor': 'Labor analgesia',
      'Cesarean delivery': 'Cesarean Delivery (c-section)',
      'Monitored Anesthesia Care': 'MAC',
      'MAC': 'Monitored Anesthesia Care (MAC)',
      'Peripheral Nerve Block': 'Regional Block',
      'Regional Block': 'Peripheral Nerve Block',
      'Spinal': 'Spinal anesthesia',
      'Epidural': 'Epidural anesthesia',
      'Intracranial': 'Neurosurgical',
      'Neurosurgical': 'Intracranial',
      'Intrathoracic': 'Thoracic',
      'Thoracic': 'Intrathoracic',
      'Pediatric': 'Pediatric 2-12 years',
      'Ultrasound Guided': 'Ultrasound Guided Regional',
    };

    if (alternateNames.containsKey(categoryName)) {
      final alternateName = alternateNames[categoryName];
      Logger.debug('Trying alternate name: $alternateName');
      final alternateCategory = categoryProvider.getCategoryByName(
        alternateName!,
      );

      if (alternateCategory != null) {
        setState(() {
          if (!_selectedCategories.any((c) => c.id == alternateCategory.id)) {
            _selectedCategories.add(alternateCategory);
            Logger.debug(
              'Added category with alternate name: ${alternateCategory.name}',
            );
          }
        });
      } else {
        Logger.warn(
          'Could not find category with alternate name: $alternateName',
        );
      }
    }

    // Remove the extraneous code that was causing 'categoryLower' errors - this was from a different context
  }

  // Update or add anesthesia types with automatic category updates
  void _updateSelectedAnesthesiaTypes(List<String> types) {
    // Check if anesthesia types have changed
    final Set<String> typesSet = Set<String>.from(types);
    final bool hasChanged = !_areSetsEqual(_selectedAnesthesiaTypes, typesSet);

    if (hasChanged) {
      setState(() {
        _selectedAnesthesiaTypes.clear();
        _selectedAnesthesiaTypes.addAll(typesSet);
        // Automatically update categories when anesthesia types change
        _updateCategoriesBasedOnAnesthesiaTypes();
      });
    }
  }

  // Helper to compare two sets for equality
  bool _areSetsEqual(Set<String> set1, Set<String> set2) {
    if (set1.length != set2.length) return false;

    for (final item in set1) {
      if (!set2.contains(item)) return false;
    }

    return true;
  }

  // Add a single anesthesia type
  void _addAnesthesiaType(String typeId) {
    if (!_selectedAnesthesiaTypes.contains(typeId)) {
      setState(() {
        _selectedAnesthesiaTypes.add(typeId);
        // Automatically update categories when adding anesthesia type
        _updateCategoriesBasedOnAnesthesiaTypes();
      });
    }
  }

  // Remove a single anesthesia type
  void _removeAnesthesiaType(String typeId) {
    if (_selectedAnesthesiaTypes.contains(typeId)) {
      setState(() {
        _selectedAnesthesiaTypes.remove(typeId);
        // Automatically update categories when removing anesthesia type
        _updateCategoriesBasedOnAnesthesiaTypes();
      });
    }
  }

  // Helper method to map anatomical categories to appropriate COA requirements
  void _mapAnatomicalCategories(String anatomicalCategory) {
    final String categoryLower = anatomicalCategory.toLowerCase();
    Logger.debug('Mapping anatomical category: $categoryLower');

    // Map common anatomical categories to COA requirements

    // Abdominal procedures
    if (categoryLower.contains('abdom') ||
        categoryLower.contains('stomach') ||
        categoryLower.contains('intestine') ||
        categoryLower.contains('colon') ||
        categoryLower.contains('bowel') ||
        categoryLower.contains('liver') ||
        categoryLower.contains('gall bladder') ||
        categoryLower.contains('spleen') ||
        categoryLower.contains('appendix') ||
        categoryLower.contains('hernia')) {
      _addCategoryByName('Intraabdominal');
    }

    // Thoracic procedures
    if (categoryLower.contains('thorac') ||
        categoryLower.contains('chest') ||
        categoryLower.contains('lung') ||
        categoryLower.contains('pleural') ||
        categoryLower.contains('esophag') &&
            !categoryLower.contains('endoscop')) {
      _addCategoryByName('Intrathoracic');
    }

    // Cardiac procedures
    if (categoryLower.contains('cardi') ||
        categoryLower.contains('heart') ||
        categoryLower.contains('coronary') ||
        categoryLower.contains('aorta') ||
        categoryLower.contains('valve')) {
      _addCategoryByName('Cardiac');
    }

    // Vascular procedures
    if (categoryLower.contains('vascular') ||
        categoryLower.contains('artery') ||
        categoryLower.contains('arterial') ||
        categoryLower.contains('vein') ||
        categoryLower.contains('endovascular')) {
      _addCategoryByName('Vascular');
    }

    // Neurological procedures - intracranial only
    if (categoryLower.contains('brain') ||
        categoryLower.contains('cranial') ||
        categoryLower.contains('intracranial') ||
        (categoryLower.contains('neuro') &&
            !categoryLower.contains('spine') &&
            !categoryLower.contains('skeletal'))) {
      _addCategoryByName('Intracranial');
    }

    // Spine procedures
    if (categoryLower.contains('spine') ||
        categoryLower.contains('spinal') && !categoryLower.contains('cord') ||
        categoryLower.contains('neuroskeletal')) {
      _addCategoryByName('Neuroskeletal (spine)');
    }

    // Orthopedic procedures
    if (categoryLower.contains('ortho') ||
        categoryLower.contains('bone') ||
        categoryLower.contains('joint') ||
        categoryLower.contains('knee') ||
        categoryLower.contains('hip') ||
        categoryLower.contains('shoulder') ||
        categoryLower.contains('spine') &&
            !categoryLower.contains('spinal cord')) {
      _addCategoryByName('Orthopedic');
    }

    // Head and neck procedures
    if (categoryLower.contains('head') ||
        categoryLower.contains('neck') ||
        categoryLower.contains('thyroid') ||
        categoryLower.contains('ent') ||
        categoryLower.contains('ear') ||
        categoryLower.contains('nose') ||
        categoryLower.contains('throat') ||
        categoryLower.contains('laryn')) {
      _addCategoryByName('Head and Neck');
    }

    // Plastic and reconstructive surgery
    if (categoryLower.contains('plastic') ||
        categoryLower.contains('reconstruct')) {
      _addCategoryByName('Plastic/Reconstructive');
    }

    // Urological procedures
    if (categoryLower.contains('urolog') ||
        categoryLower.contains('kidney') ||
        categoryLower.contains('renal') ||
        categoryLower.contains('bladder') ||
        categoryLower.contains('prostat') ||
        categoryLower.contains('uret')) {
      _addCategoryByName('Genitourinary');
    }

    // Gynecological procedures
    if (categoryLower.contains('gyn') ||
        categoryLower.contains('obstetr') ||
        categoryLower.contains('uterus') ||
        categoryLower.contains('ovary') ||
        categoryLower.contains('cervix') ||
        categoryLower.contains('hysterectomy')) {
      // Check if it's obstetric specific
      if (categoryLower.contains('obstet') ||
          categoryLower.contains('pregn') ||
          categoryLower.contains('birth') ||
          categoryLower.contains('delivery')) {
        _addCategoryByName('Obstetrical Management');
      } else {
        _addCategoryByName('Gynecologic');
      }
    }

    // Pediatric or neonatal specific procedures
    if (categoryLower.contains('pediatric') ||
        categoryLower.contains('neonat') ||
        categoryLower.contains('infant') ||
        categoryLower.contains('child')) {
      // Age categories will be handled by _updateAgeCategory
      // but add specific pediatric surgical categories if appropriate
      _addCategoryByName('Pediatric');
    }

    // Endoscopic procedures
    if (categoryLower.contains('endoscop') ||
        categoryLower.contains('colonoscop') ||
        categoryLower.contains('esophagogastroduodenoscop') ||
        categoryLower.contains('egd')) {
      _addCategoryByName('Endoscopy');
    }
  }

  // Helper method to highlight matched text for search results
  Widget _highlightMatchedText(String text, String query) {
    final RegExp regex = RegExp(query, caseSensitive: false);
    final List<TextSpan> spans = [];
    int lastIndex = 0;

    for (final Match match in regex.allMatches(text)) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex, match.start),
          style: const TextStyle(color: Colors.black54),
        ),
      );
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      lastIndex = match.end;
    }

    spans.add(
      TextSpan(
        text: text.substring(lastIndex),
        style: const TextStyle(color: Colors.black54),
      ),
    );

    return RichText(text: TextSpan(children: spans));
  }

  // Update this method to not update the procedure text field anymore
  void _updateCategoriesBasedOnAnesthesiaProcedure() {
    // Clear previous procedure-related categories
    _removeCategoryByName('Epidural Anesthesia');
    _removeCategoryByName('Peripheral Anesthesia upper');
    _removeCategoryByName('Peripheral Anesthesia lower');
    _removeCategoryByName('Regional Anesthesia Other');
    _removeCategoryByName('Ultrasound guided techniques (total of a & b)');
    _removeCategoryByName('Central Venous Catheter (CVC)');
    _removeCategoryByName('Arterial puncture/catheter insertion (A-line)');
    _removeCategoryByName('Tracheal Intubation');
    _removeCategoryByName('Ultrasound Guided Regional');
    _removeCategoryByName('Ultrasound Guided Vascular');
    _removeCategoryByName('Assessment of Chest X-Ray (CXR)');
    _removeCategoryByName('Intra-arterial Blood Pressure Monitoring');
    _removeCategoryByName('Pulmonary Artery Catheter Monitoring');
    _removeCategoryByName('Epidural Pain management');
    _removeCategoryByName('Oral Tracheal intubation (ETT)');

    if (_isAnesthesiaProcedure && _selectedAnesthesiaProcedure.isNotEmpty) {
      // Set appropriate categories based on the selected procedure
      switch (_selectedAnesthesiaProcedure) {
        case 'Thoracic Epidural':
        case 'Lumbar Epidural':
          _addCategoryByName('Epidural Anesthesia');
          _addCategoryByName('Epidural Pain management');
          break;
        case 'Regional Anesthesia Upper':
          _addCategoryByName('Peripheral Anesthesia upper');
          _addCategoryByName('Ultrasound Guided Regional');
          break;
        case 'Regional Anesthesia Lower':
          _addCategoryByName('Peripheral Anesthesia lower');
          _addCategoryByName('Ultrasound Guided Regional');
          break;
        case 'Regional Anesthesia Other':
          _addCategoryByName('Regional Anesthesia Other');
          _addCategoryByName('Ultrasound Guided Regional');
          break;
        case 'Gastric Ultrasound':
        case 'Transthoracic Echocardiogram (TTE)':
        case 'Transesophageal Echocardiogram (TEE)':
          _addCategoryByName('Ultrasound guided techniques (total of a & b)');
          break;
        case 'Assessment of Chest X-Ray':
          _addCategoryByName('Assessment of Chest X-Ray (CXR)');
          break;
        case 'Central Line Placement':
          _addCategoryByName('Central Venous Catheter (CVC)');
          _addCategoryByName('Ultrasound Guided Vascular');
          _addCategoryByName('Assessment of Chest X-Ray (CXR)');
          break;
        case 'Arterial Line Placement':
          _addCategoryByName('Arterial puncture/catheter insertion (A-line)');
          _addCategoryByName('Intra-arterial Blood Pressure Monitoring');
          break;
        case 'Tracheal Intubation':
          _addCategoryByName('Oral Tracheal intubation (ETT)');
          break;
        case 'Pulmonary Artery Catheter Placement':
          _addCategoryByName('Pulmonary Artery Catheter Placement');
          _addCategoryByName('Pulmonary Artery Catheter Monitoring');
          _addCategoryByName('Ultrasound Guided Vascular');
          break;
      }

      // For all procedures in the Imaging Assessments category, add the CXR assessment requirement
      if (_selectedAnesthesiaProcedureCategory == 'Imaging Assessments') {
        _addCategoryByName('Assessment of Chest X-Ray (CXR)');
      }

      // No longer updating the procedure text field here
      // Instead, we'll just log what was selected for debugging
      Logger.debug(
        'Selected anesthesia procedure: $_selectedAnesthesiaProcedure',
      );
    }
  }

  // Show OCR options dialog
  void _showOcrOptions() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Scan Procedure'),
            content: const Text(
              'Scan a paper document or screen with a procedure name to quickly add a case.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startOcrScan(useCamera: false);
                },
                child: const Text('From Gallery'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startOcrScan(useCamera: true);
                },
                child: const Text('Take Photo'),
              ),
            ],
          ),
    );
  }

  // Start OCR scan process
  Future<void> _startOcrScan({required bool useCamera}) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final String? extractedText = await _ocrService.scanText(
        useCamera: useCamera,
      );

      if (extractedText == null || extractedText.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'No text detected in the image';
        });
        return;
      }

      // Extract potential procedures from the OCR text
      final List<String> potentialProcedures = _ocrService
          .extractPotentialProcedures(extractedText);

      if (potentialProcedures.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'No potential procedures found in the scanned text';
        });
        return;
      }

      // Find matches in the database
      _findProcedureMatches(potentialProcedures);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error scanning text: ${e.toString()}';
      });
      Logger.error('OCR error: ${e.toString()}');
    }
  }

  // Find procedure matches in the database
  void _findProcedureMatches(List<String> potentialProcedures) {
    // List to store matches
    List<Map<String, dynamic>> matches = [];

    // First look for exact matches
    for (String procedure in potentialProcedures) {
      // Look for exact matches first
      final exactMatches =
          _allProcedures
              .where(
                (p) =>
                    p['procedureName'].toString().toLowerCase() ==
                    procedure.toLowerCase(),
              )
              .toList();

      matches.addAll(exactMatches);
    }

    // Then look for partial matches if needed
    if (matches.isEmpty) {
      for (String procedure in potentialProcedures) {
        // Look for procedures containing the scanned text
        final partialMatches =
            _allProcedures
                .where(
                  (p) =>
                      p['procedureName'].toString().toLowerCase().contains(
                        procedure.toLowerCase(),
                      ) ||
                      procedure.toLowerCase().contains(
                        p['procedureName'].toString().toLowerCase(),
                      ),
                )
                .toList();

        matches.addAll(partialMatches);
      }
    }

    // Remove duplicates
    final uniqueMatches = matches.toSet().toList();

    setState(() {
      _isLoading = false;
    });

    if (uniqueMatches.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'No matching procedures found in the database';
      });
      return;
    }

    // Show matches in a dialog for user selection
    _showProcedureMatchesDialog(uniqueMatches);
  }

  // Show dialog with procedure matches
  void _showProcedureMatchesDialog(List<Map<String, dynamic>> matches) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Procedure'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final procedure = matches[index];
                  return ListTile(
                    title: Text(procedure['procedureName']),
                    subtitle: Text(procedure['category'] ?? ''),
                    onTap: () {
                      Navigator.pop(context);
                      _selectProcedure(procedure);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }
}
