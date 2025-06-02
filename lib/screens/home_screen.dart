import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/deal.dart';
import '../utils/globals.dart';
import '../utils/user_preferences.dart';
import '../main.dart';

class HistogramData {
  final String label;
  final double value;
  final bool isYear;
  final DateTime startDate;
  final DateTime endDate;

  HistogramData({
    required this.label,
    required this.value,
    required this.isYear,
    required this.startDate,
    required this.endDate,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedTimeframe = 'This Month';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String? _userName;

  final List<String> _timeframes = [
    'This Week',
    'This Month',
    'This Quarter',
    'This Year',
    'FY 2024-25',
    'Custom Range'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final userName = await UserPreferences.getUserName();
    setState(() {
      _userName = userName;
    });
  }

  String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    )}';
  }

  String formatCurrencyCompact(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredDeals = _getFilteredDeals();
    final dashboardData = _calculateDashboardData(filteredDeals);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today),
            onSelected: (String value) {
              if (value == 'Custom Range') {
                _showCustomDateRangePicker();
              } else {
                setState(() {
                  _selectedTimeframe = value;
                  _customStartDate = null;
                  _customEndDate = null;
                });
              }
            },
            itemBuilder: (BuildContext context) {
              return _timeframes.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Row(
                    children: [
                      Icon(
                        _selectedTimeframe == choice ? Icons.check : _getTimeframeIcon(choice),
                        size: 18,
                        color: _selectedTimeframe == choice ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          choice,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          IconButton(
            icon: const Icon(Icons.calculate),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DealCalculatorScreen()),
              );
            },
            tooltip: 'Deal Calculator',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (String value) {
              if (value == 'reset_welcome') {
                _showResetWelcomeDialog();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'reset_welcome',
                  child: Row(
                    children: [
                      const Icon(Icons.refresh, size: 18),
                      const SizedBox(width: 8),
                      const Text('Reset Welcome'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUserName();
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(dashboardData),
              const SizedBox(height: 20),
              _buildTimeframeHeader(filteredDeals.length),
              const SizedBox(height: 16),
              _buildFinancialOverview(dashboardData),
              const SizedBox(height: 20),
              _buildCommissionTaxOverview(dashboardData),
              const SizedBox(height: 20),
              _buildDealsOverview(dashboardData),
              const SizedBox(height: 20),
              _buildPaymentScheduleSection(filteredDeals),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetWelcomeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Welcome'),
          content: const Text(
            'This will reset the app and show the welcome screen again. '
            'Your deals data will not be affected.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                await UserPreferences.setWelcomeCompleted(false);
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/welcome');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('RESET'),
            ),
          ],
        );
      },
    );
  }

  IconData _getTimeframeIcon(String timeframe) {
    switch (timeframe) {
      case 'This Week':
        return Icons.date_range;
      case 'This Month':
        return Icons.calendar_view_month;
      case 'This Quarter':
        return Icons.calendar_view_week;
      case 'This Year':
        return Icons.calendar_today;
      case 'FY 2024-25':
        return Icons.account_balance;
      case 'Custom Range':
        return Icons.date_range;
      default:
        return Icons.calendar_today;
    }
  }

  void _showCustomDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
      helpText: 'Select Date Range',
      cancelText: 'Cancel',
      confirmText: 'Apply',
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
        _selectedTimeframe = 'Custom Range';
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    }
  }

  Widget _buildWelcomeCard(Map<String, dynamic> dashboardData) {
  final now = DateTime.now();
  final greeting = now.hour < 12 ? 'Good Morning' :
  now.hour < 17 ? 'Good Afternoon' :
  'Good Evening';

  final personalizedGreeting = _userName != null 
      ? '$greeting, $_userName!' 
      : '$greeting, Creator!';

  // Use filtered data based on selected timeframe instead of lifetime data
  final timeframeDealsCount = dashboardData['completedDeals'] as int;
  final timeframeEarnings = dashboardData['totalEarnings'] as double;
  
  // Get display text for the timeframe
  String timeframeDisplayText = _selectedTimeframe;
  if (_selectedTimeframe == 'Custom Range' && _customStartDate != null && _customEndDate != null) {
    final formatter = DateFormat('MMM dd');
    timeframeDisplayText = '${formatter.format(_customStartDate!)} - ${formatter.format(_customEndDate!)}';
  }

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20.0),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Theme.of(context).primaryColor,
          Theme.of(context).primaryColor.withOpacity(0.8),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          personalizedGreeting,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getMotivationalMessage(dashboardData),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        // Show the selected timeframe
        Text(
          'Performance: $timeframeDisplayText',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white60,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildClickableWelcomeStatItem(
              'Deals Closed',
              timeframeDealsCount.toString(),
              Icons.handshake,
              () => _showDealsHistogram(),
            ),
            const SizedBox(width: 24),
            _buildClickableWelcomeStatItem(
              'Earnings',
              formatCurrencyCompact(timeframeEarnings),
              Icons.currency_rupee,
              () => _showEarningsHistogram(),
            ),
          ],
        ),
      ],
    ),
  );
}

