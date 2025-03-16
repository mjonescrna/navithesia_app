import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:navithesia_beta/constants/app_constants.dart';
import 'package:navithesia_beta/providers/auth_provider.dart';
import 'package:navithesia_beta/providers/case_provider.dart';
import 'package:navithesia_beta/providers/clinical_site_provider.dart';
import 'package:navithesia_beta/models/clinical_site_model.dart';
import 'package:navithesia_beta/providers/time_entry_provider.dart';
import 'package:navithesia_beta/models/time_entry_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:navithesia_beta/constants/coa_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'package:navithesia_beta/providers/theme_provider.dart';
import 'package:navithesia_beta/providers/category_provider.dart';

// Custom painter for progress ring - moved outside of the HomeScreen class
class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;

  ProgressRingPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;
    final strokeWidth = size.width / 10;
    const startAngle = -90.0 * (3.14159 / 180); // Start from top (in radians)

    // Draw background arc (full 360 degrees)
    final bgPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * 3.14159, // Full circle in radians
      false,
      bgPaint,
    );

    // Draw progress arc
    final progressPaint =
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final sweepAngle = progress * 2 * 3.14159; // Progress in radians

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final caseProvider = Provider.of<CaseProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip:
                themeProvider.isDarkMode
                    ? 'Switch to Light Mode'
                    : 'Switch to Dark Mode',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showSettingsDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              _showProfileDialog(context);
            },
          ),
        ],
      ),
      body: ScrollConfiguration(
        // This prevents overflow errors by allowing all content to scroll
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting section
              _buildGreetingSection(),
              const SizedBox(height: 24),

              // Clinical Site section
              _buildClinicalSiteSection(),
              const SizedBox(height: 24),

              // Summary cards
              _buildSummaryCards(caseProvider),
              const SizedBox(height: 24),

              // Recent cases
              _buildRecentCases(caseProvider),
              const SizedBox(height: 24),

              // Recent time entries
              _buildRecentTimeEntries(),
            ],
          ),
        ),
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
        selectedItemColor: AppColors.getPrimaryColor(isDarkMode),
        unselectedItemColor:
            isDarkMode ? Colors.grey[400] : AppColors.textLight,
      ),
    );
  }

  void _navigateToScreen(BuildContext context, int index) {
    switch (index) {
      case 0:
        // Already on home screen
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.logs);
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

  Widget _buildGreetingSection() {
    // Get the text scale factor to adapt UI based on text size settings
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final isLargeText = textScaleFactor > 1.3;
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    // Get the current user from the auth provider
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personal greeting with overflow protection
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Hello, ${user?.name.split(' ').first ?? 'there'}!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 4),
        // Welcome back with overflow protection
        Text(
          'Welcome back.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isDarkMode ? Colors.grey[300] : AppColors.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSummaryCards(CaseProvider caseProvider) {
    final timeEntryProvider = Provider.of<TimeEntryProvider>(context);
    final totalCases = caseProvider.cases.length;
    final totalClinicalHours = caseProvider
        .getTotalClinicalHoursWithTimeEntries(timeEntryProvider);
    final totalAnesthesiaHours = caseProvider.getTotalAnesthesiaHours();
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    // Get the required counts from constants or use defaults
    final requiredCases = 650; // COA requirement for total cases
    final requiredClinicalHours = 2000.0; // COA requirement for clinical hours
    final requiredAnesthesiaHours =
        600.0; // COA requirement for anesthesia hours

    // Get tracked category if it exists in SharedPreferences
    final String trackedCategory =
        _prefs?.getString('tracked_category_id') ?? 'general_anesthesia';
    final String trackedCategoryName =
        _prefs?.getString('tracked_category_name') ?? 'General Anesthesia';

    // Get detailed counts for the tracked category
    final detailedCounts = caseProvider.getDetailedCaseCountByCategory(
      trackedCategory,
    );
    final actualCount = detailedCounts['actual'] ?? 0;
    final simulatedCount = detailedCounts['simulated'] ?? 0;
    final trackedCategoryCount = detailedCounts['total'] ?? 0;

    // Find the required count for the tracked category
    int requiredCount = 40; // Default value
    try {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      final category = categoryProvider.getCategoryById(trackedCategory);
      if (category != null) {
        requiredCount = category.requiredCount;
      }
    } catch (e) {
      print('Error finding category: $e');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Summary', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 8),
            Tooltip(
              message:
                  'Clinical Hours: Total time spent in the clinical area from clock in/out\n\n'
                  'Anesthesia Hours: Time spent directly administering anesthesia from cases',
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: isDarkMode ? Colors.grey[400] : AppColors.textLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildProgressCard(
              title: 'Total Cases',
              value: '$totalCases/$requiredCases',
              icon: Icons.article,
              color: AppColors.getPrimaryColor(isDarkMode),
              current: totalCases,
              required: requiredCases,
              onTap: null, // No action for this card
            ),
            _buildProgressCard(
              title: 'Clinical Hours',
              value:
                  '${totalClinicalHours.toStringAsFixed(1)}/${requiredClinicalHours.toStringAsFixed(0)}',
              icon: Icons.access_time,
              color: AppColors.getAccentColor(isDarkMode),
              current: totalClinicalHours.toInt(),
              required: requiredClinicalHours.toInt(),
              subtitle: 'Time in clinical area',
              onTap: null, // No action for this card
            ),
            _buildProgressCard(
              title: 'Anesthesia Hours',
              value:
                  '${totalAnesthesiaHours.toStringAsFixed(1)}/${requiredAnesthesiaHours.toStringAsFixed(0)}',
              icon: Icons.medical_services,
              color: Colors.teal,
              current: totalAnesthesiaHours.toInt(),
              required: requiredAnesthesiaHours.toInt(),
              subtitle: 'Administering anesthesia',
              onTap: null, // No action for this card
            ),
            _buildProgressCard(
              title: trackedCategoryName,
              value: '$trackedCategoryCount/$requiredCount',
              icon: Icons.category,
              color:
                  isDarkMode ? AppColors.accentColorDark : AppColors.infoColor,
              current: trackedCategoryCount,
              required: requiredCount,
              subtitle:
                  simulatedCount > 0
                      ? '${actualCount} Actual, ${simulatedCount} Sim'
                      : 'All Actual Cases',
              onTap: () => _showCategorySelectionDialog(caseProvider),
            ),
          ],
        ),
      ],
    );
  }

  // New method to build progress card with ring
  Widget _buildProgressCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required int current,
    required int required,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    // Calculate progress percentage (clamped between 0 and 1)
    double progress = required > 0 ? (current / required).clamp(0.0, 1.0) : 0.0;
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    // Determine progress color based on percentage
    Color progressColor;
    if (progress >= 0.9) {
      progressColor =
          isDarkMode ? AppColors.progressGreenDark : AppColors.progressGreen;
    } else if (progress >= 0.5) {
      progressColor =
          isDarkMode ? AppColors.progressYellowDark : AppColors.progressYellow;
    } else if (progress >= 0.25) {
      progressColor =
          isDarkMode ? AppColors.progressOrangeDark : AppColors.progressOrange;
    } else {
      progressColor =
          isDarkMode ? AppColors.progressRedDark : AppColors.progressRed;
    }

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Progress ring with value inside
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress ring
                      CustomPaint(
                        size: Size.infinite,
                        painter: ProgressRingPainter(
                          progress: progress,
                          progressColor: progressColor,
                          backgroundColor:
                              isDarkMode
                                  ? Color(0xFF303030)
                                  : Colors.grey.shade200,
                        ),
                      ),

                      // Title and value in center
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color:
                                      isDarkMode
                                          ? Colors.white70
                                          : AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                value,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color:
                                      isDarkMode
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Subtitle at bottom if provided
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color:
                            isDarkMode
                                ? Colors.grey[400]
                                : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              // Indicate the card is clickable
              if (onTap != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Tap to change',
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            isDarkMode
                                ? AppColors.accentColorDark
                                : AppColors.accentColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to show category selection dialog
  void _showCategorySelectionDialog(CaseProvider caseProvider) {
    // Get the category provider to access helper methods
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );

    // Get only actual categories (non-group categories)
    final selectableCategories =
        categoryProvider.actualCategories
            .where((category) => !category.isGroup)
            .toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Category to Track'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: selectableCategories.length,
              itemBuilder: (context, index) {
                final category = selectableCategories[index];
                final int categoryCount = caseProvider.getCaseCountByCategory(
                  category.id,
                );

                // Calculate progress for this category
                final double progress =
                    category.requiredCount > 0
                        ? (categoryCount / category.requiredCount).clamp(
                          0.0,
                          1.0,
                        )
                        : 0.0;

                return ListTile(
                  title: Text(
                    category.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${categoryCount}/${category.requiredCount}'),
                  trailing: SizedBox(
                    width: 50,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(progress),
                      ),
                    ),
                  ),
                  onTap: () {
                    // Save selected category to preferences
                    _prefs?.setString('tracked_category_id', category.id);
                    _prefs?.setString('tracked_category_name', category.name);
                    setState(() {});
                    Navigator.pop(context);
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
        );
      },
    );
  }

  // Helper method to get color based on progress
  Color _getProgressColor(double progress) {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    if (progress >= 0.9)
      return isDarkMode ? AppColors.progressGreenDark : AppColors.progressGreen;
    if (progress >= 0.5)
      return isDarkMode
          ? AppColors.progressYellowDark
          : AppColors.progressYellow;
    if (progress >= 0.25)
      return isDarkMode
          ? AppColors.progressOrangeDark
          : AppColors.progressOrange;
    return isDarkMode ? AppColors.progressRedDark : AppColors.progressRed;
  }

  Widget _buildClinicalSiteSection() {
    final clinicalSiteProvider = Provider.of<ClinicalSiteProvider>(context);
    final timeEntryProvider = Provider.of<TimeEntryProvider>(context);
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    final activeSite = clinicalSiteProvider.activeSite;
    final hasActiveSite = activeSite != null;
    final isClockingIn = timeEntryProvider.activeEntry == null;
    final needsNewSite = clinicalSiteProvider.needsNewClinicalSite();

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Clinical Site',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (hasActiveSite && !needsNewSite)
                  TextButton(
                    onPressed: () => _editClinicalSite(activeSite),
                    child: Text(
                      'Edit',
                      style: TextStyle(
                        color: isDarkMode ? AppColors.accentColorDark : null,
                      ),
                    ),
                  )
                else
                  TextButton(
                    onPressed: _addClinicalSite,
                    child: Text(
                      'Add Site',
                      style: TextStyle(
                        color: isDarkMode ? AppColors.accentColorDark : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Current clinical site info
            if (hasActiveSite && !needsNewSite) ...[
              _buildClinicalSiteInfo(activeSite),
              const Divider(height: 24),

              // Clock In/Out section
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          isClockingIn
                              ? () => _clockIn(activeSite.id)
                              : () => _clockOut(),
                      icon: Icon(isClockingIn ? Icons.login : Icons.logout),
                      label: Text(isClockingIn ? 'Clock In' : 'Clock Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isClockingIn ? Colors.green : Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              // Show active time entry if any with edit button
              if (!isClockingIn) ...[
                const SizedBox(height: 16),
                _buildActiveTimeEntryWithEdit(timeEntryProvider.activeEntry!),
              ],
            ] else if (hasActiveSite && needsNewSite)
              // Rotation expired message
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      Text(
                        'Your rotation at ${activeSite.name} has ended.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color:
                              isDarkMode
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _addClinicalSite,
                        child: Text('Start New Rotation'),
                      ),
                    ],
                  ),
                ),
              )
            else
              // No active site message
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'No active clinical site. Add a site to track your time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          isDarkMode ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicalSiteInfo(ClinicalSite site) {
    final timeEntryProvider = Provider.of<TimeEntryProvider>(
      context,
      listen: false,
    );
    final totalHours = timeEntryProvider.getTotalHoursForClinicalSite(site.id);
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    // Extract abbreviation from parentheses if available
    String displayName = site.name;
    if (site.name.contains('(') && site.name.contains(')')) {
      final abbrMatch = RegExp(r'\((.*?)\)').firstMatch(site.name);
      if (abbrMatch != null && abbrMatch.group(1)!.isNotEmpty) {
        displayName = abbrMatch.group(1)!;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
          maxLines: 2, // Allow 2 lines for the name
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          site.address,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.grey[400] : AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),

        // Rotation period and progress
        Row(
          children: [
            Icon(
              Icons.date_range,
              size: 16,
              color: isDarkMode ? Colors.grey[400] : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                site.formattedPeriod,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : AppColors.textLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Progress bar
        LinearProgressIndicator(
          value: site.progressPercentage,
          minHeight: 8,
          backgroundColor: isDarkMode ? Color(0xFF303030) : Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            _getProgressColor(site.progressPercentage),
          ),
        ),
        const SizedBox(height: 8),

        // Days left and hours
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${site.daysLeft} days left',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : AppColors.textLight,
              ),
            ),
            Text(
              '${totalHours.toStringAsFixed(1)} clinical hours',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : AppColors.textLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // New method for active session with edit button
  Widget _buildActiveTimeEntryWithEdit(TimeEntry entry) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF202020) : AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  entry.formattedDuration,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isDarkMode
                            ? AppColors.accentColorDark
                            : AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  size: 18,
                ),
                onPressed: () => _showEditTimeEntryDialog(entry),
                tooltip: 'Edit Session',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Make the start time text handle overflow too
          Text(
            'Started at ${entry.formattedClockInTime}',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[300] : AppColors.textLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCases(CaseProvider caseProvider) {
    final recentCases = caseProvider.cases;
    recentCases.sort((a, b) => b.date.compareTo(a.date));
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    final casesToShow = recentCases.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Cases', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.logs);
              },
              child: Text(
                'View All',
                style: TextStyle(
                  color: isDarkMode ? AppColors.accentColorDark : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (casesToShow.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No cases recorded yet. Add your first case to track your progress.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      isDarkMode ? Colors.grey[300] : AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: casesToShow.length,
            itemBuilder: (context, index) {
              final clinicalCase = casesToShow[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(
                    clinicalCase.procedure,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${clinicalCase.anesthesiaType} - ${clinicalCase.location}',
                    style: TextStyle(
                      color:
                          isDarkMode
                              ? Colors.grey[400]
                              : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Container(
                    width: 110, // Constrain width to prevent overflow
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            '${clinicalCase.date.day}/${clinicalCase.date.month}/${clinicalCase.date.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : AppColors.textLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            size: 20,
                            color: isDarkMode ? Colors.grey[400] : null,
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              // Navigate to edit case screen
                              Navigator.of(context).pushNamed(
                                AppRoutes.addCase,
                                arguments: {'caseToEdit': clinicalCase},
                              );
                            }
                          },
                          itemBuilder:
                              (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 18),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                              ],
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    // Navigate to case details
                    // This would be implemented in a future screen
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  // Fix for the Recent Time Entries section - remove View All button and improve header
  Widget _buildRecentTimeEntries() {
    final timeEntryProvider = Provider.of<TimeEntryProvider>(context);
    final recentEntries = List<TimeEntry>.from(timeEntryProvider.entries);

    // Sort by most recent first
    recentEntries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // Take the last 5 entries
    final entriesToShow = recentEntries.take(5).toList();

    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Time Entries',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {
                // Navigate to logs screen with Clinical Hours tab selected
                Navigator.of(context).pushNamed(
                  AppRoutes.logs,
                  arguments: {
                    'initialTab': 2,
                  }, // Select the Clinical Hours tab (index 2)
                );
              },
              child: Text(
                'View All',
                style: TextStyle(
                  color: isDarkMode ? AppColors.accentColorDark : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (entriesToShow.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No time entries yet. Clock in and out to track your clinical hours.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      isDarkMode ? Colors.grey[300] : AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: entriesToShow.length,
            itemBuilder: (context, index) {
              return _buildTimeEntryItem(entriesToShow[index]);
            },
          ),
      ],
    );
  }

  // Fix overflow in time entry item by making text responsive
  Widget _buildTimeEntryItem(TimeEntry entry) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final clinicalSiteProvider = Provider.of<ClinicalSiteProvider>(context);

    // Get site name - use the correct method or find the site in the list
    final siteName =
        clinicalSiteProvider.sites
            .firstWhere(
              (site) => site.id == entry.clinicalSiteId,
              orElse:
                  () => ClinicalSite(
                    name: 'Unknown Site',
                    address: '',
                    startDate: DateTime.now(),
                    durationWeeks: 0,
                    isActive: false,
                  ),
            )
            .name;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 1,
      color: isDarkMode ? Color(0xFF202020) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        siteName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color:
                              isDarkMode ? Colors.white : AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Duration: ${entry.formattedDuration}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDarkMode
                                  ? AppColors.accentColorDark
                                  : AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    size: 20,
                  ),
                  onPressed: () => _showEditTimeEntryDialog(entry),
                  tooltip: 'Edit Time Entry',
                  constraints: BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Fix overflow by using a Column instead of Row for times
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'In: ${entry.formattedClockInTime}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[300] : AppColors.textLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Out: ${entry.clockOutTime != null ? entry.formattedClockOutTime : "Active"}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[300] : AppColors.textLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (entry.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                entry.notes,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: isDarkMode ? Colors.grey[400] : AppColors.textLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Modify _buildClinicalSiteSection to allow editing current session
  void _showEditTimeEntryDialog(TimeEntry entry) async {
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

    // Get site name - use the correct method or find the site in the list
    final siteName =
        clinicalSiteProvider.sites
            .firstWhere(
              (site) => site.id == entry.clinicalSiteId,
              orElse:
                  () => ClinicalSite(
                    name: 'Unknown Site',
                    address: '',
                    startDate: DateTime.now(),
                    durationWeeks: 0,
                    isActive: false,
                  ),
            )
            .name;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Calculate duration whenever times change - add null check
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
                                    // Show error or set clockOutTime to null
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

                          // Removed quick action buttons (Set In to Now, Set Out to Now)
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

  void _addClinicalSite() async {
    // Show dialog to add a new clinical site
    showDialog(
      context: context,
      builder: (context) => _AddClinicalSiteDialog(),
    );
  }

  void _editClinicalSite(ClinicalSite site) {
    // Show dialog to edit an existing clinical site
    showDialog(
      context: context,
      builder: (context) => _EditClinicalSiteDialog(site: site),
    );
  }

  void _clockIn(String siteId) async {
    final timeEntryProvider = Provider.of<TimeEntryProvider>(
      context,
      listen: false,
    );

    // Show dialog to select time
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _ClockInDialog(),
    );

    if (result != null) {
      await timeEntryProvider.clockIn(
        siteId,
        clockInTime: result['clockInTime'] as DateTime,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully clocked in'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _clockOut() async {
    final timeEntryProvider = Provider.of<TimeEntryProvider>(
      context,
      listen: false,
    );
    final activeEntry = timeEntryProvider.activeEntry;

    if (activeEntry != null) {
      // Show dialog to add notes and confirm clock out time
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _ClockOutDialog(timeEntry: activeEntry),
      );

      if (result != null) {
        await timeEntryProvider.clockOut(
          notes: result['notes'] as String,
          clockOutTime: result['clockOutTime'] as DateTime,
        );
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully clocked out'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: const Text(
            'Settings functionality will be implemented in a future update.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showProfileDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('User Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user != null) ...[
                Text('Name: ${user.name}'),
                const SizedBox(height: 8),
                Text('Email: ${user.email}'),
                const SizedBox(height: 8),
                Text('School: ${user.school}'),
              ] else
                const Text('User information not available'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                authProvider.logout();
                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}

// Dialog for adding a new clinical site
class _AddClinicalSiteDialog extends StatefulWidget {
  const _AddClinicalSiteDialog({super.key});

  @override
  _AddClinicalSiteDialogState createState() => _AddClinicalSiteDialogState();
}

class _AddClinicalSiteDialogState extends State<_AddClinicalSiteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _durationWeeks = 12;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isSearching = false;
  Position? _currentPosition;
  String _lastSearchPattern = '';

  // List of common hospitals for fallback
  final List<String> _commonHospitals = [
    'Swedish Medical Center',
    'Kaiser Permanente Hospital',
    'Mayo Clinic Hospital',
    'Cleveland Clinic',
    'Johns Hopkins Hospital',
    'Massachusetts General Hospital',
    'Cedars-Sinai Medical Center',
    'Stanford Hospital',
    'UCSF Medical Center',
    'UCLA Medical Center',
    'NYU Langone Medical Center',
    'Mount Sinai Hospital',
    'Memorial Hospital',
    'St. Joseph Hospital',
    'Mercy Hospital',
    'Denver Health Medical Center',
    'Children\'s Hospital Colorado',
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return;
      }

      // Check for location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions permanently denied');
        return;
      }

      // Get the current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      debugPrint('Position obtained: $_currentPosition');
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Search for hospitals using Google Places API
  Future<List<String>> _getSuggestions(String pattern) async {
    if (pattern.length < 2) return [];

    _lastSearchPattern = pattern;
    List<String> results = [];

    try {
      // Try location-based search first if we have position
      if (_currentPosition != null) {
        final nearbyResults = await _searchNearbyHospitals(pattern);
        if (nearbyResults.isNotEmpty) {
          return nearbyResults;
        }
      }

      // If no nearby results, try text search
      final textResults = await _searchHospitalsByText(pattern);
      if (textResults.isNotEmpty) {
        return textResults;
      }

      // If all API calls fail, use local fallback
      return _getLocalSuggestions(pattern);
    } catch (e) {
      debugPrint('Error in hospital search: $e');
      // Use local fallback on error
      return _getLocalSuggestions(pattern);
    }
  }

  // Search for nearby hospitals using Google Places API
  Future<List<String>> _searchNearbyHospitals(String pattern) async {
    if (_currentPosition == null) return [];

    try {
      final encodedPattern = Uri.encodeComponent(pattern);
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${_currentPosition!.latitude},${_currentPosition!.longitude}'
        '&radius=${AppConstants.hospitalSearchRadius}'
        '&type=hospital'
        '&keyword=$encodedPattern'
        '&key=${AppConstants.googleMapsApiKey}',
      );

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => http.Response('{"status":"TIMEOUT"}', 408),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final List<dynamic> places = data['results'];
          return places
              .map<String>((place) => place['name'] as String)
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error in nearby search: $e');
    }

    return [];
  }

  // Search for hospitals by text using Google Places API
  Future<List<String>> _searchHospitalsByText(String pattern) async {
    try {
      final encodedPattern = Uri.encodeComponent(pattern);
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json'
        '?query=hospitals+$encodedPattern'
        '&key=${AppConstants.googleMapsApiKey}',
      );

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => http.Response('{"status":"TIMEOUT"}', 408),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final List<dynamic> places = data['results'];
          return places
              .map<String>((place) => place['name'] as String)
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error in text search: $e');
    }

    return [];
  }

  // Get suggestions from local hospital list when API fails
  List<String> _getLocalSuggestions(String pattern) {
    return _commonHospitals
        .where(
          (hospital) => hospital.toLowerCase().contains(pattern.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Clinical Site'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TypeAhead field with Google Places integration
              TypeAheadFormField<String>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Hospital Name',
                    hintText: 'Start typing hospital name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_hospital),
                    suffixIcon:
                        _isSearching
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Icon(Icons.search),
                  ),
                ),
                suggestionsCallback: (pattern) async {
                  if (pattern.length < 2) return [];

                  setState(() => _isSearching = true);
                  final suggestions = await _getSuggestions(pattern);

                  // Only update state if this is still the current search
                  if (pattern == _lastSearchPattern && mounted) {
                    setState(() => _isSearching = false);
                  }

                  return suggestions;
                },
                itemBuilder: (context, String suggestion) {
                  return ListTile(
                    title: Text(suggestion),
                    leading: Icon(Icons.local_hospital),
                  );
                },
                onSuggestionSelected: (String suggestion) {
                  _nameController.text = suggestion;
                },
                noItemsFoundBuilder:
                    (context) => Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No hospitals found with that name.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You can enter a custom name instead.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a hospital name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Rotation Duration field
              const Text('Rotation Duration (weeks):'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle),
                    onPressed:
                        _durationWeeks > 1
                            ? () => setState(() => _durationWeeks--)
                            : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_durationWeeks',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: () => setState(() => _durationWeeks++),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveClinicalSite,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Save'),
        ),
      ],
    );
  }

  void _saveClinicalSite() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final clinicalSiteProvider = Provider.of<ClinicalSiteProvider>(
        context,
        listen: false,
      );

      final newSite = ClinicalSite(
        name: _nameController.text,
        address: "", // Use empty string for address
        startDate: DateTime.now(),
        durationWeeks: _durationWeeks,
        isActive: _isActive,
      );

      clinicalSiteProvider.addSite(newSite);
      Navigator.pop(context);
    }
  }
}

