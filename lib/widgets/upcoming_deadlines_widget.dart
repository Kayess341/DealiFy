// lib/widgets/upcoming_deadlines_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UpcomingDeadlinesWidget extends StatelessWidget {
  final dateFormat = DateFormat('MMM dd');
  
  // In a real app, this would be passed in or retrieved from a service
  final List<Map<String, dynamic>> _sampleDeadlines = [
    {
      'brandName': 'FashionBrand',
      'title': 'Instagram Post',
      'dueDate': DateTime.now().add(Duration(days: 2)),
      'platform': 'Instagram',
    },
    {
      'brandName': 'TechGadgets',
      'title': 'YouTube Review',
      'dueDate': DateTime.now().add(Duration(days: 5)),
      'platform': 'YouTube',
    },
    {
      'brandName': 'FitnessApp',
      'title': 'Instagram Story',
      'dueDate': DateTime.now().add(Duration(days: 8)),
      'platform': 'Instagram',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: _sampleDeadlines.length,
        separatorBuilder: (context, index) => Divider(height: 1),
        itemBuilder: (context, index) {
          final deadline = _sampleDeadlines[index];
          final daysLeft = deadline['dueDate']
              .difference(DateTime.now())
              .inDays;
          
          return ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              deadline['title'],
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${deadline['brandName']} • ${deadline['platform']}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  dateFormat.format(deadline['dueDate']),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  daysLeft == 0
                      ? 'Today'
                      : daysLeft == 1
                          ? 'Tomorrow'
                          : '$daysLeft days left',
                  style: TextStyle(
                    color: daysLeft < 3 ? Colors.red : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            onTap: () {
              // Navigate to deal details in a real app
            },
          );
        },
      ),
    );
  }
}
