import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:navithesia_beta/constants/app_constants.dart';
import 'package:navithesia_beta/providers/case_provider.dart';
import 'package:navithesia_beta/models/clinical_case_model.dart';
import 'package:navithesia_beta/constants/coa_constants.dart';
import 'package:navithesia_beta/widgets/coa_progress_bar.dart';
import 'package:navithesia_beta/screens/add_case/add_case_screen.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:navithesia_beta/providers/time_entry_provider.dart';
import 'package:navithesia_beta/models/time_entry_model.dart';
import 'package:navithesia_beta/providers/clinical_site_provider.dart';
import 'package:navithesia_beta/models/clinical_site_model.dart';
import 'package:navithesia_beta/providers/theme_provider.dart';
import 'package:intl/intl.dart';
import 'package:navithesia_beta/providers/category_provider.dart';
import 'package:navithesia_beta/models/coa_category_model.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Enums for export types
enum ExportType { allLogs, siteLogs, coaTranscript }

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

// Helper class for building strings
class StringBuilder {
  final StringBuffer _buffer = StringBuffer();

  void append(String text) {
    _buffer.write(text);
  }

  void appendLine(String line) {
    _buffer.writeln(line);
  }

  @override
  String toString() {
    return _buffer.toString();
  }
}

class _LogsScreenState extends State<LogsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 1; // Index for the logs tab
  String _searchQuery = '';
  String _filterCategory = 'All';
  String _sortOption = 'Date (Newest)';
  String _coaFilterOption = 'All'; // Options: 'All', 'Required', 'Recommended'
  String? _selectedSiteId;

  // Tab controller
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Set initial tab in the next frame when context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('initialTab')) {
        final initialTab = args['initialTab'] as int;
        if (initialTab >= 0 && initialTab < _tabController.length) {
          _tabController.animateTo(initialTab);
        }
      }
    });
  }

  @override
  void dispose() {
    // Properly dispose of controllers to prevent memory leaks
    _tabController.dispose();

    // Use a try-catch block to handle any disposal errors gracefully
    try {
      // Add any additional cleanup needed
    } catch (e) {
      print('Error during LogsScreen disposal: $e');
    }

    super.dispose();
  }

  // List of possible filter categories
  final List<String> _filterOptions = [
    'All',
    'General Anesthesia',
    'Epidural',
    'Spinal',
    'MAC',
  ];

  // List of possible sort options
  final List<String> _sortOptions = [
    'Date (Newest)',
    'Date (Oldest)',
    'Duration (Highest)',
    'Duration (Lowest)',
  ];

  @override
  Widget build(BuildContext context) {
    final caseProvider = Provider.of<CaseProvider>(context);
    final cases = _getFilteredCases(caseProvider.cases);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Export logs',
            onPressed: _showExportOptionsDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
          tabs: const [
            Tab(text: 'Cases', height: 40),
            Tab(text: 'COA Progress', height: 40),
            Tab(text: 'Clinical Hours', height: 40),
          ],
          indicatorColor: AppColors.accentColor,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textLight,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Cases Tab
          _buildCasesTab(caseProvider, cases),

          // COA Progress Tab
          _buildCoaProgressTab(caseProvider),

          // Clinical Hours Tab
          _buildClinicalHoursTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.addCase);
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _navigateToScreen(context, index);
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Logs'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 30),
            label: 'Add Case',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Goals',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
        ],
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: AppColors.textLight,
      ),
    );
  }

  Widget _buildCasesTab(CaseProvider caseProvider, List<ClinicalCase> cases) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search cases...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
          ),
          child: Row(
            children:
                _filterOptions.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(filter),
                      selected: _filterCategory == filter,
                      onSelected: (selected) {
                        setState(() {
                          _filterCategory = filter;
                        });
                      },
                    ),
                  );
                }).toList(),
          ),
        ),

        const SizedBox(height: 10),

        // Cases list
        Expanded(
          child: cases.isEmpty ? _buildEmptyState() : _buildCasesList(cases),
        ),
      ],
    );
  }

  Widget _buildCoaProgressTab(CaseProvider caseProvider) {
    // Get categories from CoaConstants rather than hardcoding them
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final allCategories = categoryProvider.categories;

    // Group the categories for better organization in the UI
    final Map<String, List<CoaCategory>> categoriesByGroup = {};
    for (var category in allCategories) {
      if (!categoriesByGroup.containsKey(category.group)) {
        categoriesByGroup[category.group] = [];
      }
      categoriesByGroup[category.group]!.add(category);
    }

    // Sort groups alphabetically
    final sortedGroups = categoriesByGroup.keys.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryStats(caseProvider),
          const SizedBox(height: 16),

          // Add filter toggle for required/recommended categories
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.defaultBorderRadius,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Categories',
                    style: AppTextStyles.subtitle1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildFilterChip('All', _coaFilterOption == 'All'),
                      _buildFilterChip(
                        'Required',
                        _coaFilterOption == 'Required',
                      ),
                      _buildFilterChip(
                        'Recommended',
                        _coaFilterOption == 'Recommended',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Create a collapsible card for each group of categories
          ...sortedGroups.map((group) {
            final categoriesInGroup = categoriesByGroup[group]!;

            // Skip groups with no required categories (optional categories)
            if (_coaFilterOption == 'Required' &&
                categoriesInGroup.every((c) => c.requiredCount == 0)) {
              return const SizedBox.shrink();
            }

            // Skip groups with no recommended categories
            if (_coaFilterOption == 'Recommended' &&
                categoriesInGroup.every(
                  (c) => c.recommendedCount == null || c.recommendedCount == 0,
                )) {
              return const SizedBox.shrink();
            }

            // Make the entire category group collapsible
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.defaultBorderRadius,
                ),
              ),
              child: ExpansionTile(
                initiallyExpanded: false,
                title: Text(
                  _formatGroupName(group),
                  style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Categories in this group
                        ...categoriesInGroup.where((c) => c.isRequired).map((
                          category,
                        ) {
                          // Skip subcategories (they will be shown under their parent)
                          if (category.parentId != null) {
                            return const SizedBox.shrink();
                          }

                          final int count = caseProvider.getCaseCountByCategory(
                            category.id,
                          );
                          final int required = category.requiredCount;
                          final int? recommended = category.recommendedCount;

                          // Check if this category has subcategories
                          final subcategories =
                              allCategories
                                  .where((c) => c.parentId == category.id)
                                  .toList();

                          // Calculate progress percentage using our helper method
                          final double progressPercentage = _calculateProgress(
                            count,
                            required,
                            recommended,
                          );

                          return _buildExpandableCategoryCard(
                            context: context,
                            categoryName: category.name,
                            count: count,
                            required: required,
                            recommended: recommended,
                            progressPercentage: progressPercentage,
                            hasSubcategories: subcategories.isNotEmpty,
                            subcategories: subcategories,
                            caseProvider: caseProvider,
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Helper method to format group names for display
  String _formatGroupName(String groupId) {
    return groupId
        .split('_')
        .map(
          (word) =>
              word.length > 0
                  ? '${word[0].toUpperCase()}${word.substring(1)}'
                  : '',
        )
        .join(' ');
  }

  // Helper widget to build expandable category card
  Widget _buildExpandableCategoryCard({
    required BuildContext context,
    required String categoryName,
    required int count,
    required int required,
    int? recommended,
    required double progressPercentage,
    required bool hasSubcategories,
    required List<CoaCategory> subcategories,
    required CaseProvider caseProvider,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    // Determine if we should show this category based on filter
    if (_coaFilterOption == 'Required' && required == 0) {
      return const SizedBox.shrink();
    }
    if (_coaFilterOption == 'Recommended' &&
        (recommended == null || recommended == 0)) {
      return const SizedBox.shrink();
    }

    // Calculate progress using our helper method
    final actualProgress = _calculateProgress(count, required, recommended);

    // Get progress color using our helper method
    final Color progressColor = _getProgressColor(actualProgress);

    // Format count text using our helper method
    final String countText = _formatCountDisplay(count, required, recommended);

    // Get text color based on completion
    final Color textColor = _getTextColor(
      count,
      required,
      recommended,
      isDarkMode,
    );

    // Calculate exceeded percentage for display
    final String exceededText =
        required > 0 && count > required
            ? " (${((count / required) * 100).toInt()}%)"
            : "";

    // Use a more compact text style for the count
    final TextStyle countTextStyle = AppTextStyles.caption.copyWith(
      fontWeight: FontWeight.bold,
      color: textColor,
      fontSize: 11, // Smaller font size
    );

    return ExpansionTile(
      title: Row(
        children: [
          Expanded(
            flex: 3, // Give more space to the category name
            child: Text(
              categoryName,
              style: AppTextStyles.bodyText2.copyWith(
                fontSize: 13, // Slightly smaller font
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4), // Small spacing
          Text(countText + exceededText, style: countTextStyle),
        ],
      ),
      subtitle: LinearPercentIndicator(
        lineHeight: 8.0,
        percent: actualProgress,
        backgroundColor:
            isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        barRadius: const Radius.circular(4),
        padding: EdgeInsets.zero,
        animation: true,
        animationDuration: 1000,
        linearGradient: LinearGradient(
          colors: [
            AppColors.progressRed,
            AppColors.progressOrange,
            AppColors.progressGreen,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        progressColor: null, // Use gradient instead
      ),
      children: [
        if (hasSubcategories)
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Subcategories:',
                  style: AppTextStyles.bodyText2.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12, // Smaller font size
                  ),
                ),
                const SizedBox(height: 8),
                ...subcategories.map((subcategory) {
                  final int subCount = caseProvider.getCaseCountByCategory(
                    subcategory.id,
                  );
                  final int subRequired = subcategory.requiredCount;
                  final int? subRecommended = subcategory.recommendedCount;

                  // Apply the same filter logic to subcategories
                  if (_coaFilterOption == 'Required' && subRequired == 0) {
                    return const SizedBox.shrink();
                  }
                  if (_coaFilterOption == 'Recommended' &&
                      (subRecommended == null || subRecommended == 0)) {
                    return const SizedBox.shrink();
                  }

                  // Calculate subcategory progress and format text
                  final subProgress = _calculateProgress(
                    subCount,
                    subRequired,
                    subRecommended,
                  );
                  final String subCountText = _formatCountDisplay(
                    subCount,
                    subRequired,
                    subRecommended,
                  );
                  final Color subTextColor = _getTextColor(
                    subCount,
                    subRequired,
                    subRecommended,
                    isDarkMode,
                  );

                  // Calculate exceeded percentage for subcategory
                  final String subExceededText =
                      subRequired > 0 && subCount > subRequired
                          ? " (${((subCount / subRequired) * 100).toInt()}%)"
                          : "";

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const SizedBox(width: 8), // Reduced indent
                        Expanded(
                          flex: 3, // Give more space to the category name
                          child: Text(
                            subcategory.name,
                            style: AppTextStyles.bodyText2.copyWith(
                              fontSize: 12, // Smaller font size
                              color: subTextColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4), // Small spacing
                        Text(
                          subCountText + subExceededText,
                          style: countTextStyle,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
      ],
    );
  }

  // Helper method to build filter chips
  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _coaFilterOption = label;
        });
      },
      backgroundColor:
          isSelected ? AppColors.primaryColor.withOpacity(0.1) : null,
      selectedColor: AppColors.primaryColor.withOpacity(0.2),
      labelPadding: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 2.0,
      ), // Added padding
      padding: const EdgeInsets.all(4.0), // Added padding
      elevation: isSelected ? 1.0 : 0.0, // Added subtle elevation when selected
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0), // Rounded corners
        side: BorderSide(
          color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
          width: 1.0,
        ),
      ),
    );
  }

  Widget _buildSummaryStats(CaseProvider caseProvider) {
    // Get CategoryProvider to access all categories
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    // Calculate overall completion using the actual number of unique cases
    // Instead of summing up category counts, we just use the total cases count
    int totalCompleted = caseProvider.cases.length;
    int totalRequired = 650; // Set the correct minimum total case requirement

    // Calculate completion percentage
    final double completionPercentage =
        totalRequired > 0 ? (totalCompleted / totalRequired) : 0.0;

    // Format percentage for display
    final String percentageText = (completionPercentage * 100).toStringAsFixed(
      1,
    );

    // Get color based on completion
    final Color percentageColor = _getProgressColor(completionPercentage);

    // Calculate total clinical hours
    final timeEntryProvider = Provider.of<TimeEntryProvider>(
      context,
      listen: false,
    );
    final totalClinicalHours = timeEntryProvider.getTotalHours();

    // Calculate hours completion percentage (out of 2000 required hours)
    final double hoursPercentage = (totalClinicalHours / 2000).clamp(0.0, 1.0);
    final Color hoursColor = _getProgressColor(hoursPercentage);

    // Calculate total cases - this is simply the number of case entries
    final totalCases = caseProvider.cases.length;

    // Create a more compact text style for stats
    final TextStyle statLabelStyle = AppTextStyles.bodyText2.copyWith(
      fontSize: 13,
    );

    final TextStyle statValueStyle = AppTextStyles.subtitle2.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: 13,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Progress Summary',
              style: AppTextStyles.subtitle1.copyWith(fontSize: 15),
            ),
            const Divider(),
            const SizedBox(height: 8),

            // COA Requirements Progress with layout that won't overflow
            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'COA Requirements:',
                        style: statLabelStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$totalCompleted/$totalRequired ($percentageText%)',
                      style: statValueStyle.copyWith(color: percentageColor),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),

            // Progress bar
            LinearPercentIndicator(
              lineHeight: 10.0,
              percent: completionPercentage.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              barRadius: const Radius.circular(5),
              padding: EdgeInsets.zero,
              animation: true,
              animationDuration: 1000,
              linearGradient: LinearGradient(
                colors: [
                  AppColors.progressRed,
                  AppColors.progressOrange,
                  AppColors.progressGreen,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            const SizedBox(height: 16),

            // Total Cases with layout that won't overflow
            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Total Cases:',
                        style: statLabelStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('$totalCases', style: statValueStyle),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),

            // Total Clinical Hours with layout that won't overflow
            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Total Clinical Hours:',
                        style: statLabelStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${totalClinicalHours.toStringAsFixed(1)}/2000 (${(hoursPercentage * 100).toStringAsFixed(1)}%)',
                      style: statValueStyle.copyWith(color: hoursColor),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, int index) {
    switch (index) {
      case 0:
        // Use pushReplacementNamed with a try-catch to handle any navigation errors
        try {
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        } catch (e) {
          print('Navigation error: $e');
          // Fallback navigation if the standard approach fails
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
        }
        break;
      case 1:
        // Already on logs screen
        break;
      case 2:
        Navigator.of(context).pushNamed(AppRoutes.addCase);
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed(AppRoutes.goals);
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed(AppRoutes.messages);
        break;
    }
  }

  List<ClinicalCase> _getFilteredCases(List<ClinicalCase> allCases) {
    // First, filter by search query
    List<ClinicalCase> filteredCases =
        allCases.where((caseItem) {
          final lowerQuery = _searchQuery.toLowerCase();
          return caseItem.procedure.toLowerCase().contains(lowerQuery) ||
              caseItem.location.toLowerCase().contains(lowerQuery) ||
              caseItem.anesthesiaType.toLowerCase().contains(lowerQuery) ||
              caseItem.notes.toLowerCase().contains(lowerQuery);
        }).toList();

    // Then, filter by category if not "All"
    if (_filterCategory != 'All') {
      filteredCases =
          filteredCases.where((caseItem) {
            return caseItem.coaCategories.contains(_filterCategory) ||
                caseItem.anesthesiaType == _filterCategory;
          }).toList();
    }

    // Finally, sort the cases
    filteredCases.sort((a, b) {
      switch (_sortOption) {
        case 'Date (Newest)':
          return b.date.compareTo(a.date);
        case 'Date (Oldest)':
          return a.date.compareTo(b.date);
        case 'Duration (Highest)':
          return b.durationHours.compareTo(a.durationHours);
        case 'Duration (Lowest)':
          return a.durationHours.compareTo(b.durationHours);
        default:
          return b.date.compareTo(a.date);
      }
    });

    return filteredCases;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.article_outlined,
            size: 80,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text('No Clinical Cases Found', style: AppTextStyles.headline3),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _filterCategory != 'All'
                ? 'Try changing your search or filters'
                : 'Add your first clinical case to get started',
            style: AppTextStyles.bodyText2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.addCase);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Case'),
          ),
        ],
      ),
    );
  }

  Widget _buildCasesList(List<ClinicalCase> cases) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final clinicalCase = cases[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(clinicalCase.procedure, style: AppTextStyles.subtitle1),
            subtitle: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: 4),
                Text(
                  '${clinicalCase.date.day}/${clinicalCase.date.month}/${clinicalCase.date.year}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(width: 8),
                Icon(Icons.access_time, size: 12, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                  '${clinicalCase.durationHours.toStringAsFixed(1)} hrs',
                  style: AppTextStyles.caption,
                ),
                if (clinicalCase.isSimulated) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.science, size: 12, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(
                    'Simulated',
                    style: AppTextStyles.caption.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'edit') {
                  // Navigate to edit case screen
                  Navigator.of(context).pushNamed(
                    AppRoutes.addCase,
                    arguments: {'caseToEdit': clinicalCase},
                  );
                } else if (value == 'delete') {
                  _showDeleteConfirmation(clinicalCase);
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete,
                            size: 18,
                            color: AppColors.errorColor,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(color: AppColors.errorColor),
                          ),
                        ],
                      ),
                    ),
                  ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Details section
                    _buildDetailItem(
                      'Anesthesia Type',
                      clinicalCase.anesthesiaType,
                    ),
                    _buildDetailItem(
                      'Patient Age',
                      '${clinicalCase.patientAge} (${clinicalCase.patientAgeCategory})',
                    ),
                    _buildDetailItem(
                      'Patient Gender',
                      clinicalCase.patientGender,
                    ),
                    _buildDetailItem('ASA Class', clinicalCase.asaClass),
                    _buildDetailItem('Location', clinicalCase.location),
                    if (clinicalCase.isSimulated)
                      _buildDetailItem('Case Type', 'Simulated Case'),

                    const SizedBox(height: 8),

                    // COA Categories
                    const Text(
                      'COA Categories:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 6,
                      children:
                          clinicalCase.coaCategories.map((category) {
                            return Chip(
                              label: Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: AppColors.primaryColor,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                    ),

                    // Notes section if available
                    if (clinicalCase.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Notes:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(clinicalCase.notes),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Cases'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  _filterOptions.map((filter) {
                    return RadioListTile<String>(
                      title: Text(filter),
                      value: filter,
                      groupValue: _filterCategory,
                      onChanged: (value) {
                        setState(() {
                          _filterCategory = value!;
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sort Cases'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  _sortOptions.map((option) {
                    return RadioListTile<String>(
                      title: Text(option),
                      value: option,
                      groupValue: _sortOption,
                      onChanged: (value) {
                        setState(() {
                          _sortOption = value!;
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(ClinicalCase clinicalCase) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Case'),
          content: const Text(
            'Are you sure you want to delete this case? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final caseProvider = Provider.of<CaseProvider>(
                  context,
                  listen: false,
                );
                caseProvider.deleteCase(clinicalCase.id);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Case deleted'),
                    backgroundColor: AppColors.errorColor,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.errorColor),
              ),
            ),
          ],
        );
      },
    );
  }

  // Build the Clinical Hours tab
  Widget _buildClinicalHoursTab() {
    final timeEntryProvider = Provider.of<TimeEntryProvider>(context);
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final clinicalSiteProvider = Provider.of<ClinicalSiteProvider>(context);
    final caseProvider = Provider.of<CaseProvider>(context);

    // Get all time entries and sort by most recent first
    final allEntries = List<TimeEntry>.from(timeEntryProvider.entries);
    allEntries.sort((a, b) => b.clockInTime.compareTo(a.clockInTime));

    // Calculate total clinical hours
    final totalClinicalHours = timeEntryProvider.getTotalHours();

    // Calculate total anesthesia hours from cases
    final totalAnesthesiaHours = caseProvider.getTotalAnesthesiaHours();

    // Format dates and times
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the home screen where clock in is available
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        },
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.timer),
        tooltip: 'Clock In/Out',
      ),
      body: Column(
        children: [
          // Info card explaining clinical hours
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: isDarkMode ? Colors.blue[300] : Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Clinical Hours Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? Colors.white
                                    : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Total clinical hours row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Clinical Hours:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? Colors.grey[200]
                                    : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          totalClinicalHours.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? AppColors.accentColorDark
                                    : AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Total anesthesia hours row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Anesthesia Hours:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? Colors.grey[200]
                                    : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          totalAnesthesiaHours.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? AppColors.accentColorDark
                                    : AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'According to COA guidelines: "Clinical hours include time spent in the actual administration of anesthesia (i.e., anesthesia time) and other time spent in the clinical area."',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color:
                            isDarkMode
                                ? Colors.grey[400]
                                : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // List of time entries
          Expanded(
            child:
                allEntries.isEmpty
                    ? Center(
                      child: Text(
                        'No clinical hours recorded yet.\nUse the Clock In/Out feature on the home screen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              isDarkMode
                                  ? Colors.grey[400]
                                  : AppColors.textSecondary,
                        ),
                      ),
                    )
                    : ListView.builder(
                      itemCount: allEntries.length,
                      itemBuilder: (context, index) {
                        final entry = allEntries[index];

                        // Get site name
                        final siteName =
                            clinicalSiteProvider
                                .getSiteById(entry.clinicalSiteId)
                                ?.name ??
                            'Unknown Site';

                        // Calculate duration
                        final duration =
                            entry.clockOutTime != null
                                ? entry.clockOutTime!.difference(
                                  entry.clockInTime,
                                )
                                : DateTime.now().difference(entry.clockInTime);

                        // Format duration as hours and minutes
                        final hours = duration.inHours;
                        final minutes = (duration.inMinutes % 60);
                        final durationText =
                            '$hours h ${minutes.toString().padLeft(2, '0')} m';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16.0),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    siteName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentColor.withOpacity(
                                      0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    durationText,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color:
                                          isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'In: ${dateFormat.format(entry.clockInTime)} at ${timeFormat.format(entry.clockInTime)}',
                                      style: TextStyle(
                                        color:
                                            isDarkMode
                                                ? Colors.grey[300]
                                                : Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                                if (entry.clockOutTime != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_filled,
                                          size: 16,
                                          color:
                                              isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Out: ${dateFormat.format(entry.clockOutTime!)} at ${timeFormat.format(entry.clockOutTime!)}',
                                          style: TextStyle(
                                            color:
                                                isDarkMode
                                                    ? Colors.grey[300]
                                                    : Colors.grey[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.warning,
                                          size: 16,
                                          color: Colors.orangeAccent,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Currently clocked in',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orangeAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (entry.notes.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.note,
                                          size: 16,
                                          color:
                                              isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Notes: ${entry.notes}',
                                            style: TextStyle(
                                              color:
                                                  isDarkMode
                                                      ? Colors.grey[300]
                                                      : Colors.grey[800],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            // Add edit button to modify time entries
                            trailing: IconButton(
                              icon: Icon(
                                Icons.edit,
                                color:
                                    isDarkMode ? Colors.blue[300] : Colors.blue,
                              ),
                              onPressed: () => _editTimeEntry(entry),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  // Function to edit time entry
  void _editTimeEntry(TimeEntry entry) async {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final clinicalSiteProvider = Provider.of<ClinicalSiteProvider>(
      context,
      listen: false,
    );
    final timeEntryProvider = Provider.of<TimeEntryProvider>(
      context,
      listen: false,
    );

    // Initialize with current values
    DateTime clockInTime = entry.clockInTime;
    DateTime? clockOutTime = entry.clockOutTime;
    String notes = entry.notes;

    // Get site name
    final siteName =
        clinicalSiteProvider.sites
            .firstWhere(
              (site) => site.id == entry.clinicalSiteId,
              orElse:
                  () => ClinicalSite(
                    name: 'Unknown Site',
                    address: '',
                    startDate: DateTime.now(),
                    durationWeeks: 12,
                    isActive: false,
                  ),
            )
            .name;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Calculate duration
            final duration =
                clockOutTime != null
                    ? clockOutTime!.difference(clockInTime)
                    : DateTime.now().difference(clockInTime);

            final hours = duration.inHours;
            final minutes = duration.inMinutes.remainder(60);
            final durationText = '${hours}h ${minutes}m';

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Edit Time Entry',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            isDarkMode ? Colors.white : AppColors.textPrimary,
                      ),
                    ),

                    // Site name
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                      child: Text(
                        siteName,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDarkMode
                                  ? Colors.grey[400]
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ),

                    // Date displayed as text (non-editable)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Date: ${DateFormat('EEE, MMM d, yyyy').format(clockInTime)}',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  isDarkMode
                                      ? Colors.white
                                      : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Time Picker Section with Timeline
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Clock-in time
                          InkWell(
                            onTap: () async {
                              final TimeOfDay? selectedTime =
                                  await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(
                                      clockInTime,
                                    ),
                                  );

                              if (selectedTime != null) {
                                setState(() {
                                  // Keep the same date, update just the time
                                  final DateTime newClockIn = DateTime(
                                    clockInTime.year,
                                    clockInTime.month,
                                    clockInTime.day,
                                    selectedTime.hour,
                                    selectedTime.minute,
                                  );

                                  // Validate the new time
                                  if (clockOutTime != null &&
                                      newClockIn.isAfter(clockOutTime!)) {
                                    // Show error
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Clock-in time cannot be after clock-out time',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } else {
                                    clockInTime = newClockIn;
                                  }
                                });
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Clock-in:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        DateFormat(
                                          'h:mm a',
                                        ).format(clockInTime),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isDarkMode
                                                  ? Colors.white
                                                  : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.access_time,
                                        size: 18,
                                        color:
                                            isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Visual timeline indicator
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 2,
                                    color:
                                        isDarkMode
                                            ? Colors.grey[700]
                                            : Colors.grey[400],
                                  ),
                                ),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color:
                                        clockOutTime != null
                                            ? Colors.orange
                                            : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Clock-out time
                          InkWell(
                            onTap: () async {
                              final TimeOfDay? selectedTime =
                                  await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(
                                      clockOutTime ?? DateTime.now(),
                                    ),
                                  );

                              if (selectedTime != null) {
                                setState(() {
                                  // Keep the same date as clock-in, update just the time
                                  final DateTime newClockOut = DateTime(
                                    clockInTime.year,
                                    clockInTime.month,
                                    clockInTime.day,
                                    selectedTime.hour,
                                    selectedTime.minute,
                                  );

                                  // Handle day change if necessary
                                  if (newClockOut.isBefore(clockInTime)) {
                                    // Add a day if the time is before clock-in (assume next day)
                                    clockOutTime = newClockOut.add(
                                      Duration(days: 1),
                                    );
                                  } else {
                                    clockOutTime = newClockOut;
                                  }
                                });
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Clock-out:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        clockOutTime != null
                                            ? DateFormat(
                                              'h:mm a',
                                            ).format(clockOutTime!)
                                            : 'Active',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isDarkMode
                                                  ? Colors.white
                                                  : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.access_time,
                                        size: 18,
                                        color:
                                            isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Duration
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.timelapse,
                                  size: 16,
                                  color:
                                      isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Duration: $durationText',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDarkMode
                                            ? AppColors.accentColorDark
                                            : AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Notes TextField
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: TextField(
                        controller: TextEditingController(text: notes),
                        onChanged: (value) {
                          notes = value;
                        },
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ),

                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, {
                                'clockInTime': clockInTime,
                                'clockOutTime': clockOutTime,
                                'notes': notes,
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Save'),
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

    // Process the result and update the time entry
    if (result != null) {
      try {
        await timeEntryProvider.updateTimeEntry(
          id: entry.id,
          clockInTime: result['clockInTime'] as DateTime,
          clockOutTime: result['clockOutTime'] as DateTime?,
          notes: result['notes'] as String,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Time entry updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update time entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showExportOptionsDialog() {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Export Logs'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose how you want to export your logs:',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Download option
              ListTile(
                leading: Icon(
                  Icons.download,
                  color: AppColors.getPrimaryColor(isDarkMode),
                ),
                title: const Text('Download PDF'),
                subtitle: const Text('Save logs to your device'),
                onTap: () {
                  Navigator.pop(context);
                  _exportLogs(ExportType.allLogs);
                },
              ),

              // Print option
              ListTile(
                leading: Icon(
                  Icons.print,
                  color: AppColors.getPrimaryColor(isDarkMode),
                ),
                title: const Text('Print'),
                subtitle: const Text('Send logs to printer'),
                onTap: () {
                  Navigator.pop(context);
                  _exportLogs(ExportType.siteLogs);
                },
              ),

              // Email option
              ListTile(
                leading: Icon(
                  Icons.email,
                  color: AppColors.getPrimaryColor(isDarkMode),
                ),
                title: const Text('Email'),
                subtitle: const Text('Send logs via email'),
                onTap: () {
                  Navigator.pop(context);
                  _exportLogs(ExportType.coaTranscript);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _exportLogs(ExportType exportType) {
    // Show filter options dialog for selecting what to export
    _showExportFilterDialog(exportType);
  }

  // Show dialog to filter what logs to export
  void _showExportFilterDialog(ExportType exportType) {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final clinicalSiteProvider = Provider.of<ClinicalSiteProvider>(
      context,
      listen: false,
    );
    final sites = clinicalSiteProvider.sites;

    // State variables
    bool exportAll = true;
    String selectedSiteId = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Export Logs'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // All logs option
                    RadioListTile<bool>(
                      title: const Text('All Logs'),
                      subtitle: const Text(
                        'Export complete logs organized by site',
                      ),
                      value: true,
                      groupValue: exportAll,
                      onChanged: (value) {
                        setState(() {
                          exportAll = value!;
                        });
                      },
                    ),

                    // By site option
                    RadioListTile<bool>(
                      title: const Text('Filter by Site'),
                      value: false,
                      groupValue: exportAll,
                      onChanged: (value) {
                        setState(() {
                          exportAll = value!;
                          // Pre-select first site if available
                          if (sites.isNotEmpty && selectedSiteId.isEmpty) {
                            selectedSiteId = sites.first.id;
                          }
                        });
                      },
                    ),

                    // Site selector (visible when filter by site is selected)
                    if (!exportAll && sites.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          bottom: 8.0,
                        ),
                        child: DropdownButtonFormField<String>(
                          value:
                              selectedSiteId.isEmpty
                                  ? sites.first.id
                                  : selectedSiteId,
                          decoration: const InputDecoration(
                            labelText: 'Select Clinical Site',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items:
                              sites.map((site) {
                                return DropdownMenuItem<String>(
                                  value: site.id,
                                  child: Text(
                                    site.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSiteId = value!;
                            });
                          },
                        ),
                      ),

                    // No sites message
                    if (!exportAll && sites.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No clinical sites available',
                          style: TextStyle(
                            color: isDarkMode ? Colors.red[300] : Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
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
                    Navigator.pop(context);
                    // Process the export
                    _processExport(exportType);
                  },
                  child: const Text('Export'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Handle the actual export process
  Future<void> _processExport(ExportType exportType) async {
    // Get providers
    final caseProvider = Provider.of<CaseProvider>(context, listen: false);
    final timeEntryProvider = Provider.of<TimeEntryProvider>(
      context,
      listen: false,
    );
    final clinicalSiteProvider = Provider.of<ClinicalSiteProvider>(
      context,
      listen: false,
    );

    // Prepare message
    String message = '';

    if (exportType == ExportType.allLogs) {
      message = 'Exporting all logs...';
    } else if (exportType == ExportType.siteLogs) {
      // Get the site name for the feedback message
      final clinicalSite = clinicalSiteProvider.sites.firstWhere(
        (site) => site.id == _selectedSiteId,
        orElse:
            () => ClinicalSite(
              name: 'Unknown Site',
              address: 'Unknown Address',
              startDate: DateTime.now(),
              durationWeeks: 12,
              isActive: false,
            ),
      );
      message = 'Exporting logs for ${clinicalSite.name}...';
    } else if (exportType == ExportType.coaTranscript) {
      message = 'Generating COA transcript...';
    }

    // Show feedback
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    // Generate and export the appropriate data format
    String exportData = '';
    String fileName = '';

    if (exportType == ExportType.coaTranscript) {
      // Use our new transcript generation method
      exportData = _generateCOATranscript();
      fileName = 'navisthesia_coa_transcript.txt';
    } else {
      // For other export types, create a CSV
      // TODO: Implement proper CSV export for logs
      exportData = 'Date,Category,Actual/Simulated,Duration\n';

      // Get cases based on export type
      List<ClinicalCase> casesToExport = [];
      if (exportType == ExportType.allLogs) {
        casesToExport = List.from(caseProvider.cases);
      } else if (exportType == ExportType.siteLogs && _selectedSiteId != null) {
        // For now, we'll just export all cases since clinical site filtering
        // would require adding a clinicalSiteId property to the ClinicalCase model
        casesToExport = caseProvider.cases;
        // TODO: Add site property to ClinicalCase model and uncomment this:
        // casesToExport = caseProvider.cases
        //     .where((c) => c.site?.id == _selectedSiteId)
        //     .toList();
      }

      // Add all cases to the CSV
      for (var caseItem in casesToExport) {
        // Use uniqueCategories for the first category, or show "Multiple" if more than one
        final categoryName =
            caseItem.uniqueCategories.isNotEmpty
                ? getCategoryName(caseItem.uniqueCategories.first)
                : "None";
        final actualOrSimulated = caseItem.isSimulated ? 'Simulated' : 'Actual';
        final date = DateFormat('MM/dd/yyyy').format(caseItem.date);
        exportData +=
            '$date,$categoryName,$actualOrSimulated,${caseItem.duration}\n';
      }

      fileName =
          exportType == ExportType.allLogs
              ? 'navisthesia_all_logs.csv'
              : 'navisthesia_site_logs.csv';
    }

    // Save the file and share it
    await _saveAndShareFile(exportData, fileName);
  }

  Future<void> _saveAndShareFile(String content, String fileName) async {
    try {
      // Get the application directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      // Write the content to the file
      final file = File(filePath);
      await file.writeAsString(content);

      // Share the file - implementation will depend on platform-specific sharing
      // For now, we'll just show a success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export saved to $filePath')));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export completed successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exporting file: $e')));
    }
  }

  // Helper method to get category name
  String getCategoryName(String categoryId) {
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final category = categoryProvider.categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse:
          () => CoaCategory(
            id: categoryId,
            name: 'Unknown Category',
            group: 'unknown',
            isGroup: false,
            isSimulated: false,
            requiredCount: 0,
            description: 'Unknown category',
            isRequired: false,
          ),
    );

    return category.name;
  }

  // Helper method to get progress color based on completion percentage
  Color _getProgressColor(double percentage) {
    if (percentage >= 1.0) {
      return AppColors.progressGreen; // 100% or more - Green
    }
    if (percentage >= 0.5) {
      return AppColors.progressYellow; // 50-99% - Yellow
    }
    if (percentage >= 0.25) {
      return AppColors.progressOrange; // 25-49% - Orange
    }
    return AppColors.progressRed; // 0-24% - Red
  }

  // Helper method to format count display based on required and recommended values
  String _formatCountDisplay(int count, int required, int? recommended) {
    if (required > 0) {
      // If there's a required count, show it first
      String requiredText = '$count/$required';

      // Add recommended if available
      if (recommended != null && recommended > 0) {
        requiredText += ' [$recommended]';
      }

      return requiredText;
    } else if (recommended != null && recommended > 0) {
      // Only recommended available
      return '$count/[${recommended}]';
    } else {
      // Neither required nor recommended
      return '$count/0';
    }
  }

  // Helper method to calculate progress percentage
  double _calculateProgress(int count, int required, int? recommended) {
    if (required > 0) {
      return (count / required).clamp(0.0, 1.0);
    } else if (recommended != null && recommended > 0) {
      return (count / recommended).clamp(0.0, 1.0);
    } else {
      return 0.0;
    }
  }

  // Helper method to get text color based on completion
  Color _getTextColor(
    int count,
    int required,
    int? recommended,
    bool isDarkMode,
  ) {
    if (required > 0 && count >= required) {
      return AppColors.progressGreen;
    } else if (required == 0 && recommended != null && count >= recommended) {
      return AppColors.progressGreen;
    } else if (required > 0 && count >= required / 2) {
      return AppColors.progressYellow;
    } else {
      // Better contrast for text in dark mode
      return isDarkMode ? Colors.grey[300]! : AppColors.textPrimary;
    }
  }

  // Generate COA transcript data that distinguishes between actual and simulated cases
  String _generateCOATranscript() {
    final caseProvider = Provider.of<CaseProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final StringBuilder transcript = StringBuilder();

    // Add header
    transcript.appendLine('NAVISTHESIA COA TRANSCRIPT');
    transcript.appendLine('=======================');
    transcript.appendLine(
      'Generated: ${DateFormat('MM/dd/yyyy HH:mm').format(DateTime.now())}',
    );
    transcript.appendLine('');

    // Add student info section (placeholder)
    transcript.appendLine('STUDENT INFORMATION');
    transcript.appendLine('------------------');
    transcript.appendLine('Student Name: [Student Name]');
    transcript.appendLine('Student ID: [ID Number]');
    transcript.appendLine('Program: [Program Name]');
    transcript.appendLine('');

    // First, get all non-group, non-simulated categories (actual categories)
    final List<CoaCategory> actualCategories =
        categoryProvider.categories
            .where((category) => !category.isGroup && !category.isSimulated)
            .toList();

    // Group by their category groups
    final Map<String, List<CoaCategory>> categoriesByGroup = {};
    for (var category in actualCategories) {
      if (!categoriesByGroup.containsKey(category.group)) {
        categoriesByGroup[category.group] = [];
      }
      categoriesByGroup[category.group]!.add(category);
    }

    // Process each group
    for (var groupEntry in categoriesByGroup.entries) {
      // Convert group ID to a readable title
      String groupTitle = groupEntry.key
          .split('_')
          .map(
            (word) =>
                word.isEmpty
                    ? ''
                    : '${word[0].toUpperCase()}${word.substring(1)}',
          )
          .join(' ');

      transcript.appendLine(groupTitle.toUpperCase());
      transcript.appendLine('-' * groupTitle.length);

      // Process each category in this group
      for (var category in groupEntry.value) {
        // Get the detailed counts (actual vs simulated)
        final detailedCounts = caseProvider.getDetailedCaseCountByCategory(
          category.id,
        );
        final int actualCount = detailedCounts['actual'] ?? 0;
        final int simulatedCount = detailedCounts['simulated'] ?? 0;
        final int totalCount = detailedCounts['total'] ?? 0;

        // Format the requirement text
        String requirementText = '${category.requiredCount}';
        if (category.recommendedCount != null &&
            category.recommendedCount! > 0) {
          requirementText += ' [${category.recommendedCount}]';
        }

        // Create line with proper formatting for the transcript
        final bool isMet = totalCount >= category.requiredCount;
        final String statusMark = isMet ? '✓' : ' ';

        transcript.appendLine('$statusMark ${category.name}:');
        transcript.appendLine('  Required: $requirementText');
        transcript.appendLine('  Total Completed: $totalCount');

        // Only show breakdown if there are both types
        if (actualCount > 0 && simulatedCount > 0) {
          transcript.appendLine('  • Actual Cases: $actualCount');
          transcript.appendLine('  • Simulated Cases: $simulatedCount');
        } else if (simulatedCount > 0) {
          transcript.appendLine('  • All $simulatedCount cases were simulated');
        } else if (actualCount > 0) {
          transcript.appendLine('  • All $actualCount cases were actual');
        }

        transcript.appendLine('');
      }

      transcript.appendLine('');
    }

    // Add summary of overall COA requirements
    transcript.appendLine('SUMMARY');
    transcript.appendLine('-------');

    // Total cases
    final int totalCases = caseProvider.cases.length;
    final int totalActualCases =
        caseProvider.cases.where((c) => !c.isSimulated).length;
    final int totalSimulatedCases =
        caseProvider.cases.where((c) => c.isSimulated).length;
    final bool totalCasesRequirementMet = totalCases >= 650;
    final String totalCasesStatus = totalCasesRequirementMet ? '✓' : ' ';

    transcript.appendLine('$totalCasesStatus Total Cases: $totalCases/650');
    transcript.appendLine('  • Actual Cases: $totalActualCases');
    transcript.appendLine('  • Simulated Cases: $totalSimulatedCases');

    // Clinical hours (placeholder)
    transcript.appendLine(' Clinical Hours: 0/2000');

    // Add certification
    transcript.appendLine('');
    transcript.appendLine('CERTIFICATION');
    transcript.appendLine('------------');
    transcript.appendLine(
      'This transcript represents an accurate record of the student\'s clinical experiences.',
    );
    transcript.appendLine('');
    transcript.appendLine('___________________________    ____________');
    transcript.appendLine('Program Director Signature     Date');

    return transcript.toString();
  }
}