// Dialog for editing an existing clinical site
class _EditClinicalSiteDialog extends StatefulWidget {
  final ClinicalSite site;

  const _EditClinicalSiteDialog({super.key, required this.site});

  @override
  _EditClinicalSiteDialogState createState() => _EditClinicalSiteDialogState();
}

class _EditClinicalSiteDialogState extends State<_EditClinicalSiteDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late int _durationWeeks;
  late bool _isActive;
  bool _isLoading = false;
  bool _isSearching = false;
  Position? _currentPosition;
  String _lastSearchPattern = '';

  // List of common hospitals for fallback
  final List<String> _commonHospitals = [
    'Swedish Medical Center',
    'Kaiser Permanente Hospital',
    'Mayo Clinic Hospital',
    'Cleveland Clinic',
    'Johns Hopkins Hospital',
    'Massachusetts General Hospital',
    'Cedars-Sinai Medical Center',
    'Stanford Hospital',
    'UCSF Medical Center',
    'UCLA Medical Center',
    'NYU Langone Medical Center',
    'Mount Sinai Hospital',
    'Memorial Hospital',
    'St. Joseph Hospital',
    'Mercy Hospital',
    'Denver Health Medical Center',
    'Children\'s Hospital Colorado',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.site.name);
    _durationWeeks = widget.site.durationWeeks ?? 12;
    _isActive = widget.site.isActive;
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return;
      }

      // Check for location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions permanently denied');
        return;
      }

      // Get the current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      debugPrint('Position obtained: $_currentPosition');
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Search for hospitals using Google Places API
  Future<List<String>> _getSuggestions(String pattern) async {
    if (pattern.length < 2) return [];

    _lastSearchPattern = pattern;
    List<String> results = [];

    try {
      // Try location-based search first if we have position
      if (_currentPosition != null) {
        final nearbyResults = await _searchNearbyHospitals(pattern);
        if (nearbyResults.isNotEmpty) {
          return nearbyResults;
        }
      }

      // If no nearby results, try text search
      final textResults = await _searchHospitalsByText(pattern);
      if (textResults.isNotEmpty) {
        return textResults;
      }

      // If all API calls fail, use local fallback
      return _getLocalSuggestions(pattern);
    } catch (e) {
      debugPrint('Error in hospital search: $e');
      // Use local fallback on error
      return _getLocalSuggestions(pattern);
    }
  }

  // Search for nearby hospitals using Google Places API
  Future<List<String>> _searchNearbyHospitals(String pattern) async {
    if (_currentPosition == null) return [];

    try {
      final encodedPattern = Uri.encodeComponent(pattern);
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${_currentPosition!.latitude},${_currentPosition!.longitude}'
        '&radius=${AppConstants.hospitalSearchRadius}'
        '&type=hospital'
        '&keyword=$encodedPattern'
        '&key=${AppConstants.googleMapsApiKey}',
      );

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => http.Response('{"status":"TIMEOUT"}', 408),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final List<dynamic> places = data['results'];
          return places
              .map<String>((place) => place['name'] as String)
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error in nearby search: $e');
    }

    return [];
  }

  // Search for hospitals by text using Google Places API
  Future<List<String>> _searchHospitalsByText(String pattern) async {
    try {
      final encodedPattern = Uri.encodeComponent(pattern);
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json'
        '?query=hospitals+$encodedPattern'
        '&key=${AppConstants.googleMapsApiKey}',
      );

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => http.Response('{"status":"TIMEOUT"}', 408),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final List<dynamic> places = data['results'];
          return places
              .map<String>((place) => place['name'] as String)
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error in text search: $e');
    }

    return [];
  }

  // Get suggestions from local hospital list when API fails
  List<String> _getLocalSuggestions(String pattern) {
    return _commonHospitals
        .where(
          (hospital) => hospital.toLowerCase().contains(pattern.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Clinical Site'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TypeAhead field with Google Places integration
              TypeAheadFormField<String>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Hospital Name',
                    hintText: 'Start typing hospital name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_hospital),
                    suffixIcon:
                        _isSearching
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Icon(Icons.search),
                  ),
                ),
                suggestionsCallback: (pattern) async {
                  if (pattern.length < 2) return [];

                  setState(() => _isSearching = true);
                  final suggestions = await _getSuggestions(pattern);

                  // Only update state if this is still the current search
                  if (pattern == _lastSearchPattern && mounted) {
                    setState(() => _isSearching = false);
                  }

                  return suggestions;
                },
                itemBuilder: (context, String suggestion) {
                  return ListTile(
                    title: Text(suggestion),
                    leading: Icon(Icons.local_hospital),
                  );
                },
                onSuggestionSelected: (String suggestion) {
                  _nameController.text = suggestion;
                },
                noItemsFoundBuilder:
                    (context) => Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No hospitals found with that name.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You can enter a custom name instead.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a hospital name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Active'),
                  Switch(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Rotation Duration (weeks):'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle),
                    onPressed:
                        _durationWeeks > 1
                            ? () => setState(() => _durationWeeks--)
                            : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_durationWeeks',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: () => setState(() => _durationWeeks++),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _deleteClinicalSite,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
        ElevatedButton(
          onPressed: _updateClinicalSite,
          child: const Text('Update'),
        ),
      ],
    );
  }

  void _updateClinicalSite() {
    final clinicalSiteProvider = Provider.of<ClinicalSiteProvider>(
      context,
      listen: false,
    );

    final updatedSite = widget.site.copyWith(
      name: _nameController.text,
      address: "", // Keep an empty address
      durationWeeks: _durationWeeks,
      isActive: _isActive,
      updatedAt: DateTime.now(),
    );

    clinicalSiteProvider.updateSite(updatedSite);
    Navigator.pop(context);
  }

  void _deleteClinicalSite() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Clinical Site'),
            content: const Text(
              'Are you sure you want to delete this clinical site? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final clinicalSiteProvider =
                      Provider.of<ClinicalSiteProvider>(context, listen: false);
                  clinicalSiteProvider.deleteSite(widget.site.id);
                  Navigator.pop(context); // Close confirmation dialog
                  Navigator.pop(context); // Close edit dialog
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}

