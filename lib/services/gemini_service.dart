import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/ai_analysis_result.dart';
import 'storage_service.dart';

/// Çift sağlayıcılı AI servisi.
/// Önce Gemini'yi dener; hata, kota dolumu veya zaman aşımında Groq'a düşer.
class GeminiService {
  // ===========================================================================
  // API ANAHTARLARI
  // ===========================================================================
  // API anahtarları güvenlik için kaynak koda gömülmez.
  static const String defaultGeminiKey = '';
  static const String defaultGroqKey = '';

  // ===========================================================================
  // MODELLER (en düşük / en hızlı seviye)
  // ===========================================================================
  static const String modelName = 'gemini-3.1-flash-lite';
  static const String visionModelName = 'gemini-3.1-flash-lite';

  static const String groqTextModel = 'openai/gpt-oss-20b';
  static const String groqVisionModel = 'qwen/qwen3.8-27b';

  static const Duration _timeout = Duration(seconds: 20);

  /// Aktif Gemini anahtarını getirir
  static String getActiveApiKey() {
    final savedKey = StorageService.getApiKey();
    if (savedKey.isNotEmpty) return savedKey;
    return defaultGeminiKey;
  }

  /// Aktif Groq anahtarını getirir
  static String getGroqKey() {
    final savedKey = StorageService.getGroqApiKey();
    if (savedKey.isNotEmpty) return savedKey;
    return defaultGroqKey;
  }

