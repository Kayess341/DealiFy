import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Deal {
  final String id;
  final String brandName;
  final String productName;
  final String description;
  final double payment;
  final bool isPaid;
  final DateTime dealLockedDate;
  final DateTime deliverablesDueDate;
  final int paymentTimelineDays;
  final String status;
  final String? contentLink;
  final DateTime? contentPublishedDate;
  final DateTime? paymentReceivedDate;  // NEW: Track when payment was actually received
  final Map<String, dynamic>? contentMetrics;

  Deal({
    required this.id,
    required this.brandName,
    this.productName = '',
    required this.description,
    required this.payment,
    required this.isPaid,
    required this.dealLockedDate,
    required this.deliverablesDueDate,
    required this.paymentTimelineDays,
    required this.status,
    this.contentLink,
    this.contentPublishedDate,
    this.paymentReceivedDate,  // NEW
    this.contentMetrics,
  });

  // Convert Deal to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brandName': brandName,
      'productName': productName,
      'description': description,
      'payment': payment,
      'isPaid': isPaid,
      'dealLockedDate': dealLockedDate.toIso8601String(),
      'deliverablesDueDate': deliverablesDueDate.toIso8601String(),
      'paymentTimelineDays': paymentTimelineDays,
      'status': status,
      'contentLink': contentLink,
      'contentPublishedDate': contentPublishedDate?.toIso8601String(),
      'paymentReceivedDate': paymentReceivedDate?.toIso8601String(),  // NEW
      'contentMetrics': contentMetrics,
    };
  }

  // Create Deal from JSON for persistence
  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      id: json['id'],
      brandName: json['brandName'],
      productName: json['productName'] ?? '',
      description: json['description'],
      payment: json['payment'].toDouble(),
      isPaid: json['isPaid'],
      dealLockedDate: DateTime.parse(json['dealLockedDate']),
      deliverablesDueDate: DateTime.parse(json['deliverablesDueDate']),
      paymentTimelineDays: json['paymentTimelineDays'],
      status: json['status'],
      contentLink: json['contentLink'],
      contentPublishedDate: json['contentPublishedDate'] != null 
          ? DateTime.parse(json['contentPublishedDate']) 
          : null,
      paymentReceivedDate: json['paymentReceivedDate'] != null   // NEW
          ? DateTime.parse(json['paymentReceivedDate']) 
          : null,
      contentMetrics: json['contentMetrics'] != null 
          ? Map<String, dynamic>.from(json['contentMetrics']) 
          : null,
    );
  }

  // Helper methods for payment calculations
  DateTime get expectedPaymentDate {
    final baseDate = contentPublishedDate ?? deliverablesDueDate;
    return baseDate.add(Duration(days: paymentTimelineDays));
  }

  bool get isPaymentOverdue {
    if (isPaid) return false;
    return DateTime.now().isAfter(expectedPaymentDate);
  }

  int get daysOverdue {
    if (!isPaymentOverdue) return 0;
    return DateTime.now().difference(expectedPaymentDate).inDays;
  }

  String get paymentStatus {
    if (isPaid) return 'Paid';
    if (isPaymentOverdue) return 'Overdue';
    
    final daysUntilPayment = expectedPaymentDate.difference(DateTime.now()).inDays;
    if (daysUntilPayment <= 7) return 'Due Soon';
    return 'Pending';
  }

  Color get paymentStatusColor {
    switch (paymentStatus) {
      case 'Paid':
        return Colors.green;
      case 'Overdue':
        return Colors.red;
      case 'Due Soon':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}

class DealCalculator {
  final double dealPrice;
  final double commissionRate;
  final double tdsRate;
  
  DealCalculator({
    required this.dealPrice,
    this.commissionRate = 0.20, // 20% default
    this.tdsRate = 0.10, // 10% default
  });
  
  double get commission => dealPrice * commissionRate;
  double get amountAfterCommission => dealPrice - commission;
  double get tds => amountAfterCommission * tdsRate;
  double get netAmount => amountAfterCommission - tds;
}