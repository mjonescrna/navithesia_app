import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:navithesia_beta/constants/app_constants.dart';
import 'package:navithesia_beta/providers/case_provider.dart';
import 'package:navithesia_beta/providers/category_provider.dart';
import 'package:navithesia_beta/providers/clinical_site_provider.dart';
import 'package:navithesia_beta/providers/user_goals_provider.dart';
import 'package:navithesia_beta/models/coa_category_model.dart';
import 'package:navithesia_beta/models/clinical_site_model.dart';
import 'package:navithesia_beta/providers/theme_provider.dart';
import 'dart:math' as math;

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  int _selectedIndex = 3; // Index for the goals tab
  String _searchQuery = '';

  // Total COA clinical cases requirement
  static const int _totalClinicalCasesRequired = 650;

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final caseProvider = Provider.of<CaseProvider>(context);
    final clinicalSiteProvider = Provider.of<ClinicalSiteProvider>(context);
    final userGoalsProvider = Provider.of<UserGoalsProvider>(context);

    // Get all categories and their progress
    final allCategories = categoryProvider.categories;

    // Debug: Check if we have all the categories loaded correctly
    debugPrint('DEBUG: Goals screen loaded ${allCategories.length} categories');
    // Print first 10 categories to verify
    for (int i = 0; i < math.min(10, allCategories.length); i++) {
      debugPrint('DEBUG: Category ${i + 1}: ${allCategories[i].name}');
    }

    final categoryProgressList =
        allCategories.map((category) {
          final detailedCounts = caseProvider.getDetailedCaseCountByCategory(
            category.id,
          );
          return CoaCategoryProgress.fromDetailedCounts(
            category: category,
            detailedCounts: detailedCounts,
          );
        }).toList();

    // Get total clinical cases count
    final totalClinicalCases = caseProvider.cases.length;
    final totalProgress = totalClinicalCases / _totalClinicalCasesRequired;

    // Get current clinical site
    final ClinicalSite? activeSite = clinicalSiteProvider.activeSite;

    // Get user's personal goals
    final userGoals = userGoalsProvider.userGoals;
    final userGoalCategories =
        userGoals
            .map((goal) {
              final category = categoryProvider.getCategoryById(
                goal.categoryId,
              );
              if (category != null) {
                final detailedCounts = caseProvider
                    .getDetailedCaseCountByCategory(category.id);
                return MapEntry(
                  goal,
                  CoaCategoryProgress.fromDetailedCounts(
                    category: category,
                    detailedCounts: detailedCounts,
                  ),
                );
              }
              return null;
            })
            .whereType<MapEntry<UserGoal, CoaCategoryProgress>>()
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('COA Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddPersonalGoalDialog(
                context,
                categoryProvider,
                userGoalsProvider,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Overall progress section
          _buildOverallProgress(totalClinicalCases, totalProgress, activeSite),

          // Personal goals section - now vertical with 2 columns
          Expanded(
            child: _buildPersonalGoalsSection(
              userGoalCategories,
              userGoalsProvider,
            ),
          ),
        ],
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

  Widget _buildPersonalGoalsSection(
    List<MapEntry<UserGoal, CoaCategoryProgress>> userGoalCategories,
    UserGoalsProvider userGoalsProvider,
  ) {
    if (userGoalCategories.isEmpty) {
      return _buildNoGoalsCard(context, userGoalsProvider);
    }

    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Personal Goals', style: AppTextStyles.subtitle1),
              TextButton.icon(
                onPressed: () {
                  _showAddPersonalGoalDialog(
                    context,
                    Provider.of<CategoryProvider>(context, listen: false),
                    userGoalsProvider,
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Changed to a vertical grid with 2 columns
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.5,
              ),
              itemCount: userGoalCategories.length,
              itemBuilder: (context, index) {
                final goalEntry = userGoalCategories[index];
                final goal = goalEntry.key;
                final categoryProgress = goalEntry.value;
                final category = categoryProgress.category;
                final progress = categoryProgress.progressPercentage;

                return Card(
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      _showCategoryDetailsDialog(
                        categoryProgress,
                        userGoalsProvider,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category.name,
                                  style: AppTextStyles.subtitle2,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              // Show simulation indicator if there are simulated cases
                              if (categoryProgress.hasSimulatedCases)
                                Tooltip(
                                  message: 'Includes simulated cases',
                                  child: Icon(
                                    Icons.science,
                                    color: AppColors.accentColor,
                                    size: 14,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.star,
                                  color: AppColors.accentColor,
                                  size: 14,
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${categoryProgress.currentCount}/${goal.targetCount}',
                                style: AppTextStyles.caption,
                              ),
                              // Display breakdown if there are both types
                              if (categoryProgress.actualCount > 0 &&
                                  categoryProgress.simulatedCount > 0)
                                Text(
                                  '${categoryProgress.actualCount}A/${categoryProgress.simulatedCount}S',
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber[700],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // If we have both types, show a dual-colored progress bar
                          categoryProgress.hasSimulatedCases &&
                                  categoryProgress.actualCount > 0
                              ? Stack(
                                children: [
                                  // Background bar
                                  Container(
                                    height: 8.0,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  // Actual cases (blue)
                                  FractionallySizedBox(
                                    widthFactor: (categoryProgress.actualCount /
                                            goal.targetCount)
                                        .clamp(0.0, 1.0),
                                    child: Container(
                                      height: 8.0,
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  // Simulated cases (amber) - placed on top of actual
                                  Positioned(
                                    left: (categoryProgress.actualCount /
                                            goal.targetCount *
                                            MediaQuery.of(context).size.width *
                                            0.4)
                                        .clamp(0.0, double.infinity),
                                    child: FractionallySizedBox(
                                      widthFactor: (categoryProgress
                                                  .simulatedCount /
                                              goal.targetCount)
                                          .clamp(
                                            0.0,
                                            1.0 -
                                                (categoryProgress.actualCount /
                                                        goal.targetCount)
                                                    .clamp(0.0, 1.0),
                                          ),
                                      child: Container(
                                        height: 8.0,
                                        decoration: BoxDecoration(
                                          color: Colors.amber,
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(4),
                                            bottomRight: Radius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                              :
                              // Standard progress bar for single type
                              LinearPercentIndicator(
                                lineHeight: 8.0,
                                percent: progress.clamp(0.0, 1.0),
                                padding: EdgeInsets.zero,
                                linearGradient: const LinearGradient(
                                  colors: [
                                    AppColors.progressRed,
                                    AppColors.progressOrange,
                                    AppColors.progressYellow,
                                    AppColors.progressGreen,
                                  ],
                                  stops: [0.25, 0.5, 0.75, 1.0],
                                ),
                                backgroundColor: Colors.grey.shade200,
                                barRadius: const Radius.circular(4),
                              ),
                        ],
                      ),
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

  void _navigateToScreen(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.logs);
        break;
      case 2:
        Navigator.of(context).pushNamed(AppRoutes.addCase);
        break;
      case 3:
        // Already on goals screen
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed(AppRoutes.messages);
        break;
    }
  }

  // Method to get progress color based on percentage with dark mode support
  Color _getProgressColor(double percentage, [bool? isDarkModeParam]) {
    final isDarkMode =
        isDarkModeParam ?? Provider.of<ThemeProvider>(context).isDarkMode;

    if (percentage < 0.25) {
      return isDarkMode ? AppColors.progressRedDark : AppColors.progressRed;
    } else if (percentage < 0.5) {
      return isDarkMode
          ? AppColors.progressOrangeDark
          : AppColors.progressOrange;
    } else if (percentage < 0.91) {
      return isDarkMode
          ? AppColors.progressYellowDark
          : AppColors.progressYellow;
    } else {
      return isDarkMode ? AppColors.progressGreenDark : AppColors.progressGreen;
    }
  }

  Widget _buildOverallProgress(
    int totalClinicalCases,
    double totalProgress,
    ClinicalSite? activeSite,
  ) {
    // Get the appropriate color based on progress percentage
    Color progressColor = _getProgressColor(totalProgress);

    // Get the text scale factor to adapt UI based on text size settings
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final isLargeText = textScaleFactor > 1.3;

    // Calculate responsive padding and sizes
    final circleSize = isLargeText ? 50.0 : 60.0;
    final lineWidth = isLargeText ? 10.0 : 12.0;
    final responsivePadding = EdgeInsets.all(
      16.0 * (1.0 + (textScaleFactor - 1.0) * 0.2),
    );

    return Card(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Padding(
        padding: responsivePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title with overflow protection
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Overall COA Progress',
                style: AppTextStyles.headline3.copyWith(
                  color:
                      Provider.of<ThemeProvider>(context).isDarkMode
                          ? Colors.white
                          : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (activeSite != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Current Site: ${activeSite.name}',
                    style: AppTextStyles.subtitle2.copyWith(
                      color:
                          Provider.of<ThemeProvider>(context).isDarkMode
                              ? Colors.grey[300]
                              : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Progress circle with responsive sizing
            CircularPercentIndicator(
              radius: circleSize,
              lineWidth: lineWidth,
              percent: totalProgress.clamp(0.0, 1.0),
              center: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${(totalProgress * 100).toInt()}%',
                        style: (isLargeText
                                ? AppTextStyles.headline3.copyWith(fontSize: 16)
                                : AppTextStyles.headline3)
                            .copyWith(
                              color:
                                  Provider.of<ThemeProvider>(context).isDarkMode
                                      ? Colors.white
                                      : AppColors.textPrimary,
                            ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$totalClinicalCases/$_totalClinicalCasesRequired',
                        style: (isLargeText
                                ? AppTextStyles.caption.copyWith(fontSize: 10)
                                : AppTextStyles.caption)
                            .copyWith(
                              color:
                                  Provider.of<ThemeProvider>(context).isDarkMode
                                      ? Colors.grey[300]
                                      : AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              progressColor: progressColor,
              backgroundColor:
                  Provider.of<ThemeProvider>(context).isDarkMode
                      ? Colors.grey[800]!
                      : Colors.grey[200]!,
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animationDuration: 1000,
            ),
            const SizedBox(height: 16),

            // Legend with scrollable row for accessibility
            isLargeText
                ? Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    _buildLegendItem(AppColors.progressRed, '0-25%'),
                    _buildLegendItem(AppColors.progressOrange, '26-50%'),
                    _buildLegendItem(AppColors.progressYellow, '51-90%'),
                    _buildLegendItem(AppColors.progressGreen, '91-100%'),
                  ],
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(AppColors.progressRed, '0-25%'),
                    _buildLegendItem(AppColors.progressOrange, '26-50%'),
                    _buildLegendItem(AppColors.progressYellow, '51-90%'),
                    _buildLegendItem(AppColors.progressGreen, '91-100%'),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    // Get the text scale factor for responsive design
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 4.0 * textScaleFactor.clamp(1.0, 1.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10 * textScaleFactor.clamp(0.8, 1.0),
            height: 10 * textScaleFactor.clamp(0.8, 1.0),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 4 * textScaleFactor.clamp(0.8, 1.2)),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isDarkMode ? Colors.grey[200] : AppColors.textSecondary,
              fontSize:
                  isDarkMode ? 12.0 : null, // Slightly larger text in dark mode
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showCategoryDetailsDialog(
    CoaCategoryProgress categoryProgress,
    UserGoalsProvider userGoalsProvider,
  ) {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final category = categoryProgress.category;
    final progress = categoryProgress.progressPercentage;

    // Get detailed case counts (actual vs simulated)
    final caseProvider = Provider.of<CaseProvider>(context, listen: false);
    final detailedCounts = caseProvider.getDetailedCaseCountByCategory(
      category.id,
    );
    final actualCount = detailedCounts['actual'] ?? 0;
    final simulatedCount = detailedCounts['simulated'] ?? 0;
    final totalCount = detailedCounts['total'] ?? 0;

    // Check if this category has a personal goal
    final userGoal = userGoalsProvider.getUserGoalForCategory(category.id);
    final hasPersonalGoal = userGoal != null;

    // Use personal goal target if it exists, otherwise use required count
    final targetCount =
        hasPersonalGoal ? userGoal.targetCount : category.requiredCount;
    final personalProgress =
        hasPersonalGoal ? (totalCount / targetCount).clamp(0.0, 1.0) : progress;

    // Get estimation for completion
    int remaining = targetCount - totalCount;
    remaining = remaining < 0 ? 0 : remaining;

    // Estimated time to completion (assumes 2 cases per week)
    final weeksToCompletion = remaining > 0 ? (remaining / 2).ceil() : 0;

    // Get appropriate color for progress
    final Color progressColor = _getProgressColor(
      hasPersonalGoal ? personalProgress : progress,
      isDarkMode,
    );

    showDialog(
      context: context,
      builder: (context) {
        // Get text scale factor for responsive sizing
        final textScaleFactor = MediaQuery.of(context).textScaleFactor;
        final isLargeText = textScaleFactor > 1.3;

        return AlertDialog(
          backgroundColor: isDarkMode ? Color(0xFF303030) : null,
          title: Text(
            category.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Help text if available
                if (category.helpText.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      category.helpText,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                        color:
                            isDarkMode
                                ? Colors.grey[300]
                                : AppColors.textSecondary,
                      ),
                    ),
                  ),

                // Progress Circle
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: CircularPercentIndicator(
                    radius: 75.0,
                    lineWidth: 12.0,
                    percent: hasPersonalGoal ? personalProgress : progress,
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${(hasPersonalGoal ? personalProgress * 100 : progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDarkMode
                                      ? Colors.white
                                      : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${totalCount}/$targetCount',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  isDarkMode
                                      ? Colors.grey[300]
                                      : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    progressColor: progressColor,
                    backgroundColor:
                        isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                ),

                // Breakdown of actual vs simulated cases
                if (totalCount > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isDarkMode ? Colors.grey[700]! : Colors.blue[200]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Case Breakdown:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? Colors.white
                                    : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Actual Cases:',
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? Colors.white
                                        : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '$actualCount',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkMode
                                        ? Colors.white
                                        : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Simulated Cases:',
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? Colors.white
                                        : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '$simulatedCount',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkMode
                                        ? Colors.amber[400]
                                        : Colors.amber[700],
                              ),
                            ),
                          ],
                        ),
                        if (actualCount > 0 && simulatedCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 12,
                                    child: Row(
                                      children: [
                                        Flexible(
                                          flex: actualCount,
                                          child: Container(
                                            height: 12,
                                            color:
                                                isDarkMode
                                                    ? Colors.blue[700]
                                                    : Colors.blue[400],
                                          ),
                                        ),
                                        Flexible(
                                          flex: simulatedCount,
                                          child: Container(
                                            height: 12,
                                            color:
                                                isDarkMode
                                                    ? Colors.amber[700]
                                                    : Colors.amber[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                // Statistics in a scrollable container
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.all(12 * textScaleFactor.clamp(0.8, 1.2)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasPersonalGoal)
                        _buildDetailRow(
                          'Personal Goal',
                          '${userGoal.targetCount} cases',
                        ),
                      _buildDetailRow(
                        'COA Required',
                        '${category.requiredCount} cases',
                      ),
                      _buildDetailRow('Completed Cases', '$totalCount'),
                      _buildDetailRow('Remaining Cases', '$remaining'),
                      _buildDetailRow(
                        'Estimated Completion',
                        remaining > 0
                            ? weeksToCompletion == 1
                                ? '~1 week'
                                : '~$weeksToCompletion weeks'
                            : 'Completed!',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (!hasPersonalGoal)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showAddPersonalGoalDialog(
                    context,
                    Provider.of<CategoryProvider>(context, listen: false),
                    userGoalsProvider,
                    initialCategory: category,
                  );
                },
                child: Text(
                  'Set Goal',
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? AppColors.accentColorDark
                            : AppColors.primaryColor,
                  ),
                ),
              ),
            if (hasPersonalGoal)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      // Remove personal goal
                      userGoalsProvider.removeUserGoal(category.id);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Remove Goal',
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.errorColorDark
                                : AppColors.errorColor,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Open the edit dialog with current goal settings
                      _showAddPersonalGoalDialog(
                        context,
                        Provider.of<CategoryProvider>(context, listen: false),
                        userGoalsProvider,
                        initialCategory: category,
                        isEditing: true,
                        initialTargetCount:
                            userGoal?.targetCount ?? category.requiredCount,
                      );
                    },
                    child: Text(
                      'Edit Goal',
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.accentColorDark
                                : AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Close',
                style: TextStyle(
                  color:
                      isDarkMode ? Colors.grey[300] : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    // Get text scale factor for responsive design
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final isLargeText = textScaleFactor > 1.3;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 4.0 * textScaleFactor.clamp(0.8, 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 3,
            child: Text(
              label,
              style: AppTextStyles.bodyText2.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isLargeText ? 12 : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8 * textScaleFactor.clamp(0.8, 1.0)),
          Flexible(
            flex: 2,
            child: Text(
              value,
              style: AppTextStyles.bodyText1.copyWith(
                fontSize: isLargeText ? 12 : null,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoGoalsCard(
    BuildContext context,
    UserGoalsProvider userGoalsProvider,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Card(
        color: isDarkMode ? Color(0xFF262626) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            children: [
              Icon(
                Icons.star,
                color:
                    isDarkMode
                        ? AppColors.accentColorDark
                        : AppColors.accentColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No personal goals set yet. Tap + to set your goals!',
                  style: AppTextStyles.bodyText2.copyWith(
                    color:
                        isDarkMode ? Colors.grey[300] : AppColors.textPrimary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _showAddPersonalGoalDialog(
                    context,
                    Provider.of<CategoryProvider>(context, listen: false),
                    userGoalsProvider,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDarkMode ? AppColors.accentColorDark : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('Add Goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddPersonalGoalDialog(
    BuildContext context,
    CategoryProvider categoryProvider,
    UserGoalsProvider userGoalsProvider, {
    String? preselectedCategoryId,
    CoaCategory? initialCategory,
    bool isEditing = false,
    int? initialTargetCount,
  }) {
    // Create a set to track selected categories
    final Set<String> selectedCategoryIds = {};

    // Default target count based on selected category
    int targetCount = initialTargetCount ?? 0;

    // Handle both preselectedCategoryId and initialCategory
    if (preselectedCategoryId != null) {
      selectedCategoryIds.add(preselectedCategoryId);
      final category = categoryProvider.getCategoryById(preselectedCategoryId);
      if (category != null) {
        targetCount = category.requiredCount;
      }
    } else if (initialCategory != null) {
      selectedCategoryIds.add(initialCategory.id);
      targetCount = initialCategory.requiredCount;
    }

    // Search query for filtering categories
    String searchQuery = '';

    // Get only actual categories (no simulated ones)
    final allCategories =
        categoryProvider.actualCategories.where((c) => !c.isGroup).toList();

    // Debug check to verify we have all the selectable categories
    debugPrint('Loaded ${allCategories.length} actual categories for goals');
    debugPrint('GOALS SCREEN: First 10 categories:');
    for (var i = 0; i < math.min(10, allCategories.length); i++) {
      debugPrint('Category ${i + 1}: ${allCategories[i].name}');
    }

    // Verify some expected key categories
    final hasTraumaEmergency = allCategories.any(
      (c) => c.name == 'Trauma / Emergency (E)',
    );
    final hasCentralLine = allCategories.any(
      (c) => c.name == 'Central Line Placement',
    );
    final hasNeck = allCategories.any((c) => c.name == 'Neck');

    debugPrint(
      'GOALS SCREEN Categories - has Trauma/Emergency: $hasTraumaEmergency, ' +
          'has Central Line: $hasCentralLine, has Neck: $hasNeck',
    );

    // Just to check if any names match the expected 40 categories
    int matchCount = 0;
    List<String> expectedCategories = [
      'Tracheal Intubation',
      'Supraglottic Airway Device',
      'Mask Management',
      'Alternative Airway Management',
      'Arterial Line Placement',
      'Central Line Placement',
      'IV Catheter Placement',
      'Pulmonary Artery Catheter Placement',
      'Pulmonary Artery Catheter Monitoring',
      'Assessment of Chest X-Ray',
      'Ultrasound Guided Techniques',
      'Imaging Interpretation',
      'Geriatric 65+ years',
      'Pediatric 2-12 years',
      'Pediatric <2 years',
      'Trauma / Emergency (E)',
      'Vascular',
      'Pain Management',
    ];

    for (var expected in expectedCategories) {
      if (allCategories.any((c) => c.name == expected)) {
        matchCount++;
      } else {
        debugPrint('Missing expected category: $expected');
      }
    }

    debugPrint(
      'Found $matchCount out of ${expectedCategories.length} expected categories',
    );

    showDialog(
      context: context,
      builder: (context) {
        // Get the text scale factor to adapt UI based on text size settings
        final textScaleFactor = MediaQuery.of(context).textScaleFactor;
        final isLargeText = textScaleFactor > 1.3;

        // Calculate responsive padding based on text scale
        final responsivePadding = EdgeInsets.symmetric(
          vertical: 8.0 * (1.0 + (textScaleFactor - 1.0) * 0.5),
          horizontal: 16.0 * (1.0 + (textScaleFactor - 1.0) * 0.2),
        );

        return StatefulBuilder(
          builder: (context, setState) {
            // Filter categories based on search query
            final filteredCategories =
                searchQuery.isEmpty
                    ? allCategories
                    : allCategories.where((category) {
                      return category.name.toLowerCase().contains(
                            searchQuery.toLowerCase(),
                          ) ||
                          category.description.toLowerCase().contains(
                            searchQuery.toLowerCase(),
                          );
                    }).toList();

            return Dialog(
              // Use Dialog instead of AlertDialog for more flexibility
              insetPadding: EdgeInsets.symmetric(
                horizontal: 16.0 * (1.0 + (textScaleFactor - 1.0) * 0.5),
                vertical: 24.0 * (1.0 + (textScaleFactor - 1.0) * 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Determine the maximum height based on screen size and text scale
                  final maxHeight =
                      isLargeText
                          ? MediaQuery.of(context).size.height * 0.8
                          : MediaQuery.of(context).size.height * 0.7;

                  return Container(
                    constraints: BoxConstraints(
                      maxWidth:
                          500, // Prevent excessive width on larger screens
                      maxHeight: maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title - using FittedBox to prevent overflow
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              isEditing
                                  ? 'Edit Personal Goal'
                                  : 'Add Personal Goal',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Search field - using an adjustable wrapper
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: 48.0 * textScaleFactor.clamp(1.0, 1.5),
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search Categories',
                                prefixIcon: const Icon(Icons.search),
                                border: const OutlineInputBorder(),
                                contentPadding: responsivePadding,
                                // Scale hint text down slightly if needed
                                hintStyle: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  fontSize: isLargeText ? 14.0 : null,
                                ),
                              ),
                              // Use textInputAction to better handle keyboard flow
                              textInputAction: TextInputAction.search,
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            height: 12.0 * textScaleFactor.clamp(1.0, 1.3),
                          ),

                          // Target count input - only when a category is selected
                          if (selectedCategoryIds.isNotEmpty)
                            Container(
                              padding: EdgeInsets.only(
                                bottom: 16.0 * textScaleFactor.clamp(1.0, 1.3),
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 2,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Show selected category
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'Selected: ${allCategories.firstWhere((cat) => cat.id == selectedCategoryIds.first, orElse: () => CoaCategory(id: 'unknown', name: 'Unknown', requiredCount: 0, description: '', group: '', isRequired: false)).name}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                        fontSize: isLargeText ? 14.0 : 16.0,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight:
                                            48.0 *
                                            textScaleFactor.clamp(1.0, 1.5),
                                      ),
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                          labelText: 'Target Count',
                                          border: const OutlineInputBorder(),
                                          helperText:
                                              isLargeText
                                                  ? 'Cases to complete'
                                                  : 'Number of cases you want to complete',
                                          helperMaxLines: 3,
                                          helperStyle: TextStyle(
                                            fontSize: isLargeText ? 11 : 12,
                                          ),
                                          contentPadding: responsivePadding,
                                          labelStyle: TextStyle(
                                            fontSize: isLargeText ? 14.0 : null,
                                          ),
                                          // Add prefix to make it clearer
                                          prefixIcon: const Icon(Icons.flag),
                                        ),
                                        keyboardType: TextInputType.number,
                                        initialValue: targetCount.toString(),
                                        onChanged: (value) {
                                          targetCount =
                                              int.tryParse(value) ?? 0;
                                        },
                                        // Auto focus when the field appears
                                        autofocus: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Available Categories label with overflow protection
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Available Categories (${filteredCategories.length}):',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isLargeText ? 14.0 : 16.0,
                                    ),
                                  ),
                                ),
                              ),
                              if (searchQuery.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      searchQuery = '';
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    minimumSize: Size.zero,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Clear Search',
                                    style: TextStyle(
                                      fontSize: isLargeText ? 12.0 : 14.0,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(
                            height: 8.0 * textScaleFactor.clamp(1.0, 1.2),
                          ),

                          // List of categories - using Expanded to take remaining space
                          Expanded(
                            child:
                                filteredCategories.isEmpty
                                    ? Center(
                                      child: Text(
                                        'No matching categories found',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: isLargeText ? 14.0 : null,
                                        ),
                                      ),
                                    )
                                    : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: filteredCategories.length,
                                      itemBuilder: (context, index) {
                                        final category =
                                            filteredCategories[index];
                                        final isSelected = selectedCategoryIds
                                            .contains(category.id);

                                        // Adapt RadioListTile for different text scales
                                        if (isLargeText) {
                                          // Use simplified layout for large text
                                          return InkWell(
                                            onTap: () {
                                              setState(() {
                                                selectedCategoryIds.clear();
                                                selectedCategoryIds.add(
                                                  category.id,
                                                );
                                                targetCount =
                                                    category.requiredCount;

                                                // Debug print to verify selection
                                                debugPrint(
                                                  'Tapped on category: ${category.name} with ID: ${category.id}',
                                                );
                                                debugPrint(
                                                  'Set target count to: $targetCount',
                                                );
                                              });
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8.0,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Radio<String>(
                                                    value: category.id,
                                                    groupValue:
                                                        selectedCategoryIds
                                                                .isEmpty
                                                            ? null
                                                            : selectedCategoryIds
                                                                .first,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        selectedCategoryIds
                                                            .clear();
                                                        if (value != null) {
                                                          selectedCategoryIds
                                                              .add(value);
                                                          targetCount =
                                                              category
                                                                  .requiredCount;

                                                          // Debug print to verify selection
                                                          debugPrint(
                                                            'Selected category: ${category.name} with ID: $value',
                                                          );
                                                          debugPrint(
                                                            'Set target count to: $targetCount',
                                                          );
                                                        }
                                                      });
                                                    },
                                                    activeColor:
                                                        AppColors.primaryColor,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      category.name,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            isSelected
                                                                ? FontWeight
                                                                    .bold
                                                                : FontWeight
                                                                    .normal,
                                                        fontSize:
                                                            14.0, // Smaller font size for large text scale
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        } else {
                                          // Standard RadioListTile for normal text
                                          return RadioListTile<String>(
                                            title: Text(
                                              category.name,
                                              style: TextStyle(
                                                fontWeight:
                                                    isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            value: category.id,
                                            groupValue:
                                                selectedCategoryIds.isEmpty
                                                    ? null
                                                    : selectedCategoryIds.first,
                                            onChanged: (value) {
                                              setState(() {
                                                selectedCategoryIds.clear();
                                                if (value != null) {
                                                  selectedCategoryIds.add(
                                                    value,
                                                  );
                                                  targetCount =
                                                      category.requiredCount;

                                                  // Debug print to verify selection
                                                  debugPrint(
                                                    'Selected category: ${category.name} with ID: $value',
                                                  );
                                                  debugPrint(
                                                    'Set target count to: $targetCount',
                                                  );
                                                }
                                              });
                                            },
                                            activeColor: AppColors.primaryColor,
                                            dense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 4.0,
                                                  vertical: 0.0,
                                                ),
                                          );
                                        }
                                      },
                                    ),
                          ),

                          // Actions - adjust layout based on text scale
                          Padding(
                            padding: EdgeInsets.only(
                              top: 16.0 * textScaleFactor.clamp(1.0, 1.3),
                            ),
                            child:
                                isLargeText
                                    // Vertical layout for large text
                                    ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        ElevatedButton(
                                          onPressed:
                                              selectedCategoryIds.isEmpty
                                                  ? null
                                                  : () {
                                                    // Read the final target count from the slider
                                                    final selectedCount =
                                                        targetCount < 0
                                                            ? 0
                                                            : targetCount;

                                                    // Read selected category (should be only one)
                                                    final String? categoryId =
                                                        selectedCategoryIds
                                                                .isNotEmpty
                                                            ? selectedCategoryIds
                                                                .first
                                                            : null;

                                                    if (categoryId != null) {
                                                      // Add or update the user goal
                                                      userGoalsProvider
                                                          .addUserGoal(
                                                            categoryId,
                                                            selectedCount,
                                                          );
                                                      Navigator.pop(context);
                                                    }
                                                  },
                                          child: Text(
                                            isEditing
                                                ? 'Save Changes'
                                                : 'Add Goal',
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        OutlinedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                      ],
                                    )
                                    // Horizontal layout for normal text
                                    : Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed:
                                              selectedCategoryIds.isEmpty
                                                  ? null
                                                  : () {
                                                    // Read the final target count from the slider
                                                    final selectedCount =
                                                        targetCount < 0
                                                            ? 0
                                                            : targetCount;

                                                    // Read selected category (should be only one)
                                                    final String? categoryId =
                                                        selectedCategoryIds
                                                                .isNotEmpty
                                                            ? selectedCategoryIds
                                                                .first
                                                            : null;

                                                    if (categoryId != null) {
                                                      // Add or update the user goal
                                                      userGoalsProvider
                                                          .addUserGoal(
                                                            categoryId,
                                                            selectedCount,
                                                          );
                                                      Navigator.pop(context);
                                                    }
                                                  },
                                          child: Text(
                                            isEditing
                                                ? 'Save Changes'
                                                : 'Add Goal',
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
