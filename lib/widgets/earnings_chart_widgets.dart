// lib/widgets/earnings_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class EarningsChartWidget extends StatelessWidget {
  // Sample data
  final List<EarningsData> _data = [
    EarningsData('Jan', 2800),
    EarningsData('Feb', 1500),
    EarningsData('Mar', 3200),
    EarningsData('Apr', 2300),
    EarningsData('May', 4500),
    EarningsData('Jun', 3800),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: charts.BarChart(
        _createSeriesList(),
        animate: true,
        primaryMeasureAxis: charts.NumericAxisSpec(
          renderSpec: charts.GridlineRendererSpec(
            lineStyle: charts.LineStyleSpec(
              color: charts.MaterialPalette.gray.shade300,
            ),
            labelStyle: charts.TextStyleSpec(
              fontSize: 12,
              color: charts.MaterialPalette.gray.shade600,
            ),
          ),
        ),
        domainAxis: charts.OrdinalAxisSpec(
          renderSpec: charts.SmallTickRendererSpec(
            labelStyle: charts.TextStyleSpec(
              fontSize: 12,
              color: charts.MaterialPalette.gray.shade600,
            ),
          ),
        ),
      ),
    );
  }

  List<charts.Series<EarningsData, String>> _createSeriesList() {
    return [
      charts.Series<EarningsData, String>(
        id: 'Earnings',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (EarningsData sales, _) => sales.month,
        measureFn: (EarningsData sales, _) => sales.amount,
        data: _data,
      )
    ];
  }
}

class EarningsData {
  final String month;
  final double amount;

  EarningsData(this.month, this.amount);
}