// Dialog for clocking in
class _ClockInDialog extends StatefulWidget {
  const _ClockInDialog({super.key});

  @override
  _ClockInDialogState createState() => _ClockInDialogState();
}

class _ClockInDialogState extends State<_ClockInDialog> {
  DateTime _selectedTime = DateTime.now();

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
    );

    if (pickedTime != null) {
      setState(() {
        final now = DateTime.now();
        _selectedTime = DateTime(
          now.year,
          now.month,
          now.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');

    return AlertDialog(
      title: const Text('Clock In'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time selector
          ListTile(
            title: const Text('Clock-in time:'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(timeFormat.format(_selectedTime)),
                IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _selectTime(context),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {'clockInTime': _selectedTime});
          },
          child: const Text('Clock In'),
        ),
      ],
    );
  }
}

// Dialog for clocking out
class _ClockOutDialog extends StatefulWidget {
  final TimeEntry timeEntry;

  const _ClockOutDialog({super.key, required this.timeEntry});

  @override
  _ClockOutDialogState createState() => _ClockOutDialogState();
}

class _ClockOutDialogState extends State<_ClockOutDialog> {
  final TextEditingController _notesController = TextEditingController();
  late DateTime _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = DateTime.now();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final duration = _calculateDuration();

    return AlertDialog(
      title: const Text('Clock Out'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time selector
          ListTile(
            title: const Text('Clock-out time:'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(timeFormat.format(_selectedTime)),
                IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _selectTime(context),
                ),
              ],
            ),
          ),

          Text('Session duration: $duration'),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'notes': _notesController.text,
              'clockOutTime': _selectedTime,
            });
          },
          child: const Text('Clock Out'),
        ),
      ],
    );
  }

  String _calculateDuration() {
    final difference = _selectedTime.difference(widget.timeEntry.clockInTime);
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    if (hours > 0) {
      return '$hours hr${hours != 1 ? 's' : ''} ${minutes > 0 ? '$minutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
    );

    if (pickedTime != null) {
      setState(() {
        final now = DateTime.now();
        _selectedTime = DateTime(
          now.year,
          now.month,
          now.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }
}
