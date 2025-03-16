import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:navithesia_beta/constants/app_constants.dart';
import 'package:navithesia_beta/constants/coa_constants.dart';
import 'package:navithesia_beta/widgets/coa_category_tree.dart';
import 'package:navithesia_beta/providers/case_provider.dart';

class CoaProgressScreen extends StatefulWidget {
  const CoaProgressScreen({super.key});

  @override
  State<CoaProgressScreen> createState() => _CoaProgressScreenState();
}

class _CoaProgressScreenState extends State<CoaProgressScreen> {
  // Track expanded groups
  Set<String> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('COA Clinical Requirements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.expand_more),
            onPressed: () {
              setState(() {
                if (_expandedGroups.length ==
                    CoaConstants.categoryGroups.length) {
                  // If all groups are expanded, collapse all
                  _expandedGroups = {};
                } else {
                  // Otherwise expand all
                  _expandedGroups =
                      CoaConstants.categoryGroups
                          .map((group) => group.id)
                          .toSet();
                }
              });
            },
            tooltip: 'Expand/Collapse All',
          ),
        ],
      ),
      body: Consumer<CaseProvider>(
        builder: (context, caseProvider, _) {
          return ListView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            children: [
              ...CoaConstants.categoryGroups.map(
                (group) => CoaCategoryTree(
                  groupId: group.id,
                  showProgress: true,
                  showHelpText: true,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
