import 'package:flutter/material.dart';

import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _groqKeyController = TextEditingController();
  bool _obscureApiKey = true;
  bool _obscureGroqKey = true;
  bool _isTesting = false;
  bool _isTestingGroq = false;
  String? _testMessage;
  bool? _testSuccess;
  String? _groqTestMessage;
  bool? _groqTestSuccess;

  int _dailyGoal = 2000;

  @override
  void initState() {
    super.initState();
    _apiKeyController.text = StorageService.getApiKey();
    _groqKeyController.text = StorageService.getGroqApiKey();
    _dailyGoal = StorageService.getDailyCalorieGoal();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _groqKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    await StorageService.saveApiKey(key);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gemini API Anahtarı başarıyla kaydedildi!'),
          backgroundColor: AppTheme.primaryEmerald,
        ),
      );
      setState(() {});
    }
  }

  Future<void> _testApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _testSuccess = false;
        _testMessage = 'Lütfen önce bir API anahtarı girin.';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testMessage = null;
    });

    final success = await GeminiService.testApiKey(key);

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = success;
        _testMessage = success
            ? 'Bağlantı Başarılı! Gemini API aktif ve çalışıyor.'
            : 'Bağlantı Başarısız! Lütfen anahtarınızı kontrol edin.';
      });
    }
  }

  Future<void> _saveGroqKey() async {
    final key = _groqKeyController.text.trim();
    await StorageService.saveGroqApiKey(key);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Groq API Anahtarı başarıyla kaydedildi!'),
          backgroundColor: AppTheme.primaryEmerald,
        ),
      );
      setState(() {});
    }
  }

  Future<void> _testGroqKey() async {
    final key = _groqKeyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _groqTestSuccess = false;
        _groqTestMessage = 'Lütfen önce bir Groq anahtarı girin.';
      });
      return;
    }

    setState(() {
      _isTestingGroq = true;
      _groqTestMessage = null;
    });

    final success = await GeminiService.testApiKey(key, provider: 'groq');

    if (mounted) {
      setState(() {
        _isTestingGroq = false;
        _groqTestSuccess = success;
        _groqTestMessage = success
            ? 'Bağlantı Başarılı! Groq API aktif ve çalışıyor.'
            : 'Bağlantı Başarısız! Lütfen anahtarınızı kontrol edin.';
      });
    }
  }

  Future<void> _updateDailyGoal(int newGoal) async {
    await StorageService.saveDailyCalorieGoal(newGoal);
    setState(() {
      _dailyGoal = newGoal;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Günlük kalori hedefi $newGoal kcal olarak güncellendi!',
          ),
          backgroundColor: AppTheme.primaryEmerald,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showCustomGoalDialog() {
    final controller = TextEditingController(text: _dailyGoal.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text(
          'Özel Kalori Hedefi',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Hedef Kalori (kcal)',
            suffixText: 'kcal',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 500 && val < 10000) {
                _updateDailyGoal(val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text(
          'Verileri Sıfırla',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Tüm kaydedilmiş öğünleriniz silinecek. Bu işlem geri alınamaz. Emin misiniz?',
          style: TextStyle(color: Color(0xFFCBD5E1)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tümünü Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearAllMeals();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tüm öğün verileri temizlendi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConfigured = GeminiService.hasApiKey();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Ayarlar & Yapay Zeka')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section 1: Gemini API Configuration
          _buildSectionHeader('GEMINI API AYARLARI', Icons.smart_toy_rounded),
          const SizedBox(height: 12),
          GlassPanel(
            radius: 24,
            padding: const EdgeInsets.all(18),
            borderColor: isConfigured
                ? AppTheme.primaryEmerald.withValues(alpha: 0.5)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gemini API Anahtarı',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isConfigured
                            ? AppTheme.primaryEmerald.withValues(alpha: 0.15)
                            : const Color(0xFFEF4444).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isConfigured ? 'Aktif' : 'Tanımsız',
                        style: TextStyle(
                          color: isConfigured
                              ? AppTheme.primaryLight
                              : const Color(0xFFEF4444),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Google AI Studio üzerinden ücretsiz aldığınız API anahtarınızı buraya yapıştırıp kaydedebilirsiniz veya sohbette bana iletebilirsiniz.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _apiKeyController,
                  obscureText: _obscureApiKey,
                  decoration: InputDecoration(
                    hintText: 'AIzaSy...',
                    prefixIcon: const Icon(
                      Icons.vpn_key_rounded,
                      color: AppTheme.primaryEmerald,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureApiKey
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                      onPressed: () =>
                          setState(() => _obscureApiKey = !_obscureApiKey),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isTesting ? null : _testApiKey,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.wifi_protected_setup_rounded,
                                size: 18,
                              ),
                        label: const Text('Bağlantıyı Test Et'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppTheme.darkBorder),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveApiKey,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Kaydet'),
                      ),
                    ),
                  ],
                ),
                if (_testMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _testSuccess == true
                          ? AppTheme.primaryEmerald.withValues(alpha: 0.12)
                          : const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _testMessage!,
                      style: TextStyle(
                        color: _testSuccess == true
                            ? AppTheme.primaryLight
                            : const Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Section 1b: Groq API Configuration (fallback sağlayıcı)
          _buildSectionHeader(
            'GROQ API AYARLARI (YEDEK SAĞLAYICI)',
            Icons.bolt_rounded,
          ),
          const SizedBox(height: 12),
          GlassPanel(
            radius: 24,
            padding: const EdgeInsets.all(18),
            borderColor: isConfigured
                ? AppTheme.primaryEmerald.withValues(alpha: 0.5)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Groq API Anahtarı',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Yedek Aktif',
                        style: TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gemini yanıt vermezse veya kotası biterse analizler otomatik olarak Groq ile devam eder. Anahtar girmezseniz yerleşik anahtar kullanılır.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _groqKeyController,
                  obscureText: _obscureGroqKey,
                  decoration: InputDecoration(
                    hintText: 'gsk_...',
                    prefixIcon: const Icon(
                      Icons.vpn_key_rounded,
                      color: Color(0xFFF59E0B),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureGroqKey
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                      onPressed: () =>
                          setState(() => _obscureGroqKey = !_obscureGroqKey),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isTestingGroq ? null : _testGroqKey,
                        icon: _isTestingGroq
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.wifi_protected_setup_rounded,
                                size: 18,
                              ),
                        label: const Text('Bağlantıyı Test Et'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppTheme.darkBorder),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveGroqKey,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Kaydet'),
                      ),
                    ),
                  ],
                ),
                if (_groqTestMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _groqTestSuccess == true
                          ? AppTheme.primaryEmerald.withValues(alpha: 0.12)
                          : const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _groqTestMessage!,
                      style: TextStyle(
                        color: _groqTestSuccess == true
                            ? AppTheme.primaryLight
                            : const Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Section 2: Daily Calorie Target
          _buildSectionHeader('GÜNLÜK HEDEF', Icons.track_changes_rounded),
          const SizedBox(height: 12),
          GlassPanel(
            radius: 24,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Günlük Kalori Hedefi',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '$_dailyGoal kcal',
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildGoalPresetChip('1800 (Diyet)', 1800),
                    _buildGoalPresetChip('2000 (Denge)', 2000),
                    _buildGoalPresetChip('2300 (Aktif)', 2300),
                    _buildGoalPresetChip('2600 (Kilo Alma)', 2600),
                    ActionChip(
                      label: const Text('Özel Hedef...'),
                      avatar: const Icon(Icons.edit, size: 14),
                      onPressed: _showCustomGoalDialog,
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                      side: const BorderSide(color: AppTheme.glassBorder),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Section 3: Data Management & About
          _buildSectionHeader('VERİ & HAKKINDA', Icons.info_outline_rounded),
          const SizedBox(height: 12),
          GlassPanel(
            radius: 24,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.delete_sweep_rounded,
                    color: Color(0xFFEF4444),
                  ),
                  title: const Text(
                    'Öğün Geçmişini Sıfırla',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Tüm kaydedilmiş yemekleri siler',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  onTap: _clearAllData,
                ),
                const Divider(color: AppTheme.darkBorder, height: 1),
                const ListTile(
                  leading: Icon(
                    Icons.auto_awesome_rounded,
                    color: AppTheme.primaryEmerald,
                  ),
                  title: Text(
                    'Model: Gemini 3.1 Flash-Lite + Groq',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Otomatik yedekli multimodal vision API',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ),
                const Divider(color: AppTheme.darkBorder, height: 1),
                const ListTile(
                  leading: Icon(
                    Icons.verified_user_rounded,
                    color: Color(0xFF38BDF8),
                  ),
                  title: Text(
                    'KaloriHesapla v1.0.0',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Flutter ile Geliştirildi',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalPresetChip(String label, int goal) {
    final isSelected = _dailyGoal == goal;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryEmerald,
      backgroundColor: AppTheme.darkCardElevated,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) _updateDailyGoal(goal);
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryEmerald, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
