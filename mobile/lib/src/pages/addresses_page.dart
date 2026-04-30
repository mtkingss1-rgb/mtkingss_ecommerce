import 'package:flutter/material.dart';
import '../api/authed_api_client.dart';
import '../models/address.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key, required this.api});

  final AuthedApiClient api;

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  List<Address> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    try {
      final result = await widget.api.getAddresses();
      final addressesList = (result['addresses'] as List<dynamic>?)?.map((item) {
            return Address.fromJson(item as Map<String, dynamic>);
          }).toList() ??
          [];

      if (mounted) {
        setState(() => _addresses = addressesList);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading addresses: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAddress(String id) async {
    try {
      await widget.api.deleteAddress(id: id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address deleted'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAddresses();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showDeleteConfirm(Address address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Remove "${address.label}" address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAddress(address.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddAddressPage(api: widget.api),
          ),
        ).then((_) => _loadAddresses()),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off_outlined,
                        size: 64,
                        color: theme.hintColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No addresses yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first delivery address',
                        style: TextStyle(color: theme.hintColor),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _addresses.length,
                  itemBuilder: (context, i) {
                    final addr = _addresses[i];
                    return _buildAddressCard(addr, theme);
                  },
                ),
    );
  }

  Widget _buildAddressCard(Address address, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: address.isDefault ? theme.colorScheme.primary : theme.dividerColor,
          width: address.isDefault ? 2 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          address.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (address.isDefault)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      address.street,
                      style: TextStyle(color: theme.hintColor, fontSize: 13),
                    ),
                    Text(
                      '${address.city}, ${address.state} ${address.zipCode}',
                      style: TextStyle(color: theme.hintColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Edit'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditAddressPage(api: widget.api, address: address),
                        ),
                      ).then((_) => _loadAddresses());
                    },
                  ),
                  PopupMenuItem(
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    onTap: () => _showDeleteConfirm(address),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Add/Edit Address Page
class AddAddressPage extends StatefulWidget {
  const AddAddressPage({super.key, required this.api});
  final AuthedApiClient api;

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _labelController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _labelController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_labelController.text.isEmpty ||
        _streetController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _stateController.text.isEmpty ||
        _zipController.text.isEmpty) {
      _showError('All fields are required');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.api.addAddress(
        label: _labelController.text,
        street: _streetController.text,
        city: _cityController.text,
        state: _stateController.text,
        zipCode: _zipController.text,
        country: 'Cambodia',
        isDefault: _isDefault,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError(_parseAddressError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  String _parseAddressError(String error) {
    if (error.contains('duplicate key') && error.contains('label')) {
      return 'An address with this label already exists.';
    }
    return error.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Address')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildField(_labelController, 'Label (Home, Work, etc)',
                Icons.label_outline),
            const SizedBox(height: 16),
            _buildField(_streetController, 'Street Address', Icons.location_on_outlined),
            const SizedBox(height: 16),
            _buildField(_cityController, 'City', Icons.location_city_outlined),
            const SizedBox(height: 16),
            _buildField(_stateController, 'State/Province', Icons.map_outlined),
            const SizedBox(height: 16),
            _buildField(_zipController, 'Zip/Postal Code', Icons.mail_outline),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _isDefault,
              onChanged: (val) => setState(() => _isDefault = val ?? false),
              title: const Text('Set as default address'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      )
                    : const Text('Add Address',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      enabled: !_isLoading,
    );
  }
}

// Edit Address Page
class EditAddressPage extends StatefulWidget {
  const EditAddressPage({super.key, required this.api, required this.address});
  final AuthedApiClient api;
  final Address address;

  @override
  State<EditAddressPage> createState() => _EditAddressPageState();
}

class _EditAddressPageState extends State<EditAddressPage> {
  late TextEditingController _labelController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;
  late bool _isDefault;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.address.label);
    _streetController = TextEditingController(text: widget.address.street);
    _cityController = TextEditingController(text: widget.address.city);
    _stateController = TextEditingController(text: widget.address.state);
    _zipController = TextEditingController(text: widget.address.zipCode);
    _isDefault = widget.address.isDefault;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _updateAddress() async {
    setState(() => _isLoading = true);
    try {
      await widget.api.updateAddress(
        id: widget.address.id,
        label: _labelController.text,
        street: _streetController.text,
        city: _cityController.text,
        state: _stateController.text,
        zipCode: _zipController.text,
        country: widget.address.country,
        isDefault: _isDefault,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address updated'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError(_parseAddressError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  String _parseAddressError(String error) {
    if (error.contains('duplicate key') && error.contains('label')) {
      return 'An address with this label already exists.';
    }
    return error.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Address')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildField(_labelController, 'Label'),
            const SizedBox(height: 16),
            _buildField(_streetController, 'Street'),
            const SizedBox(height: 16),
            _buildField(_cityController, 'City'),
            const SizedBox(height: 16),
            _buildField(_stateController, 'State'),
            const SizedBox(height: 16),
            _buildField(_zipController, 'Zip Code'),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _isDefault,
              onChanged: (val) => setState(() => _isDefault = val ?? false),
              title: const Text('Default address'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      )
                    : const Text('Update Address',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      enabled: !_isLoading,
    );
  }
}
