import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:navithesia_beta/models/coa_category_model.dart';
import 'package:navithesia_beta/constants/app_constants.dart';
import 'dart:math';

class CategoryProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  List<CoaCategory> _categories = [];
  List<String> _selectedCategoryIds = [];
  bool _isLoading = false;

  CategoryProvider(this._prefs) {
    _loadCategories();
    _loadSelectedCategories();
  }

  List<CoaCategory> get categories => _categories;
  List<CoaCategory> get selectedCategories =>
      _categories
          .where((category) => _selectedCategoryIds.contains(category.id))
          .toList();
  bool get isLoading => _isLoading;

  // Load categories from JSON file
  Future<void> _loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      // First get the comprehensive list of 40 required built-in categories
      final List<CoaCategory> builtInCategories =
          await _loadBuiltInCategories();

      // Debug the built-in categories
      debugPrint('Built-in categories count: ${builtInCategories.length}');
      for (int i = 0; i < min(10, builtInCategories.length); i++) {
        debugPrint('Built-in category ${i + 1}: ${builtInCategories[i].name}');
      }

      // Set categories to the built-in list as a starting point
      _categories = builtInCategories;

      // Try to load from the file as a fallback
      bool loadedFromFile = false;

      // Only use the file-based loading if built-in categories failed somehow
      if (_categories.isEmpty) {
        try {
          final String jsonString = await rootBundle.loadString(
            'assets/data/clinical_procedures.json',
          );
          final Map<String, dynamic> jsonData = json.decode(jsonString);

          // Check if we have the coa_categories field in the JSON
          if (jsonData.containsKey('coa_categories')) {
            final List<dynamic> categoriesJson = jsonData['coa_categories'];
            _categories =
                categoriesJson
                    .map((categoryJson) => CoaCategory.fromJson(categoryJson))
                    .toList();

            loadedFromFile = true;
            debugPrint('Loaded ${_categories.length} categories from JSON');
          }
          // Try the COA categories section
          else if (jsonData.containsKey('coa_category_list')) {
            final List<dynamic> categoriesJson = jsonData['coa_category_list'];
            _categories =
                categoriesJson
                    .map((categoryJson) => CoaCategory.fromJson(categoryJson))
                    .toList();

            loadedFromFile = true;
            debugPrint(
              'Loaded ${_categories.length} categories from coa_category_list',
            );
          }
          // Extract from procedures
          else if (jsonData.containsKey('procedures')) {
            // Extract unique categories from procedures
            final List<dynamic> procedures = jsonData['procedures'];

            // Build a unique set of categories
            final Set<String> uniqueCategories = {};
            final List<CoaCategory> extractedCategories = [];
            int idCounter = 1;

            // Extract categories from procedures
            for (var procedure in procedures) {
              if (procedure.containsKey('coa_categories')) {
                final List<dynamic> procCategories =
                    procedure['coa_categories'];
                for (var categoryName in procCategories) {
                  if (categoryName is String &&
                      !uniqueCategories.contains(categoryName)) {
                    uniqueCategories.add(categoryName);
                    extractedCategories.add(
                      CoaCategory(
                        id: idCounter.toString(),
                        name: categoryName,
                        requiredCount: 25, // Default
                        description: 'Category for $categoryName',
                        group: 'extracted',
                        isRequired: false,
                      ),
                    );
                    idCounter++;
                  }
                }
              }
            }

            if (extractedCategories.isNotEmpty) {
              _categories = extractedCategories;
              loadedFromFile = true;
              debugPrint(
                'Extracted ${_categories.length} unique categories from procedures',
              );
            }
          }
        } catch (e) {
          debugPrint('Error loading from procedures.json: $e');
        }

        // If we couldn't load from the file, try loading from the COA requirements file
        if (!loadedFromFile) {
          try {
            final String coaJsonString = await rootBundle.loadString(
              'assets/data/coa_requirements.json',
            );
            final Map<String, dynamic> coaJsonData = json.decode(coaJsonString);

            if (coaJsonData.containsKey('categories')) {
              final List<dynamic> coaCategoriesJson = coaJsonData['categories'];
              _categories =
                  coaCategoriesJson
                      .map((categoryJson) => CoaCategory.fromJson(categoryJson))
                      .toList();

              loadedFromFile = true;
              debugPrint(
                'Loaded ${_categories.length} categories from coa_requirements.json',
              );
            }
          } catch (e) {
            debugPrint('Error loading from coa_requirements.json: $e');
          }
        }
      }

      // Last resort - create default categories if all else failed
      if (_categories.isEmpty) {
        _createDefaultCategories();
        debugPrint('Created default list of ${_categories.length} categories');
      }

      // Debug output to verify we have all the categories
      debugPrint('Final categories count: ${_categories.length}');

      // Print the first 10 categories for verification
      for (int i = 0; i < min(10, _categories.length); i++) {
        debugPrint('Category ${i + 1}: ${_categories[i].name}');
      }

      // Verify a few of the expected categories exist
      final hasTraumaEmergency = _categories.any(
        (c) => c.name == 'Trauma / Emergency (E)',
      );
      final hasCentralLine = _categories.any(
        (c) => c.name == 'Central Line Placement',
      );
      final hasNeck = _categories.any((c) => c.name == 'Neck');

      debugPrint(
        'Verification - has Trauma/Emergency: $hasTraumaEmergency, ' +
            'has Central Line: $hasCentralLine, has Neck: $hasNeck',
      );
    } catch (e) {
      debugPrint('Error in _loadCategories: $e');
      // If all loading attempts fail, create some default categories
      _createDefaultCategories();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load a comprehensive list of built-in categories with exact COA requirements
  Future<List<CoaCategory>> _loadBuiltInCategories() async {
    // Define all categories based on the new structure
    List<CoaCategory> builtInCategories = [
      // ACTUAL CATEGORIES

      // Special Cases
      CoaCategory(
        id: 'special_cases',
        name: 'Special Cases',
        requiredCount: 0,
        description: 'Special case types and procedures',
        group: 'special_cases',
        isRequired: false,
        isGroup: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'trauma_emergency',
        name: 'Trauma/Emergency (E)',
        requiredCount: 30,
        description: 'Trauma and emergency cases',
        group: 'special_cases',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'cesarean_delivery',
        name: 'Cesarean delivery (C-section)',
        requiredCount: 10,
        description: 'Anesthesia for cesarean delivery',
        group: 'special_cases',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'labor_analgesia',
        name: 'Labor analgesia',
        requiredCount: 10,
        description: 'Pain management during labor',
        group: 'special_cases',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'pain_management',
        name: 'Pain Management',
        requiredCount: 20,
        description: 'Acute and chronic pain management',
        group: 'special_cases',
        isRequired: true,
        isSimulated: false,
      ),

      // Anatomical Categories
      CoaCategory(
        id: 'anatomical_categories',
        name: 'Anatomical Categories',
        requiredCount: 0,
        description: 'Categories based on anatomical regions',
        group: 'anatomical_categories',
        isRequired: false,
        isGroup: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'intraabdominal',
        name: 'Intra-abdominal',
        requiredCount: 75,
        description: 'Intra-abdominal surgical procedures',
        group: 'anatomical_categories',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'intracranial_open',
        name: 'Intracranial Open',
        requiredCount: 10,
        description: 'Open intracranial surgical procedures',
        group: 'anatomical_categories',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'intracranial_closed',
        name: 'Intracranial Closed',
        requiredCount: 10,
        description: 'Closed intracranial surgical procedures',
        group: 'anatomical_categories',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'oropharyngeal',
        name: 'Oropharyngeal',
        requiredCount: 20,
        description: 'Oropharyngeal procedures',
        group: 'anatomical_categories',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'heart_open_bypass',
        name: 'Heart: Open Heart w/ bypass',
        requiredCount: 5,
        description: 'Open heart surgery with bypass',
        group: 'anatomical_categories',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'heart_open_no_bypass',
        name: 'Heart: Open Heart w/o bypass',
        requiredCount: 5,
        description: 'Open heart surgery without bypass',
        group: 'anatomical_categories',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'heart_closed',
        name: 'Heart: Closed Heart',
        requiredCount: 5,
        description: 'Closed heart procedures',
        group: 'anatomical_categories',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'lung',
        name: 'Lung',
        requiredCount: 15,
        description: 'Pulmonary surgical procedures',
        group: 'anatomical_categories',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'other_intrathoracic',
        name: 'Other Intrathoracic',
        requiredCount: 10,
        description: 'Other intrathoracic procedures',
        group: 'anatomical_categories',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'neck',
        name: 'Neck',
        requiredCount: 20,
        description: 'Neck surgical procedures',
        group: 'anatomical_categories',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'neuroskeletal',
        name: 'Neuroskeletal (spine)',
        requiredCount: 20,
        description: 'Spine and neuroskeletal procedures',
        group: 'anatomical_categories',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'vascular',
        name: 'Vascular',
        requiredCount: 20,
        description: 'Vascular surgical procedures',
        group: 'anatomical_categories',
        isRequired: true,
        isSimulated: false,
      ),

      // Methods of Anesthesia
      CoaCategory(
        id: 'methods_of_anesthesia',
        name: 'Methods of Anesthesia',
        requiredCount: 0,
        description: 'Different methods of anesthesia delivery',
        group: 'methods_of_anesthesia',
        isRequired: false,
        isGroup: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'general_anesthesia',
        name: 'General Anesthesia (GA)',
        requiredCount: 400,
        description: 'Administration of general anesthesia',
        group: 'methods_of_anesthesia',
        isRequired: true,
        isSimulated: false,
        keywords: ['GA', 'General'],
      ),
      CoaCategory(
        id: 'inhalation_induction',
        name: 'Inhalation induction',
        requiredCount: 20,
        description: 'Inhalation induction of anesthesia',
        group: 'methods_of_anesthesia',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'mask_management',
        name: 'Mask management',
        requiredCount: 25,
        description: 'Face mask ventilation techniques',
        group: 'methods_of_anesthesia',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'laryngeal_mask',
        name: 'Laryngeal Mask',
        requiredCount: 25,
        description: 'Placement and management of laryngeal mask airways',
        group: 'methods_of_anesthesia',
        isRequired: true,
        isSimulated: false,
        keywords: ['LMA', 'Supraglottic'],
      ),
      CoaCategory(
        id: 'opa_npa',
        name: 'OPA or NPA',
        requiredCount: 25,
        description: 'Oral or nasal pharyngeal airways',
        group: 'methods_of_anesthesia',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'oral_intubation',
        name: 'Oral Intubation (ETT)',
        requiredCount: 250,
        description: 'Oral endotracheal intubation',
        group: 'methods_of_anesthesia',
        isRequired: true,
        isSimulated: false,
        keywords: ['ETT', 'Endotracheal', 'Intubation', 'Airway'],
      ),
      CoaCategory(
        id: 'nasal_intubation',
        name: 'Nasal Intubation (ETT)',
        requiredCount: 10,
        description: 'Nasal endotracheal intubation',
        group: 'methods_of_anesthesia',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'fiberoptic_intubation',
        name: 'Fiberoptic Intubation',
        requiredCount: 5,
        description: 'Fiberoptic guided intubation',
        group: 'methods_of_anesthesia',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'videoscope_intubation',
        name: 'Videoscope intubation',
        requiredCount: 5,
        description: 'Video laryngoscope guided intubation',
        group: 'methods_of_anesthesia',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'airway_assessment',
        name: 'Airway assessment',
        requiredCount: 50,
        description: 'Preoperative airway assessment',
        group: 'methods_of_anesthesia',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'intubating_lma',
        name: 'Intubating LMA, Jet ventilation, Bougie',
        requiredCount: 5,
        description: 'Advanced airway techniques',
        group: 'methods_of_anesthesia',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'emergence_anesthesia',
        name: 'Emergence from anesthesia',
        requiredCount: 400,
        description: 'Management of emergence from anesthesia',
        group: 'methods_of_anesthesia',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'moderate_deep_sedation',
        name: 'Moderate / deep sedation',
        requiredCount: 50,
        description: 'Monitored anesthesia care with sedation',
        group: 'methods_of_anesthesia',
        isRequired: true,
        isSimulated: false,
        keywords: ['MAC', 'Sedation'],
      ),

      // Regional techniques
      CoaCategory(
        id: 'regional_techniques',
        name: 'Regional techniques',
        requiredCount: 0,
        description: 'Regional anesthesia techniques',
        group: 'regional_techniques',
        isRequired: false,
        isGroup: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'spinal_anesthesia',
        name: 'Spinal Anesthesia',
        requiredCount: 50,
        description: 'Administration of spinal anesthesia',
        group: 'regional_techniques',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'spinal_pain',
        name: 'Spinal Pain management',
        requiredCount: 10,
        description: 'Spinal techniques for pain management',
        group: 'regional_techniques',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'epidural_anesthesia',
        name: 'Epidural Anesthesia',
        requiredCount: 50,
        description: 'Administration of epidural anesthesia',
        group: 'regional_techniques',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'epidural_pain',
        name: 'Epidural Pain management',
        requiredCount: 10,
        description: 'Epidural techniques for pain management',
        group: 'regional_techniques',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'peripheral_upper',
        name: 'Peripheral Anesthesia upper',
        requiredCount: 10,
        description: 'Peripheral nerve blocks for upper extremities',
        group: 'regional_techniques',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'peripheral_lower',
        name: 'Peripheral Anesthesia lower',
        requiredCount: 10,
        description: 'Peripheral nerve blocks for lower extremities',
        group: 'regional_techniques',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'pain_management_upper',
        name: 'Pain management upper',
        requiredCount: 5,
        description: 'Pain management for upper extremities',
        group: 'regional_techniques',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'pain_management_lower',
        name: 'Pain management lower',
        requiredCount: 5,
        description: 'Pain management for lower extremities',
        group: 'regional_techniques',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'regional_other',
        name: 'Regional Anesthesia Other',
        requiredCount: 5,
        description: 'Other regional anesthesia techniques',
        group: 'regional_techniques',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'regional_pain',
        name: 'Regional Pain management',
        requiredCount: 5,
        description: 'Regional techniques for pain management',
        group: 'regional_techniques',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'ultrasound_guided_regional',
        name: 'Ultrasound guided Regional',
        requiredCount: 10,
        description: 'Ultrasound guided regional anesthesia',
        group: 'regional_techniques',
        isRequired: true,
        isSimulated: false,
      ),

      // Arterial Technique
      CoaCategory(
        id: 'arterial_technique',
        name: 'Arterial Technique',
        requiredCount: 0,
        description: 'Arterial access and monitoring techniques',
        group: 'arterial_technique',
        isRequired: false,
        isGroup: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'arterial_line',
        name: 'Arterial puncture/catheter insertion (A-line)',
        requiredCount: 25,
        description:
            'Arterial line placement for vascular access and monitoring',
        group: 'arterial_technique',
        isRequired: true,
        isSimulated: false,
        keywords: ['A-line', 'Arterial', 'Art line'],
      ),
      CoaCategory(
        id: 'intraarterial_bp',
        name: 'Intra-arterial blood pressure monitoring',
        requiredCount: 30,
        description: 'Monitoring blood pressure using arterial line',
        group: 'arterial_technique',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'ultrasound_guided_vascular_arterial',
        name: 'Ultrasound guided vascular',
        requiredCount: 10,
        description: 'Ultrasound guided arterial access',
        group: 'arterial_technique',
        isRequired: true,
        isSimulated: false,
      ),

      // Central Venous Catheter (CVC)
      CoaCategory(
        id: 'central_venous_catheter',
        name: 'Central Venous Catheter (CVC)',
        requiredCount: 0,
        description: 'Central venous access and monitoring',
        group: 'central_venous',
        isRequired: false,
        isGroup: true,
        isSimulated: false,
        keywords: ['CVC', 'Central line', 'CVL', 'Central access'],
      ),
      CoaCategory(
        id: 'cvc_placement',
        name: 'CVC Placement',
        requiredCount: 10,
        description: 'Central venous catheter placement',
        group: 'central_venous',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'picc_placement',
        name: 'PICC Placement',
        requiredCount: 2,
        description: 'Peripherally inserted central catheter placement',
        group: 'central_venous',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'ultrasound_guided_vascular_venous',
        name: 'Ultrasound guided vascular',
        requiredCount: 10,
        description: 'Ultrasound guided venous access',
        group: 'central_venous',
        isRequired: true,
        isSimulated: false,
      ),

      // Pulmonary Artery Catheter
      CoaCategory(
        id: 'pulmonary_artery_catheter',
        name: 'Pulmonary Artery Catheter',
        requiredCount: 0,
        description: 'Pulmonary artery catheterization and monitoring',
        group: 'pulmonary_artery',
        isRequired: false,
        isGroup: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'pa_catheter_placement',
        name: 'PA catheter Placement',
        requiredCount: 5,
        description: 'Pulmonary artery catheter placement',
        group: 'pulmonary_artery',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'pa_catheter_monitoring',
        name: 'PA catheter Monitoring',
        requiredCount: 10,
        description: 'Pulmonary artery catheter monitoring',
        group: 'pulmonary_artery',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'ultrasound_guided_vascular_pa',
        name: 'Ultrasound guided vascular',
        requiredCount: 5,
        description: 'Ultrasound guided pulmonary artery catheter placement',
        group: 'pulmonary_artery',
        isRequired: true,
        isSimulated: false,
      ),

      // Other
      CoaCategory(
        id: 'other',
        name: 'Other',
        requiredCount: 0,
        description: 'Other procedures and techniques',
        group: 'other',
        isRequired: false,
        isGroup: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'pocus',
        name: 'Point of Care Ultrasound (POCUS)',
        requiredCount: 5,
        description: 'Point of care ultrasound examinations',
        group: 'other',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'iv_placement',
        name: 'Intravenous catheter placement (PIV)',
        requiredCount: 100,
        description: 'Peripheral intravenous catheter placement',
        group: 'other',
        isRequired: true,
        isSimulated: false,
      ),
      CoaCategory(
        id: 'chest_xray',
        name: 'Assessment of Chest X-Ray (CXR)',
        requiredCount: 5,
        recommendedCount: 10,
        description: 'Interpretation of chest X-rays',
        group: 'other',
        isRequired: true,
        isSimulated: false,
      ),

      // SIMULATED CATEGORIES

      // Simulated procedures
      CoaCategory(
        id: 'simulated',
        name: 'Simulated',
        requiredCount: 0,
        description: 'Simulated procedures for training',
        group: 'simulated',
        isRequired: false,
        isGroup: true,
        isSimulated: true,
      ),
      CoaCategory(
        id: 'simulated_fiberoptic',
        name: 'Fiberoptic Intubation',
        requiredCount: 5,
        description: 'Simulated fiberoptic guided intubation',
        group: 'simulated',
        isRequired: true,
        isSimulated: true,
      ),
      CoaCategory(
        id: 'simulated_videoscope',
        name: 'Videoscope tracheal intubation',
        requiredCount: 5,
        description: 'Simulated video laryngoscope guided intubation',
        group: 'simulated',
        isRequired: true,
        isSimulated: true,
      ),
      CoaCategory(
        id: 'simulated_ultrasound_regional',
        name: 'Ultrasound guided Regional',
        requiredCount: 10,
        description: 'Simulated ultrasound guided regional anesthesia',
        group: 'simulated',
        isRequired: true,
        isSimulated: true,
      ),
      CoaCategory(
        id: 'simulated_ultrasound_vascular',
        name: 'Ultrasound guided vascular',
        requiredCount: 10,
        description: 'Simulated ultrasound guided vascular access',
        group: 'simulated',
        isRequired: true,
        isSimulated: true,
      ),
      CoaCategory(
        id: 'simulated_cvc',
        name: 'CVC Placement',
        requiredCount: 5,
        description: 'Simulated central venous catheter placement',
        group: 'simulated',
        isRequired: true,
        isSimulated: true,
      ),
      CoaCategory(
        id: 'simulated_picc',
        name: 'PICC Placement',
        requiredCount: 2,
        description:
            'Simulated peripherally inserted central catheter placement',
        group: 'simulated',
        isRequired: true,
        isSimulated: true,
      ),
      CoaCategory(
        id: 'simulated_pocus',
        name: 'Point of Care Ultrasound (POCUS)',
        requiredCount: 5,
        description: 'Simulated point of care ultrasound examinations',
        group: 'simulated',
        isRequired: true,
        isSimulated: true,
      ),
    ];

    // Print totals for verification
    int totalRequired = 0;
    for (var category in builtInCategories.where(
      (c) => c.parentId == null || c.parentId!.isEmpty,
    )) {
      if (category.requiredCount > 0) {
        totalRequired += category.requiredCount;
      }
    }
    debugPrint(
      'Total required cases from top-level categories: $totalRequired',
    );

    return builtInCategories;
  }

  // Create default categories if loading from file fails
  void _createDefaultCategories() {
    _categories = [
      CoaCategory(
        id: '1',
        name: 'General Anesthesia',
        requiredCount: 400,
        description: 'Administration of general anesthesia',
        group: 'anesthesia_types',
        isRequired: true,
      ),
      CoaCategory(
        id: '2',
        name: 'Epidural',
        requiredCount: 25,
        description: 'Administration of epidural anesthesia',
        group: 'anesthesia_types',
        isRequired: true,
      ),
      CoaCategory(
        id: '3',
        name: 'Spinal',
        requiredCount: 25,
        description: 'Administration of spinal anesthesia',
        group: 'anesthesia_types',
        isRequired: true,
      ),
      CoaCategory(
        id: '4',
        name: 'MAC',
        requiredCount: 25,
        description: 'Monitored anesthesia care',
        group: 'anesthesia_types',
        isRequired: true,
      ),
    ];
  }

  // Load selected categories from SharedPreferences
  Future<void> _loadSelectedCategories() async {
    try {
      final selectedCategoriesJson = _prefs.getString(
        AppConstants.selectedCategoriesKey,
      );
      if (selectedCategoriesJson != null) {
        final List<dynamic> decodedCategories = json.decode(
          selectedCategoriesJson,
        );
        _selectedCategoryIds = decodedCategories.cast<String>();
      } else {
        // If no selected categories are saved, select the first 4 by default
        _selectedCategoryIds =
            _categories
                .take(AppConstants.maxDashboardCategories)
                .map((c) => c.id)
                .toList();
        await _saveSelectedCategories();
      }
    } catch (e) {
      debugPrint('Error loading selected categories: $e');
    }
    notifyListeners();
  }

  // Save selected categories to SharedPreferences
  Future<void> _saveSelectedCategories() async {
    await _prefs.setString(
      AppConstants.selectedCategoriesKey,
      json.encode(_selectedCategoryIds),
    );
  }

  // Select a category for the dashboard
  Future<bool> selectCategory(String categoryId) async {
    if (_selectedCategoryIds.length >= AppConstants.maxDashboardCategories) {
      return false;
    }

    if (!_selectedCategoryIds.contains(categoryId)) {
      _selectedCategoryIds.add(categoryId);
      await _saveSelectedCategories();
      notifyListeners();
    }
    return true;
  }

  // Deselect a category from the dashboard
  Future<void> deselectCategory(String categoryId) async {
    _selectedCategoryIds.remove(categoryId);
    await _saveSelectedCategories();
    notifyListeners();
  }

  // Get a category by ID
  CoaCategory? getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere((c) => c.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  // Get a category by name
  CoaCategory? getCategoryByName(String categoryName) {
    try {
      return _categories.firstWhere((c) => c.name == categoryName);
    } catch (e) {
      return null;
    }
  }

  // Check if a category is selected
  bool isCategorySelected(String categoryId) {
    return _selectedCategoryIds.contains(categoryId);
  }

  // Get all categories with their selection status
  List<CoaCategory> getCategoriesWithSelectionStatus() {
    return _categories.map((category) {
      return category.copyWith(
        isSelected: _selectedCategoryIds.contains(category.id),
      );
    }).toList();
  }

  // Get all selectable categories (excluding group categories)
  List<CoaCategory> get selectableCategories =>
      _categories
          .where(
            (category) =>
                !category.isGroup &&
                // Don't allow selecting parent categories with child categories
                !(category.subcategoryIds.isNotEmpty &&
                    category.subcategoryIds.any(
                      (id) =>
                          _categories.any((c) => c.id == id && !c.isSimulated),
                    )),
          )
          .toList();

  // Get selectable actual categories (for regular case logging)
  List<CoaCategory> get selectableActualCategories =>
      _categories
          .where(
            (category) =>
                !category.isGroup &&
                !category.isSimulated &&
                // Don't allow selecting parent categories with child categories
                !(category.subcategoryIds.isNotEmpty &&
                    category.subcategoryIds.any(
                      (id) =>
                          _categories.any((c) => c.id == id && !c.isSimulated),
                    )),
          )
          .toList();

  // Get selectable simulated categories (for simulation case logging)
  List<CoaCategory> get selectableSimulatedCategories =>
      _categories
          .where(
            (category) =>
                !category.isGroup &&
                category.isSimulated &&
                // Don't allow selecting parent categories with simulated child categories
                !(category.subcategoryIds.isNotEmpty &&
                    category.subcategoryIds.any(
                      (id) =>
                          _categories.any((c) => c.id == id && c.isSimulated),
                    )),
          )
          .toList();

  // Get a category's child categories
  List<CoaCategory> getChildCategories(String parentId) {
    return _categories.where((c) => c.parentId == parentId).toList();
  }

  // Get all categories that are part of a specific group
  List<CoaCategory> getCategoriesByGroup(String groupName) {
    return _categories.where((c) => c.group == groupName).toList();
  }

  // Get actual categories (non-simulated)
  List<CoaCategory> get actualCategories =>
      _categories.where((category) => !category.isSimulated).toList();

  // Get simulated categories
  List<CoaCategory> get simulatedCategories =>
      _categories.where((category) => category.isSimulated).toList();
}