  static bool hasApiKey() {
    return getActiveApiKey().isNotEmpty || getGroqKey().isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // KULLANICI PROFİLİ EDİNİMİ
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>?> requestUserProfile() async {
    const systemInstruction = '''
Sen bir diyetisyen asistanısın. Kullanıcıdan temel sağlık bilgilerini al ve SADECE aşağıdaki JSON şemasına uygun bir JSON nesnesi üret. JSON dışında hiçbir metin, açıklama veya markdown ekleme.

{
  "name": "Kullanıcının adı soyadı",
  "age": 25,
  "gender": "Erkek",
  "height": 175,
  "weight": 70.0,
  "targetWeight": 68.0,
  "waterGoalMl": 2500,
  "activityLevel": 2
}

activityLevel değerleri: 0=Hareketsiz, 1=Az hareketli, 2=Orta, 3=Aktif, 4=Profesyonel sporcu
Eğer kullanıcı bilgi girmezse makul varsayılan değerler kullan.
Yanıt sadece geçerli JSON olmalı.
''';

    final raw = await _requestWithFallback(
      prompt: systemInstruction,
      temperature: 0.1,
      jsonMode: true,
    );
    if (raw == null) return null;

    try {
      String clean = _stripFences(raw);
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // YEMEK FOTOĞRAFI ANALİZİ
  // ---------------------------------------------------------------------------
  static Future<AiAnalysisResult> analyzeFood({
    Uint8List? imageBytes,
    String? mimeType,
    String? userPrompt,
  }) async {
    const systemInstruction = '''
Sen uzman bir klinik diyetisyen ve beslenme uzmanısın.
Görevin: Kullanıcının gönderdiği yemek görselini ve/veya açıklamasını analiz ederek kalori ve besin değerlerini hassas bir şekilde hesaplamak.
Yanıtını MUTLAKA ve SADECE aşağıdaki JSON şemasına uygun olarak üret. JSON dışında hiçbir karşılama, selamlama veya markdown tırnağı yazma:

{
  "yemek_adi": "Tanımlanan yemeğin adı",
  "tahmini_porsiyon": "Tahmini porsiyon veya ağırlık (örn: 1 tabak / 250g)",
  "toplam_kalori": 450,
  "protein_g": 24.5,
  "karbonhidrat_g": 42.0,
  "yag_g": 14.0,
  "lif_g": 6.0,
  "saglik_puani": 8,
  "besin_degerlendirmesi": "Besleyicilik, doyuruculuk ve sağlık açısından 1-2 cümlelik profesyonel değerlendirme.",
  "icindekiler": ["Malzeme 1", "Malzeme 2", "Malzeme 3"]
}
''';

    final userInstruction = userPrompt != null && userPrompt.isNotEmpty
        ? 'Kullanıcı Açıklaması: "$userPrompt". Lütfen bu bilgi ve görsel ışığında analizi yap.'
        : 'Lütfen bu görseldeki yemeği tanımlayıp kalori ve makro besinlerini hesapla.';

    final raw = await _requestWithFallback(
      prompt: '$systemInstruction\n\n$userInstruction',
      temperature: 0.2,
      jsonMode: true,
      imageBytes: imageBytes,
      mimeType: mimeType,
    );

    if (raw == null) {
      return AiAnalysisResult.error(
        'Yapay zeka servislerine ulaşılamadı. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    }
    return _parseJsonOutput(raw);
  }

  // ---------------------------------------------------------------------------
  // ORTAK FALLBACK MANTIĞI: Önce Gemini, olmazsa Groq
  // ---------------------------------------------------------------------------
  /// İsteği önce Gemini'ye atar; başarısız olursa Groq'a düşer.
  /// İki servis de başarısızsa null döner.
  static Future<String?> _requestWithFallback({
    required String prompt,
    required double temperature,
    required bool jsonMode,
    Uint8List? imageBytes,
    String? mimeType,
  }) async {
    try {
      final text = await _requestGemini(
        prompt: prompt,
        temperature: temperature,
        jsonMode: jsonMode,
        imageBytes: imageBytes,
        mimeType: mimeType,
      );
      if (text != null) return text;
    } catch (_) {
      // Gemini yavaş / hatalı → Groq'a düş
    }

    try {
      return await _requestGroq(
        prompt: prompt,
        temperature: temperature,
        jsonMode: jsonMode,
        imageBytes: imageBytes,
        mimeType: mimeType,
      );
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // GEMINI
  // ---------------------------------------------------------------------------
  static Future<String?> _requestGemini({
    required String prompt,
    required double temperature,
    required bool jsonMode,
    Uint8List? imageBytes,
    String? mimeType,
  }) async {
    final apiKey = getActiveApiKey();
    if (apiKey.isEmpty) return null;

    final model = (imageBytes != null && imageBytes.isNotEmpty) ? visionModelName : modelName;
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final List<Map<String, dynamic>> parts = [
      {'text': prompt}
    ];
    if (imageBytes != null && imageBytes.isNotEmpty) {
      parts.add({
        'inline_data': {
          'mime_type': mimeType ?? 'image/jpeg',
          'data': base64Encode(imageBytes),
        }
      });
    }

    final requestBody = jsonEncode({
      'contents': [
        {'parts': parts}
      ],
      'generationConfig': {
        'temperature': temperature,
        'topP': 0.95,
        if (jsonMode) 'response_mime_type': 'application/json',
      }
    });

    final response = await http
        .post(url, headers: {'Content-Type': 'application/json'}, body: requestBody)
        .timeout(_timeout);

    if (response.statusCode != 200) return null;

    final responseJson = jsonDecode(response.body);
    final candidates = responseJson['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;

    final content = candidates[0]['content'];
    final responseParts = content?['parts'] as List?;
    if (responseParts == null || responseParts.isEmpty) return null;

    final rawText = (responseParts[0]['text'] as String? ?? '').trim();
    return rawText.isEmpty ? null : rawText;
  }

  // ---------------------------------------------------------------------------
  // GROQ (OpenAI uyumlu)
  // ---------------------------------------------------------------------------
  static Future<String?> _requestGroq({
    required String prompt,
    required double temperature,
    required bool jsonMode,
    Uint8List? imageBytes,
    String? mimeType,
  }) async {
    final apiKey = getGroqKey();
    if (apiKey.isEmpty) return null;

    final hasImage = imageBytes != null && imageBytes.isNotEmpty;
    final model = hasImage ? groqVisionModel : groqTextModel;

    final Map<String, dynamic> userContent;
    if (hasImage) {
      userContent = {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': prompt},
          {
            'type': 'image_url',
            'image_url': {
              'url': 'data:${mimeType ?? 'image/jpeg'};base64,${base64Encode(imageBytes)}',
            }
          },
        ]
      };
    } else {
      userContent = {'role': 'user', 'content': prompt};
    }

    final requestBody = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': 'Sen bir diyetisyen asistanısın. SADECE geçerli JSON üret.'},
        userContent,
      ],
      'temperature': temperature,
      if (jsonMode) 'response_format': {'type': 'json_object'},
    });

    final response = await http
        .post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: requestBody,
        )
        .timeout(_timeout);

    if (response.statusCode != 200) return null;

    final responseJson = jsonDecode(response.body);
    final choices = responseJson['choices'] as List?;
    if (choices == null || choices.isEmpty) return null;

    final rawText = (choices[0]['message']?['content'] as String? ?? '').trim();
    return rawText.isEmpty ? null : rawText;
  }

  // ---------------------------------------------------------------------------
  // API ANAHTAR TESTİ
  // ---------------------------------------------------------------------------
  /// 'gemini' veya 'groq' için bağlantı testi.
  static Future<bool> testApiKey(String key, {String provider = 'gemini'}) async {
    try {
      if (provider == 'groq') {
        final response = await http
            .post(
              Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $key',
              },
              body: jsonEncode({
                'model': groqTextModel,
                'messages': [
                  {'role': 'user', 'content': 'Merhaba, sadece "OK" cevabını ver.'}
                ],
              }),
            )
            .timeout(const Duration(seconds: 15));
        return response.statusCode == 200;
      }

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$key',
      );
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': 'Merhaba, sadece "OK" cevabını ver.'}
                  ]
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // YARDIMCI METODLAR
  // ---------------------------------------------------------------------------
  static String _stripFences(String rawText) {
    String clean = rawText.trim();
    if (clean.startsWith('```')) {
      clean = clean.replaceFirst(RegExp(r'^```[a-z]*\n?'), '');
      clean = clean.replaceFirst(RegExp(r'```$'), '');
      clean = clean.trim();
    }
    return clean;
  }

  static AiAnalysisResult _parseJsonOutput(String rawText) {
    try {
      final cleanText = _stripFences(rawText);
      final parsed = jsonDecode(cleanText) as Map<String, dynamic>;
      return AiAnalysisResult.fromGeminiJson(parsed);
    } catch (e) {
      return AiAnalysisResult.error('Yapay zeka yanıtı çözümlenemedi: $rawText');
    }
  }

  static AiAnalysisResult getDemoResult({String? prompt}) {
    return AiAnalysisResult(
      foodName: prompt != null && prompt.isNotEmpty ? prompt : 'Karışık Izgara & Fırın Sebzeler',
      portion: '1 porsiyon (yaklaşık 320g)',
      calories: 520,
      protein: 38.0,
      carbs: 26.0,
      fat: 18.0,
      fiber: 6.5,
      healthScore: 9,
      advice: 'Zengin protein ve lif içeriğiyle kas gelişimini ve uzun süre tokluğu destekler. Çok dengeli bir öğün!',
      ingredients: ['Tavuk Göğsü', 'Köfte', 'Kabak', 'Kırmızı Biber', 'Kekik', 'Zeytinyağı'],
      isSuccess: true,
    );
  }
}
