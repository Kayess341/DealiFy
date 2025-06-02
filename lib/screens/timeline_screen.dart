import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/deal.dart';
import '../utils/globals.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  _TimelineScreenState createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  String _selectedFilter = 'All';
  
  final List<String> _filterOptions = ['All', 'This Week', 'This Month', 'Overdue'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Timeline'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (String value) {
              setState(() {
                _selectedFilter = value;
                if (value == 'This Week') {
                  _selectedDate = DateTime.now();
                } else if (value == 'This Month') {
                  _selectedDate = DateTime.now();
                }
              });
            },
            itemBuilder: (BuildContext context) {
              return _filterOptions.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Row(
                    children: [
                      Icon(
                        _getFilterIcon(choice),
                        size: 20,
                        color: _selectedFilter == choice ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(choice),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
                _focusedMonth = DateTime.now();
              });
            },
            tooltip: 'Go to Today',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChip(),
          _buildCalendarHeader(),
          _buildWeekdayHeaders(),
          _buildCalendarGrid(),
          _buildSelectedDateContent(),
        ],
      ),
    );
  }

  Widget _buildFilterChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            'Filter: $_selectedFilter',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            '${_getFilteredDeals().length} deadlines',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final monthFormat = DateFormat('MMMM yyyy');
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month - 1,
                  1,
                );
              });
            },
          ),
          GestureDetector(
            onTap: _showMonthYearPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    monthFormat.format(_focusedMonth),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month + 1,
                  1,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: weekdays.map((day) {
          return Expanded(
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    return SizedBox(
      height: 300,
      child: _buildCalendarMonth(),
    );
  }

  Widget _buildCalendarMonth() {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final firstDayOfWeek = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;
    
    // Get deals for this month
    final monthDeals = globalDeals.where((deal) {
      return (deal.dealLockedDate.year == _focusedMonth.year && 
              deal.dealLockedDate.month == _focusedMonth.month) ||
             (deal.deliverablesDueDate.year == _focusedMonth.year && 
              deal.deliverablesDueDate.month == _focusedMonth.month);
    }).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 42, // 6 weeks * 7 days
      itemBuilder: (context, index) {
        final dayOffset = index - firstDayOfWeek;
        
        if (dayOffset < 0 || dayOffset >= daysInMonth) {
          return Container(); // Empty cell
        }
        
        final day = DateTime(_focusedMonth.year, _focusedMonth.month, dayOffset + 1);
        final isToday = _isSameDay(day, DateTime.now());
        final isSelected = _isSameDay(day, _selectedDate);
        
        // Check for deals on this day
        final dayDeals = monthDeals.where((deal) {
          return _isSameDay(deal.deliverablesDueDate, day) || 
                 _isSameDay(deal.dealLockedDate, day);
        }).toList();
        
        final hasDeadlines = dayDeals.any((deal) => _isSameDay(deal.deliverablesDueDate, day));
        final hasDealLocked = dayDeals.any((deal) => _isSameDay(deal.dealLockedDate, day));
        final isOverdue = dayDeals.any((deal) => 
          _isSameDay(deal.deliverablesDueDate, day) && 
          day.isBefore(DateTime.now()) && 
          deal.status != 'Completed'
        );

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = day;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected 
                ? Colors.blue
                : isToday 
                  ? Colors.blue.shade100
                  : null,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isSelected 
                ? Border.all(color: Colors.blue, width: 2)
                : null,
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isSelected 
                        ? Colors.white
                        : isToday 
                          ? Colors.blue
                          : Colors.black,
                      fontWeight: isSelected || isToday 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                    ),
                  ),
                ),
                if (hasDeadlines || hasDealLocked)
                  Positioned(
                    bottom: 2,
                    left: 2,
                    right: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasDealLocked)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (hasDeadlines)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: isOverdue ? Colors.red : Colors.orange,
                              shape: BoxShape.circle,
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
    );
  }

  Widget _buildSelectedDateContent() {
    final selectedDeals = _getDealsForDate(_selectedDate);
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      dateFormat.format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (selectedDeals.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${selectedDeals.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: selectedDeals.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: selectedDeals.length,
                    itemBuilder: (context, index) {
                      return _buildDealTimelineCard(selectedDeals[index]);
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No events on this day',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a different date or add a new deal',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealTimelineCard(Deal deal) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final calculator = DealCalculator(dealPrice: deal.payment);
    final isDeadlineDay = _isSameDay(deal.deliverablesDueDate, _selectedDate);
    final isDealLockedDay = _isSameDay(deal.dealLockedDate, _selectedDate);
    final isOverdue = deal.deliverablesDueDate.isBefore(DateTime.now()) && 
                     deal.status != 'Completed';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    deal.brandName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isDeadlineDay)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOverdue ? Colors.red : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isOverdue ? 'OVERDUE' : 'DUE TODAY',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isDealLockedDay && !isDeadlineDay)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'DEAL LOCKED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              deal.description,
              style: TextStyle(
                color: Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            if (isDeadlineDay) ...[
              const Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.orange),
                  SizedBox(width: 4),
                  Text(
                    'Deliverables due today',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (isDealLockedDay && !isDeadlineDay) ...[
              const Row(
                children: [
                  Icon(Icons.handshake, size: 16, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    'Deal was locked on this date',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deal Value',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      currencyFormat.format(deal.payment),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net Amount',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      currencyFormat.format(calculator.netAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      deal.status,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(deal.status),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  List<Deal> _getDealsForDate(DateTime date) {
    return globalDeals.where((deal) {
      return _isSameDay(deal.deliverablesDueDate, date) || 
             _isSameDay(deal.dealLockedDate, date);
    }).toList();
  }

  List<Deal> _getFilteredDeals() {
    final now = DateTime.now();
    
    switch (_selectedFilter) {
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return globalDeals.where((deal) {
          return deal.deliverablesDueDate.isAfter(startOfWeek) &&
                 deal.deliverablesDueDate.isBefore(endOfWeek.add(const Duration(days: 1)));
        }).toList();
      
      case 'This Month':
        return globalDeals.where((deal) {
          return deal.deliverablesDueDate.year == now.year &&
                 deal.deliverablesDueDate.month == now.month;
        }).toList();
      
      case 'Overdue':
        return globalDeals.where((deal) {
          return deal.deliverablesDueDate.isBefore(now) &&
                 deal.status != 'Completed';
        }).toList();
      
      default:
        return globalDeals;
    }
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'This Week':
        return Icons.date_range;
      case 'This Month':
        return Icons.calendar_month;
      case 'Overdue':
        return Icons.warning;
      default:
        return Icons.all_inclusive;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.blue;
      case 'Pending':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showMonthYearPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _focusedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _focusedMonth = DateTime(picked.year, picked.month, 1);
        _selectedDate = picked;
      });
    }
  }
}