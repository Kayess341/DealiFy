import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/deal.dart';
import 'utils/globals.dart';
import 'screens/home_screen.dart';
import 'screens/deals_screen.dart';
import 'screens/timeline_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/reports_screen.dart';
import 'utils/user_preferences.dart';
import 'screens/welcome_screen.dart';

// Keep the DealMoneyBreakdownWidget here since it's used across multiple screens
class DealMoneyBreakdownWidget extends StatelessWidget {
  final double dealPrice;
  final double commissionRate;
  final double tdsRate;
  final bool showTitle;
  
  const DealMoneyBreakdownWidget({
    super.key,
    required this.dealPrice,
    this.commissionRate = 0.20,
    this.tdsRate = 0.10,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final calculator = DealCalculator(
      dealPrice: dealPrice,
      commissionRate: commissionRate,
      tdsRate: tdsRate,
    );
    
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Row(
                children: [
                  Icon(Icons.calculate, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Money Breakdown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            _buildBreakdownRow(
              'Deal Price',
              currencyFormat.format(calculator.dealPrice),
              Colors.blue,
              isMain: true,
            ),
            const Divider(height: 24),
            _buildBreakdownRow(
              'Commission (${(commissionRate * 100).toInt()}%)',
              '- ${currencyFormat.format(calculator.commission)}',
              Colors.red,
            ),
            const SizedBox(height: 8),
            _buildBreakdownRow(
              'After Commission',
              currencyFormat.format(calculator.amountAfterCommission),
              Colors.grey[600]!,
            ),
            const SizedBox(height: 8),
            _buildBreakdownRow(
              'TDS (${(tdsRate * 100).toInt()}%)',
              '- ${currencyFormat.format(calculator.tds)}',
              Colors.red,
            ),
            const Divider(height: 24),
            _buildBreakdownRow(
              'Net Amount',
              currencyFormat.format(calculator.netAmount),
              Colors.green,
              isMain: true,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet, 
                       color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You will receive: ${currencyFormat.format(calculator.netAmount)}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
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

  Widget _buildBreakdownRow(String label, String amount, Color color, {bool isMain = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isMain ? 15 : 13,
                fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
                color: isMain ? Colors.black : Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              amount,
              style: TextStyle(
                fontSize: isMain ? 15 : 13,
                fontWeight: isMain ? FontWeight.bold : FontWeight.w500,
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
}

void main() {
  runApp(CreatorDealsApp());
}

class CreatorDealsApp extends StatelessWidget {
  const CreatorDealsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DealiFy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF6200EE),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      home: AppInitializer(), // Changed to use AppInitializer
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/main': (context) => const MainNavigationScreen(),
      },
    );
  }
}

// NEW: App Initializer to check welcome completion
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  bool _showWelcome = true;

  @override
  void initState() {
    super.initState();
    _checkWelcomeStatus();
  }

  Future<void> _checkWelcomeStatus() async {
    try {
      // Load user preferences first
      final isWelcomeCompleted = await UserPreferences.isWelcomeCompleted();
      
      // Load deals data
      await DealDataManager.loadDeals();
      
      setState(() {
        _showWelcome = !isWelcomeCompleted;
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing app: $e');
      setState(() {
        _isLoading = false;
        _showWelcome = true; // Default to showing welcome on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.handshake,
                    size: 50,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Loading indicator
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),
                
                // Loading text
                const Text(
                  'DealiFy',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Loading your creator workspace...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Navigate to appropriate screen
    return _showWelcome ? const WelcomeScreen() : const MainNavigationScreen();
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  String? _userName;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    DealsScreen(),
    const TimelineScreen(),
    const PortfolioScreen(),
    const ReportsScreen(),
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.handshake),
              label: 'Deals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.timeline),
              label: 'Timeline',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work),
              label: 'Portfolio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }
}

// Keep the DealCalculatorScreen here since it's accessed from multiple places
class DealCalculatorScreen extends StatefulWidget {
  const DealCalculatorScreen({super.key});

  @override
  _DealCalculatorScreenState createState() => _DealCalculatorScreenState();
}

class _DealCalculatorScreenState extends State<DealCalculatorScreen> {
  final _dealPriceController = TextEditingController();
  final _commissionController = TextEditingController(text: '20');
  final _tdsController = TextEditingController(text: '10');
  
  double _dealPrice = 0;
  double _commissionRate = 0.20;
  double _tdsRate = 0.10;

  @override
  void initState() {
    super.initState();
    _dealPriceController.addListener(_updateCalculation);
    _commissionController.addListener(_updateRates);
    _tdsController.addListener(_updateRates);
  }

  void _updateCalculation() {
    setState(() {
      _dealPrice = double.tryParse(_dealPriceController.text) ?? 0;
    });
  }

  void _updateRates() {
    setState(() {
      _commissionRate = (double.tryParse(_commissionController.text) ?? 20) / 100;
      _tdsRate = (double.tryParse(_tdsController.text) ?? 10) / 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deal Calculator'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Calculate Your Earnings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dealPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Deal Price',
                        prefixText: '₹',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.currency_rupee),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _commissionController,
                            decoration: const InputDecoration(
                              labelText: 'Commission %',
                              border: OutlineInputBorder(),
                              suffixText: '%',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _tdsController,
                            decoration: const InputDecoration(
                              labelText: 'TDS %',
                              border: OutlineInputBorder(),
                              suffixText: '%',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_dealPrice > 0)
              DealMoneyBreakdownWidget(
                dealPrice: _dealPrice,
                commissionRate: _commissionRate,
                tdsRate: _tdsRate,
              ),
            const SizedBox(height: 16),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'How it works:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Commission is deducted from the total deal price\n'
                      '• TDS is calculated on the remaining amount after commission\n'
                      '• Net amount is what you actually receive',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dealPriceController.dispose();
    _commissionController.dispose();
    _tdsController.dispose();
    super.dispose();
  }
}