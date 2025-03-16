import 'package:flutter/material.dart';
import 'package:navithesia_beta/constants/app_constants.dart';
import 'package:navithesia_beta/constants/coa_constants.dart';
import 'package:navithesia_beta/models/coa_category_model.dart';
import 'package:provider/provider.dart';
import 'package:navithesia_beta/providers/case_provider.dart';
import 'package:navithesia_beta/providers/theme_provider.dart';

class CoaCategoryTree extends StatelessWidget {
  final String groupId;
  final bool showProgress;
  final bool showHelpText;
  final Function(CoaCategory)? onCategoryTap;

  const CoaCategoryTree({
    super.key,
    required this.groupId,
    this.showProgress = true,
    this.showHelpText = true,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    // Add error handling for group lookup
    final group = CoaConstants.categoryGroups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => CoaConstants.categoryGroups.first,
    );

    // Add safe extraction of category IDs with error handling
    final rootCategories = <CoaCategory>[];
    try {
      rootCategories.addAll(
        group.categoryIds.map((id) {
          try {
            return CoaConstants.categories.firstWhere((c) => c.id == id);
          } catch (e) {
            debugPrint('Category with ID $id not found: $e');
            // Return a placeholder category instead of crashing
            return CoaCategory(
              id: 'error_$id',
              name: 'Unknown Category',
              helpText: 'Category not found',
              requiredCount: 0,
              isRequired: false,
              description: 'Category not found in database',
              group: 'unknown',
            );
          }
        }),
      );
    } catch (e) {
      debugPrint('Error processing categories for group ${group.id}: $e');
    }

    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  group.title,
                  style: AppTextStyles.subtitle1.copyWith(
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showHelpText && group.description.isNotEmpty) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: group.description,
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color:
                        isDarkMode ? Colors.grey[400] : AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            group.description,
            style: AppTextStyles.caption.copyWith(
              color: isDarkMode ? Colors.grey[400] : AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          children:
              rootCategories
                  .map((category) => _buildCategoryTile(context, category))
                  .toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, CoaCategory category) {
    return Consumer<CaseProvider>(
      builder: (context, caseProvider, _) {
        // Add try-catch to handle potential errors in counting cases
        int count = 0;
        try {
          count = caseProvider.getCaseCountByCategory(category.id);
        } catch (e) {
          debugPrint('Error getting case count for ${category.id}: $e');
        }

        // Add safe lookup for subcategories with error handling
        final subcategories = <CoaCategory>[];
        try {
          subcategories.addAll(CoaConstants.getSubcategories(category.id));
        } catch (e) {
          debugPrint('Error getting subcategories for ${category.id}: $e');
        }

        final hasSubcategories = subcategories.isNotEmpty;

        return hasSubcategories
            ? _buildParentCategoryTile(context, category, subcategories, count)
            : _buildLeafCategoryTile(context, category, count);
      },
    );
  }

  Widget _buildParentCategoryTile(
    BuildContext context,
    CoaCategory category,
    List<CoaCategory> subcategories,
    int count,
  ) {
    return ExpansionTile(
      title: _buildCategoryHeader(context, category, count),
      children:
          subcategories
              .map((subcat) => _buildCategoryTile(context, subcat))
              .toList(),
    );
  }

  Widget _buildLeafCategoryTile(
    BuildContext context,
    CoaCategory category,
    int count,
  ) {
    return ListTile(
      title: _buildCategoryHeader(context, category, count),
      onTap: onCategoryTap != null ? () => onCategoryTap!(category) : null,
    );
  }

  Widget _buildCategoryHeader(
    BuildContext context,
    CoaCategory category,
    int count,
  ) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final isLargeText = textScaleFactor > 1.3;
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Use Flexible to allow the text to shrink and avoid overflow
            Flexible(
              flex: 3,
              child: Text(
                category.name,
                style: AppTextStyles.bodyText1.copyWith(
                  fontWeight:
                      category.isRequired ? FontWeight.bold : FontWeight.normal,
                  fontSize: isLargeText ? 14 : null,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
                maxLines: isLargeText ? 2 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Add spacing to separate text from badge
            SizedBox(width: 8),
            // Use a fixed width container for the progress badge to avoid jumping
            if (showProgress && category.requiredCount > 0)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 80),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getProgressColor(
                      count,
                      category.requiredCount,
                      isDarkMode,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count/${category.requiredCount}',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isLargeText ? 10 : 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        if (showHelpText && category.helpText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              category.helpText,
              style: AppTextStyles.caption.copyWith(
                color: isDarkMode ? Colors.grey[400] : AppColors.textSecondary,
                fontStyle: FontStyle.italic,
                fontSize: isLargeText ? 10 : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (showProgress && category.requiredCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              height: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Stack(
                  children: [
                    // Background
                    Container(
                      width: double.infinity,
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    ),
                    // Foreground with gradient
                    FractionallySizedBox(
                      widthFactor: (count / category.requiredCount).clamp(
                        0.0,
                        1.0,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _getProgressGradientColors(
                              count,
                              category.requiredCount,
                              isDarkMode,
                            ),
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getProgressColor(int count, int required, bool isDarkMode) {
    double percentage = 0.0;
    if (required > 0) {
      percentage = count / required * 100.0;
    }

    if (percentage <= 25) {
      return isDarkMode ? AppColors.progressRedDark : AppColors.progressRed;
    } else if (percentage <= 50) {
      return isDarkMode
          ? AppColors.progressOrangeDark
          : AppColors.progressOrange;
    } else if (percentage <= 90) {
      return isDarkMode
          ? AppColors.progressYellowDark
          : AppColors.progressYellow;
    } else {
      return isDarkMode ? AppColors.progressGreenDark : AppColors.progressGreen;
    }
  }

  // Helper method to get gradient colors based on progress
  List<Color> _getProgressGradientColors(
    int count,
    int required,
    bool isDarkMode,
  ) {
    double progress = required > 0 ? (count / required).clamp(0.0, 1.0) : 0.0;

    // Create a gradient that transitions smoothly between the color ranges
    if (progress <= 0.25) {
      // Red gradient (darker to lighter red)
      final baseColor =
          isDarkMode ? AppColors.progressRedDark : AppColors.progressRed;
      return [baseColor.withOpacity(0.8), baseColor];
    } else if (progress <= 0.5) {
      // Red to Orange gradient
      return isDarkMode
          ? [AppColors.progressRedDark, AppColors.progressOrangeDark]
          : [AppColors.progressRed, AppColors.progressOrange];
    } else if (progress <= 0.9) {
      // Orange to Yellow gradient
      return isDarkMode
          ? [AppColors.progressOrangeDark, AppColors.progressYellowDark]
          : [AppColors.progressOrange, AppColors.progressYellow];
    } else {
      // Yellow to Green gradient
      return isDarkMode
          ? [AppColors.progressYellowDark, AppColors.progressGreenDark]
          : [AppColors.progressYellow, AppColors.progressGreen];
    }
  }
}