// Add these methods inside the _HomeScreenState class

// Updated _buildWelcomeStatItem to be clickable
Widget _buildClickableWelcomeStatItem(String label, String value, IconData icon, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.touch_app,
                    color: Colors.white60,
                    size: 12,
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

// Method to show deals histogram
void _showDealsHistogram() {
  final histogramData = _calculateDealsHistogramData();
  _showHistogramModal('Deals Closed Over Time', histogramData, false);
}

// Method to show earnings histogram
void _showEarningsHistogram() {
  final histogramData = _calculateEarningsHistogramData();
  _showHistogramModal('Earnings Over Time', histogramData, true);
}

// Calculate deals histogram data
List<HistogramData> _calculateDealsHistogramData() {
  if (globalDeals.isEmpty) return [];

  final now = DateTime.now();
  final data = <HistogramData>[];
  
  // Group deals by financial year and month
  final dealsByPeriod = <String, List<Deal>>{};
  
  for (final deal in globalDeals) {
    final dealDate = deal.dealLockedDate;
    final fy = _getFinancialYear(dealDate);
    final currentFY = _getFinancialYear(now);
    
    String periodKey;
    if (fy < currentFY) {
      // Previous years - group by financial year
      periodKey = 'FY ${fy.toString().substring(2)}';
    } else {
      // Current financial year - group by month
      periodKey = DateFormat('MMM yy').format(dealDate);
    }
    
    dealsByPeriod.putIfAbsent(periodKey, () => []).add(deal);
  }

  // Convert to histogram data
  final sortedKeys = dealsByPeriod.keys.toList()..sort((a, b) {
    // Custom sorting: FY entries first, then monthly entries
    if (a.startsWith('FY') && !b.startsWith('FY')) return -1;
    if (!a.startsWith('FY') && b.startsWith('FY')) return 1;
    return a.compareTo(b);
  });

  for (final key in sortedKeys) {
    final deals = dealsByPeriod[key]!;
    final isYear = key.startsWith('FY');
    final completedDeals = deals.where((deal) => 
      deal.status == 'Completed' || 
      (deal.contentLink != null && deal.contentLink!.isNotEmpty)
    ).length;
    
    data.add(HistogramData(
      label: key,
      value: completedDeals.toDouble(),
      isYear: isYear,
      startDate: deals.map((d) => d.dealLockedDate).reduce((a, b) => a.isBefore(b) ? a : b),
      endDate: deals.map((d) => d.dealLockedDate).reduce((a, b) => a.isAfter(b) ? a : b),
    ));
  }

  return data;
}

// Calculate earnings histogram data
List<HistogramData> _calculateEarningsHistogramData() {
  if (globalDeals.isEmpty) return [];

  final now = DateTime.now();
  final data = <HistogramData>[];
  
  // Group deals by financial year and month
  final dealsByPeriod = <String, List<Deal>>{};
  
  for (final deal in globalDeals) {
    final dealDate = deal.dealLockedDate;
    final fy = _getFinancialYear(dealDate);
    final currentFY = _getFinancialYear(now);
    
    String periodKey;
    if (fy < currentFY) {
      // Previous years - group by financial year
      periodKey = 'FY ${fy.toString().substring(2)}';
    } else {
      // Current financial year - group by month
      periodKey = DateFormat('MMM yy').format(dealDate);
    }
    
    dealsByPeriod.putIfAbsent(periodKey, () => []).add(deal);
  }

  // Convert to histogram data
  final sortedKeys = dealsByPeriod.keys.toList()..sort((a, b) {
    // Custom sorting: FY entries first, then monthly entries
    if (a.startsWith('FY') && !b.startsWith('FY')) return -1;
    if (!a.startsWith('FY') && b.startsWith('FY')) return 1;
    return a.compareTo(b);
  });

  for (final key in sortedKeys) {
    final deals = dealsByPeriod[key]!;
    final isYear = key.startsWith('FY');
    final totalEarnings = deals.fold(0.0, (sum, deal) => sum + deal.payment);
    
    data.add(HistogramData(
      label: key,
      value: totalEarnings,
      isYear: isYear,
      startDate: deals.map((d) => d.dealLockedDate).reduce((a, b) => a.isBefore(b) ? a : b),
      endDate: deals.map((d) => d.dealLockedDate).reduce((a, b) => a.isAfter(b) ? a : b),
    ));
  }

  return data;
}

// Helper method to get financial year
int _getFinancialYear(DateTime date) {
  if (date.month >= 4) {
    return date.year;
  } else {
    return date.year - 1;
  }
}

// Show histogram modal
void _showHistogramModal(String title, List<HistogramData> data, bool isEarnings) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isEarnings ? Colors.green : Colors.blue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isEarnings ? Icons.currency_rupee : Icons.handshake,
                      color: isEarnings ? Colors.green : Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Chart
            Expanded(
              child: data.isEmpty
                  ? _buildEmptyChart()
                  : _buildHistogramChart(data, isEarnings),
            ),
            
            // Legend and summary
            _buildChartLegend(data, isEarnings),
          ],
        ),
      );
    },
  );
}

