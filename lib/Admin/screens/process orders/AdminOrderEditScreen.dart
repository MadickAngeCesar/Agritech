import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  final String token;

  const AdminOrdersScreen({Key? key, required this.token}) : super(key: key);

  @override
  _AdminOrdersScreenState createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  late ApiService _apiService;
  List<dynamic> _orders = [];
  List<dynamic> _filteredOrders = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';
  String _selectedPaymentStatus = 'all';
  String _selectedDateFilter = 'all';

  final List<String> _statusOptions = [
    'all',
    'pending',
    'processing',
    'shipped',
    'delivered',
    'cancelled'
  ];

  final List<String> _paymentStatusOptions = [
    'all',
    'pending',
    'paid',
    'failed',
    'refunded'
  ];

  final List<String> _dateFilterOptions = [
    'all',
    'today',
    'this week',
    'this month'
  ];

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(
      baseUrl: 'http://51.75.31.246:3000/api',
      token: widget.token,
    );
    _fetchOrders();
    _searchController.addListener(_searchOrders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    try {
      final response = await _apiService.get('/orders/admin/orders');
      setState(() {
        _orders = response;
        _filteredOrders = response;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching orders: $e',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.black)),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  void _searchOrders() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredOrders = _orders.where((order) {
        final orderNumber = order['order_number'].toString().toLowerCase();
        final customerName = order['User']?['full_name']?.toString().toLowerCase() ?? '';
        final phone = order['User']?['phone']?.toString().toLowerCase() ?? '';

        return orderNumber.contains(query) ||
            customerName.contains(query) ||
            phone.contains(query);
      }).toList();
    });
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredOrders = _orders.where((order) {
        final statusMatch = _selectedStatus == 'all' ||
            order['status'].toLowerCase() == _selectedStatus;

        final paymentStatusMatch = _selectedPaymentStatus == 'all' ||
            order['payment_status'].toLowerCase() == _selectedPaymentStatus;

        final now = DateTime.now();
        final orderDate = DateTime.parse(order['createdAt']);
        final dateMatch = _selectedDateFilter == 'all' ||
            (_selectedDateFilter == 'today' &&
                orderDate.year == now.year &&
                orderDate.month == now.month &&
                orderDate.day == now.day) ||
            (_selectedDateFilter == 'this week' &&
                orderDate.isAfter(now.subtract(Duration(days: 7)))) ||
            (_selectedDateFilter == 'this month' &&
                orderDate.year == now.year &&
                orderDate.month == now.month);

        return statusMatch && paymentStatusMatch && dateMatch;
      }).toList();

      if (_searchController.text.isNotEmpty) {
        _searchOrders();
      }
    });
  }

  Future<void> _updateOrderStatus(int orderId, String status, String paymentStatus) async {
    try {
      await _apiService.put('/orders/admin/orders/$orderId/status', body: {
        'status': status,
        'payment_status': paymentStatus,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Order updated successfully',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.black)),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      await _fetchOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.black)),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  void _showEditDialog(dynamic order) {
    String status = order['status'];
    String paymentStatus = order['payment_status'];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Order #${order['order_number']}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: status,
                items: ['pending', 'processing', 'shipped', 'delivered', 'cancelled']
                    .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    s.toUpperCase(),
                    style: TextStyle(fontFamily: 'Poppins', color: Colors.black),
                  ),
                ))
                    .toList(),
                onChanged: (val) => status = val!,
                decoration: InputDecoration(
                  labelText: 'Status',
                  labelStyle: TextStyle(fontFamily: 'Poppins', color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: TextStyle(fontFamily: 'Poppins', color: Colors.black),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: paymentStatus,
                items: ['pending', 'paid', 'failed', 'refunded']
                    .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    s.toUpperCase(),
                    style: TextStyle(fontFamily: 'Poppins', color: Colors.black),
                  ),
                ))
                    .toList(),
                onChanged: (val) => paymentStatus = val!,
                decoration: InputDecoration(
                  labelText: 'Payment Status',
                  labelStyle: TextStyle(fontFamily: 'Poppins', color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: TextStyle(fontFamily: 'Poppins', color: Colors.black),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CANCEL',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _updateOrderStatus(order['id'], status, paymentStatus);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CAF50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'SAVE CHANGES',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Color(0xFF4CAF50);
      case 'shipped':
        return Color(0xFF2196F3);
      case 'processing':
        return Color(0xFFFF9800);
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Color(0xFF4CAF50);
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Color(0xFF9C27B0);
      default:
        return Colors.orange;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Orders',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20),

              Text(
                'Order Status',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                items: _statusOptions.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(fontFamily: 'Poppins', color: Colors.black),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: TextStyle(fontFamily: 'Poppins', color: Colors.black),
              ),
              SizedBox(height: 16),

              Text(
                'Payment Status',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPaymentStatus,
                items: _paymentStatusOptions.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(fontFamily: 'Poppins', color: Colors.black),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentStatus = value!;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: TextStyle(fontFamily: 'Poppins', color: Colors.black),
              ),
              SizedBox(height: 16),

              Text(
                'Date Range',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedDateFilter,
                items: _dateFilterOptions.map((filter) {
                  return DropdownMenuItem(
                    value: filter,
                    child: Text(
                      filter.toUpperCase(),
                      style: TextStyle(fontFamily: 'Poppins', color: Colors.black),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDateFilter = value!;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: TextStyle(fontFamily: 'Poppins', color: Colors.black),
              ),
              SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedStatus = 'all';
                        _selectedPaymentStatus = 'all';
                        _selectedDateFilter = 'all';
                      });
                      Navigator.pop(context);
                      _applyFilters();
                    },
                    child: Text(
                      'RESET',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _applyFilters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CAF50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'APPLY',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'Poppins',
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ),
      ),
      child: Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            'Order Management',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Color(0xFF4CAF50),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.filter_alt, color: Colors.white),
              onPressed: _showFilterDialog,
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchOrders,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search orders...',
                  hintStyle: TextStyle(fontFamily: 'Poppins', color: Colors.black54),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                style: TextStyle(fontFamily: 'Poppins', color: Colors.black),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  if (_selectedStatus != 'all' ||
                      _selectedPaymentStatus != 'all' ||
                      _selectedDateFilter != 'all')
                    Chip(
                      label: Text(
                        'Filters Applied',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Color(0xFF4CAF50),
                      deleteIcon: Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _selectedStatus = 'all';
                          _selectedPaymentStatus = 'all';
                          _selectedDateFilter = 'all';
                        });
                        _applyFilters();
                      },
                    ),
                  SizedBox(width: 8),
                  if (_selectedStatus != 'all')
                    Chip(
                      label: Text(
                        'Status: ${_selectedStatus}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                      backgroundColor: Colors.grey[200],
                    ),
                  SizedBox(width: 8),
                  if (_selectedPaymentStatus != 'all')
                    Chip(
                      label: Text(
                        'Payment: ${_selectedPaymentStatus}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                      backgroundColor: Colors.grey[200],
                    ),
                  SizedBox(width: 8),
                  if (_selectedDateFilter != 'all')
                    Chip(
                      label: Text(
                        'Date: ${_selectedDateFilter}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                      backgroundColor: Colors.grey[200],
                    ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                ),
              )
                  : RefreshIndicator(
                onRefresh: _fetchOrders,
                color: Color(0xFF4CAF50),
                child: _filteredOrders.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory, size: 60, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'No orders found',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedStatus = 'all';
                            _selectedPaymentStatus = 'all';
                            _selectedDateFilter = 'all';
                            _searchController.clear();
                          });
                          _applyFilters();
                        },
                        child: Text(
                          'Clear all filters',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.separated(
                  padding: EdgeInsets.all(16),
                  itemCount: _filteredOrders.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = _filteredOrders[index];
                    final user = order['User'];
                    final customerName = user?['full_name'] ?? 'Unknown';
                    final phone = user?['phone'] ?? 'N/A';
                    final date = DateFormat('MMM dd, yyyy - hh:mm a')
                        .format(DateTime.parse(order['createdAt']));

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showEditDialog(order),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order #${order['order_number']}',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(order['status'])
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      order['status'].toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: _getStatusColor(order['status']),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                date,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    customerName,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    phone,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.location_on_outlined, size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      order['shipping_address'] ?? 'No address provided',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.local_shipping_outlined, size: 16, color: Colors.blueGrey),
                                  SizedBox(width: 8),
                                  Text(
                                    'Shipping Method: ${order['shipping_method'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.payment_outlined, size: 16, color: Colors.teal),
                                  SizedBox(width: 8),
                                  Text(
                                    'Payment Method: ${order['payment_method'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.notes_outlined, size: 16, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Notes: ${order['notes'] ?? 'None'}',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Divider(height: 1),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'TOTAL',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Text(
                                        'XAF ${order['total_amount']}',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getPaymentStatusColor(
                                          order['payment_status'])
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      order['payment_status'].toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: _getPaymentStatusColor(
                                            order['payment_status']),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Color(0xFF4CAF50)),
                                    onPressed: () => _showEditDialog(order),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}