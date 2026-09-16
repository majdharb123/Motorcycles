import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/product.dart';

class Admin extends StatefulWidget {
  const Admin({super.key});

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  static const String baseUrl = 'https://motorcycles-zroi.onrender.com';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _starController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _engineController = TextEditingController();
  final _powerController = TextEditingController();
  final _topSpeedController = TextEditingController();
  final _fuelController = TextEditingController();
  final _weightController = TextEditingController();
  final _mileageController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageName;
  List<Product> products = [];
  bool _isLoadingProducts = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _starController.dispose();
    _descriptionController.dispose();
    _engineController.dispose();
    _powerController.dispose();
    _topSpeedController.dispose();
    _fuelController.dispose();
    _weightController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String _responseMessage(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['message'] != null) {
        return body['message'].toString();
      }
    } catch (_) {
      // The server did not return JSON, so use the fallback message.
    }
    return fallback;
  }

  Future<void> fetchProducts() async {
    if (mounted) setState(() => _isLoadingProducts = true);

    try {
      final response = await http.get(Uri.parse('$baseUrl/api/product'));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! List) {
          throw const FormatException('Invalid products response');
        }

        final fetchedProducts = decoded.map<Product>((item) {
          return Product(
            id: item['id'].toString(),
            name: item['name']?.toString() ?? '',
            description: item['description']?.toString() ?? '',
            price: double.tryParse(item['price']?.toString() ?? '') ?? 0,
            star: int.tryParse(item['star']?.toString() ?? '') ?? 0,
            engine: item['engine']?.toString() ?? '',
            power: int.tryParse(item['power']?.toString() ?? '') ?? 0,
            topSpeed: int.tryParse(item['topspeed']?.toString() ?? '') ?? 0,
            fuel: int.tryParse(item['fuel']?.toString() ?? '') ?? 0,
            weight: int.tryParse(item['weight']?.toString() ?? '') ?? 0,
            mileage: int.tryParse(item['mileage']?.toString() ?? '') ?? 0,
            image: item['image']?.toString() ?? '',
          );
        }).toList();

        if (mounted) setState(() => products = fetchedProducts);
      } else {
        _showMessage(
          _responseMessage(response, 'Failed to load products'),
          isError: true,
        );
      }
    } catch (error) {
      debugPrint('Error fetching products: $error');
      _showMessage('Could not connect to the server', isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile == null) return;
      final bytes = await pickedFile.readAsBytes();

      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _imageName = pickedFile.name;
        });
      }
    } catch (error) {
      debugPrint('Image picker error: $error');
      _showMessage('Could not select the image', isError: true);
    }
  }

  Future<void> _addProduct() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_imageBytes == null || _imageName == null) {
      _showMessage('Please select a product image', isError: true);
      return;
    }

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      _showMessage('Your session expired. Please log in again.', isError: true);
      return;
    }

    if (mounted) setState(() => _isSaving = true);

    final request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/api/addProduct'))
          ..headers['Authorization'] = 'Bearer $token'
          ..fields.addAll({
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'price': _priceController.text.trim(),
            'star': _starController.text.trim(),
            'engine': _engineController.text.trim(),
            'power': _powerController.text.trim(),
            'topspeed': _topSpeedController.text.trim(),
            'fuel': _fuelController.text.trim(),
            'weight': _weightController.text.trim(),
            'mileage': _mileageController.text.trim(),
          })
          ..files.add(
            http.MultipartFile.fromBytes(
              'image',
              _imageBytes!,
              filename: _imageName,
            ),
          );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _clearForm();
        await fetchProducts();
        _showMessage('Product added successfully');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _showMessage(
          _responseMessage(response, 'Admin access is required'),
          isError: true,
        );
      } else {
        _showMessage(
          _responseMessage(response, 'Failed to add the product'),
          isError: true,
        );
      }
    } catch (error) {
      debugPrint('Error adding product: $error');
      _showMessage('Could not connect to the server', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _priceController.clear();
    _starController.clear();
    _descriptionController.clear();
    _engineController.clear();
    _powerController.clear();
    _topSpeedController.clear();
    _fuelController.clear();
    _weightController.clear();
    _mileageController.clear();
    if (mounted) {
      setState(() {
        _imageBytes = null;
        _imageName = null;
      });
    }
  }

  Future<void> _deleteProduct(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      _showMessage('Your session expired. Please log in again.', isError: true);
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/product/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        await fetchProducts();
        _showMessage('Product deleted successfully');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _showMessage(
          _responseMessage(response, 'Admin access is required'),
          isError: true,
        );
      } else {
        _showMessage(
          _responseMessage(response, 'Failed to delete the product'),
          isError: true,
        );
      }
    } catch (error) {
      debugPrint('Delete error: $error');
      _showMessage('Could not connect to the server', isError: true);
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return 'Required';
        if (keyboardType == TextInputType.number &&
            double.tryParse(text) == null) {
          return 'Invalid number';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel - Product Management'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchProducts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          'Add New Product',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(_nameController, 'Name'),
                        _buildTextField(
                          _priceController,
                          'Price',
                          keyboardType: TextInputType.number,
                        ),
                        _buildTextField(
                          _starController,
                          'Star',
                          keyboardType: TextInputType.number,
                        ),
                        _buildTextField(_descriptionController, 'Description'),
                        _buildTextField(_engineController, 'Engine'),
                        _buildTextField(
                          _powerController,
                          'Power',
                          keyboardType: TextInputType.number,
                        ),
                        _buildTextField(
                          _topSpeedController,
                          'Top Speed',
                          keyboardType: TextInputType.number,
                        ),
                        _buildTextField(
                          _fuelController,
                          'Fuel Capacity',
                          keyboardType: TextInputType.number,
                        ),
                        _buildTextField(
                          _weightController,
                          'Weight',
                          keyboardType: TextInputType.number,
                        ),
                        _buildTextField(
                          _mileageController,
                          'Mileage',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isSaving ? null : _pickImage,
                              icon: const Icon(Icons.image),
                              label: const Text('Pick Image'),
                            ),
                            if (_imageBytes != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  _imageBytes!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              const Text('No image selected'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _addProduct,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Add Product'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Products List',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 3,
                child: _isLoadingProducts
                    ? const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : products.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: Text('No products available')),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Image')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Price')),
                            DataColumn(label: Text('Star')),
                            DataColumn(label: Text('Engine')),
                            DataColumn(label: Text('Power')),
                            DataColumn(label: Text('Top Speed')),
                            DataColumn(label: Text('Fuel')),
                            DataColumn(label: Text('Weight')),
                            DataColumn(label: Text('Mileage')),
                            DataColumn(label: Text('Action')),
                          ],
                          rows: products.map((product) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  product.image.isNotEmpty
                                      ? Image.network(
                                          '$baseUrl/api/uploads/${product.image}',
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.broken_image),
                                        )
                                      : const Icon(Icons.image_not_supported),
                                ),
                                DataCell(Text(product.name)),
                                DataCell(Text('\$${product.price}')),
                                DataCell(Text(product.star.toString())),
                                DataCell(Text(product.engine)),
                                DataCell(Text(product.power.toString())),
                                DataCell(Text(product.topSpeed.toString())),
                                DataCell(Text(product.fuel.toString())),
                                DataCell(Text(product.weight.toString())),
                                DataCell(Text(product.mileage.toString())),
                                DataCell(
                                  IconButton(
                                    tooltip: 'Delete product',
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteProduct(product.id),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
