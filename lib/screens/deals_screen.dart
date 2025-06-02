import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/deal.dart';
import '../utils/globals.dart';
import '../main.dart';
import 'package:flutter/services.dart';

class DealsScreen extends StatefulWidget {
  @override
  _DealsScreenState createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  String _sortBy = 'Date (Newest)';
  String _filterBy = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Track which year/month sections are expanded
  final Set<String> _expandedSections = <String>{};
  
  final List<String> _sortOptions = [
    'Date (Newest)',
    'Date (Oldest)', 
    'Amount (High to Low)',
    'Amount (Low to High)',
    'Brand (A-Z)',
    'Status'
  ];
  
  final List<String> _filterOptions = [
    'All',
    'Active',
    'Pending', 
    'Completed',
    'Paid',
    'Unpaid',
    'Overdue Payments'
  ];

  @override
  void initState() {
    super.initState();
    // Expand current year and month by default
    final now = DateTime.now();
    final currentYear = now.year.toString();
    final currentMonth = DateFormat('MMMM yyyy').format(now);
    _expandedSections.add(currentYear);
    _expandedSections.add(currentMonth);
    
    // Debug print to check the format
    print('Current month format: $currentMonth');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final organizedDeals = _getOrganizedDeals();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Brand Deals'),
        actions: [
          IconButton(
            icon: Icon(Icons.calculate),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DealCalculatorScreen()),
              );
            },
            tooltip: 'Deal Calculator',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.sort),
            onSelected: (String value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return _sortOptions.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Row(
                    children: [
                      Icon(
                        _sortBy == choice ? Icons.check : _getSortIcon(choice),
                        size: 20,
                        color: _sortBy == choice ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(choice)),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (String value) {
              setState(() {
                _filterBy = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return _filterOptions.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Row(
                    children: [
                      Icon(
                        _filterBy == choice ? Icons.check : _getFilterIcon(choice),
                        size: 20,
                        color: _filterBy == choice ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(choice)),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          if (globalDeals.isEmpty)
            Expanded(child: _buildEmptyState())
          else if (organizedDeals.isEmpty)
            Expanded(child: _buildNoResultsState())
          else
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16.0),
                itemCount: organizedDeals.length,
                itemBuilder: (context, index) {
                  final section = organizedDeals[index];
                  return _buildSection(section);
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddDealDialog();
        },
        child: Icon(Icons.add),
        tooltip: 'Add New Deal',
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final filteredCount = _getFilteredAndSearchedDeals().length;
    
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search deals, brands, products...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          SizedBox(height: 12),
          
          // Filter chips and stats
          Row(
            children: [
              Icon(Icons.filter_list, size: 16, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text(
                'Sort: $_sortBy',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_filterBy != 'All') ...[
                SizedBox(width: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_alt, size: 12, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        _filterBy,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Spacer(),
              Text(
                '$filteredCount deal${filteredCount != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(DealSection section) {
    final isExpanded = _expandedSections.contains(section.key);
    
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Section Header
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedSections.remove(section.key);
                } else {
                  _expandedSections.add(section.key);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: section.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      section.icon,
                      color: section.color,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: section.color,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${section.deals.length} deal${section.deals.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              '${_formatCurrency(section.totalAmount)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.green[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: section.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: section.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Section Content
          if (isExpanded) ...[
            Divider(height: 1, color: Colors.grey[300]),
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                children: section.deals.map((deal) => _buildDealCard(deal)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Replace the existing _buildDealCard method in deals_screen.dart

Widget _buildDealCard(Deal deal) {
  final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
  final dateFormat = DateFormat('MMM dd, yyyy');
  final calculator = DealCalculator(dealPrice: deal.payment);
  
  return Card(
    margin: EdgeInsets.only(bottom: 8.0),
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    child: InkWell(
      onTap: () {
        _showDealDetails(deal);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.all(12.0),
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
                        deal.brandName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (deal.productName.isNotEmpty) ...[
                        SizedBox(height: 2),
                        Text(
                          deal.productName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatusChip(deal.status),
              ],
            ),
            SizedBox(height: 8),
            Text(
              deal.description,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            
            // Compact money info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deal: ${currencyFormat.format(deal.payment)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      Text(
                        'Net: ${currencyFormat.format(calculator.netAmount)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
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
                        'Due: ${dateFormat.format(deal.deliverablesDueDate)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: _getDueDateColor(deal.deliverablesDueDate),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            _getPaymentStatusIcon(deal.paymentStatus),
                            color: deal.paymentStatusColor,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              deal.paymentStatus,
                              style: TextStyle(
                                fontSize: 11,
                                color: deal.paymentStatusColor,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey[400],
                ),
              ],
            ),
            
            // Action buttons section
            SizedBox(height: 8),
            _buildActionButtons(deal),
          ],
        ),
      ),
    ),
  );
}

// New method to build action buttons based on deal status
Widget _buildActionButtons(Deal deal) {
  // If deal is completed and paid, show completion status
  if (deal.status == 'Completed' && deal.isPaid) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Completed & Paid',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          if (deal.contentPublishedDate != null)
            Text(
              DateFormat('MMM dd').format(deal.contentPublishedDate!),
              style: TextStyle(
                color: Colors.green.shade600,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
  
  // If deal is completed but not paid, show payment pending
  if (deal.status == 'Completed' && !deal.isPaid) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: Colors.blue, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Awaiting Payment',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                      if (deal.contentPublishedDate != null)
                        Text(
                          'Done: ${DateFormat('MMM dd').format(deal.contentPublishedDate!)}',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 8),
        SizedBox(
          width: 100,
          height: 36,
          child: ElevatedButton.icon(
            icon: Icon(Icons.payment, size: 14),
            label: Text('Paid', style: TextStyle(fontSize: 11)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () {
              _markPaymentReceived(deal);
            },
          ),
        ),
      ],
    );
  }
  
  // If deal is not completed, show work completion button
  // and conditionally show payment button if content is done
  if (deal.status != 'Completed') {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 32,
            child: ElevatedButton.icon(
              icon: Icon(Icons.check_circle, size: 16),
              label: Text('Mark Done', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                _markDealAsComplete(deal);
              },
            ),
          ),
        ),
        // Show payment button if content link exists (work done but not marked complete)
        if (deal.contentLink != null && deal.contentLink!.isNotEmpty && !deal.isPaid) ...[
          SizedBox(width: 8),
          SizedBox(
            width: 90,
            height: 32,
            child: ElevatedButton.icon(
              icon: Icon(Icons.payment, size: 14),
              label: Text('Paid', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                _markPaymentReceived(deal);
              },
            ),
          ),
        ],
      ],
    );
  }
  
  // Fallback - should not reach here
  return SizedBox.shrink();
}

// Updated _markPaymentReceived method in deals_screen.dart
void _markPaymentReceived(Deal deal) {
  DateTime selectedPaymentDate = DateTime.now();  // Default to today
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Mark Payment as Received'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Brand: ${deal.brandName}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (deal.productName.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    'Product: ${deal.productName}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
                SizedBox(height: 16),
                
                // Payment Date Selector
                Text(
                  'When did you receive the payment?',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedPaymentDate,
                      firstDate: deal.dealLockedDate,
                      lastDate: DateTime.now(),
                      helpText: 'Select Payment Received Date',
                    );
                    if (picked != null) {
                      setState(() {
                        selectedPaymentDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            DateFormat('MMM dd, yyyy').format(selectedPaymentDate),
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Details:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Deal Amount:'),
                          Text(
                            NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(deal.payment),
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Expected Net Amount:'),
                          Text(
                            NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(
                              DealCalculator(dealPrice: deal.payment).netAmount
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'This will record the payment in your cash flow analytics.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final index = globalDeals.indexWhere((d) => d.id == deal.id);
                  if (index != -1) {
                    globalDeals[index] = Deal(
                      id: deal.id,
                      brandName: deal.brandName,
                      productName: deal.productName,
                      description: deal.description,
                      payment: deal.payment,
                      isPaid: true, // Mark as paid
                      dealLockedDate: deal.dealLockedDate,
                      deliverablesDueDate: deal.deliverablesDueDate,
                      paymentTimelineDays: deal.paymentTimelineDays,
                      status: deal.status,
                      contentLink: deal.contentLink,
                      contentPublishedDate: deal.contentPublishedDate,
                      paymentReceivedDate: selectedPaymentDate,  // NEW: Set payment received date
                      contentMetrics: deal.contentMetrics,
                    );
                  }
                  
                  await DealDataManager.saveDeals();
                  
                  Navigator.pop(context);
                  setState(() {});
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment marked as received on ${DateFormat('MMM dd, yyyy').format(selectedPaymentDate)}!'),
                      backgroundColor: Colors.green,
                      action: SnackBarAction(
                        label: 'View Deal',
                        textColor: Colors.white,
                        onPressed: () {
                          _showDealDetails(globalDeals.firstWhere((d) => d.id == deal.id));
                        },
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Text('MARK AS PAID'),
              ),
            ],
          );
        },
      );
    },
  );
}


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.handshake, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No deals yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text('Tap the + button to add your first deal!'),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No deals found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text('Try adjusting your search or filters'),
          SizedBox(height: 16),
          ElevatedButton.icon(
            icon: Icon(Icons.clear),
            label: Text('Clear Filters'),
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
                _filterBy = 'All';
                _sortBy = 'Date (Newest)';
              });
            },
          ),
        ],
      ),
    );
  }

  // Helper methods for organizing deals
  List<DealSection> _getOrganizedDeals() {
    final deals = _getFilteredAndSearchedDeals();
    final sections = <DealSection>[];
    
    if (deals.isEmpty) return sections;
    
    try {
      // Group deals by year first
      final dealsByYear = <int, List<Deal>>{};
      for (final deal in deals) {
        final year = deal.dealLockedDate.year;
        dealsByYear.putIfAbsent(year, () => []).add(deal);
      }
      
      // Sort years in descending order
      final sortedYears = dealsByYear.keys.toList()..sort((a, b) => b.compareTo(a));
      
      for (final year in sortedYears) {
        final yearDeals = dealsByYear[year]!;
        
        // Group year deals by month
        final dealsByMonth = <String, List<Deal>>{};
        for (final deal in yearDeals) {
          try {
            final monthKey = DateFormat('MMMM yyyy').format(deal.dealLockedDate);
            dealsByMonth.putIfAbsent(monthKey, () => []).add(deal);
          } catch (e) {
            print('Error formatting date: ${deal.dealLockedDate}, error: $e');
            // Fallback to a simple format
            final monthKey = '${_getMonthName(deal.dealLockedDate.month)} ${deal.dealLockedDate.year}';
            dealsByMonth.putIfAbsent(monthKey, () => []).add(deal);
          }
        }
        
        // Sort months in descending order
        final sortedMonths = dealsByMonth.keys.toList()..sort((a, b) {
          try {
            final dateA = DateFormat('MMMM yyyy').parse(a);
            final dateB = DateFormat('MMMM yyyy').parse(b);
            return dateB.compareTo(dateA);
          } catch (e) {
            // Fallback to string comparison if date parsing fails
            return b.compareTo(a);
          }
        });
        
        // Add year section
        final yearTotalAmount = yearDeals.fold(0.0, (sum, deal) => sum + deal.payment);
        sections.add(DealSection(
          key: year.toString(),
          title: year.toString(),
          deals: yearDeals,
          totalAmount: yearTotalAmount,
          icon: Icons.calendar_today,
          color: Colors.blue[800]!,
          isYear: true,
        ));
        
        // Add month sections
        for (final monthKey in sortedMonths) {
          final monthDeals = dealsByMonth[monthKey]!;
          _applySorting(monthDeals);
          
          final monthTotalAmount = monthDeals.fold(0.0, (sum, deal) => sum + deal.payment);
          sections.add(DealSection(
            key: monthKey,
            title: monthKey,
            deals: monthDeals,
            totalAmount: monthTotalAmount,
            icon: Icons.calendar_view_month,
            color: _getMonthColor(monthKey),
            isYear: false,
          ));
        }
      }
      
      return sections;
    } catch (e) {
      print('Error organizing deals: $e');
      // Fallback: return a simple flat list
      return [
        DealSection(
          key: 'all',
          title: 'All Deals',
          deals: deals,
          totalAmount: deals.fold(0.0, (sum, deal) => sum + deal.payment),
          icon: Icons.list,
          color: Colors.blue[600]!,
          isYear: false,
        )
      ];
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  List<Deal> _getFilteredAndSearchedDeals() {
    List<Deal> deals = List.from(globalDeals);
    
    // Apply filters
    switch (_filterBy) {
      case 'Active':
        deals = deals.where((deal) => deal.status == 'Active').toList();
        break;
      case 'Pending':
        deals = deals.where((deal) => deal.status == 'Pending').toList();
        break;
      case 'Completed':
        deals = deals.where((deal) => deal.status == 'Completed').toList();
        break;
      case 'Paid':
        deals = deals.where((deal) => deal.isPaid).toList();
        break;
      case 'Unpaid':
        deals = deals.where((deal) => !deal.isPaid).toList();
        break;
      case 'Overdue Payments':
        deals = deals.where((deal) => deal.isPaymentOverdue).toList();
        break;
    }
    
    // Apply search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      deals = deals.where((deal) {
        return deal.brandName.toLowerCase().contains(query) ||
               deal.productName.toLowerCase().contains(query) ||
               deal.description.toLowerCase().contains(query);
      }).toList();
    }
    
    return deals;
  }

  void _applySorting(List<Deal> deals) {
    switch (_sortBy) {
      case 'Date (Newest)':
        deals.sort((a, b) => b.dealLockedDate.compareTo(a.dealLockedDate));
        break;
      case 'Date (Oldest)':
        deals.sort((a, b) => a.dealLockedDate.compareTo(b.dealLockedDate));
        break;
      case 'Amount (High to Low)':
        deals.sort((a, b) => b.payment.compareTo(a.payment));
        break;
      case 'Amount (Low to High)':
        deals.sort((a, b) => a.payment.compareTo(b.payment));
        break;
      case 'Brand (A-Z)':
        deals.sort((a, b) => a.brandName.compareTo(b.brandName));
        break;
      case 'Status':
        deals.sort((a, b) => a.status.compareTo(b.status));
        break;
    }
  }

  Color _getMonthColor(String monthKey) {
    // Extract month from "MMMM yyyy" format (e.g., "January 2025")
    try {
      final date = DateFormat('MMMM yyyy').parse(monthKey);
      final month = date.month;
      final colors = [
        Colors.blue[600]!,    // Jan
        Colors.purple[600]!,  // Feb
        Colors.green[600]!,   // Mar
        Colors.orange[600]!,  // Apr
        Colors.pink[600]!,    // May
        Colors.teal[600]!,    // Jun
        Colors.indigo[600]!,  // Jul
        Colors.red[600]!,     // Aug
        Colors.amber[600]!,   // Sep
        Colors.cyan[600]!,    // Oct
        Colors.lime[600]!,    // Nov
        Colors.brown[600]!,   // Dec
      ];
      return colors[(month - 1) % colors.length];
    } catch (e) {
      // Fallback to blue if parsing fails
      return Colors.blue[600]!;
    }
  }

  IconData _getSortIcon(String sort) {
    switch (sort) {
      case 'Date (Newest)':
      case 'Date (Oldest)':
        return Icons.access_time;
      case 'Amount (High to Low)':
      case 'Amount (Low to High)':
        return Icons.currency_rupee;
      case 'Brand (A-Z)':
        return Icons.business;
      case 'Status':
        return Icons.info;
      default:
        return Icons.sort;
    }
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'Active':
        return Icons.play_circle;
      case 'Pending':
        return Icons.pending;
      case 'Completed':
        return Icons.check_circle;
      case 'Paid':
        return Icons.payments;
      case 'Unpaid':
        return Icons.payment;
      case 'Overdue Payments':
        return Icons.warning;
      default:
        return Icons.filter_list;
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }

  // All the existing methods remain the same...
  IconData _getPaymentStatusIcon(String status) {
    switch (status) {
      case 'Paid':
        return Icons.check_circle;
      case 'Overdue':
        return Icons.warning;
      case 'Due Soon':
        return Icons.schedule;
      default:
        return Icons.pending;
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Active':
        color = Colors.blue;
        break;
      case 'Pending':
        color = Colors.orange;
        break;
      case 'Completed':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
        ),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Color _getDueDateColor(DateTime dueDate) {
    if (dueDate.isBefore(DateTime.now())) {
      return Colors.red;
    } else if (dueDate.difference(DateTime.now()).inDays < 7) {
      return Colors.orange;
    } else {
      return Colors.black;
    }
  }

  // Rest of the existing methods (_markDealAsComplete, _showDealDetails, etc.) remain unchanged...
  // [Include all the existing methods from the original deals_screen.dart]
  
  void _markDealAsComplete(Deal deal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime selectedDate = DateTime.now();
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Mark Deal as Complete'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Brand: ${deal.brandName}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (deal.productName.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      'Product: ${deal.productName}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                  SizedBox(height: 16),
                  Text('When did you complete this project?'),
                  SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: deal.dealLockedDate,
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Completion Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(selectedDate),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final index = globalDeals.indexWhere((d) => d.id == deal.id);
                    if (index != -1) {
                      globalDeals[index] = Deal(
                        id: deal.id,
                        brandName: deal.brandName,
                        productName: deal.productName,
                        description: deal.description,
                        payment: deal.payment,
                        isPaid: deal.isPaid,
                        dealLockedDate: deal.dealLockedDate,
                        deliverablesDueDate: deal.deliverablesDueDate,
                        paymentTimelineDays: deal.paymentTimelineDays,
                        status: 'Completed',
                        contentLink: 'completed',
                        contentPublishedDate: selectedDate,
                        contentMetrics: null,
                      );
                    }
                    
                    await DealDataManager.saveDeals();
                    
                    Navigator.pop(context);
                    setState(() {});
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Deal marked as complete!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text('MARK COMPLETE'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      setState(() {});
    });
  }

  void _showAddDealDialog() {
  final _formKey = GlobalKey<FormState>();
  String _brandName = '';
  String _productName = '';
  String _description = '';
  double _payment = 0.0;
  DateTime _dealLockedDate = DateTime.now();
  DateTime _deliverablesDueDate = DateTime.now().add(Duration(days: 30));
  int _paymentTimelineDays = 45;
  // Remove _isPaid variable - all new deals start as unpaid

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Add New Deal'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Brand Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the brand name';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _brandName = value ?? '';
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                        helperText: 'Optional: Name of the product being promoted',
                      ),
                      onSaved: (value) {
                        _productName = value ?? '';
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Description/Deliverables *',
                        border: OutlineInputBorder(),
                        helperText: 'Describe the work to be done',
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please describe the deliverables';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _description = value ?? '';
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Payment Amount *',
                        prefixText: '₹',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.currency_rupee),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the payment amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _payment = double.tryParse(value ?? '0') ?? 0.0;
                      },
                      onChanged: (value) {
                        setState(() {
                          _payment = double.tryParse(value) ?? 0.0;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Payment Timeline (Days) *',
                        border: OutlineInputBorder(),
                        suffixText: 'days',
                        suffixIcon: Icon(Icons.schedule),
                        helperText: 'e.g., 30, 45, 60 days from content delivery',
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: _paymentTimelineDays.toString(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter payment timeline';
                        }
                        final days = int.tryParse(value);
                        if (days == null || days < 1 || days > 365) {
                          return 'Please enter a valid number between 1-365 days';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _paymentTimelineDays = int.tryParse(value ?? '45') ?? 45;
                      },
                      onChanged: (value) {
                        setState(() {
                          _paymentTimelineDays = int.tryParse(value) ?? 45;
                        });
                      },
                    ),
                    if (_payment > 0) ...[
                      SizedBox(height: 16),
                      DealMoneyBreakdownWidget(
                        dealPrice: _payment,
                        showTitle: false,
                      ),
                    ],
                    SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _dealLockedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            _dealLockedDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Deal Locked Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                          helperText: 'When the deal was agreed upon',
                        ),
                        child: Text(
                          DateFormat('MMM dd, yyyy').format(_dealLockedDate),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _deliverablesDueDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(Duration(days: 730)),
                        );
                        if (picked != null) {
                          setState(() {
                            _deliverablesDueDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Deliverables Due Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                          helperText: 'When content delivery is/was due',
                        ),
                        child: Text(
                          DateFormat('MMM dd, yyyy').format(_deliverablesDueDate),
                        ),
                      ),
                    ),
                    // Remove the Payment Received checkbox entirely
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You can mark payment as received later from the deal card.',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    
                    final newDeal = Deal(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      brandName: _brandName,
                      productName: _productName,
                      description: _description,
                      payment: _payment,
                      isPaid: false, // Always start as unpaid
                      dealLockedDate: _dealLockedDate,
                      deliverablesDueDate: _deliverablesDueDate,
                      paymentTimelineDays: _paymentTimelineDays,
                      status: 'Active',
                    );
                    
                    setState(() {
                      globalDeals.insert(0, newDeal);
                    });
                    
                    await DealDataManager.saveDeals();
                    
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Deal added successfully!')),
                    );
                  }
                },
                child: Text('ADD DEAL'),
              ),
            ],
          );
        },
      );
    },
  ).then((_) {
    setState(() {});
  });
}

  void _showDealDetails(Deal deal) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24.0),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deal.brandName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (deal.productName.isNotEmpty) ...[
                            SizedBox(height: 4),
                            Text(
                              deal.productName,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Deliverables:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  deal.description,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 24),
                
                DealMoneyBreakdownWidget(
                  dealPrice: deal.payment,
                ),
                
                SizedBox(height: 24),
                
                if (deal.status == 'Completed' && deal.contentPublishedDate != null)
                  _buildCompletionStatusSection(deal, dateFormat)
                else
                  _buildPendingWorkSection(deal),
                
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Deal Locked Date',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(dateFormat.format(deal.dealLockedDate)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Deliverables Due Date',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            dateFormat.format(deal.deliverablesDueDate),
                            style: TextStyle(
                              color: _getDueDateColor(deal.deliverablesDueDate),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Status',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            deal.paymentStatus,
                            style: TextStyle(
                              color: deal.paymentStatusColor,
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
                            'Status',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(deal.status),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      icon: Icon(Icons.edit),
                      label: Text('Edit'),
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditDealDialog(deal);
                      },
                    ),
                    if (deal.status != 'Completed')
                      ElevatedButton.icon(
                        icon: Icon(Icons.check_circle, color: Colors.white),
                        label: Text('Mark Done'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _markDealAsComplete(deal);
                        },
                      ),
                    OutlinedButton.icon(
                      icon: Icon(Icons.delete, color: Colors.red),
                      label: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showDeleteConfirmation(deal);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletionStatusSection(Deal deal, DateFormat dateFormat) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Project Completed',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Completed on: ${dateFormat.format(deal.contentPublishedDate!)}',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingWorkSection(Deal deal) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pending_actions, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Work in Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Mark as complete when you finish the deliverables.',
            style: TextStyle(
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.check_circle),
              label: Text('Mark as Done'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _markDealAsComplete(deal);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Updated _showEditDealDialog method in deals_screen.dart
void _showEditDealDialog(Deal deal) {
  final _formKey = GlobalKey<FormState>();
  String _brandName = deal.brandName;
  String _productName = deal.productName;
  String _description = deal.description;
  double _payment = deal.payment;
  DateTime _dealLockedDate = deal.dealLockedDate;
  DateTime _deliverablesDueDate = deal.deliverablesDueDate;
  int _paymentTimelineDays = deal.paymentTimelineDays;
  bool _isPaid = deal.isPaid;
  String _status = deal.status;
  String? _contentLink = deal.contentLink;
  DateTime? _contentPublishedDate = deal.contentPublishedDate;
  DateTime? _paymentReceivedDate = deal.paymentReceivedDate;  // NEW

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Edit Deal'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: _brandName,
                      decoration: InputDecoration(
                        labelText: 'Brand Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the brand name';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _brandName = value ?? '';
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      initialValue: _productName,
                      decoration: InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                        helperText: 'Optional: Name of the product being promoted',
                      ),
                      onSaved: (value) {
                        _productName = value ?? '';
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      initialValue: _description,
                      decoration: InputDecoration(
                        labelText: 'Description/Deliverables *',
                        border: OutlineInputBorder(),
                        helperText: 'Describe the work to be done',
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please describe the deliverables';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _description = value ?? '';
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      initialValue: _payment.toString(),
                      decoration: InputDecoration(
                        labelText: 'Payment Amount *',
                        prefixText: '₹',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.currency_rupee),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the payment amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _payment = double.tryParse(value ?? '0') ?? 0.0;
                      },
                      onChanged: (value) {
                        setState(() {
                          _payment = double.tryParse(value) ?? deal.payment;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      initialValue: _paymentTimelineDays.toString(),
                      decoration: InputDecoration(
                        labelText: 'Payment Timeline (Days) *',
                        border: OutlineInputBorder(),
                        suffixText: 'days',
                        suffixIcon: Icon(Icons.schedule),
                        helperText: 'e.g., 30, 45, 60 days from content delivery',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter payment timeline';
                        }
                        final days = int.tryParse(value);
                        if (days == null || days < 1 || days > 365) {
                          return 'Please enter a valid number between 1-365 days';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _paymentTimelineDays = int.tryParse(value ?? '45') ?? 45;
                      },
                      onChanged: (value) {
                        setState(() {
                          _paymentTimelineDays = int.tryParse(value) ?? deal.paymentTimelineDays;
                        });
                      },
                    ),
                    if (_payment > 0) ...[
                      SizedBox(height: 16),
                      DealMoneyBreakdownWidget(
                        dealPrice: _payment,
                        showTitle: false,
                      ),
                    ],
                    SizedBox(height: 16),
                    
                    // Status Dropdown
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: InputDecoration(
                        labelText: 'Deal Status',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info),
                      ),
                      items: ['Active', 'Pending', 'Completed'].map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _status = newValue ?? 'Active';
                          // If changing to completed, set current date as published date
                          if (_status == 'Completed' && _contentPublishedDate == null) {
                            _contentPublishedDate = DateTime.now();
                            _contentLink = 'completed';
                          }
                          // If changing from completed, clear published date and link
                          if (_status != 'Completed') {
                            _contentPublishedDate = null;
                            _contentLink = null;
                          }
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Content completion date (only show if status is Completed)
                    if (_status == 'Completed') ...[
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _contentPublishedDate ?? DateTime.now(),
                            firstDate: _dealLockedDate,
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _contentPublishedDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Content Published Date',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                            helperText: 'When the content was published/delivered',
                          ),
                          child: Text(
                            _contentPublishedDate != null 
                              ? DateFormat('MMM dd, yyyy').format(_contentPublishedDate!)
                              : 'Select date',
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        initialValue: _contentLink == 'completed' ? '' : (_contentLink ?? ''),
                        decoration: InputDecoration(
                          labelText: 'Content Link (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                          helperText: 'Link to published content (optional)',
                        ),
                        onSaved: (value) {
                          _contentLink = value?.isNotEmpty == true ? value : 'completed';
                        },
                      ),
                      SizedBox(height: 16),
                    ],
                    
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _dealLockedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            _dealLockedDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Deal Locked Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                          helperText: 'When the deal was agreed upon',
                        ),
                        child: Text(
                          DateFormat('MMM dd, yyyy').format(_dealLockedDate),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _deliverablesDueDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(Duration(days: 730)),
                        );
                        if (picked != null) {
                          setState(() {
                            _deliverablesDueDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Deliverables Due Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                          helperText: 'When content delivery is/was due',
                        ),
                        child: Text(
                          DateFormat('MMM dd, yyyy').format(_deliverablesDueDate),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Payment Status Section
                    CheckboxListTile(
                      title: Text('Payment Received'),
                      value: _isPaid,
                      onChanged: (value) {
                        setState(() {
                          _isPaid = value ?? false;
                          // If marking as paid and no payment date set, set to today
                          if (_isPaid && _paymentReceivedDate == null) {
                            _paymentReceivedDate = DateTime.now();
                          }
                          // If unmarking as paid, clear payment date
                          if (!_isPaid) {
                            _paymentReceivedDate = null;
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    
                    // Payment Received Date (only show if payment is marked as received)
                    if (_isPaid) ...[
                      SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _paymentReceivedDate ?? DateTime.now(),
                            firstDate: _dealLockedDate,
                            lastDate: DateTime.now(),
                            helpText: 'Select Payment Received Date',
                          );
                          if (picked != null) {
                            setState(() {
                              _paymentReceivedDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            border: Border.all(color: Colors.green.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.payment, color: Colors.green[700], size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Payment Received Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                    Text(
                                      _paymentReceivedDate != null 
                                        ? DateFormat('MMM dd, yyyy').format(_paymentReceivedDate!)
                                        : 'Tap to select date',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.calendar_today, color: Colors.green[600], size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    
                    // Find the deal index and update it
                    final index = globalDeals.indexWhere((d) => d.id == deal.id);
                    if (index != -1) {
                      globalDeals[index] = Deal(
                        id: deal.id, // Keep the same ID
                        brandName: _brandName,
                        productName: _productName,
                        description: _description,
                        payment: _payment,
                        isPaid: _isPaid,
                        dealLockedDate: _dealLockedDate,
                        deliverablesDueDate: _deliverablesDueDate,
                        paymentTimelineDays: _paymentTimelineDays,
                        status: _status,
                        contentLink: _contentLink,
                        contentPublishedDate: _contentPublishedDate,
                        paymentReceivedDate: _paymentReceivedDate,  // NEW
                        contentMetrics: deal.contentMetrics, // Keep existing metrics
                      );
                    }
                    
                    // Save to persistent storage
                    await DealDataManager.saveDeals();
                    
                    Navigator.pop(context);
                    
                    // Refresh the UI
                    setState(() {});
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Deal updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: Text('UPDATE DEAL'),
              ),
            ],
          );
        },
      );
    },
  ).then((_) {
    // Refresh the screen when dialog is closed
    setState(() {});
  });
}

  void _showDeleteConfirmation(Deal deal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Deal'),
          content: Text('Are you sure you want to delete the deal with ${deal.brandName}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                setState(() {
                  globalDeals.removeWhere((d) => d.id == deal.id);
                });
                
                await DealDataManager.saveDeals();
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deal deleted successfully')),
                );
              },
              child: Text('DELETE'),
            ),
          ],
        );
      },
    );
  }
}

// Data class for organizing deals into sections
class DealSection {
  final String key;
  final String title;
  final List<Deal> deals;
  final double totalAmount;
  final IconData icon;
  final Color color;
  final bool isYear;

  DealSection({
    required this.key,
    required this.title,
    required this.deals,
    required this.totalAmount,
    required this.icon,
    required this.color,
    required this.isYear,
  });
}