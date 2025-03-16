import 'package:flutter/material.dart';
import 'package:navithesia_beta/constants/app_constants.dart';
import 'package:navithesia_beta/models/coa_category_model.dart' as cat;
import 'package:navithesia_beta/models/coa_category_group_model.dart'
    as cat_group;

class CoaConstants {
  // Category Groups
  static final List<cat_group.CoaCategoryGroup> categoryGroups = [
    cat_group.CoaCategoryGroup(
      id: 'anesthesia_types',
      title: 'Anesthesia Types',
      description: 'Methods of anesthesia administration',
      categoryIds: [
        'general_anesthesia',
        'mac',
        'spinal',
        'epidural',
        'combined_spinal_epidural',
        'regional_upper',
        'regional_lower',
      ],
    ),
    cat_group.CoaCategoryGroup(
      id: 'patient_characteristics',
      title: 'Patient Characteristics',
      description: 'Patient age groups and physical status',
      categoryIds: [
        'geriatric',
        'pediatric_2_12',
        'pediatric_under_2',
        'neonate',
        'asa_3',
        'asa_4',
        'asa_5',
      ],
    ),
    cat_group.CoaCategoryGroup(
      id: 'assessments',
      title: 'Patient Assessments',
      description: 'Pre and post-anesthetic assessments',
      categoryIds: ['preanesthetic_assessment', 'postanesthetic_assessment'],
    ),
    cat_group.CoaCategoryGroup(
      id: 'anatomical_procedures',
      title: 'Anatomical Procedures',
      description: 'Procedures categorized by anatomical location',
      categoryIds: [
        'intraabdominal',
        'intracranial',
        'oropharyngeal',
        'intrathoracic',
        'neck',
        'neuroskeletal',
        'vascular',
      ],
    ),
    cat_group.CoaCategoryGroup(
      id: 'airway_management',
      title: 'Airway Management',
      description: 'Different airway management techniques',
      categoryIds: [
        'tracheal_intubation',
        'mask_management',
        'supraglottic_airway',
        'alternative_airway',
      ],
    ),
    cat_group.CoaCategoryGroup(
      id: 'special_techniques',
      title: 'Special Techniques',
      description: 'Special procedures and techniques',
      categoryIds: [
        'arterial_line',
        'central_line',
        'ultrasound_guided',
        'ultrasound_guided_techniques',
        'imaging_interpretation',
        'iv_placement',
        'chest_xray',
      ],
    ),
    cat_group.CoaCategoryGroup(
      id: 'special_cases',
      title: 'Special Cases',
      description: 'Special case types and emergency procedures',
      categoryIds: [
        'trauma_emergency',
        'obstetric_management',
        'cesarean_delivery',
        'pain_management',
      ],
    ),
  ];

