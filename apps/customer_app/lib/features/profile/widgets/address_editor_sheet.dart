import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/delivery_address.dart';
import '../../location/pages/map_picker_page.dart';

/// Bottom-sheet editor for creating or updating a saved delivery address
/// with landmark validation and interactive GPS/Map pin picking.
Future<DeliveryAddress?> showAddressEditorSheet(
  BuildContext context, {
  DeliveryAddress? initial,
  required String defaultPhone,
  required String defaultRecipientName,
}) {
  return showModalBottomSheet<DeliveryAddress>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => _AddressEditorSheet(
      initial: initial,
      defaultPhone: defaultPhone,
      defaultRecipientName: defaultRecipientName,
    ),
  );
}

class _AddressEditorSheet extends StatefulWidget {
  const _AddressEditorSheet({
    this.initial,
    required this.defaultPhone,
    required this.defaultRecipientName,
  });

  final DeliveryAddress? initial;
  final String defaultPhone;
  final String defaultRecipientName;

  @override
  State<_AddressEditorSheet> createState() => _AddressEditorSheetState();
}

class _AddressEditorSheetState extends State<_AddressEditorSheet> {
  static const List<String> _labels = <String>[
    'বাসা',
    'অফিস',
    'কলেজ / মেস',
    'অন্যান্য',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _recipientController;
  late final TextEditingController _areaController;
  late final TextEditingController _landmarkController;
  late final TextEditingController _noteController;

  late String _label;
  late String _zone;
  late bool _isDefault;
  double? _lat;
  double? _lng;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final DeliveryAddress? init = widget.initial;
    _label = init?.label ?? _labels.first;
    _zone = (init != null && AppConstants.serviceZones.contains(init.zone))
        ? init.zone
        : AppConstants.defaultZone;
    _isDefault = init?.isDefault ?? true;
    _lat = init?.latitude;
    _lng = init?.longitude;
    _recipientController = TextEditingController(
      text: init?.recipientName.isNotEmpty == true
          ? init!.recipientName
          : widget.defaultRecipientName,
    );
    _areaController = TextEditingController(text: init?.area ?? '');
    _landmarkController = TextEditingController(text: init?.landmark ?? '');
    _noteController = TextEditingController(text: init?.note ?? '');
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _detectGps() async {
    setState(() => _locating = true);
    try {
      final GpsFix fix = await LocationService.fetchCurrentGps();
      if (!mounted) return;
      setState(() {
        _lat = fix.latitude;
        _lng = fix.longitude;
        _zone = fix.zone;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GPS শনাক্ত হয়েছে • ${fix.zone}')),
      );
    } on LocationFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _openMapPicker() async {
    final PickedLocation? picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute<PickedLocation>(
        builder: (_) => MapPickerPage(
          initialLatitude: _lat,
          initialLongitude: _lng,
          initialZone: _zone,
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _lat = picked.latitude;
        _lng = picked.longitude;
        _zone = picked.zone;
      });
    }
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      DeliveryAddress(
        id: widget.initial?.id,
        label: _label,
        recipientName: _recipientController.text.trim(),
        phone: widget.initial?.phone.isNotEmpty == true
            ? widget.initial!.phone
            : widget.defaultPhone,
        zone: _zone,
        area: _areaController.text.trim(),
        landmark: _landmarkController.text.trim(),
        note: _noteController.text.trim(),
        latitude: _lat,
        longitude: _lng,
        isDefault: _isDefault,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.initial == null
                      ? 'নতুন ঠিকানা যোগ করুন'
                      : 'ঠিকানা সম্পাদনা করুন',
                  style: text.titleLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _labels.map((String item) {
                    final bool selected = _label == item;
                    return ChoiceChip(
                      label: Text(item),
                      selected: selected,
                      selectedColor: AppColors.primarySoft,
                      labelStyle: TextStyle(
                        color: selected
                            ? AppColors.primaryDeep
                            : AppColors.slate60,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      onSelected: (_) => setState(() => _label = item),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primarySoft),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.gps_fixed_rounded,
                            size: 18,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _lat != null && _lng != null
                                  ? 'পিন সেট: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}'
                                  : 'GPS বা ম্যাপ থেকে নির্ভুল পিন যোগ করুন',
                              style: text.bodySmall?.copyWith(
                                color: AppColors.primaryDeep,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 40),
                                backgroundColor: AppColors.surface,
                              ),
                              onPressed: _locating ? null : _detectGps,
                              icon: _locating
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.my_location_rounded,
                                      size: 16,
                                    ),
                              label: const Text('GPS নিন'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 40),
                              ),
                              onPressed: _openMapPicker,
                              icon: const Icon(Icons.map_rounded, size: 16),
                              label: const Text('ম্যাপে বাছুন'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _zone,
                  decoration: const InputDecoration(labelText: 'এলাকা / জোন'),
                  items: AppConstants.serviceZones
                      .map(
                        (String z) =>
                            DropdownMenuItem<String>(value: z, child: Text(z)),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    if (value != null) setState(() => _zone = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _recipientController,
                  decoration: const InputDecoration(
                    labelText: 'প্রাপকের নাম',
                    hintText: 'যেমন: রফিকুল ইসলাম',
                  ),
                  validator: (String? v) =>
                      (v ?? '').trim().isEmpty ? 'নাম লিখুন' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _areaController,
                  decoration: const InputDecoration(
                    labelText: 'রাস্তা / পাড়া / গ্রাম',
                    hintText: 'যেমন: কলেজ রোড, ২য় গলি',
                  ),
                  validator: (String? v) =>
                      (v ?? '').trim().isEmpty ? 'এলাকার নাম লিখুন' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _landmarkController,
                  decoration: const InputDecoration(
                    labelText: 'ল্যান্ডমার্ক (আবশ্যক)',
                    hintText: 'যেমন: সোনালী ব্যাংকের পেছনে',
                    prefixIcon: Icon(
                      Icons.flag_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  validator: (String? v) =>
                      (v ?? '').trim().isEmpty ? 'ল্যান্ডমার্ক লিখুন' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'অতিরিক্ত নির্দেশনা (ঐচ্ছিক)',
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.primary,
                  title: const Text('ডিফল্ট ঠিকানা হিসেবে সেট করুন'),
                  value: _isDefault,
                  onChanged: (bool value) => setState(() => _isDefault = value),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'ঠিকানা সেভ করুন',
                  icon: Icons.save_outlined,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
