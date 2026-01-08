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
  PriceType _selectedPriceType = PriceType.voluntary;
  List<PaymentMethod> _selectedPayments = [PaymentMethod.cash, PaymentMethod.transfer];
  bool _isLoading = false;
  bool _isGettingLocation = false;
  double? _latitude;
  double? _longitude;
  double? _distanceKm;
  PriceEstimate? _priceEstimate;
  bool _useEstimatedPrice = false;
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
                  const SizedBox(height: 24),
                  _buildIllustration(),
                  const SizedBox(height: 24),
                  _buildCategorySelector(),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _titleController,
                    label: 'Judul Permintaan',
                    hint: 'Contoh: Titip beli kopi Starbucks dong!',
                    icon: Icons.title,
                    validator: (v) => v?.isEmpty ?? true ? 'Judul wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _descriptionController,
                    label: 'Deskripsi',
                    hint: 'Jelaskan detail bantuan yang kamu butuhkan...',
                    icon: Icons.description,
                    maxLines: 3,
                    validator: (v) => v?.isEmpty ?? true ? 'Deskripsi wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildLocationField(),
                  const SizedBox(height: 24),
                  _buildPriceSection(),
                  if (_priceEstimate != null && !_priceEstimate!.isFreeCategory) ...[
                    const SizedBox(height: 16),
                    _buildPriceEstimateCard(),
                  ],
                  const SizedBox(height: 24),
                  _buildPaymentMethodSection(),
                  const SizedBox(height: 32),
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
    final textSecondary = AppTheme.getTextSecondary(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Tulong ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.secondaryColor, Color(0xFFFF8BA7)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Minta Bantuan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Ceritakan apa yang kamu butuhkan, komunitas siap membantu!', style: TextStyle(fontSize: 14, color: textSecondary)),
      ],
    );
  }

  Widget _buildIllustration() {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.secondaryColor.withValues(alpha: 0.1), AppTheme.primaryColor.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.handshake_rounded, size: 32, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Jangan ragu minta bantuan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 4),
                Text('Ongkos bisa nego atau seikhlasnya kok! 😊', style: TextStyle(fontSize: 12, color: textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    final textPrimary = AppTheme.getTextPrimary(context);
    final cardColor = AppTheme.getCardColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pilih Kategori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(DummyData.categories.length, (index) {
            final category = DummyData.categories[index];
            final isSelected = _selectedCategory == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Color(category['color']) : cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? Color(category['color']) : (isDark ? Colors.grey.shade700 : Colors.grey.shade200)),
                  boxShadow: isSelected ? [BoxShadow(color: Color(category['color']).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(category['icon'] as IconData, size: 18, color: isSelected ? Colors.white : Color(category['color'])),
                    const SizedBox(width: 6),
                    Text(category['name'], style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
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
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            validator: validator,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
              prefixIcon: Icon(icon, color: AppTheme.primaryColor),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
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
            Text('Lokasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
            const SizedBox(width: 8),
            if (_latitude != null && _longitude != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 12, color: AppTheme.accentColor),
                    const SizedBox(width: 4),
                    Text('GPS Aktif', style: TextStyle(fontSize: 10, color: AppTheme.accentColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: TextFormField(
            controller: _locationController,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              hintText: 'Contoh: Kemang, Jakarta Selatan',
              hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
              prefixIcon: Icon(Icons.location_on, color: AppTheme.primaryColor),
              suffixIcon: _isGettingLocation
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : IconButton(
                      icon: Icon(Icons.my_location, color: AppTheme.primaryColor),
                      onPressed: _getCurrentLocation,
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _getCurrentLocation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.gps_fixed, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Text('Gunakan lokasi saat ini', style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
              ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.payments_outlined, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text('Ongkos Bantuan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Pilih cara menentukan ongkos untuk penolong',
          style: TextStyle(fontSize: 12, color: textSecondary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPriceTypeChip(PriceType.voluntary, 'Seikhlasnya', Icons.volunteer_activism, AppTheme.primaryColor),
            _buildPriceTypeChip(PriceType.free, 'Gratis', Icons.favorite, AppTheme.accentColor),
            if (_priceEstimate != null && !_priceEstimate!.isFreeCategory)
              _buildEstimatedPriceChip(),
            _buildPriceTypeChip(PriceType.fixed, 'Tentukan Sendiri', Icons.edit, const Color(0xFFFF9F43)),
          ],
        ),
        if (_selectedPriceType == PriceType.fixed) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: TextFormField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Masukkan nominal ongkos',
                hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Text('Rp', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 16)),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEstimatedPriceChip() {
    final isSelected = _useEstimatedPrice;
    final chipColor = const Color(0xFF54A0FF);
    return GestureDetector(
      onTap: () {
        setState(() {
          _useEstimatedPrice = true;
          _selectedPriceType = PriceType.negotiable;
          if (_priceEstimate?.suggestedPrice != null) {
            _budgetController.text = _priceEstimate!.suggestedPrice!.toInt().toString();
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? chipColor : Colors.grey.shade200),
          boxShadow: isSelected ? [BoxShadow(color: chipColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 18, color: isSelected ? Colors.white : chipColor),
            const SizedBox(width: 6),
            Text('Pakai Estimasi', style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : AppTheme.textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceEstimateCard() {
    if (_priceEstimate == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF54A0FF).withValues(alpha: 0.15), const Color(0xFF54A0FF).withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF54A0FF).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF54A0FF).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calculate, color: Color(0xFF54A0FF), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Estimasi Ongkos', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    Text(
                      _priceEstimate!.displayRange,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF54A0FF)),
                    ),
                  ],
                ),
              ),
              if (_distanceKm != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.near_me, size: 14, color: Color(0xFF54A0FF)),
                      const SizedBox(width: 4),
                      Text(
                        '~${_distanceKm!.toStringAsFixed(1)} km',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF54A0FF), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _priceEstimate!.message,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          // Heavy item toggle for relevant categories
          if (_shouldShowHeavyItemOption())
            GestureDetector(
              onTap: () {
                setState(() {
                  _isHeavyItem = !_isHeavyItem;
                  _updatePriceEstimate();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _isHeavyItem ? const Color(0xFFFF9F43).withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isHeavyItem ? const Color(0xFFFF9F43) : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isHeavyItem ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 18,
                      color: _isHeavyItem ? const Color(0xFFFF9F43) : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Barang berat (+Rp 5rb)',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isHeavyItem ? const Color(0xFFFF9F43) : AppTheme.textSecondary,
                        fontWeight: _isHeavyItem ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showPriceTableDialog(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 14, color: AppTheme.primaryColor),
                const SizedBox(width: 4),
                Text(
                  'Lihat tabel harga',
                  style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
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

  Widget _buildPriceTypeChip(PriceType type, String label, IconData icon, Color chipColor) {
    final isSelected = _selectedPriceType == type && !_useEstimatedPrice;
    final textPrimary = AppTheme.getTextPrimary(context);
    final cardColor = AppTheme.getCardColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPriceType = type;
          _useEstimatedPrice = false;
          if (type == PriceType.free || type == PriceType.voluntary) _budgetController.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? chipColor : (isDark ? Colors.grey.shade700 : Colors.grey.shade200)),
          boxShadow: isSelected ? [BoxShadow(color: chipColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : chipColor),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text('Metode Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildPaymentChip(PaymentMethod.cash, 'Cash', Icons.payments_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _buildPaymentChip(PaymentMethod.transfer, 'Transfer', Icons.account_balance_outlined)),
          ],
        ),
        const SizedBox(height: 8),
        Text('Pilih minimal satu metode pembayaran', style: TextStyle(fontSize: 12, color: textSecondary)),
      ],
    );
  }

  Widget _buildPaymentChip(PaymentMethod method, String label, IconData icon) {
    final isSelected = _selectedPayments.contains(method);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final cardColor = AppTheme.getCardColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected && _selectedPayments.length > 1) {
            _selectedPayments.remove(method);
          } else if (!isSelected) {
            _selectedPayments.add(method);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.grey.shade700 : Colors.grey.shade200), width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isSelected ? AppTheme.primaryColor : textSecondary),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 14, color: isSelected ? AppTheme.primaryColor : textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
            if (isSelected) ...[const SizedBox(width: 8), Icon(Icons.check_circle, size: 18, color: AppTheme.primaryColor)],
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
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send, color: Colors.white),
            SizedBox(width: 8),
            Text('Kirim Permintaan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    
    try {
      final address = await _locationService.getCurrentAddress();
      final position = _locationService.currentPosition;
      
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
      setState(() => _isGettingLocation = false);
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
            _buildConfirmRow('Pembayaran', _selectedPayments.map((p) => p == PaymentMethod.cash ? 'Cash' : 'Transfer').join(' / ')),
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
    switch (_selectedPriceType) {
      case PriceType.free: return 'Gratis';
      case PriceType.voluntary: return 'Seikhlasnya';
      case PriceType.fixed: return _budgetController.text.isNotEmpty ? 'Rp ${_budgetController.text}' : 'Seikhlasnya';
      case PriceType.negotiable: return _budgetController.text.isNotEmpty ? 'Rp ${_budgetController.text} (Nego)' : 'Nego';
    }
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
      acceptedPayments: _selectedPayments,
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
      _selectedPriceType = PriceType.voluntary;
      _selectedPayments = [PaymentMethod.cash, PaymentMethod.transfer];
      _latitude = null;
      _longitude = null;
      _distanceKm = null;
      _priceEstimate = null;
      _useEstimatedPrice = false;
      _isHeavyItem = false;
    });
  }
}
