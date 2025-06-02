import '../models/deal.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Global list to store deals - shared across all screens
List<Deal> globalDeals = [];

// Data persistence helper class
class DealDataManager {
  static const String _dealsKey = 'deals_data';
  
  // Save deals to persistent storage
  static Future<void> saveDeals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dealsJson = globalDeals.map((deal) => deal.toJson()).toList();
      await prefs.setString(_dealsKey, jsonEncode(dealsJson));
      print('Deals saved successfully: ${globalDeals.length} deals');
    } catch (e) {
      print('Error saving deals: $e');
    }
  }
  
  // Load deals from persistent storage
  static Future<void> loadDeals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dealsString = prefs.getString(_dealsKey);
      
      if (dealsString != null) {
        final dealsJson = jsonDecode(dealsString) as List;
        globalDeals = dealsJson.map((json) => Deal.fromJson(json)).toList();
        print('Deals loaded successfully: ${globalDeals.length} deals');
      } else {
        print('No saved deals found');
        globalDeals = [];
      }
    } catch (e) {
      print('Error loading deals: $e');
      globalDeals = []; // Fallback to empty list
    }
  }
  
  // Clear all deals (for testing or reset functionality)
  static Future<void> clearDeals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dealsKey);
      globalDeals.clear();
      print('All deals cleared');
    } catch (e) {
      print('Error clearing deals: $e');
    }
  }
}