import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ai_analysis_result.dart';
import '../models/meal_item.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import 'settings_screen.dart';

class ScannerScreen extends StatefulWidget {
  final VoidCallback? onMealAdded;

  const ScannerScreen({super.key, this.onMealAdded});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _promptController = TextEditingController();

  Uint8List? _selectedImageBytes;
  String? _selectedImageMime;
  String? _selectedImageName;

  bool _isLoading = false;
  String _loadingMessage = 'Yapay zeka hazırlanıyor...';
  AiAnalysisResult? _analysisResult;
  MealType _selectedMealType = MealType.ogle;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final ext = pickedFile.name.split('.').last.toLowerCase();
        final mime = ext == 'png' ? 'image/png' : 'image/jpeg';

        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageMime = mime;
          _selectedImageName = pickedFile.name;
          _analysisResult = null; // Eski sonucu sıfırla
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf seçilirken bir hata oluştu: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageMime = null;
      _selectedImageName = null;
      _analysisResult = null;
    });
  }

  Future<void> _startAnalysis({bool forceDemo = false}) async {
    // Fotoğraf veya metin var mı kontrolü
    if (_selectedImageBytes == null && _promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir yemek fotoğrafı seçin veya yemek adını yazın.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // API Key kontrolü
    if (!forceDemo && !GeminiService.hasApiKey()) {
      _showMissingApiKeyDialog();
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Yemek taranıyor ve bileşenleri ayrıştırılıyor...';
      _analysisResult = null;
    });

    if (forceDemo) {
      // Demo simülasyonu
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) {
        setState(() {
          _isLoading = false;
          _analysisResult = GeminiService.getDemoResult(
            prompt: _promptController.text.trim().isNotEmpty
                ? _promptController.text.trim()
                : null,
          );
        });
      }
      return;
    }

    // Gerçek Gemini API Çağrısı
    final result = await GeminiService.analyzeFood(
      imageBytes: _selectedImageBytes,
      mimeType: _selectedImageMime,
      userPrompt: _promptController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _analysisResult = result;
      });

      if (!result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Analiz sırasında bir hata oluştu.'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showMissingApiKeyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.key_rounded, color: AppTheme.primaryEmerald),
            SizedBox(width: 8),
            Text('Gemini API Anahtarı', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Yapay zeka analizini kullanabilmek için Gemini API anahtarınızı girmeniz gerekmektedir.\n\nŞimdi Ayarlar sayfasından anahtarınızı ekleyebilir veya arayüzü test etmek için Demo Modunu kullanabilirsiniz.',
          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startAnalysis(forceDemo: true);
            },
            child: const Text('Demo Olarak Dene', style: TextStyle(color: AppTheme.carbsColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ).then((_) => setState(() {}));
            },
            child: const Text('Ayarlara Git'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToDiary() async {
    if (_analysisResult == null || !_analysisResult!.isSuccess) return;

    final newMeal = MealItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _analysisResult!.foodName,
      calories: _analysisResult!.calories,
      protein: _analysisResult!.protein,
      carbs: _analysisResult!.carbs,
      fat: _analysisResult!.fat,
      fiber: _analysisResult!.fiber,
      portion: _analysisResult!.portion,
      mealType: _selectedMealType,
      healthScore: _analysisResult!.healthScore,
      healthTip: _analysisResult!.advice,
      ingredients: _analysisResult!.ingredients,
      dateTime: DateTime.now(),
    );

    await StorageService.addMeal(newMeal);
    widget.onMealAdded?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text('${newMeal.name} günlüğünüze kaydedildi!'),
            ],
          ),
          backgroundColor: AppTheme.primaryEmerald,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Yemek Tarayıcı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'API Ayarları',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ).then((_) => setState(() {}));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Resim Alanı
            _buildImagePickerBox(),
            const SizedBox(height: 16),

            // Opsiyonel Not Girişi
            TextField(
              controller: _promptController,
              decoration: InputDecoration(
                hintText: 'Ekstra bilgi veya yemek adı (Örn: 1 kase mercimek, az yağlı)...',
                prefixIcon: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryEmerald),
                suffixIcon: _promptController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _promptController.clear()),
                      )
                    : null,
              ),
              maxLines: 2,
              minLines: 1,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            // Analiz Butonu
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _startAnalysis(),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  _isLoading ? _loadingMessage : 'Yapay Zeka ile Kalori Hesapla',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryEmerald,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            if (!GeminiService.hasApiKey() && !_isLoading) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () => _startAnalysis(forceDemo: true),
                  icon: const Icon(Icons.play_circle_outline, size: 18, color: AppTheme.carbsColor),
                  label: const Text(
                    'API anahtarsız Demo Sonucu Dene',
                    style: TextStyle(color: AppTheme.carbsColor, fontSize: 13),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Analiz Sonuç Kartı
            if (_analysisResult != null && _analysisResult!.isSuccess)
              _buildAnalysisResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerBox() {
    if (_selectedImageBytes != null) {
      return Stack(
        children: [
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryEmerald, width: 2),
              image: DecorationImage(
                image: MemoryImage(_selectedImageBytes!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.7),
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: _removeSelectedImage,
                tooltip: 'Fotoğrafı Kaldır',
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.primaryEmerald, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _selectedImageName ?? 'Görsel Seçildi',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return GlassPanel(
      radius: 24,
      padding: EdgeInsets.zero,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: AppTheme.primaryEmerald,
              size: 38,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Yemek Fotoğrafı Yükleyin',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gemini Vision tabağınızdaki yemeği otomatik tanır',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_rounded, size: 18),
                label: const Text('Kamera'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.darkBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded, size: 18),
                label: const Text('Galeri'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResultCard() {
    final result = _analysisResult!;

    Color scoreColor;
    if (result.healthScore >= 8) {
      scoreColor = AppTheme.scoreHigh;
    } else if (result.healthScore >= 5) {
      scoreColor = AppTheme.scoreMid;
    } else {
      scoreColor = AppTheme.scoreLow;
    }

    return GlassPanel(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppTheme.primaryEmerald, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'AI ANALİZ SONUCU',
                    style: TextStyle(
                      color: AppTheme.primaryEmerald,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scoreColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_rounded, color: scoreColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Sağlık: ${result.healthScore}/10',
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Food Name & Portion
          Text(
            result.foodName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tahmini Porsiyon: ${result.portion}',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 18),

          // Total Calorie Highlight
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryEmerald.withValues(alpha: 0.22),
                  AppTheme.primaryEmerald.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.45)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded, color: AppTheme.carbsColor, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Toplam Kalori',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  '${result.calories} kcal',
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Macro Breakdown Grid
          Row(
            children: [
              Expanded(child: _buildMacroBadge('Protein', '${result.protein}g', AppTheme.proteinColor)),
              const SizedBox(width: 8),
              Expanded(child: _buildMacroBadge('Karb.', '${result.carbs}g', AppTheme.carbsColor)),
              const SizedBox(width: 8),
              Expanded(child: _buildMacroBadge('Yağ', '${result.fat}g', AppTheme.fatColor)),
              const SizedBox(width: 8),
              Expanded(child: _buildMacroBadge('Lif', '${result.fiber}g', AppTheme.fiberColor)),
            ],
          ),
          const SizedBox(height: 18),

          // Dietitian Advice / Evaluation
          if (result.advice.isNotEmpty) ...[
            const Text(
              'Diyetisyen & AI Değerlendirmesi',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Text(
                result.advice,
                style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Ingredients Chips
          if (result.ingredients.isNotEmpty) ...[
            const Text(
              'Tespit Edilen İçerikler',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: result.ingredients.map((ing) {
                return Chip(
                  label: Text(ing, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                  backgroundColor: AppTheme.darkCardElevated,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(color: AppTheme.darkBorder),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Meal Type Selector
          const Text(
            'Hangi Öğüne Eklensin?',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: MealType.values.map((type) {
              final isSelected = _selectedMealType == type;
              return ChoiceChip(
                label: Text('${type.iconAssetOrEmoji} ${type.displayName}'),
                selected: isSelected,
                selectedColor: AppTheme.primaryEmerald,
                backgroundColor: AppTheme.darkCardElevated,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  if (selected) setState(() => _selectedMealType = type);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saveToDiary,
              icon: const Icon(Icons.bookmark_add_rounded),
              label: const Text('Günlüğüme Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryEmerald,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
