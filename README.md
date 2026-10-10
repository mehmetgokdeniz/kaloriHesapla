# KaloriAI

Flutter ile geliştirilmiş kalori, öğün ve su takibi uygulaması.

## Özellikler

- Günlük kalori ve makro takibi
- Öğün ekleme ve geçmiş görüntüleme
- Yapay zekâ destekli öğün analizi
- Gemini ve Groq API desteği
- Saatlik su içme bildirimleri
- Kalıcı günlük seri takibi
- Android ve iOS uygulama ikonları

## Kurulum

```bash
flutter pub get
flutter run
```

Yapay zekâ özelliklerini kullanmak için uygulamadaki **Ayarlar** ekranından Gemini veya Groq API anahtarınızı girin. Güvenlik nedeniyle API anahtarları kaynak koda dahil edilmez.

## Android APK

Release APK oluşturmak için:

```bash
flutter build apk --release
```

Çıktı:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Bildirimler

Uygulama ilk açılışta bildirim izni ister. İzin verildiğinde her saat su içme hatırlatıcısı gönderilir.

## Lisans

Bu proje kişisel kullanım ve eğitim amaçlıdır.
