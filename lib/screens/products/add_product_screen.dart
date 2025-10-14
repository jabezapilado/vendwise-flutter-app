import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:vendwise/backend/app_repository.dart';
import 'package:vendwise/backend/bootstrap.dart';
import 'package:vendwise/backend/storage_service.dart';
import 'package:vendwise/models/productmodel.dart';
import 'package:vendwise/widgets/app_overlays.dart';
import 'package:vendwise/widgets/primary_app_bar.dart';
import 'package:vendwise/widgets/product_image.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceMediumController = TextEditingController();
  final TextEditingController _priceLargeController = TextEditingController();

  final List<String> _categories = <String>['Drinks', 'Food', 'Add-ons'];
  String? _selectedCategory = 'Drinks';
  String? _pickedFileLabel;
  PlatformFile? _pickedFile;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceMediumController.dispose();
    _priceLargeController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null) {
      return;
    }

    final file = result.files.single;
    if (file.bytes == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to read the selected file. Please try again.'),
        ),
      );
      return;
    }

    setState(() {
      _pickedFile = file;
      _pickedFileLabel = file.name;
    });
  }

  void _clearSelectedImage() {
    setState(() {
      _pickedFile = null;
      _pickedFileLabel = null;
    });
  }

  Future<void> _submitProduct() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    double parsePrice(String value) => double.tryParse(value.trim()) ?? 0;

    final double mediumPrice = parsePrice(_priceMediumController.text);
    final String largeRaw = _priceLargeController.text.trim();
    final double largePrice = largeRaw.isEmpty
        ? mediumPrice
        : parsePrice(largeRaw);

    String? imageUrl;
    if (_pickedFile != null) {
      if (!supabaseRepositoryActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supabase is not connected; image upload skipped.'),
          ),
        );
      } else {
        final storageService = getSupabaseStorageService();
        if (storageService == null) {
          setState(() {
            _isSubmitting = false;
            _errorMessage =
                'Supabase storage bucket is not configured. Update .env or create the bucket.';
          });
          return;
        }

        try {
          imageUrl = await storageService.uploadPlatformFile(
            _pickedFile!,
            directory: 'products',
          );
        } catch (error, stackTrace) {
          FlutterError.reportError(
            FlutterErrorDetails(exception: error, stack: stackTrace),
          );
          setState(() {
            _isSubmitting = false;
            _errorMessage = 'Image upload failed: $error';
          });
          return;
        }
      }
    }

    final ProductDraft draft = ProductDraft(
      productName: _nameController.text.trim(),
      productDesc: _descriptionController.text.trim(),
      priceM: mediumPrice,
      priceL: largePrice,
      prodType: _selectedCategory ?? 'Drinks',
      prodImage: imageUrl,
      clearImage: false,
    );

    try {
      await appRepository.createProduct(draft);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
      setState(() {
        _errorMessage = 'Failed to add product: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PrimaryAppBar(
        title: 'Add Product',
        section: AppSection.products,
      ),
      backgroundColor: const Color(0xFFFFFFFF),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const <Widget>[
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
                const SizedBox(height: 16),
                Image.asset('assets/icons/logo_black.png', height: 90),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _buildForm(),
                ),
                if (_errorMessage != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildSectionLabel('Type'),
            SizedBox(
              height: 40,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: _categories
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
                onChanged: (String? value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a type.';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionLabel('Product Name'),
            _buildTextField(
              controller: _nameController,
              hintText: 'Product Name',
              keyboardType: TextInputType.name,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter product name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildSectionLabel('Price for Medium (₱)'),
            _buildTextField(
              controller: _priceMediumController,
              hintText: 'Medium Price',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter medium price';
                }
                if (double.tryParse(value.trim()) == null) {
                  return 'Price must be a number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildSectionLabel('Price for Large (₱)'),
            _buildTextField(
              controller: _priceLargeController,
              hintText: 'Large Price (optional)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return null;
                }
                if (double.tryParse(value.trim()) == null) {
                  return 'Price must be a number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildSectionLabel('Description'),
            TextFormField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Description',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter product description';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildSectionLabel('Product Image'),
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
                    : const ProductImage(
                        imageUrl: null,
                        fit: BoxFit.cover,
                        placeholderAsset: 'assets/icons/logo.png',
                      ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _pickedFile == null || _isSubmitting
                    ? null
                    : _clearSelectedImage,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear selection'),
              ),
            ),
            const SizedBox(height: 12),
            _buildSectionLabel('Upload Your File Here:'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _isSubmitting ? null : _pickFile,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: _pickedFileLabel == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const <Widget>[
                            Icon(Icons.image, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Tap to Upload',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        )
                      : Text(
                          'Selected: $_pickedFileLabel',
                          style: const TextStyle(color: Colors.black),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: <Widget>[
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26347C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isSubmitting ? null : _submitProduct,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Add Product',
                              style: TextStyle(
                                fontSize: 12,
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
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF822222),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 12,
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

  Widget _buildSectionLabel(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(top: 10.0, bottom: 8.0),
          child: Text(
            title,
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
    required TextInputType keyboardType,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      height: 40,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }
}
