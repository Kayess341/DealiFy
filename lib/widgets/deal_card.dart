// lib/widgets/deal_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/brand_deal.dart';

class DealCard extends StatelessWidget {
  final BrandDeal deal;
  final VoidCallback onTap;
  final dateFormat = DateFormat('MMM dd, yyyy');
  final currencyFormat = NumberFormat.currency(symbol: '\$');

  DealCard({
    Key? key,
    required this.deal,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      deal.brandName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(context),
                ],
              ),
              SizedBox(height: 8),
              Text(
                deal.description,
                style: TextStyle(
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          currencyFormat.format(deal.payment),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Due Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          dateFormat.format(deal.dueDate),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _getDueDateColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildProgressIndicator(context),
              SizedBox(height: 8),
              Text(
                '${deal.completedDeliverables}/${deal.totalDeliverables} deliverables completed',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    String label;
    Color color;

    if (deal.isCompleted) {
      label = 'Completed';
      color = Colors.green;
    } else if (deal.isPaid) {
      label = 'Paid';
      color = Colors.blue;
    } else if (deal.dueDate.isBefore(DateTime.now())) {
      label = 'Overdue';
      color = Colors.red;
    } else {
      label = 'Active';
      color = Colors.orange;
    }

    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: deal.progressPercentage,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Color _getDueDateColor(BuildContext context) {
    if (deal.dueDate.isBefore(DateTime.now())) {
      return Colors.red;
    } else if (deal.dueDate.difference(DateTime.now()).inDays < 7) {
      return Colors.orange;
    } else {
      return Colors.black;
    }
  }
}