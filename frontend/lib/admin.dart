import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/product.dart';


class Admin extends StatefulWidget {
  const Admin({super.key});

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> {
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

  File? _pickedImage;
  Uint8List? _webImage;
  XFile? _imageFile;

  List<Product> products = [];
  final String baseUrl = "https://motorcycles-zroi.onrender.com";

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/api/product"));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        setState(() {
          products = data.map((item) {
            return Product(
              id: item['id'].toString(),
              name: item['name'] ?? '',
              description: item['description'] ?? '',
              price: double.tryParse(item['price'].toString()) ?? 0.0,
              star: int.tryParse(item['star']?.toString() ?? '0') ?? 0,
              engine: item['engine'] ?? '',
              power: int.tryParse(item['power']?.toString() ?? '0') ?? 0,
              topSpeed: int.tryParse(item['topspeed']?.toString() ?? '0') ?? 0,
              fuel: int.tryParse(item['fuel']?.toString() ?? '0') ?? 0,
              weight: int.tryParse(item['weight']?.toString() ?? '0') ?? 0,
              mileage: int.tryParse(item['mileage']?.toString() ?? '0') ?? 0,
              image: item['image'] ?? '',
            );
          }).toList();
        });
      } else {
        debugPrint("Failed to fetch products: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching products: $e");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
          _imageFile = pickedFile;
        });
      } else {
        setState(() {
          _pickedImage = File(pickedFile.path);
          _imageFile = pickedFile;
        });
      }
    }
  }

  Future<void> _addProduct() async {
    if (_formKey.currentState!.validate() && _imageFile != null) {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/api/addProduct"),
      );

      request.fields['name'] = _nameController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['price'] = _priceController.text;
      request.fields['star'] = _starController.text;
      request.fields['engine'] = _engineController.text;
      request.fields['power'] = _powerController.text;
      request.fields['topspeed'] = _topSpeedController.text;
      request.fields['fuel'] = _fuelController.text;
      request.fields['weight'] = _weightController.text;
      request.fields['mileage'] = _mileageController.text;

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            _webImage!,
            filename: 'upload.jpg',
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('image', _pickedImage!.path),
        );
      }

      try {
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          _clearForm();
          fetchProducts();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print("Error uploading: $e");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and pick image')),
      );
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
    setState(() {
      _pickedImage = null;
      _webImage = null;
      _imageFile = null;
    });
  }

  Future<void> _deleteProduct(String id) async {
    try {
      final response = await http.delete(Uri.parse("$baseUrl/api/product/$id"));
      if (response.statusCode == 200) {
        fetchProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deleted successfully'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Delete error: $e");
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
        if (value == null || value.isEmpty) return 'Required';
        if (keyboardType == TextInputType.number &&
            double.tryParse(value) == null)
          return 'Invalid number';
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form لإضافة المنتج
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image),
                            label: const Text('Pick Image'),
                          ),
                          const SizedBox(width: 12),
                          if (_imageFile != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb
                                  ? Image.memory(
                                      _webImage!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      _pickedImage!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                            )
                          else
                            const Text('No image'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _addProduct,
                        child: const Text('Add Product'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // عرض المنتجات
            Text(
              'Products List',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              child: products.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(48.0),
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
                        rows: products
                            .map(
                              (p) => DataRow(
                                cells: [
                                  DataCell(
                                    p.image != null
                                        ? Image.network(
                                            "$baseUrl/api/uploads/${p.image}",
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(Icons.image_not_supported),
                                  ),
                                  DataCell(Text(p.name)),
                                  DataCell(Text('\$${p.price}')),
                                  DataCell(Text(p.star.toString())),
                                  DataCell(Text(p.engine)),
                                  DataCell(Text(p.power.toString())),
                                  DataCell(Text(p.topSpeed.toString())),
                                  DataCell(Text(p.fuel.toString())),
                                  DataCell(Text(p.weight.toString())),
                                  DataCell(Text(p.mileage.toString())),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteProduct(p.id),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
