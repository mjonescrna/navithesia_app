import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:navithesia_beta/constants/app_constants.dart';
import 'package:navithesia_beta/providers/auth_provider.dart';
import 'package:navithesia_beta/providers/theme_provider.dart';
import 'dart:math' as math;

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int _selectedIndex = 4; // Index for the messages tab
  int _currentTabIndex = 0; // 0 for instructors, 1 for peers

  // Dummy data for demonstration
  final List<Map<String, dynamic>> _instructors = [
    {
      'id': '1',
      'name': 'Dr. Sarah Johnson',
      'role': 'Clinical Instructor',
      'avatarUrl': null,
      'lastMessage': 'Please submit your case logs by Friday.',
      'time': '10:30 AM',
      'unread': true,
    },
    {
      'id': '2',
      'name': 'Dr. Michael Chen',
      'role': 'Program Director',
      'avatarUrl': null,
      'lastMessage': 'Great job on your presentation yesterday!',
      'time': 'Yesterday',
      'unread': false,
    },
    {
      'id': '3',
      'name': 'Dr. Emily Rodriguez',
      'role': 'Simulation Lab Coordinator',
      'avatarUrl': null,
      'lastMessage':
          'The next simulation session is scheduled for next Monday.',
      'time': 'Jul 15',
      'unread': false,
    },
  ];

  final List<Map<String, dynamic>> _peers = [
    {
      'id': '4',
      'name': 'Alex Thompson',
      'role': 'SRNA - Year 2',
      'avatarUrl': null,
      'lastMessage': 'Do you have the notes from yesterday\'s lecture?',
      'time': '2:45 PM',
      'unread': true,
    },
    {
      'id': '5',
      'name': 'Jessica Lee',
      'role': 'SRNA - Year 3',
      'avatarUrl': null,
      'lastMessage':
          'I\'ll be at the clinical site tomorrow if you need any help.',
      'time': 'Yesterday',
      'unread': true,
    },
    {
      'id': '6',
      'name': 'Ryan Patel',
      'role': 'SRNA - Year 2',
      'avatarUrl': null,
      'lastMessage': 'Thanks for sharing the study materials!',
      'time': 'Jul 14',
      'unread': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality would be implemented here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs for Instructors and Peers
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(
                  AppConstants.defaultBorderRadius,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      title: 'Instructors',
                      index: 0,
                      count:
                          _instructors.where((i) => i['unread'] == true).length,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      title: 'Peers',
                      index: 1,
                      count: _peers.where((p) => p['unread'] == true).length,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Message list
          Expanded(
            child:
                _currentTabIndex == 0
                    ? _buildMessageList(_instructors, isDarkMode)
                    : _buildMessageList(_peers, isDarkMode),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewMessageDialog(),
        backgroundColor:
            isDarkMode ? AppColors.accentColorDark : AppColors.primaryColor,
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
        selectedItemColor:
            isDarkMode ? AppColors.accentColorDark : AppColors.primaryColor,
        unselectedItemColor:
            isDarkMode ? Colors.grey[400] : AppColors.textLight,
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
        Navigator.of(context).pushReplacementNamed(AppRoutes.goals);
        break;
      case 4:
        // Already on messages screen
        break;
    }
  }

  Widget _buildTabButton({
    required String title,
    required int index,
    required int count,
    required bool isDarkMode,
  }) {
    final isSelected = _currentTabIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _currentTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? (isDarkMode
                      ? AppColors.accentColorDark
                      : AppColors.primaryColor)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color:
                    isSelected
                        ? Colors.white
                        : (isDarkMode ? Colors.white : AppColors.textPrimary),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? Colors.white
                          : (isDarkMode ? Colors.white : AppColors.accentColor),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color:
                        isSelected
                            ? (isDarkMode
                                ? AppColors.accentColorDark
                                : AppColors.primaryColor)
                            : (isDarkMode ? Colors.black : Colors.white),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(
    List<Map<String, dynamic>> messages,
    bool isDarkMode,
  ) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message,
              size: 80,
              color: isDarkMode ? Colors.grey[600] : AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No Messages',
              style: AppTextStyles.headline3.copyWith(
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your conversations will appear here',
              style: AppTextStyles.bodyText2.copyWith(
                color: isDarkMode ? Colors.grey[400] : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: messages.length,
      separatorBuilder:
          (context, index) =>
              Divider(color: isDarkMode ? Colors.grey[800] : null),
      itemBuilder: (context, index) {
        final message = messages[index];
        return InkWell(
          onTap: () {
            _navigateToChat(message);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      isDarkMode
                          ? AppColors.accentColorDark
                          : AppColors.primaryColor,
                  child:
                      message['avatarUrl'] != null
                          ? null
                          : Text(
                            message['name']
                                .toString()
                                .split(' ')
                                .map((e) => e[0])
                                .take(2)
                                .join(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
                const SizedBox(width: 16),

                // Message content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              message['name'],
                              style: AppTextStyles.subtitle1.copyWith(
                                fontWeight:
                                    message['unread'] == true
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color:
                                    isDarkMode
                                        ? Colors.white
                                        : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            message['time'],
                            style: AppTextStyles.caption.copyWith(
                              color:
                                  message['unread'] == true
                                      ? (isDarkMode
                                          ? AppColors.accentColorDark
                                          : AppColors.accentColor)
                                      : (isDarkMode
                                          ? Colors.grey[400]
                                          : AppColors.textLight),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message['role'],
                        style: AppTextStyles.caption.copyWith(
                          color: isDarkMode ? Colors.grey[400] : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              message['lastMessage'],
                              style: TextStyle(
                                color:
                                    message['unread'] == true
                                        ? (isDarkMode
                                            ? Colors.white
                                            : AppColors.textPrimary)
                                        : (isDarkMode
                                            ? Colors.grey[400]
                                            : AppColors.textSecondary),
                                fontWeight:
                                    message['unread'] == true
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (message['unread'] == true)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color:
                                    isDarkMode
                                        ? AppColors.accentColorDark
                                        : AppColors.accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
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
  }

  void _navigateToChat(Map<String, dynamic> contact) {
    // In a real app, this would navigate to a chat screen
    // For now, just show a placeholder message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chat with ${contact['name']} coming soon!')),
    );

    // Mark as read
    if (_currentTabIndex == 0) {
      setState(() {
        final index = _instructors.indexWhere((i) => i['id'] == contact['id']);
        if (index != -1) {
          _instructors[index]['unread'] = false;
        }
      });
    } else {
      setState(() {
        final index = _peers.indexWhere((p) => p['id'] == contact['id']);
        if (index != -1) {
          _peers[index]['unread'] = false;
        }
      });
    }
  }

  void _showNewMessageDialog() {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'New Message',
            style: TextStyle(
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          backgroundColor: isDarkMode ? Color(0xFF303030) : null,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Who would you like to message?',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[300] : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showContactsList(_instructors, 'Instructors');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDarkMode ? AppColors.accentColorDark : null,
                ),
                child: const Text('Instructor'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showContactsList(_peers, 'Peers');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDarkMode ? AppColors.accentColorDark : null,
                ),
                child: const Text('Peer'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode ? AppColors.accentColorDark : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showContactsList(List<Map<String, dynamic>> contacts, String title) {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          backgroundColor: isDarkMode ? Color(0xFF303030) : null,
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isDarkMode
                            ? AppColors.accentColorDark
                            : AppColors.primaryColor,
                    child: Text(
                      contact['name']
                          .toString()
                          .split(' ')
                          .map((e) => e[0])
                          .take(2)
                          .join(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    contact['name'],
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    contact['role'],
                    style: TextStyle(
                      color:
                          isDarkMode
                              ? Colors.grey[400]
                              : AppColors.textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToChat(contact);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode ? AppColors.accentColorDark : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Format timestamp to relative time
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
