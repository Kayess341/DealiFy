import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/deal.dart';
import '../utils/globals.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _timeRange = 'This Month';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  final List<String> _timeRanges = [
    'This Month',
    'Last Month',
    'This Quarter',
    'This Year',
    'Last Year',
    'FY 2024-25', // Current Financial Year
    'Custom Range',
    'All Time',
  ];

  String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    )}';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Financial'),
            Tab(text: 'Deal Analytics'),
            Tab(text: 'Business Insights'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today),
            onSelected: (String value) {
              if (value == 'Custom Range') {
                _showCustomDateRangePicker();
              } else {
                setState(() {
                  _timeRange = value;
                  _customStartDate = null;
                  _customEndDate = null;
                });
              }
            },
            itemBuilder: (BuildContext context) {
              return _timeRanges.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Row(
                    children: [
                      Icon(
                        _timeRange == choice ? Icons.check : _getTimeRangeIcon(choice),
                        size: 18,
                        color: _timeRange == choice ? Colors.green : Colors.grey,
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
            icon: const Icon(Icons.download),
            onPressed: () {
              _showExportOptions();
            },
            tooltip: 'Export Reports',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFinancialTab(),
          _buildDealAnalyticsTab(),
          _buildBusinessInsightsTab(),
        ],
      ),
    );
  }

  IconData _getTimeRangeIcon(String timeRange) {
    switch (timeRange) {
      case 'This Month':
      case 'Last Month':
        return Icons.calendar_view_month;
      case 'This Quarter':
        return Icons.calendar_view_week;
      case 'This Year':
      case 'Last Year':
        return Icons.calendar_today;
      case 'FY 2024-25':
        return Icons.account_balance;
      case 'Custom Range':
        return Icons.date_range;
      case 'All Time':
        return Icons.all_inclusive;
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
      helpText: 'Select Date Range for Reports',
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
        _timeRange = 'Custom Range';
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    }
  }

  

  Widget _buildDealAnalyticsTab() {
    final filteredDeals = _getFilteredDeals();
    final analyticsData = _calculateDealAnalytics(filteredDeals);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeRangeHeader(),
          const SizedBox(height: 16),
          _buildDealSummaryCards(analyticsData),
          const SizedBox(height: 24),
          _buildSectionHeader('Deal Status Distribution'),
          const SizedBox(height: 16),
          _buildDealStatusChart(analyticsData),
          const SizedBox(height: 24),
          _buildSectionHeader('Content Status Breakdown'),
          const SizedBox(height: 16),
          _buildContentStatusChart(analyticsData),
          const SizedBox(height: 24),
          _buildSectionHeader('Top Brands'),
          const SizedBox(height: 16),
          _buildTopBrandsTable(analyticsData),
        ],
      ),
    );
  }

  Widget _buildBusinessInsightsTab() {
    final filteredDeals = _getFilteredDeals();
    final insightsData = _calculateBusinessInsights(filteredDeals);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeRangeHeader(),
          const SizedBox(height: 16),
          _buildInsightsSummaryCards(insightsData),
          const SizedBox(height: 24),
          _buildSectionHeader('Monthly Goal Tracking'),
          const SizedBox(height: 16),
          _buildGoalTrackingCard(insightsData),
          const SizedBox(height: 24),
          _buildSectionHeader('Deal Frequency Analysis'),
          const SizedBox(height: 16),
          _buildDealFrequencyChart(),
        ],
      ),
    );
  }

  Widget _buildTimeRangeHeader() {
    String displayText = _timeRange;
    if (_timeRange == 'Custom Range' && _customStartDate != null && _customEndDate != null) {
      final formatter = DateFormat('MMM dd, yyyy');
      displayText = '${formatter.format(_customStartDate!)} - ${formatter.format(_customEndDate!)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.date_range,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Period: $displayText',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  Widget _buildFinancialSummaryCards(Map<String, double> data) {
  return Column(
    children: [
      Row(
        children: [
          _buildSummaryCard(
            'Total Earnings',
            formatCurrency(data['totalEarnings']!),
            Icons.attach_money,
            Colors.green,
          ),
          const SizedBox(width: 16),
          _buildSummaryCard(
            'Net Earnings',
            formatCurrency(data['netEarnings']!),
            Icons.account_balance_wallet,
            Colors.blue,
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          _buildSummaryCard(
            'Work Pending',
            formatCurrency(data['workPendingAmount']!),
            Icons.pending_actions,
            Colors.orange,
          ),
          const SizedBox(width: 16),
          _buildSummaryCard(
            'Average Deal Value',
            formatCurrency(data['averageDealValue']!),
            Icons.bar_chart,
            Colors.purple,
          ),
        ],
      ),
    ],
  );
}

  Widget _buildFinancialTab() {
  final filteredDeals = _getFilteredDeals();
  final financialData = _calculateFinancialData(filteredDeals);
  final cashFlowData = _calculateCashFlowData(filteredDeals);  // NEW

  return SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimeRangeHeader(),
        const SizedBox(height: 16),
        _buildFinancialSummaryCards(financialData),
        const SizedBox(height: 24),
        _buildSectionHeader('Earnings Breakdown'),
        const SizedBox(height: 16),
        _buildEarningsBreakdownChart(financialData),
        const SizedBox(height: 24),
        _buildSectionHeader('Payment Status Overview'),
        const SizedBox(height: 16),
        _buildPaymentStatusCards(financialData),
        const SizedBox(height: 24),
        
        // NEW: Cash Flow Section
        _buildSectionHeader('Cash Flow Analysis'),
        const SizedBox(height: 16),
        _buildCashFlowSection(cashFlowData),
        const SizedBox(height: 24),
        
        _buildSectionHeader('Commission & Tax Analysis'),
        const SizedBox(height: 16),
        _buildCommissionTaxBreakdown(financialData),
      ],
    ),
  );
}

  Widget _buildDealSummaryCards(Map<String, dynamic> data) {
    return Column(
      children: [
        Row(
          children: [
            _buildSummaryCard(
              'Total Deals',
              '${data['totalDeals']}',
              Icons.handshake,
              Colors.blue,
            ),
            const SizedBox(width: 16),
            _buildSummaryCard(
              'Completed Deals',
              '${data['completedDeals']}',
              Icons.check_circle,
              Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildSummaryCard(
              'Active Deals',
              '${data['activeDeals']}',
              Icons.pending_actions,
              Colors.orange,
            ),
            const SizedBox(width: 16),
            _buildSummaryCard(
              'Unique Brands',
              '${data['uniqueBrands']}',
              Icons.business,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightsSummaryCards(Map<String, dynamic> data) {
    return Column(
      children: [
        Row(
          children: [
            _buildSummaryCard(
              'Deal Frequency',
              '${(data['dealsPerMonth'] as double).toStringAsFixed(1)}/month',
              Icons.speed,
              Colors.teal,
            ),
            const SizedBox(width: 16),
            _buildSummaryCard(
              'Growth Rate',
              '${(data['growthRate'] as double).toStringAsFixed(1)}%',
              Icons.trending_up,
              (data['growthRate'] as double) >= 0 ? Colors.green : Colors.red,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildSummaryCard(
              'Repeat Brands',
              '${data['repeatBrands']}%',
              Icons.refresh,
              Colors.cyan,
            ),
            const SizedBox(width: 16),
            _buildSummaryCard(
              'Monthly Target',
              formatCurrency(100000.0),
              Icons.flag,
              Colors.indigo,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsBreakdownChart(Map<String, double> data) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildBreakdownRow('Total Earnings', data['totalEarnings']!, Colors.blue),
            const SizedBox(height: 8),
            _buildBreakdownRow('Commission Deducted', data['totalCommission']!, Colors.red),
            const SizedBox(height: 8),
            _buildBreakdownRow('TDS Deducted', data['totalTDS']!, Colors.orange),
            const Divider(),
            _buildBreakdownRow('Net Earnings', data['netEarnings']!, Colors.green, isMain: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount, Color color, {bool isMain = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isMain ? 16 : 14,
            fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          formatCurrency(amount),
          style: TextStyle(
            fontSize: isMain ? 16 : 14,
            fontWeight: isMain ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  // Updated Payment Status Cards with clickable Pending Payment card
  Widget _buildPaymentStatusCards(Map<String, double> data) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatusCard(
              'Paid',
              formatCurrency(data['paidAmount']!),
              '${data['paidCount']!.toInt()} deals',
              Colors.green,
              'Payment received',
            ),
            const SizedBox(width: 12),
            _buildClickableStatusCard(
              'Pending Payment',
              formatCurrency(data['pendingPaymentAmount']!),
              '${data['pendingPaymentCount']!.toInt()} deals',
              Colors.blue,
              'Content delivered, awaiting payment',
                  () => _showPendingPaymentDetails(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatusCard(
              'Work Pending',
              formatCurrency(data['workPendingAmount']!),
              '${data['workPendingCount']!.toInt()} deals',
              Colors.orange,
              'Content creation in progress',
            ),
            const SizedBox(width: 12),
            // Performance indicator
            _buildStatusCard(
              'Completion Rate',
              '${((data['paidCount']! + data['pendingPaymentCount']!) / (data['totalDealsCount']!) * 100).toStringAsFixed(0)}%',
              'Deals with content',
              Colors.purple,
              'Content delivery performance',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusCard(String title, String amount, String subtitle, Color color, [String? description]) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getStatusIcon(title), color: color, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[400],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClickableStatusCard(String title, String amount, String subtitle, Color color, String description, VoidCallback onTap) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_getStatusIcon(title), color: color, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[400],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Paid':
        return Icons.check_circle;
      case 'Pending Payment':
        return Icons.schedule;
      case 'Work Pending':
        return Icons.pending_actions;
      case 'Completion Rate':
        return Icons.trending_up;
      default:
        return Icons.info;
    }
  }

  // New method to show pending payment details
  void _showPendingPaymentDetails() {
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
                    Text(
                      'Pending Payments',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Content delivered, awaiting payment',
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
                      const SizedBox(height: 8),
                      Text(
                        'All deals are either paid or work is pending',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: pendingPaymentDeals.length,
                  itemBuilder: (context, index) {
                    final deal = pendingPaymentDeals[index];
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
                            Icons.schedule,
                            color: Colors.blue,
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
                            const SizedBox(height: 4),
                            Text(
                              deal.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.link, size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  'Content published',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (deal.contentPublishedDate != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Published: ${DateFormat('MMM dd, yyyy').format(deal.contentPublishedDate!)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'Expected payment: ${DateFormat('MMM dd, yyyy').format(deal.expectedPaymentDate)}',
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
                              formatCurrency(deal.payment),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 4),
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
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Due soon',
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
                        'Total Pending: ${formatCurrency(pendingPaymentDeals.fold(0.0, (sum, deal) => sum + deal.payment))}',
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

  // Updated Commission Tax Breakdown with two sections
  Widget _buildCommissionTaxBreakdown(Map<String, double> data) {
    return Row(
      children: [
        // Total Liability Section (based on all deals closed)
        Expanded(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Total Liability',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on all deals closed',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLiabilityRow('Commission (20%)', data['totalCommission']!, Colors.red),
                  const SizedBox(height: 8),
                  _buildLiabilityRow('TDS (10%)', data['totalTDS']!, Colors.orange),
                  const Divider(),
                  _buildLiabilityRow('Total Deductions', data['totalCommission']! + data['totalTDS']!, Colors.red, isTotal: true),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Paid Section (based on payments received)
        Expanded(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.paid, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Paid',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on payments received',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLiabilityRow('Commission Paid', data['paidCommission']!, Colors.green),
                  const SizedBox(height: 8),
                  _buildLiabilityRow('TDS Paid', data['paidTDS']!, Colors.teal),
                  const Divider(),
                  _buildLiabilityRow('Total Paid', data['paidCommission']! + data['paidTDS']!, Colors.green, isTotal: true),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // NEW: Calculate cash flow data based on payment received dates
Map<String, dynamic> _calculateCashFlowData(List<Deal> deals) {
  // Only consider deals where payment was actually received
  final paidDeals = deals.where((deal) => 
    deal.isPaid && deal.paymentReceivedDate != null).toList();
  
  final now = DateTime.now();
  
  // Group payments by month for trending
  final paymentsByMonth = <String, List<Deal>>{};
  for (final deal in paidDeals) {
    final monthKey = DateFormat('MMM yyyy').format(deal.paymentReceivedDate!);
    paymentsByMonth.putIfAbsent(monthKey, () => []).add(deal);
  }
  
  // Calculate cash flow metrics
  final totalCashReceived = paidDeals.fold(0.0, (sum, deal) => sum + deal.payment);
  final netCashReceived = paidDeals.fold(0.0, (sum, deal) => 
    sum + DealCalculator(dealPrice: deal.payment).netAmount);
  
  // This month's cash flow
  final thisMonthPaid = paidDeals.where((deal) =>
    deal.paymentReceivedDate!.year == now.year &&
    deal.paymentReceivedDate!.month == now.month).toList();
  
  final thisMonthCash = thisMonthPaid.fold(0.0, (sum, deal) => 
    sum + DealCalculator(dealPrice: deal.payment).netAmount);
    
  // Average monthly cash flow (last 6 months)
  final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);
  final recentPaidDeals = paidDeals.where((deal) =>
    deal.paymentReceivedDate!.isAfter(sixMonthsAgo)).toList();
  
  final avgMonthlyCash = recentPaidDeals.isNotEmpty 
    ? recentPaidDeals.fold(0.0, (sum, deal) => 
        sum + DealCalculator(dealPrice: deal.payment).netAmount) / 6
    : 0.0;
  
  // Find largest payment
  Deal? largestPayment;
  if (paidDeals.isNotEmpty) {
    largestPayment = paidDeals.reduce((current, next) => 
      current.payment > next.payment ? current : next);
  }
  
  return {
    'totalDealsCount': paidDeals.length,
    'totalCashReceived': totalCashReceived,
    'netCashReceived': netCashReceived,
    'thisMonthCash': thisMonthCash,
    'thisMonthDeals': thisMonthPaid.length,
    'avgMonthlyCash': avgMonthlyCash,
    'paymentsByMonth': paymentsByMonth,
    'largestPayment': largestPayment,
    'paidDeals': paidDeals,
  };
}

// NEW: Build cash flow section
Widget _buildCashFlowSection(Map<String, dynamic> cashFlowData) {
  final paidDeals = cashFlowData['paidDeals'] as List<Deal>;
  
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.green[600]),
              const SizedBox(width: 8),
              const Text(
                'Cash Flow (Payment Received Dates)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Cash flow summary cards
          Row(
            children: [
              _buildCashFlowCard(
                'Total Cash In',
                formatCurrency(cashFlowData['netCashReceived']),
                '${cashFlowData['totalDealsCount']} payments',
                Icons.account_balance_wallet,
                Colors.green,
              ),
              const SizedBox(width: 12),
              _buildCashFlowCard(
                'This Month',
                formatCurrency(cashFlowData['thisMonthCash']),
                '${cashFlowData['thisMonthDeals']} payments',
                Icons.calendar_month,
                Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildCashFlowCard(
                'Monthly Average',
                formatCurrency(cashFlowData['avgMonthlyCash']),
                'Last 6 months',
                Icons.bar_chart,
                Colors.purple,
              ),
              const SizedBox(width: 12),
              _buildCashFlowCard(
                'Largest Payment',
                cashFlowData['largestPayment'] != null 
                  ? formatCurrency(DealCalculator(dealPrice: (cashFlowData['largestPayment'] as Deal).payment).netAmount)
                  : '₹0',
                cashFlowData['largestPayment'] != null 
                  ? (cashFlowData['largestPayment'] as Deal).brandName
                  : 'None yet',
                Icons.star,
                Colors.orange,
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Cash flow timeline
          _buildCashFlowTimeline(cashFlowData),
          
          const SizedBox(height: 16),
          
          // Recent payments list
          if (paidDeals.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Payments',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _showAllCashFlowDetails(cashFlowData),
                  child: Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...paidDeals.take(3).map((deal) => _buildCashFlowItem(deal)).toList(),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No payments received yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mark deals as paid to track cash flow',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
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

// NEW: Build cash flow card
Widget _buildCashFlowCard(String title, String value, String subtitle, IconData icon, Color color) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
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
              Icon(icon, color: color, size: 18),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.trending_up, color: color, size: 10),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    ),
  );
}

// NEW: Build cash flow timeline
Widget _buildCashFlowTimeline(Map<String, dynamic> cashFlowData) {
  final paymentsByMonth = cashFlowData['paymentsByMonth'] as Map<String, List<Deal>>;
  
  if (paymentsByMonth.isEmpty) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        'No payment history to display',
        style: TextStyle(color: Colors.grey[600]),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  // Get last 6 months
  final sortedMonths = paymentsByMonth.keys.toList()..sort((a, b) {
    final dateA = DateFormat('MMM yyyy').parse(a);
    final dateB = DateFormat('MMM yyyy').parse(b);
    return dateB.compareTo(dateA);
  });
  
  final recentMonths = sortedMonths.take(6).toList();
  
  return Container(
    height: 120,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Cash Flow Trend',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            children: recentMonths.map((month) {
              final monthDeals = paymentsByMonth[month]!;
              final monthCash = monthDeals.fold(0.0, (sum, deal) => 
                sum + DealCalculator(dealPrice: deal.payment).netAmount);
              
              // Calculate relative height (simple approach)
              final maxCash = paymentsByMonth.values
                .map((deals) => deals.fold(0.0, (sum, deal) => 
                  sum + DealCalculator(dealPrice: deal.payment).netAmount))
                .reduce((a, b) => a > b ? a : b);
              
              final height = maxCash > 0 ? (monthCash / maxCash) * 60 : 0.0;
              
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        formatCurrencyCompact(monthCash),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: height,
                        decoration: BoxDecoration(
                          color: Colors.green[400],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(2),
                            topRight: Radius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        month.split(' ')[0], // Just month name
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
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

// NEW: Build cash flow item
Widget _buildCashFlowItem(Deal deal) {
  final calculator = DealCalculator(dealPrice: deal.payment);
  
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.green,
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
                  fontSize: 13,
                ),
              ),
              if (deal.productName.isNotEmpty)
                Text(
                  deal.productName,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatCurrency(calculator.netAmount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.green,
              ),
            ),
            Text(
              DateFormat('MMM dd').format(deal.paymentReceivedDate!),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// NEW: Show all cash flow details
void _showAllCashFlowDetails(Map<String, dynamic> cashFlowData) {
  final paidDeals = (cashFlowData['paidDeals'] as List<Deal>)
    ..sort((a, b) => b.paymentReceivedDate!.compareTo(a.paymentReceivedDate!));
    
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
                  Text(
                    'Cash Flow History',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Payments received (${paidDeals.length} total)',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: paidDeals.length,
                itemBuilder: (context, index) {
                  final deal = paidDeals[index];
                  final calculator = DealCalculator(dealPrice: deal.payment);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Icon(
                          Icons.payments,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        deal.brandName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
                                fontSize: 13,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                'Received: ${DateFormat('MMM dd, yyyy').format(deal.paymentReceivedDate!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Gross Amount:',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                    ),
                                    Text(
                                      formatCurrency(deal.payment),
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Deductions:',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                    ),
                                    Text(
                                      '- ${formatCurrency(calculator.commission + calculator.tds)}',
                                      style: const TextStyle(fontSize: 11, color: Colors.red),
                                    ),
                                  ],
                                ),
                                const Divider(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Net Received:',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      formatCurrency(calculator.netAmount),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'PAID',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                      'Total Net Cash: ${formatCurrency(cashFlowData['netCashReceived'])}',
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

// Helper method for compact currency formatting
String formatCurrencyCompact(double amount) {
  if (amount >= 100000) {
    return '₹${(amount / 100000).toStringAsFixed(1)}L';
  } else if (amount >= 1000) {
    return '₹${(amount / 1000).toStringAsFixed(1)}K';
  } else {
    return '₹${amount.toStringAsFixed(0)}';
  }
}

  Widget _buildLiabilityRow(String label, double amount, Color color, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          formatCurrency(amount),
          style: TextStyle(
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDealStatusChart(Map<String, dynamic> data) {
    final total = data['totalDeals'] as int;
    if (total == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No deals to analyze'),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Deal Status Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusIndicator(
                  'Completed',
                  data['completedDeals'] as int,
                  total,
                  Colors.green,
                ),
                _buildStatusIndicator(
                  'Active',
                  data['activeDeals'] as int,
                  total,
                  Colors.blue,
                ),
                _buildStatusIndicator(
                  'Pending',
                  data['pendingDeals'] as int,
                  total,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // New Content Status Chart
  Widget _buildContentStatusChart(Map<String, dynamic> data) {
    final total = data['totalDeals'] as int;
    if (total == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No deals to analyze'),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Content Delivery Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusIndicator(
                  'Published',
                  data['dealsWithContent'] as int,
                  total,
                  Colors.green,
                ),
                _buildStatusIndicator(
                  'In Progress',
                  data['dealsWithoutContent'] as int,
                  total,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;

    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBrandsTable(Map<String, dynamic> data) {
    final topBrands = data['topBrands'] as List<Map<String, dynamic>>;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Row(
              children: [
                Expanded(flex: 3, child: Text('Brand', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Deals', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(flex: 3, child: Text('Revenue', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              ],
            ),
            const Divider(),
            ...topBrands.take(5).map((brand) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(brand['name'] as String)),
                    Expanded(flex: 2, child: Text('${brand['deals']}', textAlign: TextAlign.center)),
                    Expanded(flex: 3, child: Text(formatCurrency(brand['revenue'] as double), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalTrackingCard(Map<String, dynamic> data) {
    const monthlyGoal = 100000.0;
    final currentEarnings = data['monthlyEarnings'] as double;
    final progress = currentEarnings / monthlyGoal;
    final remaining = monthlyGoal - currentEarnings;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly Goal Progress',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: progress >= 1.0 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress > 1.0 ? 1.0 : progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.green : Colors.orange,
              ),
              minHeight: 8,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Achieved',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      formatCurrency(currentEarnings),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      remaining > 0 ? 'Remaining' : 'Exceeded by',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      formatCurrency(remaining.abs()),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: remaining > 0 ? Colors.orange : Colors.green,
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

  Widget _buildDealFrequencyChart() {
    final thisMonthDeals = globalDeals.where((deal) =>
    deal.dealLockedDate.month == DateTime.now().month &&
        deal.dealLockedDate.year == DateTime.now().year).length;

    final lastMonthDeals = globalDeals.where((deal) {
      final lastMonth = DateTime(DateTime.now().year, DateTime.now().month - 1);
      return deal.dealLockedDate.month == lastMonth.month &&
          deal.dealLockedDate.year == lastMonth.year;
    }).length;

    final avgDealsPerMonth = _calculateAverageDealsPerMonth();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Deal Closure Pattern',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFrequencyIndicator('This Month', thisMonthDeals.toDouble(), Colors.green),
                _buildFrequencyIndicator('Last Month', lastMonthDeals.toDouble(), Colors.blue),
                _buildFrequencyIndicator('Avg/Month', avgDealsPerMonth, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyIndicator(String label, double value, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Data calculation methods - UPDATED to include Work Pending logic and Financial Year
  List<Deal> _getFilteredDeals() {
    final now = DateTime.now();

    switch (_timeRange) {
      case 'This Month':
        return globalDeals.where((deal) =>
        deal.dealLockedDate.year == now.year &&
            deal.dealLockedDate.month == now.month).toList();

      case 'Last Month':
        final lastMonth = DateTime(now.year, now.month - 1);
        return globalDeals.where((deal) =>
        deal.dealLockedDate.year == lastMonth.year &&
            deal.dealLockedDate.month == lastMonth.month).toList();

      case 'This Quarter':
        final quarterStart = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1);
        return globalDeals.where((deal) =>
        deal.dealLockedDate.isAfter(quarterStart.subtract(const Duration(days: 1))) &&
            deal.dealLockedDate.isBefore(now.add(const Duration(days: 1)))).toList();

      case 'This Year':
        return globalDeals.where((deal) =>
        deal.dealLockedDate.year == now.year).toList();

      case 'Last Year':
        return globalDeals.where((deal) =>
        deal.dealLockedDate.year == now.year - 1).toList();

      case 'FY 2024-25':
      // Financial Year: April 1st to March 31st
        final currentYear = now.year;
        final fyStart = now.month >= 4
            ? DateTime(currentYear, 4, 1)  // Current FY started in April of current year
            : DateTime(currentYear - 1, 4, 1);  // Current FY started in April of previous year
        final fyEnd = fyStart.add(const Duration(days: 365)); // March 31st next year

        return globalDeals.where((deal) =>
        deal.dealLockedDate.isAfter(fyStart.subtract(const Duration(days: 1))) &&
            deal.dealLockedDate.isBefore(fyEnd)).toList();

      case 'Custom Range':
        if (_customStartDate != null && _customEndDate != null) {
          return globalDeals.where((deal) =>
          deal.dealLockedDate.isAfter(_customStartDate!.subtract(const Duration(days: 1))) &&
              deal.dealLockedDate.isBefore(_customEndDate!.add(const Duration(days: 1)))).toList();
        }
        return globalDeals;

      default: // All Time
        return globalDeals;
    }
  }

  Map<String, double> _calculateFinancialData(List<Deal> deals) {
    final totalEarnings = deals.fold(0.0, (sum, deal) => sum + deal.payment);
    final totalCommission = deals.fold(0.0, (sum, deal) =>
    sum + DealCalculator(dealPrice: deal.payment).commission);
    final totalTDS = deals.fold(0.0, (sum, deal) =>
    sum + DealCalculator(dealPrice: deal.payment).tds);
    final netEarnings = deals.fold(0.0, (sum, deal) =>
    sum + DealCalculator(dealPrice: deal.payment).netAmount);

    // Categorize deals based on work status
    final paidDeals = deals.where((deal) => deal.isPaid).toList();

    // Pending Payment: Content is uploaded but payment not received
    final pendingPaymentDeals = deals.where((deal) =>
    !deal.isPaid &&
        deal.contentLink != null &&
        deal.contentLink!.isNotEmpty).toList();

    // Work Pending: Deal exists but content not uploaded yet
    final workPendingDeals = deals.where((deal) =>
    !deal.isPaid &&
        (deal.contentLink == null || deal.contentLink!.isEmpty)).toList();

    final paidAmount = paidDeals.fold(0.0, (sum, deal) => sum + deal.payment);
    final pendingPaymentAmount = pendingPaymentDeals.fold(0.0, (sum, deal) => sum + deal.payment);
    final workPendingAmount = workPendingDeals.fold(0.0, (sum, deal) => sum + deal.payment);

    // Calculate paid commission and TDS (based on paid deals only)
    final paidCommission = paidDeals.fold(0.0, (sum, deal) =>
    sum + DealCalculator(dealPrice: deal.payment).commission);
    final paidTDS = paidDeals.fold(0.0, (sum, deal) =>
    sum + DealCalculator(dealPrice: deal.payment).tds);

    final averageDealValue = deals.isNotEmpty ? totalEarnings / deals.length : 0.0;

    return {
      'totalEarnings': totalEarnings,
      'netEarnings': netEarnings,
      'totalCommission': totalCommission,
      'totalTDS': totalTDS,
      'paidCommission': paidCommission,
      'paidTDS': paidTDS,
      'averageDealValue': averageDealValue,
      'paidAmount': paidAmount,
      'paidCount': paidDeals.length.toDouble(),
      'pendingPaymentAmount': pendingPaymentAmount,
      'pendingPaymentCount': pendingPaymentDeals.length.toDouble(),
      'workPendingAmount': workPendingAmount,
      'workPendingCount': workPendingDeals.length.toDouble(),
      'totalDealsCount': deals.length.toDouble(),
    };
  }

  Map<String, dynamic> _calculateDealAnalytics(List<Deal> deals) {
    final totalDeals = deals.length;
    final completedDeals = deals.where((deal) => deal.status == 'Completed').length;
    final activeDeals = deals.where((deal) => deal.status == 'Active').length;
    final pendingDeals = deals.where((deal) => deal.status == 'Pending').length;

    // Content status analytics
    final dealsWithContent = deals.where((deal) =>
    deal.contentLink != null && deal.contentLink!.isNotEmpty).length;
    final dealsWithoutContent = totalDeals - dealsWithContent;

    // Group deals by brand
    final brandDeals = <String, List<Deal>>{};
    for (final deal in deals) {
      brandDeals.putIfAbsent(deal.brandName, () => []).add(deal);
    }

    final topBrands = brandDeals.entries.map((entry) {
      final brandRevenue = entry.value.fold(0.0, (sum, deal) => sum + deal.payment);
      return {
        'name': entry.key,
        'deals': entry.value.length,
        'revenue': brandRevenue,
      };
    }).toList()..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

    return {
      'totalDeals': totalDeals,
      'completedDeals': completedDeals,
      'activeDeals': activeDeals,
      'pendingDeals': pendingDeals,
      'uniqueBrands': brandDeals.length,
      'topBrands': topBrands,
      'dealsWithContent': dealsWithContent,
      'dealsWithoutContent': dealsWithoutContent,
    };
  }

  Map<String, dynamic> _calculateBusinessInsights(List<Deal> deals) {
    if (deals.isEmpty) {
      return {
        'dealsPerMonth': 0.0,
        'growthRate': 0.0,
        'repeatBrands': 0,
        'monthlyEarnings': 0.0,
      };
    }

    // Calculate deals per month
    final firstDeal = deals.reduce((a, b) =>
    a.dealLockedDate.isBefore(b.dealLockedDate) ? a : b);
    final monthsSinceFirst = DateTime.now().difference(firstDeal.dealLockedDate).inDays / 30;
    final dealsPerMonth = monthsSinceFirst > 0 ? deals.length / monthsSinceFirst : 0.0;

    // Calculate growth rate (comparing last 3 months vs previous 3 months)
    final now = DateTime.now();
    final last3Months = globalDeals.where((deal) =>
        deal.dealLockedDate.isAfter(DateTime(now.year, now.month - 3))).toList();
    final prev3Months = globalDeals.where((deal) =>
    deal.dealLockedDate.isAfter(DateTime(now.year, now.month - 6)) &&
        deal.dealLockedDate.isBefore(DateTime(now.year, now.month - 3))).toList();

    final lastEarnings = last3Months.fold(0.0, (sum, deal) => sum + deal.payment);
    final prevEarnings = prev3Months.fold(0.0, (sum, deal) => sum + deal.payment);
    final growthRate = prevEarnings > 0 ? ((lastEarnings - prevEarnings) / prevEarnings * 100) : 0.0;

    // Calculate repeat brand percentage
    final brandCounts = <String, int>{};
    for (final deal in globalDeals) {
      brandCounts[deal.brandName] = (brandCounts[deal.brandName] ?? 0) + 1;
    }
    final repeatBrands = brandCounts.values.where((count) => count > 1).length;
    final repeatPercentage = brandCounts.isNotEmpty ? (repeatBrands / brandCounts.length * 100) : 0;

    // Current month earnings
    final monthlyEarnings = globalDeals.where((deal) =>
    deal.dealLockedDate.month == now.month &&
        deal.dealLockedDate.year == now.year).fold(0.0, (sum, deal) => sum + deal.payment);

    return {
      'dealsPerMonth': dealsPerMonth,
      'growthRate': growthRate,
      'repeatBrands': repeatPercentage.round(),
      'monthlyEarnings': monthlyEarnings,
    };
  }

  double _calculateAverageDealsPerMonth() {
    if (globalDeals.isEmpty) return 0.0;

    final firstDeal = globalDeals.reduce((a, b) =>
    a.dealLockedDate.isBefore(b.dealLockedDate) ? a : b);
    final monthsSinceFirst = DateTime.now().difference(firstDeal.dealLockedDate).inDays / 30;

    return monthsSinceFirst > 0 ? globalDeals.length / monthsSinceFirst : 0.0;
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Export Reports',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Export as PDF'),
                subtitle: Text('Complete financial report for $_timeRange'),
                onTap: () {
                  Navigator.pop(context);
                  _exportAsPDF();
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: const Text('Export as CSV'),
                subtitle: const Text('Deal data for spreadsheet analysis'),
                onTap: () {
                  Navigator.pop(context);
                  _exportAsCSV();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.blue),
                title: const Text('Share Summary'),
                subtitle: const Text('Quick earnings summary'),
                onTap: () {
                  Navigator.pop(context);
                  _shareSummary();
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.purple),
                title: const Text('Tax Report'),
                subtitle: const Text('TDS and commission breakdown'),
                onTap: () {
                  Navigator.pop(context);
                  _generateTaxReport();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _exportAsPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating PDF report for $_timeRange...'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // In a real app, open the generated PDF
          },
        ),
      ),
    );
  }

  void _exportAsCSV() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Exporting deal data as CSV...'),
        action: SnackBarAction(
          label: 'Download',
          onPressed: () {
            // In a real app, download the CSV file
          },
        ),
      ),
    );
  }

  void _generateTaxReport() {
    final deals = _getFilteredDeals();
    final financialData = _calculateFinancialData(deals);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating tax report for $_timeRange...'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            _showTaxReportDialog(financialData);
          },
        ),
      ),
    );
  }

  void _showTaxReportDialog(Map<String, double> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tax Report'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Period: $_timeRange', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildTaxReportRow('Total Gross Income', data['totalEarnings']!),
              _buildTaxReportRow('Commission Paid', data['totalCommission']!),
              _buildTaxReportRow('TDS Deducted', data['totalTDS']!),
              const Divider(),
              _buildTaxReportRow('Net Income', data['netEarnings']!, isTotal: true),
              const SizedBox(height: 16),
              Text(
                'Note: This is a summary report. Please consult with a tax professional for accurate tax filing.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportAsPDF();
            },
            child: const Text('Export PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxReportRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            formatCurrency(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  void _shareSummary() {
    final deals = _getFilteredDeals();
    final financialData = _calculateFinancialData(deals);

    String periodText = _timeRange;
    if (_timeRange == 'Custom Range' && _customStartDate != null && _customEndDate != null) {
      final formatter = DateFormat('MMM dd, yyyy');
      periodText = '${formatter.format(_customStartDate!)} - ${formatter.format(_customEndDate!)}';
    }

    final summary = '''
📊 Earnings Report ($periodText)

💰 Total Earnings: ${formatCurrency(financialData['totalEarnings']!)}
💎 Net Earnings: ${formatCurrency(financialData['netEarnings']!)}
🔄 Work Pending: ${formatCurrency(financialData['workPendingAmount']!)}
⏳ Awaiting Payment: ${formatCurrency(financialData['pendingPaymentAmount']!)}
✅ Paid: ${formatCurrency(financialData['paidAmount']!)}

🤝 Deals: ${deals.length}
🏢 Brands: ${_calculateDealAnalytics(deals)['uniqueBrands']}

💸 Deductions:
• Commission: ${formatCurrency(financialData['totalCommission']!)}
• TDS: ${formatCurrency(financialData['totalTDS']!)}

Generated by DealiFy App 📱
    ''';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Summary copied to clipboard!'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Earnings Summary'),
                content: Text(summary),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}