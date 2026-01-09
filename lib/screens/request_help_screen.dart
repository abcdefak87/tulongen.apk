import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../data/dummy_data.dart';
import '../models/help_request.dart';
import '../utils/currency_formatter.dart';
import '../widgets/loading_overlay.dart';
import '../services/location_service.dart';
import '../services/pricing_service.dart';
import '../services/firestore_service.dart';

class RequestHelpScreen extends StatefulWidget {
  const RequestHelpScreen({super.key});

  @override
  State<RequestHelpScreen> createState() => _RequestHelpScreenState();
}

class _RequestHelpScreenState extends State<RequestHelpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationService = LocationService();
  final _pricingService = PricingService();
  final _firestoreService = FirestoreService();
  
  int _selectedCategory = 0;
  PriceType _selectedPriceType = PriceType.negotiable;
  PaymentMethod _selectedPayment = PaymentMethod.cash;
  bool _isLoading = false;
  bool _isGettingLocation = false;
  double? _latitude;
  double? _longitude;
  double? _distanceKm;
  PriceEstimate? _priceEstimate;
  bool _isHeavyItem = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: LoadingOverlay(
          isLoading: _isLoading,
          message: 'Mengirim permintaan...',
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildCategorySelector(),
                  const SizedBox(height: 18),
                  _buildInputField(
                    controller: _titleController,
                    label: 'Judul',
                    hint: 'Contoh: Titip beli makan siang',
                    icon: Icons.edit_outlined,
                    validator: (v) => v?.isEmpty ?? true ? 'Judul wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),
                  _buildInputField(
                    controller: _descriptionController,
                    label: 'Deskripsi',
                    hint: 'Jelaskan detail yang dibutuhkan',
                    icon: Icons.notes_outlined,
                    maxLines: 3,
                    validator: (v) => v?.isEmpty ?? true ? 'Deskripsi wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),
                  _buildLocationField(),
                  const SizedBox(height: 18),
                  _buildPriceSection(),
                  const SizedBox(height: 18),
                  _buildPaymentMethodSection(),
                  const SizedBox(height: 28),
                  _buildSubmitButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final textPrimary = AppTheme.getTextPrimary(context);
    
    return Text('Minta Bantuan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary));
  }

  Widget _buildCategorySelector() {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final cardColor = AppTheme.getCardColor(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(DummyData.categories.length, (index) {
            final category = DummyData.categories[index];
            final isSelected = _selectedCategory == index;
            final color = Color(category['color']);
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? color : cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? color : AppTheme.getBorderColor(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(category['icon'] as IconData, size: 14, color: isSelected ? Colors.white : color),
                    const SizedBox(width: 5),
                    Text(category['name'], style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : textPrimary)),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final cardColor = AppTheme.getCardColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.getBorderColor(context)),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            validator: validator,
            style: TextStyle(color: textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5), fontSize: 14),
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 12, right: 8, top: maxLines > 1 ? 14 : 0),
                child: Icon(icon, color: textSecondary, size: 20),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(
                left: 0,
                right: 14,
                top: maxLines > 1 ? 14 : 12,
                bottom: maxLines > 1 ? 14 : 12,
              ),
              alignLabelWithHint: maxLines > 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final cardColor = AppTheme.getCardColor(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Lokasi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
            const SizedBox(width: 8),
            if (_latitude != null && _longitude != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 10, color: AppTheme.accentColor),
                    const SizedBox(width: 3),
                    Text('GPS', style: TextStyle(fontSize: 10, color: AppTheme.accentColor, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.getBorderColor(context)),
          ),
          child: TextFormField(
            controller: _locationController,
            style: TextStyle(color: textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Contoh: Kemang, Jakarta Selatan',
              hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5), fontSize: 14),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(Icons.location_on_outlined, color: textSecondary, size: 20),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: _isGettingLocation
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : IconButton(
                      icon: Icon(Icons.my_location, color: AppTheme.primaryColor, size: 20),
                      onPressed: _getCurrentLocation,
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final cardColor = AppTheme.getCardColor(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ongkos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildPriceTypeChip(PriceType.negotiable, 'Nego')),
            const SizedBox(width: 10),
            Expanded(child: _buildPriceTypeChip(PriceType.fixed, 'Sesuai Jarak')),
          ],
        ),
        if (_selectedPriceType == PriceType.fixed) ...[
          const SizedBox(height: 10),
          _buildPriceEstimateCard(),
        ],
      ],
    );
  }

  Widget _buildPriceTypeChip(PriceType type, String label) {
    final isSelected = _selectedPriceType == type;
    final textPrimary = AppTheme.getTextPrimary(context);
    final cardColor = AppTheme.getCardColor(context);
    final chipColor = type == PriceType.negotiable ? AppTheme.primaryColor : const Color(0xFF54A0FF);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPriceType = type;
          if (type == PriceType.fixed && _latitude != null) {
            _calculatePriceEstimate();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withValues(alpha: 0.1) : cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? chipColor : AppTheme.getBorderColor(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Icon(Icons.check, size: 16, color: chipColor),
              const SizedBox(width: 6),
            ],
            Text(label, style: TextStyle(fontSize: 13, color: isSelected ? chipColor : textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceEstimateCard() {
    final textSecondary = AppTheme.getTextSecondary(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final cardColor = AppTheme.getCardColor(context);
    
    if (_priceEstimate == null && _latitude == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.getBorderColor(context)),
        ),
        child: Text('Aktifkan GPS untuk melihat estimasi ongkos', style: TextStyle(fontSize: 12, color: textSecondary, fontStyle: FontStyle.italic)),
      );
    }
    
    if (_priceEstimate == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estimasi ongkos', style: TextStyle(fontSize: 12, color: textSecondary)),
              if (_distanceKm != null)
                Text('~${_distanceKm!.toStringAsFixed(1)} km', style: TextStyle(fontSize: 11, color: textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(_priceEstimate!.displayRange, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
          if (_shouldShowHeavyItemOption()) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isHeavyItem = !_isHeavyItem;
                  _updatePriceEstimate();
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isHeavyItem ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 16,
                    color: _isHeavyItem ? const Color(0xFFFF9F43) : textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text('Barang berat (+Rp 5rb)', style: TextStyle(fontSize: 11, color: textSecondary)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _shouldShowHeavyItemOption() {
    final category = DummyData.categories[_selectedCategory]['category'] as HelpCategory;
    return category == HelpCategory.shopping || category == HelpCategory.daily;
  }

  void _showPriceTableDialog() {
    final priceTable = _pricingService.getPriceTable();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.table_chart, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Tabel Estimasi Ongkos'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Harga berdasarkan jarak, lebih murah dari ojol karena ini tolong-menolong sesama',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ...priceTable.map((range) => _buildPriceTableRow(range)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppTheme.accentColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gaming, Study, Nongkrong biasanya gratis atau seikhlasnya',
                        style: TextStyle(fontSize: 11, color: AppTheme.accentColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceTableRow(PriceRange range) {
    final surfaceColor = AppTheme.getSurfaceColor(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              range.distanceLabel,
              style: TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              range.priceLabel,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            range.label,
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }



  Widget _buildPaymentMethodSection() {
    final textPrimary = AppTheme.getTextPrimary(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pembayaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildPaymentChip(PaymentMethod.cash, 'Cash')),
            const SizedBox(width: 10),
            Expanded(child: _buildPaymentChip(PaymentMethod.transfer, 'Transfer')),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentChip(PaymentMethod method, String label) {
    final isSelected = _selectedPayment == method;
    final textPrimary = AppTheme.getTextPrimary(context);
    final cardColor = AppTheme.getCardColor(context);
    
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.08) : cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.getBorderColor(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Icon(Icons.check, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
            ],
            Text(label, style: TextStyle(fontSize: 13, color: isSelected ? AppTheme.primaryColor : textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _showConfirmDialog,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Text('Kirim Permintaan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() => _isGettingLocation = true);
    
    try {
      final address = await _locationService.getCurrentAddress();
      final position = _locationService.currentPosition;
      
      if (!mounted) return;
      
      if (address != null && position != null) {
        setState(() {
          _locationController.text = address;
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
        
        // Hitung estimasi harga berdasarkan jarak (asumsi dari lokasi user ke lokasi request)
        // Untuk demo, kita gunakan jarak random 1-10 km
        // Di production, ini akan dihitung dari lokasi penolong ke lokasi request
        await _calculatePriceEstimate();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [const Icon(Icons.location_on, color: Colors.white, size: 20), const SizedBox(width: 8), const Text('Lokasi berhasil dideteksi')]),
              backgroundColor: AppTheme.accentColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [const Icon(Icons.error_outline, color: Colors.white, size: 20), const SizedBox(width: 8), const Text('Gagal mendapatkan lokasi. Cek izin GPS.')]),
              backgroundColor: AppTheme.secondaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              action: SnackBarAction(
                label: 'Buka Pengaturan',
                textColor: Colors.white,
                onPressed: () => Geolocator.openLocationSettings(),
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  Future<void> _calculatePriceEstimate() async {
    if (_latitude == null || _longitude == null) return;
    
    final category = DummyData.categories[_selectedCategory]['category'] as HelpCategory;
    
    // Untuk demo, gunakan jarak estimasi berdasarkan lokasi
    // Di production, ini bisa dihitung dari rata-rata jarak penolong terdekat
    // atau user bisa input jarak manual
    
    // Simulasi: ambil jarak dari koordinat (simplified)
    // Asumsi: setiap 0.01 derajat ≈ 1.1 km
    final estimatedDistance = 3.0; // Default 3 km untuk demo
    
    setState(() {
      _distanceKm = estimatedDistance;
      _priceEstimate = _pricingService.calculatePrice(
        distanceKm: estimatedDistance,
        category: category,
        isHeavyItem: _isHeavyItem,
      );
    });
  }

  void _updatePriceEstimate() {
    if (_latitude == null || _longitude == null) return;
    
    final category = DummyData.categories[_selectedCategory]['category'] as HelpCategory;
    
    setState(() {
      _priceEstimate = _pricingService.calculatePrice(
        distanceKm: _distanceKm ?? 3.0,
        category: category,
        isHeavyItem: _isHeavyItem,
      );
    });
  }

  void _showConfirmDialog() {
    if (!_formKey.currentState!.validate()) return;

    final category = DummyData.categories[_selectedCategory];
    String priceInfo = _getPriceInfo();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Permintaan', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Color(category['color']).withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(category['icon'] as IconData, size: 32, color: Color(category['color'])),
            ),
            const SizedBox(height: 16),
            Text(_titleController.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            _buildConfirmRow('Kategori', category['name']),
            _buildConfirmRow('Ongkos', priceInfo),
            _buildConfirmRow('Pembayaran', _selectedPayment == PaymentMethod.cash ? 'Cash' : 'Transfer'),
            if (_locationController.text.isNotEmpty) _buildConfirmRow('Lokasi', _locationController.text),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitRequest();
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  String _getPriceInfo() {
    if (_selectedPriceType == PriceType.fixed && _priceEstimate != null) {
      return _priceEstimate!.displayRange;
    }
    return 'Nego';
  }

  void _submitRequest() async {
    setState(() => _isLoading = true);
    
    final category = DummyData.categories[_selectedCategory];
    final budget = parseCurrency(_budgetController.text)?.toDouble();
    
    final requestId = await _firestoreService.createHelpRequest(
      title: _titleController.text,
      description: _descriptionController.text,
      category: category['category'] as HelpCategory,
      priceType: _selectedPriceType,
      budget: budget,
      location: _locationController.text.isNotEmpty ? _locationController.text : null,
      latitude: _latitude,
      longitude: _longitude,
      acceptedPayments: [_selectedPayment],
    );
    
    setState(() => _isLoading = false);
    
    if (!mounted) return;
    
    if (requestId != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.accentColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.check_circle, size: 48, color: AppTheme.accentColor),
              ),
              const SizedBox(height: 16),
              const Text('Permintaan Terkirim!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              Text('Tunggu penawaran dari penolong ya!', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetForm();
                },
                child: const Text('Tutup'),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal mengirim permintaan. Coba lagi.'),
          backgroundColor: AppTheme.secondaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _budgetController.clear();
    setState(() {
      _selectedPriceType = PriceType.negotiable;
      _selectedPayment = PaymentMethod.cash;
      _latitude = null;
      _longitude = null;
      _distanceKm = null;
      _priceEstimate = null;
      _isHeavyItem = false;
    });
  }
}
