import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/deal.dart';
import '../utils/globals.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  _PortfolioScreenState createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final dateFormat = DateFormat('MMM dd, yyyy');
  String _selectedFilter = 'All';
  
  final List<String> _filterOptions = [
    'All',
    'This Year',
    'Last 6 Months',
    'Last 3 Months',
    'This Month',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get only completed deals
    final completedDeals = globalDeals.where((deal) => 
      deal.status == 'Completed' && deal.contentPublishedDate != null).toList();
    
    // Filter by time period
    final filteredDeals = _getFilteredDeals(completedDeals);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Projects'),
            Tab(text: 'Brands'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (String value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return _filterOptions.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Row(
                    children: [
                      Icon(
                        _selectedFilter == choice ? Icons.check : Icons.calendar_today,
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
            icon: const Icon(Icons.analytics),
            onPressed: () {
              _showPortfolioAnalytics(filteredDeals);
            },
            tooltip: 'Portfolio Analytics',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProjectsTab(filteredDeals),
          _buildBrandsTab(filteredDeals),
        ],
      ),
    );
  }

  Widget _buildProjectsTab(List<Deal> deals) {
    return Column(
      children: [
        _buildFilterHeader(deals, 'Projects'),
        _buildStatsRow(deals),
        if (deals.isEmpty)
          Expanded(child: _buildEmptyState())
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: deals.length,
              itemBuilder: (context, index) {
                return _buildPortfolioCard(deals[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBrandsTab(List<Deal> deals) {
    // Group deals by brand
    final brandDeals = <String, List<Deal>>{};
    for (final deal in deals) {
      brandDeals.putIfAbsent(deal.brandName, () => []).add(deal);
    }

    // Sort brands by total project count (descending)
    final sortedBrands = brandDeals.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return Column(
      children: [
        _buildFilterHeader(deals, 'Brands'),
        _buildBrandsStatsRow(sortedBrands),
        if (sortedBrands.isEmpty)
          Expanded(child: _buildEmptyBrandsState())
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: sortedBrands.length,
              itemBuilder: (context, index) {
                final brandEntry = sortedBrands[index];
                return _buildBrandCard(brandEntry.key, brandEntry.value);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFilterHeader(List<Deal> deals, String tabName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Icon(
            tabName == 'Projects' ? Icons.work : Icons.business,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Completed $tabName - $_selectedFilter',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          Text(
            tabName == 'Projects' 
              ? '${deals.length} projects'
              : '${_getUniqueBrandsCount(deals)} brands',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(List<Deal> deals) {
    int totalProjects = deals.length;
    double totalEarnings = deals.fold(0, (sum, deal) => sum + deal.payment);
    int uniqueBrands = deals.map((deal) => deal.brandName).toSet().length;
    
    DateTime? lastCompleted = deals.isNotEmpty 
        ? deals.reduce((latest, deal) => 
            deal.contentPublishedDate!.isAfter(latest.contentPublishedDate!) 
              ? deal : latest).contentPublishedDate
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildStatItem('Projects', totalProjects.toString(), Icons.work),
          _buildStatItem('Brands', uniqueBrands.toString(), Icons.business),
          _buildStatItem('Earnings', _formatCurrency(totalEarnings), Icons.currency_rupee),
          if (lastCompleted != null)
            _buildStatItem('Last Work', _getDaysAgo(lastCompleted), Icons.schedule),
        ],
      ),
    );
  }

  Widget _buildBrandsStatsRow(List<MapEntry<String, List<Deal>>> brandEntries) {
    int totalBrands = brandEntries.length;
    int totalProjects = brandEntries.fold(0, (sum, entry) => sum + entry.value.length);
    double totalEarnings = brandEntries.fold(0, (sum, entry) => 
      sum + entry.value.fold(0.0, (brandSum, deal) => brandSum + deal.payment));
    
    // Find brand with most projects
    String topBrand = brandEntries.isNotEmpty 
        ? brandEntries.first.key 
        : 'None';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildStatItem('Brands', totalBrands.toString(), Icons.business),
          _buildStatItem('Projects', totalProjects.toString(), Icons.work),
          _buildStatItem('Earnings', _formatCurrency(totalEarnings), Icons.currency_rupee),
          _buildStatItem('Top Brand', topBrand, Icons.star, isTopBrand: true),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {bool isTopBrand = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isTopBrand ? Colors.amber.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: isTopBrand ? Border.all(color: Colors.amber.shade200) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon, 
              size: 20, 
              color: isTopBrand ? Colors.amber.shade700 : Colors.blue,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isTopBrand ? Colors.amber.shade800 : null,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isTopBrand ? Colors.amber.shade700 : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandCard(String brandName, List<Deal> brandDeals) {
    final totalProjects = brandDeals.length;
    final totalEarnings = brandDeals.fold(0.0, (sum, deal) => sum + deal.payment);
    final latestProject = brandDeals.reduce((latest, deal) => 
      deal.contentPublishedDate!.isAfter(latest.contentPublishedDate!) ? deal : latest);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showBrandDetails(brandName, brandDeals);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getBrandColor(brandName).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: _getBrandColor(brandName).withOpacity(0.3)),
                    ),
                    child: Icon(
                      Icons.business,
                      color: _getBrandColor(brandName),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          brandName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalProjects project${totalProjects > 1 ? 's' : ''} completed',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Earnings',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _formatCurrency(totalEarnings),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
                            'Latest Project',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            dateFormat.format(latestProject.contentPublishedDate!),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
            Icons.work_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'All'
                ? 'No completed projects yet'
                : 'No projects completed in $_selectedFilter',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete your deals to see them in your portfolio',
            style: TextStyle(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to deals screen
              DefaultTabController.of(context)?.animateTo(1); // Deals tab
            },
            child: const Text('Go to Deals'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBrandsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'All'
                ? 'No brand partnerships yet'
                : 'No brand work completed in $_selectedFilter',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete deals with brands to see them here',
            style: TextStyle(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to deals screen
              DefaultTabController.of(context)?.animateTo(1); // Deals tab
            },
            child: const Text('Go to Deals'),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard(Deal deal) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showProjectDetails(deal);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'COMPLETED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Deliverables:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                deal.description,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Project Value',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          currencyFormat.format(deal.payment),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                          'Completed On',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          dateFormat.format(deal.contentPublishedDate!),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBrandDetails(String brandName, List<Deal> brandDeals) {
    final totalProjects = brandDeals.length;
    final totalEarnings = brandDeals.fold(0.0, (sum, deal) => sum + deal.payment);
    final averageProjectValue = totalEarnings / totalProjects;
    
    // Sort deals by completion date (most recent first)
    brandDeals.sort((a, b) => b.contentPublishedDate!.compareTo(a.contentPublishedDate!));
    
    final firstProject = brandDeals.last.contentPublishedDate!;
    final latestProject = brandDeals.first.contentPublishedDate!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getBrandColor(brandName).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: _getBrandColor(brandName)),
                    ),
                    child: Icon(
                      Icons.business,
                      color: _getBrandColor(brandName),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          brandName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Brand Partnership Details',
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
              const SizedBox(height: 24),
              
              // Partnership Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getBrandColor(brandName).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getBrandColor(brandName).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildSummaryItem(
                          'Projects',
                          totalProjects.toString(),
                          Icons.work,
                        ),
                        _buildSummaryItem(
                          'Total Earnings',
                          _formatCurrency(totalEarnings),
                          Icons.currency_rupee,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildSummaryItem(
                          'Average Value',
                          _formatCurrency(averageProjectValue),
                          Icons.bar_chart,
                        ),
                        _buildSummaryItem(
                          'Partnership Since',
                          dateFormat.format(firstProject),
                          Icons.handshake,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Projects List
              Row(
                children: [
                  const Text(
                    'Project History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$totalProjects projects',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: ListView.builder(
                  itemCount: brandDeals.length,
                  itemBuilder: (context, index) {
                    final deal = brandDeals[index];
                    final isLatest = index == 0;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: isLatest ? 3 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isLatest 
                            ? BorderSide(color: _getBrandColor(brandName), width: 2)
                            : BorderSide.none,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isLatest 
                                ? _getBrandColor(brandName).withOpacity(0.2)
                                : Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.work,
                              color: isLatest 
                                ? _getBrandColor(brandName)
                                : Colors.grey[600],
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (deal.productName.isNotEmpty)
                                      Text(
                                        deal.productName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    else
                                      Text(
                                        'Project ${brandDeals.length - index}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      deal.description,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (isLatest)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getBrandColor(brandName),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'LATEST',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Completed: ${dateFormat.format(deal.contentPublishedDate!)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ),
                                Text(
                                  NumberFormat.currency(symbol: '₹', decimalDigits: 0)
                                      .format(deal.payment),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showProjectDetails(deal);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.grey[700]),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showProjectDetails(Deal deal) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final calculator = DealCalculator(dealPrice: deal.payment);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (deal.productName.isNotEmpty) ...[
                            const SizedBox(height: 4),
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
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Project Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Project Completed',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                            Text(
                              'Completed on ${dateFormat.format(deal.contentPublishedDate!)}',
                              style: TextStyle(
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Deliverables Section
                const Text(
                  'Deliverables:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    deal.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Project Information
                const Text(
                  'Project Details:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                _buildInfoRow('Brand Name', deal.brandName),
                if (deal.productName.isNotEmpty)
                  _buildInfoRow('Product Name', deal.productName),
                _buildInfoRow('Project Value', currencyFormat.format(deal.payment)),
                _buildInfoRow('Net Earnings', currencyFormat.format(calculator.netAmount)),
                _buildInfoRow('Deal Locked', dateFormat.format(deal.dealLockedDate)),
                _buildInfoRow('Due Date', dateFormat.format(deal.deliverablesDueDate)),
                _buildInfoRow('Completed On', dateFormat.format(deal.contentPublishedDate!)),
                _buildInfoRow('Payment Status', deal.isPaid ? 'Received' : 'Pending'),
                
                const SizedBox(height: 24),
                
                // Timeline Section
                const Text(
                  'Project Timeline:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                _buildTimelineItem(
                  'Deal Locked',
                  deal.dealLockedDate,
                  Icons.handshake,
                  Colors.blue,
                ),
                _buildTimelineItem(
                  'Due Date',
                  deal.deliverablesDueDate,
                  Icons.schedule,
                  Colors.orange,
                ),
                _buildTimelineItem(
                  'Completed',
                  deal.contentPublishedDate!,
                  Icons.check_circle,
                  Colors.green,
                ),
                if (!deal.isPaid)
                  _buildTimelineItem(
                    'Expected Payment',
                    deal.expectedPaymentDate,
                    Icons.payment,
                    deal.isPaymentOverdue ? Colors.red : Colors.purple,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, DateTime date, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  dateFormat.format(date),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  List<Deal> _getFilteredDeals(List<Deal> deals) {
    final now = DateTime.now();
    
    switch (_selectedFilter) {
      case 'This Year':
        return deals.where((deal) =>
          deal.contentPublishedDate!.year == now.year).toList();
      
      case 'Last 6 Months':
        final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);
        return deals.where((deal) =>
          deal.contentPublishedDate!.isAfter(sixMonthsAgo)).toList();
      
      case 'Last 3 Months':
        final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
        return deals.where((deal) =>
          deal.contentPublishedDate!.isAfter(threeMonthsAgo)).toList();
      
      case 'This Month':
        return deals.where((deal) =>
          deal.contentPublishedDate!.year == now.year &&
          deal.contentPublishedDate!.month == now.month).toList();
      
      default: // 'All'
        return deals;
    }
  }

  int _getUniqueBrandsCount(List<Deal> deals) {
    return deals.map((deal) => deal.brandName).toSet().length;
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

  String _getDaysAgo(DateTime date) {
    final difference = DateTime.now().difference(date).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return '1 day ago';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).floor()} weeks ago';
    return '${(difference / 30).floor()} months ago';
  }

  Color _getBrandColor(String brandName) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    final index = brandName.hashCode.abs() % colors.length;
    return colors[index];
  }

  void _showPortfolioAnalytics(List<Deal> deals) {
    // Calculate analytics from completed projects
    final totalProjects = deals.length;
    final totalEarnings = deals.fold(0.0, (sum, deal) => sum + deal.payment);
    final uniqueBrands = deals.map((deal) => deal.brandName).toSet().length;
    final averageProjectValue = totalProjects > 0 ? totalEarnings / totalProjects : 0.0;
    
    // Calculate brand frequency
    final brandCount = <String, int>{};
    for (var deal in deals) {
      brandCount[deal.brandName] = (brandCount[deal.brandName] ?? 0) + 1;
    }
    
    final topBrand = brandCount.entries.isEmpty 
        ? 'None' 
        : brandCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Portfolio Analytics',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                'Period: $_selectedFilter',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              
              // Analytics Cards
              Row(
                children: [
                  _buildAnalyticsCard(
                    'Total Projects', 
                    totalProjects.toString(), 
                    Icons.work, 
                    Colors.blue
                  ),
                  const SizedBox(width: 16),
                  _buildAnalyticsCard(
                    'Total Earnings', 
                    _formatCurrency(totalEarnings), 
                    Icons.currency_rupee, 
                    Colors.green
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildAnalyticsCard(
                    'Unique Brands', 
                    uniqueBrands.toString(), 
                    Icons.business, 
                    Colors.purple
                  ),
                  const SizedBox(width: 16),
                  _buildAnalyticsCard(
                    'Avg Project Value', 
                    _formatCurrency(averageProjectValue), 
                    Icons.bar_chart, 
                    Colors.orange
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              const Text(
                'Top Performing Brand:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topBrand,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (brandCount[topBrand] != null)
                            Text(
                              '${brandCount[topBrand]} projects completed',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              const Text(
                'Brand Breakdown:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: brandCount.entries.length,
                  itemBuilder: (context, index) {
                    final entry = brandCount.entries.elementAt(index);
                    final percentage = totalProjects > 0 ? (entry.value / totalProjects * 100).round() : 0;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: totalProjects > 0 ? entry.value / totalProjects : 0,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getBrandColorFromIndex(index),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('${entry.value} ($percentage%)'),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getBrandColorFromIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }
}