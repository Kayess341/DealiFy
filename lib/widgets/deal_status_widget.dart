// lib/widgets/deal_status_widget.dart
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class DealStatusWidget extends StatelessWidget {
  // Sample data
  final List<StatusData> _data = [
    StatusData('Active', 5, Colors.blue),
    StatusData('Completed', 8, Colors.green),
    StatusData('Pending', 3, Colors.orange),
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
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: charts.PieChart(
              _createSeriesList(),
              animate: true,
              defaultRenderer: charts.ArcRendererConfig(
                arcWidth: 60,
                arcRendererDecorators: [
                  charts.ArcLabelDecorator(
                    labelPosition: charts.ArcLabelPosition.auto,
                  )
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _data.map((data) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: data.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        data.status,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<charts.Series<StatusData, String>> _createSeriesList() {
    return [
      charts.Series<StatusData, String>(
        id: 'Deal Status',
        domainFn: (StatusData data, _) => data.status,
        measureFn: (StatusData data, _) => data.count,
        colorFn: (StatusData data, _) => charts.ColorUtil.fromDartColor(data.color),
        data: _data,
        labelAccessorFn: (StatusData data, _) => '${data.count}',
      )
    ];
  }
}

class StatusData {
  final String status;
  final int count;
  final Color color;

  StatusData(this.status, this.count, this.color);
}