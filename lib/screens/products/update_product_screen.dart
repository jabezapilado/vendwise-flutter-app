import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:vendwise/backend/app_repository.dart';
import 'package:vendwise/backend/bootstrap.dart';
import 'package:vendwise/backend/storage_service.dart';
import 'package:vendwise/models/productmodel.dart';
import 'package:vendwise/screens/dashboard/dashboard_screen.dart';
import 'package:vendwise/screens/inventory/inventory_screen.dart';
import 'package:vendwise/screens/products/products_screen.dart';
import 'package:vendwise/screens/dashboard/sales_report.dart';
import 'package:vendwise/screens/dashboard/transaction_screen.dart';
import 'package:vendwise/widgets/product_image.dart';

class UpdateProductScreen extends StatefulWidget {
  const UpdateProductScreen({super.key, required this.product});

  final Productmodel product;

  @override
  State<UpdateProductScreen> createState() => _UpdateProductScreenState();
}

class _UpdateProductScreenState extends State<UpdateProductScreen> {
  final int _selectedIndex = 2;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _productNameController;
  late final TextEditingController _priceMediumController;
  late final TextEditingController _priceLargeController;
  late final TextEditingController _descriptionController;

  final List<String> _productTypes = <String>['Drinks', 'Food', 'Add-ons'];

