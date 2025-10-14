import 'package:flutter/material.dart';
import 'package:vendwise/backend/app_repository.dart';
import 'package:vendwise/models/inventorymodel.dart';
import 'package:vendwise/models/suppliermodel.dart';

class UpdateInventoryScreen extends StatefulWidget {
  const UpdateInventoryScreen({super.key, required this.inventory});

  final Inventorymodel inventory;

  @override
  State<UpdateInventoryScreen> createState() => _UpdateInventoryScreenState();
}

class _UpdateInventoryScreenState extends State<UpdateInventoryScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _productNameController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _contactController;
  late final TextEditingController _emailController;

  List<Suppliermodel> _suppliers = const <Suppliermodel>[];
  Suppliermodel? _selectedSupplier;
  bool _isSubmitting = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    final inventory = widget.inventory;
    _productNameController = TextEditingController(text: inventory.productName);
    _priceController = TextEditingController(text: inventory.price.toString());
    _quantityController = TextEditingController(
      text: inventory.quantity.toString(),
    );
    _contactController = TextEditingController(
      text: inventory.contactNum?.toString() ?? '',
    );
    _emailController = TextEditingController(text: inventory.email ?? '');
    if (inventory.supplierName != null && inventory.supplierName!.isNotEmpty) {
      _selectedSupplier = Suppliermodel(
        id: '',
        supplierName: inventory.supplierName!,
        contactNum: inventory.contactNum,
        email: inventory.email,
      );
    }
    _loadSuppliers();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    try {
      final fetchedSuppliers = await appRepository.fetchSuppliers();
      if (!mounted) return;
      Suppliermodel? selected = _selectedSupplier;

      if (fetchedSuppliers.isNotEmpty) {
        if (widget.inventory.supplierName != null &&
            widget.inventory.supplierName!.isNotEmpty) {
          selected = fetchedSuppliers.firstWhere(
            (supplier) =>
                supplier.supplierName == widget.inventory.supplierName,
            orElse: () => selected ?? fetchedSuppliers.first,
          );
        } else {
          selected ??= fetchedSuppliers.first;
        }
      }

      setState(() {
        _suppliers = fetchedSuppliers;
        _selectedSupplier = selected;
      });
      _syncContactDetails();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _suppliers = const <Suppliermodel>[];
      });
    }
  }

  void _syncContactDetails() {
    if (_selectedSupplier != null) {
      _contactController.text = _selectedSupplier!.contactNum?.toString() ?? '';
      _emailController.text = _selectedSupplier!.email ?? '';
    }
  }

  Future<void> _submitInventoryUpdate() async {
    if (_isSubmitting || _isDeleting) return;
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double? price = double.tryParse(_priceController.text.trim());
    final int? quantity = int.tryParse(_quantityController.text.trim());

    if (price == null) {
      _showSnackbar('Please enter a valid price.');
      return;
    }

    if (quantity == null) {
      _showSnackbar('Please enter a valid quantity.');
      return;
    }

    final draft = InventoryDraft(
      productName: _productNameController.text.trim(),
      supplierName: _selectedSupplier?.supplierName,
      price: price,
      quantity: quantity,
      contactNum: int.tryParse(_contactController.text.trim()),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      await appRepository.updateInventory(widget.inventory.id, draft);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      _showSnackbar('Failed to update inventory. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    if (_isSubmitting || _isDeleting) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete inventory item?'),
        content: const Text(
          'This action cannot be undone. Are you sure you want to delete this inventory item?',
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
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await appRepository.deleteInventory(widget.inventory.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      _showSnackbar('Failed to delete inventory. Please try again.');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: const Color(0xFFFFFFFF),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      leading: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.menu, color: Colors.white),
      ),
      title: const Text(
        'Update Inventory',
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

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSectionLabel('Supplier'),
            SizedBox(
              height: 40,
              child: DropdownButtonFormField<String>(
                // TODO: Replace with DropdownMenu when migrating to Flutter 3.33+ APIs.
                // ignore: deprecated_member_use
                value:
                    _suppliers.any(
                      (supplier) =>
                          supplier.supplierName ==
                          _selectedSupplier?.supplierName,
                    )
                    ? _selectedSupplier?.supplierName
                    : null,
                hint: const Text(
                  'Select a Supplier',
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
                items: _suppliers
                    .map(
                      (supplier) => DropdownMenuItem<String>(
                        value: supplier.supplierName,
                        child: Text(
                          supplier.supplierName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    if (value == null) {
                      _selectedSupplier = null;
                    } else {
                      _selectedSupplier = _suppliers.firstWhere(
                        (supplier) => supplier.supplierName == value,
                      );
                    }
                  });
                  _syncContactDetails();
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
            _buildSectionLabel('Price (₱)'),
            _buildTextField(
              controller: _priceController,
              hintText: 'Price',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter price';
                }
                if (double.tryParse(value.trim()) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            _buildSectionLabel('Quantity'),
            _buildTextField(
              controller: _quantityController,
              hintText: 'Quantity',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter quantity';
                }
                if (int.tryParse(value.trim()) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            _buildSectionLabel('Contact Number'),
            _buildTextField(
              controller: _contactController,
              hintText: 'Contact Number',
              keyboardType: TextInputType.phone,
            ),
            _buildSectionLabel('Email'),
            _buildTextField(
              controller: _emailController,
              hintText: 'Email',
              keyboardType: TextInputType.emailAddress,
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
                      onPressed: _isSubmitting || _isDeleting
                          ? null
                          : _submitInventoryUpdate,
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
                              'Update Inventory',
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
                          : _confirmDelete,
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
                              'Delete Inventory',
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