  // Categories
  static final List<cat.CoaCategory> categories = [
    // Anesthesia Types
    cat.CoaCategory(
      id: 'general_anesthesia',
      name: 'General Anesthesia',
      requiredCount: 400,
      description: 'Administration of general anesthesia',
      group: 'anesthesia_types',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'mac',
      name: 'Monitored Anesthesia Care (MAC)',
      requiredCount: 25,
      description: 'Sedation and monitoring without general anesthesia',
      group: 'anesthesia_types',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'spinal',
      name: 'Spinal',
      requiredCount: 10,
      description: 'Spinal anesthesia administration',
      group: 'anesthesia_types',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'epidural',
      name: 'Epidural',
      requiredCount: 10,
      description: 'Epidural anesthesia administration',
      group: 'anesthesia_types',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'combined_spinal_epidural',
      name: 'Combined Spinal-Epidural (CSE)',
      requiredCount: 5,
      description: 'Combined spinal and epidural anesthesia',
      group: 'anesthesia_types',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'regional_upper',
      name: 'Regional Anesthesia Upper',
      requiredCount: 10,
      description: 'Regional anesthesia for upper extremities',
      group: 'anesthesia_types',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'regional_lower',
      name: 'Regional Anesthesia Lower',
      requiredCount: 10,
      description: 'Regional anesthesia for lower extremities',
      group: 'anesthesia_types',
      isRequired: true,
    ),

    // Airway Management
    cat.CoaCategory(
      id: 'tracheal_intubation',
      name: 'Tracheal intubation (ETT)',
      requiredCount: 100,
      description: 'Endotracheal tube placement',
      group: 'airway_management',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'supraglottic_airway',
      name: 'Supraglottic Airway Device (SGA)',
      requiredCount: 25,
      description: 'Supraglottic airway device placement',
      group: 'airway_management',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'mask_management',
      name: 'Mask Management',
      requiredCount: 25,
      description: 'Airway management using mask ventilation',
      group: 'airway_management',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'alternative_airway',
      name: 'Alternative Airway Management',
      requiredCount: 5,
      description: 'Alternative methods for airway management',
      group: 'airway_management',
      isRequired: true,
    ),

    // Access and Monitoring
    cat.CoaCategory(
      id: 'arterial_line',
      name: 'Arterial Line Placement (A-line)',
      requiredCount: 25,
      description:
          'Arterial puncture/catheter insertion for blood pressure monitoring',
      group: 'access_and_monitoring',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'arterial_monitoring',
      name: 'Intra-arterial Blood Pressure Monitoring',
      requiredCount: 30,
      description: 'Monitoring of blood pressure via arterial line',
      group: 'access_and_monitoring',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'central_line',
      name: 'Central Venous Catheter (CVC)',
      requiredCount: 10,
      description: 'Central venous catheter placement',
      group: 'access_and_monitoring',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'non_picc_actual',
      name: 'Non-PICC Placement (Actual)',
      requiredCount: 5,
      description: 'Actual placement of non-PICC central lines',
      group: 'access_and_monitoring',
      isRequired: true,
      parentId: 'central_line',
    ),
    cat.CoaCategory(
      id: 'non_picc_simulated',
      name: 'Non-PICC Placement (Simulated)',
      requiredCount: 0,
      description: 'Simulated placement of non-PICC central lines',
      group: 'access_and_monitoring',
      isRequired: false,
      parentId: 'central_line',
    ),
    cat.CoaCategory(
      id: 'picc_actual',
      name: 'PICC Placement (Actual)',
      requiredCount: 0,
      description: 'Actual placement of PICC lines',
      group: 'access_and_monitoring',
      isRequired: false,
      parentId: 'central_line',
    ),
    cat.CoaCategory(
      id: 'picc_simulated',
      name: 'PICC Placement (Simulated)',
      requiredCount: 0,
      description: 'Simulated placement of PICC lines',
      group: 'access_and_monitoring',
      isRequired: false,
      parentId: 'central_line',
    ),
    cat.CoaCategory(
      id: 'central_line_monitoring',
      name: 'Central Line Monitoring',
      requiredCount: 15,
      description: 'Monitoring using central venous catheter',
      group: 'access_and_monitoring',
      isRequired: true,
      parentId: 'central_line',
    ),
    cat.CoaCategory(
      id: 'pa_catheter_placement',
      name: 'Pulmonary Artery Catheter Placement',
      requiredCount: 5,
      description: 'Pulmonary artery catheter placement',
      group: 'access_and_monitoring',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'pa_catheter_monitoring',
      name: 'Pulmonary Artery Catheter Monitoring',
      requiredCount: 10,
      description: 'Monitoring using pulmonary artery catheter',
      group: 'access_and_monitoring',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'ultrasound_guided_techniques',
      name: 'Ultrasound Guided Techniques',
      requiredCount: 20,
      description: 'Procedures guided by ultrasound technology',
      group: 'special_techniques',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'regional_ultrasound',
      name: 'Regional Ultrasound',
      requiredCount: 10,
      description: 'Ultrasound guided regional techniques',
      group: 'special_techniques',
      isRequired: true,
      parentId: 'ultrasound_guided_techniques',
    ),
    cat.CoaCategory(
      id: 'regional_ultrasound_actual',
      name: 'Actual Regional Ultrasound',
      requiredCount: 0,
      description: 'Actual ultrasound guided regional techniques',
      group: 'special_techniques',
      isRequired: false,
      parentId: 'regional_ultrasound',
    ),
    cat.CoaCategory(
      id: 'regional_ultrasound_simulated',
      name: 'Simulated Regional Ultrasound',
      requiredCount: 0,
      description: 'Simulated ultrasound guided regional techniques',
      group: 'special_techniques',
      isRequired: false,
      parentId: 'regional_ultrasound',
    ),
    cat.CoaCategory(
      id: 'vascular_ultrasound',
      name: 'Vascular Ultrasound',
      requiredCount: 10,
      description: 'Ultrasound guided vascular access',
      group: 'special_techniques',
      isRequired: true,
      parentId: 'ultrasound_guided_techniques',
    ),
    cat.CoaCategory(
      id: 'vascular_ultrasound_actual',
      name: 'Actual Vascular Ultrasound',
      requiredCount: 0,
      description: 'Actual ultrasound guided vascular access',
      group: 'special_techniques',
      isRequired: false,
      parentId: 'vascular_ultrasound',
    ),
    cat.CoaCategory(
      id: 'vascular_ultrasound_simulated',
      name: 'Simulated Vascular Ultrasound',
      requiredCount: 0,
      description: 'Simulated ultrasound guided vascular access',
      group: 'special_techniques',
      isRequired: false,
      parentId: 'vascular_ultrasound',
    ),
    cat.CoaCategory(
      id: 'pocus',
      name: 'Point of Care Ultrasound (POCUS)',
      requiredCount: 0,
      description: 'Point of care ultrasound examination',
      group: 'special_techniques',
      isRequired: false,
      parentId: 'ultrasound_guided_techniques',
    ),
    cat.CoaCategory(
      id: 'pocus_actual',
      name: 'Actual POCUS',
      requiredCount: 0,
      description: 'Actual point of care ultrasound examination',
      group: 'special_techniques',
      isRequired: false,
      parentId: 'pocus',
    ),
    cat.CoaCategory(
      id: 'pocus_simulated',
      name: 'Simulated POCUS',
      requiredCount: 0,
      description: 'Simulated point of care ultrasound examination',
      group: 'special_techniques',
      isRequired: false,
      parentId: 'pocus',
    ),
    cat.CoaCategory(
      id: 'iv_placement',
      name: 'Intravenous Catheter Placement',
      requiredCount: 100,
      description: 'Intravenous catheter placement',
      group: 'access_and_monitoring',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'advanced_monitoring',
      name: 'Advanced Noninvasive Hemodynamic Monitoring',
      requiredCount: 0,
      description: 'Advanced noninvasive hemodynamic monitoring',
      group: 'access_and_monitoring',
      isRequired: false,
    ),
    cat.CoaCategory(
      id: 'chest_xray',
      name: 'Assessment of Chest X-Ray (CXR)',
      requiredCount: 5,
      recommendedCount: 10,
      description: 'Interpretation of chest X-rays',
      group: 'other',
      isRequired: true,
    ),

    // Obstetric Anesthesia
    cat.CoaCategory(
      id: 'obstetric_management',
      name: 'Obstetrical Management',
      requiredCount: 15,
      description: 'Anesthesia management for obstetrical patients',
      group: 'obstetric_anesthesia',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'cesarean_delivery',
      name: 'Cesarean Delivery (c-section)',
      requiredCount: 10,
      description: 'Anesthesia for cesarean section',
      group: 'obstetric_anesthesia',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'labor_analgesia',
      name: 'Analgesia for Labor',
      requiredCount: 10,
      description: 'Pain management during labor',
      group: 'obstetric_anesthesia',
      isRequired: true,
    ),

    // Patient Demographics - Age
    cat.CoaCategory(
      id: 'geriatric',
      name: 'Geriatric 65+ years',
      requiredCount: 50,
      description: 'Patients aged 65 years and older',
      group: 'patient_characteristics',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'pediatric_2_12',
      name: 'Pediatric 2-12 years',
      requiredCount: 30,
      description: 'Pediatric patients aged 2-12 years',
      group: 'patient_characteristics',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'pediatric_under_2',
      name: 'Pediatric <2 years',
      requiredCount: 10,
      description: 'Pediatric patients under 2 years of age',
      group: 'patient_characteristics',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'neonate',
      name: 'Neonate',
      requiredCount: 5,
      description: 'Neonatal patients',
      group: 'patient_characteristics',
      isRequired: true,
    ),

    // Patient Physical Status
    cat.CoaCategory(
      id: 'asa_3',
      name: 'ASA III',
      requiredCount: 50,
      description: 'ASA physical status III patients',
      group: 'patient_characteristics',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'asa_4',
      name: 'ASA IV',
      requiredCount: 25,
      description: 'ASA physical status IV patients',
      group: 'patient_characteristics',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'asa_5',
      name: 'ASA V',
      requiredCount: 5,
      description: 'ASA physical status V patients',
      group: 'patient_characteristics',
      isRequired: true,
    ),

    // Assessments
    cat.CoaCategory(
      id: 'preanesthetic_assessment',
      name: 'Initial Preanesthetic Assessment',
      requiredCount: 100,
      description: 'Assessment performed before anesthesia',
      group: 'assessments',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'postanesthetic_assessment',
      name: 'Postanesthetic Assessment',
      requiredCount: 100,
      description: 'Assessment performed after anesthesia',
      group: 'assessments',
      isRequired: true,
    ),

    // Anatomical Location
    cat.CoaCategory(
      id: 'intraabdominal',
      name: 'Intraabdominal',
      requiredCount: 40,
      description: 'Procedures involving the abdomen',
      group: 'anatomical_procedures',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'intracranial',
      name: 'Intracranial',
      requiredCount: 10,
      description: 'Procedures involving the cranium',
      group: 'anatomical_procedures',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'intrathoracic',
      name: 'Intrathoracic',
      requiredCount: 20,
      description: 'Procedures involving the thorax',
      group: 'anatomical_procedures',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'heart',
      name: 'Heart',
      requiredCount: 10,
      description: 'Procedures involving the heart',
      group: 'anatomical_procedures',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'lung',
      name: 'Lung',
      requiredCount: 10,
      description: 'Procedures involving the lungs',
      group: 'anatomical_procedures',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'oropharyngeal',
      name: 'Oropharyngeal',
      requiredCount: 10,
      description: 'Procedures involving the oropharynx',
      group: 'anatomical_procedures',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'neck',
      name: 'Neck',
      requiredCount: 10,
      description: 'Procedures involving the neck',
      group: 'anatomical_procedures',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'neuroskeletal',
      name: 'Neuroskeletal (spine)',
      requiredCount: 10,
      description: 'Procedures involving the spine',
      group: 'anatomical_procedures',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'trauma_emergency',
      name: 'Trauma / Emergency (E)',
      requiredCount: 30,
      description: 'Trauma and emergency procedures',
      group: 'anatomical_procedures',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'vascular',
      name: 'Vascular',
      requiredCount: 10,
      description: 'Procedures involving blood vessels',
      group: 'anatomical_procedures',
      isRequired: true,
    ),
    cat.CoaCategory(
      id: 'pain_management',
      name: 'Pain Management',
      requiredCount: 25,
      description: 'Pain management procedures',
      group: 'pain_management',
      isRequired: true,
    ),
  ];

  // Helper function to get color based on completion percentage
  static Color getProgressColor(int count, int required) {
    if (required <= 0) return AppColors.primaryColor;

    final double percentage = (count / required) * 100;
    if (percentage <= 25) return AppColors.progressRed;
    if (percentage <= 50) return AppColors.progressOrange;
    if (percentage <= 90) return AppColors.progressYellow;
    return AppColors.progressGreen;
  }

  // Helper function to get all categories in a group
  static List<cat.CoaCategory> getCategoriesInGroup(String groupId) {
    return categories.where((cat) => cat.group == groupId).toList();
  }

  // Helper function to get subcategories of a category
  static List<cat.CoaCategory> getSubcategories(String categoryId) {
    final category = categories.firstWhere((cat) => cat.id == categoryId);
    return categories
        .where((cat) => category.subcategoryIds.contains(cat.id))
        .toList();
  }

  // Helper function to get parent category
  static cat.CoaCategory? getParentCategory(String categoryId) {
    final category = categories.firstWhere((cat) => cat.id == categoryId);
    if (category.parentId == null) return null;
    return categories.firstWhere((cat) => cat.id == category.parentId);
  }
}