  String? _selectedType;
  String? _selectedFileName;
  String? _imageUrl;
  PlatformFile? _pickedFile;
  bool _isSubmitting = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _productNameController = TextEditingController(text: product.productName);
    _priceMediumController = TextEditingController(
      text: product.priceM.toString(),
    );
    _priceLargeController = TextEditingController(
      text: product.priceL.toString(),
    );
    _descriptionController = TextEditingController(text: product.productDesc);
    _selectedType = product.prodType.isEmpty ? null : product.prodType;
    _imageUrl = product.prodImage;
    _selectedFileName = _deriveDisplayLabel(_imageUrl);
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _priceMediumController.dispose();
    _priceLargeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _deriveDisplayLabel(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final Uri? uri = Uri.tryParse(value);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      for (final segment in uri.pathSegments.reversed) {
        if (segment.isNotEmpty) {
          return segment;
        }
      }
    }
    final parts = value.split(RegExp(r'[\\/]+'));
    if (parts.isNotEmpty) {
      final nonEmpty = parts.where((segment) => segment.isNotEmpty).toList();
      if (nonEmpty.isNotEmpty) {
        return nonEmpty.last;
      }
    }
    return value;
  }

  Future<void> _pickFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null) {
      return;
    }

    final PlatformFile file = result.files.single;
    if (file.bytes == null) {
      _showSnackbar(
        'Unable to read the selected file. Please enable storage permissions and try again.',
      );
      return;
    }

    setState(() {
      _pickedFile = file;
      _selectedFileName = file.name;
    });
  }

  void _clearSelectedImage() {
    setState(() {
      _pickedFile = null;
      _selectedFileName = null;
      _imageUrl = null;
    });
  }

  Future<void> _submitProductUpdate() async {
    if (_isSubmitting || _isDeleting) return;
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final int? priceMedium = int.tryParse(_priceMediumController.text.trim());
    final String largeRaw = _priceLargeController.text.trim();
    final int? priceLarge = largeRaw.isEmpty
        ? priceMedium
        : int.tryParse(largeRaw);

    if (priceMedium == null) {
      _showSnackbar('Please enter a valid price for medium.');
      return;
    }

    if (priceLarge == null) {
      _showSnackbar('Please enter a valid price for large.');
      return;
    }

    if (_selectedType == null || _selectedType!.isEmpty) {
      _showSnackbar('Please select a product type.');
      return;
    }

    const int minimumPrice = 0;
    if (priceMedium < minimumPrice || priceLarge < minimumPrice) {
      _showSnackbar('Price values cannot be negative.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? imageUrl = _imageUrl;

      if (_pickedFile != null) {
        if (!supabaseRepositoryActive) {
          _showSnackbar('Supabase is not connected; image upload skipped.');
        } else {
          final storageService = getSupabaseStorageService();
          if (storageService == null) {
            if (!mounted) {
              return;
            }
            setState(() {
              _isSubmitting = false;
            });
            _showSnackbar(
              'Supabase storage bucket is not configured. Update .env or create the bucket.',
            );
            return;
          }
          try {
            imageUrl = await storageService.uploadPlatformFile(
              _pickedFile!,
              directory: 'products',
            );
            _imageUrl = imageUrl;
            _selectedFileName = _deriveDisplayLabel(imageUrl);
            _pickedFile = null;
          } catch (error, stackTrace) {
            FlutterError.reportError(
              FlutterErrorDetails(exception: error, stack: stackTrace),
            );
            if (!mounted) {
              return;
            }
            setState(() {
              _isSubmitting = false;
            });
            _showSnackbar('Image upload failed: $error');
            return;
          }
        }
      }

      final bool hadExistingImage =
          widget.product.prodImage != null &&
          widget.product.prodImage!.isNotEmpty;
      final bool shouldRemoveImage =
          imageUrl == null && hadExistingImage && _pickedFile == null;

      final draft = ProductDraft(
        productName: _productNameController.text.trim(),
        productDesc: _descriptionController.text.trim(),
        priceM: priceMedium,
        priceL: priceLarge,
        prodType: _selectedType!,
        prodImage: imageUrl,
        clearImage: shouldRemoveImage,
      );

      await appRepository.updateProduct(widget.product.id, draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully.')),
      );
      Navigator.pop(context, true);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
      if (!mounted) return;
      _showSnackbar('Failed to update product. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteProduct() async {
    if (_isSubmitting || _isDeleting) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete product?'),
          content: const Text(
            'This action cannot be undone. Are you sure you want to delete this product?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await appRepository.deleteProduct(widget.product.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      _showSnackbar('Failed to delete product. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const InventoryScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProductsScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TransactionScreen()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SalesReport()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: const Color(0xFFFFFFFF),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DashboardScreen(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.arrow_back_ios_new,
                            color: Color(0xFFADADAD),
                            size: 20,
                          ),
                          SizedBox(width: 1),
                          Text(
                            'Back',
                            style: TextStyle(
                              color: Color(0xFFADADAD),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Image.asset('assets/icons/logo_black.png', height: 90),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _buildForm(),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      leading: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.menu, color: Colors.white),
      ),
      title: const Text(
        'Update Product',
        style: TextStyle(
          fontFamily: 'Inter',
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications, color: Colors.white),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.account_circle, color: Colors.white),
        ),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD74848), Color(0xFF111C51)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD74848), Color(0xFF111C51)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.white,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.space_dashboard_sharp),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_rounded),
              label: 'Inventory',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_rounded),
              label: 'Products',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_edu_rounded),
              label: 'Transactions',
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

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSectionLabel('Type'),
            SizedBox(
              height: 40,
              child: DropdownButtonFormField<String>(
                // TODO: replace with controller/initialValue once project migrates to updated Dropdown API.
                // ignore: deprecated_member_use
                value: _selectedType,
                style: const TextStyle(fontSize: 14),
                hint: const Text(
                  'Select a Type',
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
                items: _productTypes
                    .map(
                      (String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedType = newValue;
                  });
                },
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a type.';
                  }
                  return null;
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
            _buildSectionLabel('Product Name'),
            _buildTextField(
              controller: _productNameController,
              hintText: 'Product Name',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter product name';
                }
                return null;
              },
            ),
            _buildSectionLabel('Price for Medium (₱)'),
            _buildTextField(
              controller: _priceMediumController,
              hintText: 'Price',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter price';
                }
                if (int.tryParse(value.trim()) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            _buildSectionLabel('Price for Large (₱)'),
            _buildTextField(
              controller: _priceLargeController,
              hintText: 'Price',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return null;
                }
                if (int.tryParse(value.trim()) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            _buildSectionLabel('Description'),
            _buildTextField(
              controller: _descriptionController,
              hintText: 'Description',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            _buildSectionLabel('Current Image'),
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: _pickedFile != null && _pickedFile!.bytes != null
                    ? Image.memory(_pickedFile!.bytes!, fit: BoxFit.cover)
                    : ProductImage(
                        imageUrl: _imageUrl,
                        fit: BoxFit.cover,
                        placeholderAsset: 'assets/icons/logo.png',
                      ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed:
                    (_imageUrl == null && _pickedFile == null) || _isSubmitting
                    ? null
                    : _clearSelectedImage,
                icon: const Icon(Icons.delete_outline),
                label: Text(
                  _pickedFile != null ? 'Clear selection' : 'Remove image',
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildSectionLabel('Upload Your File Here:'),
            const SizedBox(height: 5),
            GestureDetector(
              onTap: _isSubmitting ? null : _pickFile,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: _selectedFileName == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.image, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Tap to Upload',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        )
                      : Text(
                          'Selected: $_selectedFileName',
                          style: const TextStyle(color: Colors.black),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 35,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26347C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isSubmitting ? null : _submitProductUpdate,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Update Product',
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 35,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF822222),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isDeleting || _isSubmitting
                          ? null
                          : _confirmDeleteProduct,
                      child: _isDeleting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Delete Product',
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10.0),
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4D0202),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      children: [
        const SizedBox(height: 5),
        SizedBox(
          height: 40,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: validator,
            keyboardType: keyboardType,
          ),
        ),
      ],
    );
  }
}