// Build histogram chart
Widget _buildHistogramChart(List<HistogramData> data, bool isEarnings) {
  if (data.isEmpty) return _buildEmptyChart();

  final maxValue = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
  
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        // Chart area
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((item) {
              final height = maxValue > 0 ? (item.value / maxValue) * 200 : 0.0;
              final barColor = item.isYear
                  ? (isEarnings ? Colors.green[600]! : Colors.blue[600]!)
                  : (isEarnings ? Colors.green[400]! : Colors.blue[400]!);
              
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Value label on top
                      Container(
                        height: 30,
                        alignment: Alignment.bottomCenter,
                        child: Text(
                          isEarnings 
                              ? formatCurrencyCompact(item.value)
                              : item.value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Bar
                      Container(
                        height: height,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Label at bottom
                      Container(
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: item.isYear ? FontWeight.bold : FontWeight.normal,
                            color: item.isYear ? Colors.black87 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}

// Build empty chart
Widget _buildEmptyChart() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.bar_chart,
          size: 64,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          'No data available',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add some deals to see analytics',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}

// Build chart legend and summary
Widget _buildChartLegend(List<HistogramData> data, bool isEarnings) {
  if (data.isEmpty) return const SizedBox();

  final total = data.fold(0.0, (sum, item) => sum + item.value);
  final average = total / data.length;

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
    ),
    child: Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(
              'Financial Years',
              isEarnings ? Colors.green[600]! : Colors.blue[600]!,
            ),
            const SizedBox(width: 24),
            _buildLegendItem(
              'Current FY Months',
              isEarnings ? Colors.green[400]! : Colors.blue[400]!,
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    isEarnings 
                        ? formatCurrency(total)
                        : total.toInt().toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Average:',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    isEarnings 
                        ? formatCurrency(average)
                        : average.round().toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// Build legend item
Widget _buildLegendItem(String label, Color color) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
    ],
  );
}

  Widget _buildWelcomeStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeframeHeader(int dealsCount) {
    String displayText = _selectedTimeframe;
    if (_selectedTimeframe == 'Custom Range' && _customStartDate != null && _customEndDate != null) {
      final formatter = DateFormat('MMM dd, yyyy');
      displayText = '${formatter.format(_customStartDate!)} - ${formatter.format(_customEndDate!)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Analytics for $displayText',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$dealsCount deals',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialOverview(Map<String, dynamic> data) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Financial Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildFinancialCard(
                  'Total Earnings',
                  formatCurrencyCompact(data['totalEarnings']),
                  Icons.trending_up,
                  Colors.blue,
                  subtitle: 'Gross amount',
                ),
                const SizedBox(width: 12),
                _buildFinancialCard(
                  'Net Earnings',
                  formatCurrencyCompact(data['netEarnings']),
                  Icons.account_balance_wallet,
                  Colors.green,
                  subtitle: 'After deductions',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildClickableFinancialCard(
                  'Net Paid',
                  formatCurrencyCompact(data['netPaidAmount']),
                  Icons.check_circle,
                  Colors.green,
                  subtitle: '${data['paidCount']} deals',
                  onTap: () => _showNetPaidDetails(),
                ),
                const SizedBox(width: 12),
                _buildFinancialCard(
                  'Work Pending',
                  formatCurrencyCompact(data['workPendingAmount']),
                  Icons.pending_actions,
                  Colors.orange,
                  subtitle: '${data['workPendingCount']} deals',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildClickableFinancialCard(
                  'Net Pending Payment',
                  formatCurrencyCompact(data['netPendingPaymentAmount']),
                  Icons.schedule,
                  Colors.blue,
                  subtitle: '${data['pendingPaymentCount']} deals',
                  onTap: () => _showNetPendingPaymentDetails(),
                ),
                const SizedBox(width: 12),
                Container(
                  width: (MediaQuery.of(context).size.width - 56) / 2,
                  height: 80,
                ),
              ],
            ),
            if (data['overdueCount'] > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${data['overdueCount']} payments are overdue',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.trending_up, color: color, size: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClickableFinancialCard(String title, String value, IconData icon, Color color, {String? subtitle, VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_forward_ios, color: color, size: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommissionTaxOverview(Map<String, dynamic> data) {
  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.purple[600]),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Commission & Tax Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance, color: Colors.red, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Total Liability',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildLiabilityRow('Commission (20%)', data['totalCommission'], Colors.red),
                      const SizedBox(height: 6),
                      _buildLiabilityRow('TDS (10%)', data['totalTDS'], Colors.orange),
                      const Divider(height: 16),
                      _buildLiabilityRow('Total', data['totalCommission'] + data['totalTDS'], Colors.red, isTotal: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.paid, color: Colors.green, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Total Paid',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildLiabilityRow('Commission', data['paidCommission'], Colors.green),
                      const SizedBox(height: 6),
                      _buildLiabilityRow('TDS', data['paidTDS'], Colors.teal),
                      const Divider(height: 16),
                      _buildLiabilityRow('Total', data['paidCommission'] + data['paidTDS'], Colors.green, isTotal: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildLiabilityRow(String label, double amount, Color color, {bool isTotal = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 13 : 11,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          flex: 2,
          child: Text(
            formatCurrencyCompact(amount),
            style: TextStyle(
              fontSize: isTotal ? 13 : 11,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildDealsOverview(Map<String, dynamic> data) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.handshake, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'Deals Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildClickableDealStatusIndicator(
                  'Completed',
                  data['completedDeals'],
                  data['totalDeals'],
                  Colors.green,
                  () => _showCompletedDealsDetails(),
                ),
                _buildClickableDealStatusIndicator(
                  'Active',
                  data['activeDeals'],
                  data['totalDeals'],
                  Colors.blue,
                  () => _showActiveDealsDetails(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.business, color: Colors.grey[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Working with ${data['uniqueBrands']} unique brands',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClickableDealStatusIndicator(String label, int count, int total, Color color, VoidCallback onTap) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
              ),
              child: Center(
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Icon(
              Icons.touch_app,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentScheduleSection(List<Deal> deals) {
  final paymentSchedule = _getPaymentSchedule(deals);
  
  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_outlined, color: Colors.orange[600]),
              const SizedBox(width: 8),
              const Text(
                'Payment Schedule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (paymentSchedule['overdue']?.isNotEmpty == true) ...[
            _buildPaymentSection(
              'Overdue Payments',
              paymentSchedule['overdue']!,
              Colors.red,
              Icons.warning,
              'Payment is overdue',
            ),
            const SizedBox(height: 16),
          ],
          
          if (paymentSchedule['dueSoon']?.isNotEmpty == true) ...[
            _buildPaymentSection(
              'Due Soon (Next 7 Days)',
              paymentSchedule['dueSoon']!,
              Colors.orange,
              Icons.schedule,
              'Payment due within 7 days',
            ),
            const SizedBox(height: 16),
          ],
          
          if (paymentSchedule['upcoming']?.isNotEmpty == true) ...[
            _buildPaymentSection(
              'Upcoming Payments',
              paymentSchedule['upcoming']!.take(3).toList(),
              Colors.blue,
              Icons.calendar_today,
              'Payments scheduled for later',
            ),
            const SizedBox(height: 16),
          ],
          
          if ((paymentSchedule['overdue']?.isEmpty ?? true) && 
              (paymentSchedule['dueSoon']?.isEmpty ?? true) && 
              (paymentSchedule['upcoming']?.isEmpty ?? true)) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No pending payments',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All payments are up to date!',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

// Replace the _buildPaymentSection method in your home_screen.dart

Widget _buildPaymentSection(String title, List<Deal> deals, Color color, IconData icon, String description) {
  final totalAmount = deals.fold(0.0, (sum, deal) => sum + deal.payment);
  final totalNetAmount = deals.fold(0.0, (sum, deal) => 
    sum + DealCalculator(dealPrice: deal.payment).netAmount);
  
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${deals.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        
        // Show limited items
        ...deals.take(3).map((deal) => _buildPaymentItem(deal, color)).toList(),
        
        // Clickable "show more" section
        if (deals.length > 3) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _showAllPaymentsModal(title, deals, color, icon),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.2), style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.visibility,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'View all ${deals.length} payments',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: color,
                  ),
                ],
              ),
            ),
          ),
        ],
        
        const SizedBox(height: 12),
        
        // Summary section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gross Amount:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    formatCurrency(totalAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Net Amount Due:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    formatCurrency(totalNetAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// Add this new method to show all payments in a scrollable modal
void _showAllPaymentsModal(String title, List<Deal> deals, Color color, IconData icon) {
  final totalAmount = deals.fold(0.0, (sum, deal) => sum + deal.payment);
  final totalNetAmount = deals.fold(0.0, (sum, deal) => 
    sum + DealCalculator(dealPrice: deal.payment).netAmount);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: color, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                                Text(
                                  '${deals.length} payment${deals.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Content - Scrollable list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: deals.length,
                    itemBuilder: (context, index) {
                      final deal = deals[index];
                      final calculator = DealCalculator(dealPrice: deal.payment);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: color.withOpacity(0.3)),
                            ),
                            child: Icon(icon, color: color),
                          ),
                          title: Text(
                            deal.brandName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (deal.productName.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  deal.productName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                deal.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.schedule, size: 14, color: color),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Expected: ${DateFormat('MMM dd, yyyy').format(deal.expectedPaymentDate)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              if (deal.isPaymentOverdue) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.error, size: 14, color: Colors.red),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Overdue by ${deal.daysOverdue} days',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 8),
                              // Payment breakdown
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Deal Amount:',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                        Text(
                                          formatCurrencyCompact(deal.payment),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Commission (20%):',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                        Text(
                                          '- ${formatCurrencyCompact(calculator.commission)}',
                                          style: const TextStyle(fontSize: 12, color: Colors.red),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'TDS (10%):',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                        Text(
                                          '- ${formatCurrencyCompact(calculator.tds)}',
                                          style: const TextStyle(fontSize: 12, color: Colors.orange),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Net Due:',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          formatCurrencyCompact(calculator.netAmount),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (deal.isPaymentOverdue)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${deal.daysOverdue}d',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Footer with summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Gross Amount:',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  formatCurrency(totalAmount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Net Amount:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Text(
                                  formatCurrency(totalNetAmount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.timeline, size: 18),
                              label: const Text('View Timeline'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                // Navigate to timeline screen
                                DefaultTabController.of(context)?.animateTo(2);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _buildPaymentItem(Deal deal, Color color) {
  final dateFormat = DateFormat('MMM dd');
  final calculator = DealCalculator(dealPrice: deal.payment);
  
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deal.brandName,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              if (deal.productName.isNotEmpty) ...[
                Text(
                  deal.productName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Show both gross and net amounts
            Text(
              formatCurrencyCompact(deal.payment),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              formatCurrencyCompact(calculator.netAmount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
            Text(
              dateFormat.format(deal.expectedPaymentDate),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (deal.isPaymentOverdue)
              Text(
                '${deal.daysOverdue}d overdue',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

  // Helper methods
  List<Deal> _getFilteredDeals() {
    final now = DateTime.now();

    switch (_selectedTimeframe) {
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return globalDeals.where((deal) {
          return deal.dealLockedDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              deal.dealLockedDate.isBefore(endOfWeek.add(const Duration(days: 1)));
        }).toList();

      case 'This Month':
        return globalDeals.where((deal) {
          return deal.dealLockedDate.year == now.year &&
              deal.dealLockedDate.month == now.month;
        }).toList();

      case 'This Quarter':
        final quarterStart = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1);
        return globalDeals.where((deal) {
          return deal.dealLockedDate.isAfter(quarterStart.subtract(const Duration(days: 1))) &&
              deal.dealLockedDate.isBefore(now.add(const Duration(days: 1)));
        }).toList();

      case 'This Year':
        return globalDeals.where((deal) {
          return deal.dealLockedDate.year == now.year;
        }).toList();

      case 'FY 2024-25':
        final currentYear = now.year;
        final fyStart = now.month >= 4
            ? DateTime(currentYear, 4, 1)
            : DateTime(currentYear - 1, 4, 1);
        final fyEnd = fyStart.add(const Duration(days: 365));

        return globalDeals.where((deal) {
          return deal.dealLockedDate.isAfter(fyStart.subtract(const Duration(days: 1))) &&
              deal.dealLockedDate.isBefore(fyEnd);
        }).toList();

      case 'Custom Range':
        if (_customStartDate != null && _customEndDate != null) {
          return globalDeals.where((deal) {
            return deal.dealLockedDate.isAfter(_customStartDate!.subtract(const Duration(days: 1))) &&
                deal.dealLockedDate.isBefore(_customEndDate!.add(const Duration(days: 1)));
          }).toList();
        }
        return globalDeals;

      default:
        return globalDeals;
    }
  }

  Map<String, dynamic> _calculateDashboardData(List<Deal> deals) {
    final totalDeals = deals.length;
    final completedDeals = deals.where((deal) =>
    deal.contentLink != null && deal.contentLink!.isNotEmpty).length;
    final activeDeals = deals.where((deal) =>
    deal.contentLink == null || deal.contentLink!.isEmpty).length;

    final totalEarnings = deals.fold(0.0, (sum, deal) => sum + deal.payment);
    final netEarnings = deals.fold(0.0, (sum, deal) =>
    sum + DealCalculator(dealPrice: deal.payment).netAmount);

    final paidDeals = deals.where((deal) => deal.isPaid).toList();
    final pendingPaymentDeals = deals.where((deal) =>
    !deal.isPaid &&
        deal.contentLink != null &&
        deal.contentLink!.isNotEmpty).toList();
    final workPendingDeals = deals.where((deal) =>
    !deal.isPaid &&
        (deal.contentLink == null || deal.contentLink!.isEmpty)).toList();

    final paidAmount = paidDeals.fold(0.0, (sum, deal) => sum + deal.payment);
    final pendingPaymentAmount = pendingPaymentDeals.fold(0.0, (sum, deal) => sum + deal.payment);
    final workPendingAmount = workPendingDeals.fold(0.0, (sum, deal) => sum + deal.payment);

    final netPaidAmount = paidDeals.fold(0.0, (sum, deal) =>
    sum + DealCalculator(dealPrice: deal.payment).netAmount);
    final netPendingPaymentAmount = pendingPaymentDeals.fold(0.0, (sum, deal) =>
    sum + DealCalculator(dealPrice: deal.payment).netAmount);

    final totalCommission = deals.fold(0.0, (sum, deal) =>
    sum + DealCalculator(dealPrice: deal.payment).commission);
    final totalTDS = deals.fold(0.0, (sum, deal) =>
    sum + DealCalculator(dealPrice: deal.payment).tds);

    final paidCommission = paidDeals.fold(0.0, (sum, deal) =>
    sum + DealCalculator(dealPrice: deal.payment).commission);
    final paidTDS = paidDeals.fold(0.0, (sum, deal) =>
    sum + DealCalculator(dealPrice: deal.payment).tds);

    final unpaidDeals = deals.where((deal) => !deal.isPaid).toList();
    final overdueDeals = unpaidDeals.where((deal) => deal.isPaymentOverdue).length;

    final brandSet = <String>{};
    for (final deal in deals) {
      brandSet.add(deal.brandName);
    }
    final uniqueBrands = brandSet.length;

    return {
      'totalDeals': totalDeals,
      'activeDeals': activeDeals,
      'completedDeals': completedDeals,
      'totalEarnings': totalEarnings,
      'netEarnings': netEarnings,
      'paidAmount': paidAmount,
      'paidCount': paidDeals.length,
      'netPaidAmount': netPaidAmount,
      'pendingPaymentAmount': pendingPaymentAmount,
      'pendingPaymentCount': pendingPaymentDeals.length,
      'netPendingPaymentAmount': netPendingPaymentAmount,
      'workPendingAmount': workPendingAmount,
      'workPendingCount': workPendingDeals.length,
      'totalCommission': totalCommission,
      'totalTDS': totalTDS,
      'paidCommission': paidCommission,
      'paidTDS': paidTDS,
      'overdueCount': overdueDeals,
      'uniqueBrands': uniqueBrands,
    };
  }

  List<Deal> _getThisWeekDeadlines() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return globalDeals
        .where((deal) =>
    deal.deliverablesDueDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        deal.deliverablesDueDate.isBefore(endOfWeek.add(const Duration(days: 1))) &&
        deal.status != 'Completed')
        .toList();
  }

  String _getMotivationalMessage(Map<String, dynamic> dashboardData) {
    final completedDeals = dashboardData['completedDeals'] as int;
    final totalEarnings = dashboardData['totalEarnings'] as double;

    if (completedDeals == 0) {
      return "Ready to start your creator journey? Add your first deal!";
    } else if (completedDeals < 5) {
      return "Great start! You're building your creator business.";
    } else if (totalEarnings > 50000) {
      return "Impressive! You're becoming a successful creator.";
    } else {
      return "Keep growing! Your creator empire is expanding.";
    }
  }

  Map<String, List<Deal>> _getPaymentSchedule(List<Deal> deals) {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    
    final unpaidDeals = deals.where((deal) => 
      !deal.isPaid && 
      deal.contentLink != null && 
      deal.contentLink!.isNotEmpty
    ).toList();

    final overdue = <Deal>[];
    final dueSoon = <Deal>[];
    final upcoming = <Deal>[];

    for (final deal in unpaidDeals) {
      if (deal.expectedPaymentDate.isBefore(now)) {
        overdue.add(deal);
      } else if (deal.expectedPaymentDate.isBefore(nextWeek)) {
        dueSoon.add(deal);
      } else {
        upcoming.add(deal);
      }
    }

    overdue.sort((a, b) => a.expectedPaymentDate.compareTo(b.expectedPaymentDate));
    dueSoon.sort((a, b) => a.expectedPaymentDate.compareTo(b.expectedPaymentDate));
    upcoming.sort((a, b) => a.expectedPaymentDate.compareTo(b.expectedPaymentDate));

    return {
      'overdue': overdue,
      'dueSoon': dueSoon,
      'upcoming': upcoming,
    };
  }

  // Detail modal methods
  void _showNetPaidDetails() {
    final filteredDeals = _getFilteredDeals();
    final paidDeals = filteredDeals.where((deal) => deal.isPaid).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Net Paid Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Payments received (net amounts)',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: paidDeals.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No payments received yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: paidDeals.length,
                  itemBuilder: (context, index) {
                    final deal = paidDeals[index];
                    final calculator = DealCalculator(dealPrice: deal.payment);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                        title: Text(
                          deal.brandName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (deal.productName.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                deal.productName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              'Deal Amount: ${formatCurrency(deal.payment)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Commission: ${formatCurrency(calculator.commission)}',
                              style: TextStyle(fontSize: 12, color: Colors.red[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'TDS: ${formatCurrency(calculator.tds)}',
                              style: TextStyle(fontSize: 12, color: Colors.orange[600]),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Net Paid',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              formatCurrency(calculator.netAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total Net Paid: ${formatCurrency(paidDeals.fold(0.0, (sum, deal) => sum + DealCalculator(dealPrice: deal.payment).netAmount))}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNetPendingPaymentDetails() {
    final filteredDeals = _getFilteredDeals();
    final pendingPaymentDeals = filteredDeals.where((deal) =>
    !deal.isPaid &&
        deal.contentLink != null &&
        deal.contentLink!.isNotEmpty).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Net Pending Payments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Content delivered, awaiting payment (net amounts)',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: pendingPaymentDeals.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending payments',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: pendingPaymentDeals.length,
                  itemBuilder: (context, index) {
                    final deal = pendingPaymentDeals[index];
                    final calculator = DealCalculator(dealPrice: deal.payment);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Icon(
                            deal.isPaymentOverdue ? Icons.warning : Icons.schedule,
                            color: deal.isPaymentOverdue ? Colors.red : Colors.blue,
                          ),
                        ),
                        title: Text(
                          deal.brandName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (deal.productName.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                deal.productName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              'Deal Amount: ${formatCurrency(deal.payment)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Commission: ${formatCurrency(calculator.commission)}',
                              style: TextStyle(fontSize: 12, color: Colors.red[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'TDS: ${formatCurrency(calculator.tds)}',
                              style: TextStyle(fontSize: 12, color: Colors.orange[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Expected: ${DateFormat('MMM dd, yyyy').format(deal.expectedPaymentDate)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: deal.isPaymentOverdue ? Colors.red : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Net Expected',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              formatCurrency(calculator.netAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blue,
                              ),
                            ),
                            if (deal.isPaymentOverdue)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${deal.daysOverdue}d overdue',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total Net Pending: ${formatCurrency(pendingPaymentDeals.fold(0.0, (sum, deal) => sum + DealCalculator(dealPrice: deal.payment).netAmount))}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCompletedDealsDetails() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Completed deals details - Feature coming soon!')),
    );
  }

  void _showActiveDealsDetails() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Active deals details - Feature coming soon!')),
    );
  }
}