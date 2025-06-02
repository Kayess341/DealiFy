// lib/screens/add_deal_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/brand_deal.dart';

class AddDealScreen extends StatefulWidget {
  @override
  _AddDealScreenState createState() => _AddDealScreenState();
}

class _AddDealScreenState extends State<AddDealScreen> {
  final _formKey = GlobalKey<FormState>();
  final dateFormat = DateFormat('MMM dd, yyyy');
  
  String _brandName = '';
  String _description = '';
  double _payment = 0.0;
  DateTime _startDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(Duration(days: 30));
  List<ContentDeliverable> _deliverables = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Deal'),
        actions: [
          TextButton(
            onPressed: _saveForm,
            child: Text(
              'SAVE',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Brand Information'),
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
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onSaved: (value) {
                  _description = value ?? '';
                },
              ),
              SizedBox(height: 24),
              
              _buildSectionTitle('Deal Terms'),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Payment Amount *',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
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
              ),
              SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      'Start Date',
                      _startDate,
                      (newDate) {
                        setState(() {
                          _startDate = newDate;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildDateField(
                      'Due Date',
                      _dueDate,
                      (newDate) {
                        setState(() {
                          _dueDate = newDate;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              
              _buildSectionTitle('Content Deliverables'),
              ..._buildDeliverablesList(),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addDeliverable,
                icon: Icon(Icons.add),
                label: Text('Add Deliverable'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.grey.shade300,
                  onPrimary: Colors.black87,
                ),
              ),
              SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveForm,
                  child: Text('SAVE DEAL'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime initialDate,
    Function(DateTime) onDateSelected,
  ) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime.now().subtract(Duration(days: 365)),
          lastDate: DateTime.now().add(Duration(days: 365)),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        child: Text(dateFormat.format(initialDate)),
      ),
    );
  }

  List<Widget> _buildDeliverablesList() {
    return _deliverables.asMap().entries.map((entry) {
      int idx = entry.key;
      ContentDeliverable deliverable = entry.value;
      
      return Card(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      deliverable.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _deliverables.removeAt(idx);
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text('Platform: ${deliverable.platform}'),
              Text('Due: ${dateFormat.format(deliverable.dueDate)}'),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _addDeliverable() async {
    // Show dialog to add deliverable
    final result = await showDialog<ContentDeliverable>(
      context: context,
      builder: (ctx) => AddDeliverableDialog(),
    );
    
    if (result != null) {
      setState(() {
        _deliverables.add(result);
      });
    }
  }

  void _saveForm() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      
      // In a real app, save to database or API
      final newDeal = BrandDeal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        brandName: _brandName,
        description: _description,
        payment: _payment,
        isPaid: false,
        startDate: _startDate,
        dueDate: _dueDate,
        deliverables: _deliverables,
      );
      
      // For now, just go back
      Navigator.pop(context);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deal added successfully')),
      );
    }
  }
}

class AddDeliverableDialog extends StatefulWidget {
  @override
  _AddDeliverableDialogState createState() => _AddDeliverableDialogState();
}

class _AddDeliverableDialogState extends State<AddDeliverableDialog> {
  final _formKey = GlobalKey<FormState>();
  final dateFormat = DateFormat('MMM dd, yyyy');
  
  String _title = '';
  String _platform = 'Instagram';
  DateTime _dueDate = DateTime.now().add(Duration(days: 7));
  
  final _platforms = [
    'Instagram',
    'YouTube',
    'TikTok',
    'Facebook',
    'Twitter',
    'Blog',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Content Deliverable'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onSaved: (value) {
                  _title = value ?? '';
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Platform',
                  border: OutlineInputBorder(),
                ),
                value: _platform,
                items: _platforms.map((platform) {
                  return DropdownMenuItem(
                    value: platform,
                    child: Text(platform),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _platform = value ?? 'Instagram';
                  });
                },
              ),
              SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _dueDate = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Due Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(dateFormat.format(_dueDate)),
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
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              _formKey.currentState?.save();
              
              Navigator.pop(
                context,
                ContentDeliverable(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: _title,
                  platform: _platform,
                  dueDate: _dueDate,
                  isCompleted: false,
                ),
              );
            }
          },
          child: Text('ADD'),
        ),
      ],
    );
  }
}