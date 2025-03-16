import 'package:flutter/material.dart';
import 'package:navithesia_beta/constants/app_constants.dart';
import 'package:navithesia_beta/constants/coa_constants.dart';
import 'package:navithesia_beta/widgets/coa_progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:navithesia_beta/providers/case_provider.dart';
import 'package:navithesia_beta/models/coa_category_model.dart';

class CoaCategoryGroup extends StatelessWidget {
  final String title;
  final List<String> categories;
  final bool isExpanded;
  final Function(bool)? onExpansionChanged;
  final bool showDebugInfo;

  const CoaCategoryGroup({
    super.key,
    required this.title,
    required this.categories,
    this.isExpanded = false,
    this.onExpansionChanged,
    this.showDebugInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    // Use Consumer to ensure the widget rebuilds when CaseProvider changes
    return Consumer<CaseProvider>(
      builder: (context, caseProvider, _) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.defaultBorderRadius,
            ),
          ),
          child: ExpansionTile(
            initiallyExpanded: isExpanded,
            onExpansionChanged: onExpansionChanged,
            title: Text(title, style: AppTextStyles.subtitle1),
            backgroundColor: Colors.transparent,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  children:
                      categories.map((category) {
                        // Find the category or return a default with 0 required count
                        final coaCategory = CoaConstants.categories.firstWhere(
                          (cat) => cat.name == category,
                          orElse:
                              () => CoaCategory(
                                id: 'unknown',
                                name: category,
                                requiredCount: 0,
                                description: 'Unknown category',
                                group: 'unknown',
                                isRequired: false,
                              ),
                        );
                        final int count = caseProvider.getCaseCountByCategory(
                          coaCategory.id,
                        );
                        final int required = coaCategory.requiredCount;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CoaProgressBar(
                                category: category,
                                count: count,
                                required: required,
                              ),
                              if (showDebugInfo && count == 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Matching cases: ${caseProvider.getCasesByCategory(category).length}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
