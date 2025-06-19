import 'package:flutter/material.dart';

/// Legal texts for the Solar Browser application
class LegalTexts {
  /// Get the privacy policy text for the specified language
  static String getPrivacyPolicy(String languageCode) {
    print('DEBUG: Getting privacy policy for language: $languageCode');
    switch (languageCode) {
      case 'tr':
        final text = '''
GİZLİLİK POLİTİKASI - YENİ GÜNCELLEME

Solar Browser, kullanıcı verilerini koruma konusunda son derece hassastır ve gizliliğinize saygı duyar.

🔒 VERİ GÜVENLİĞİ:
• Tarayıcı tarafından toplanan tüm veriler yalnızca sizin cihazınızda saklanır ve işlenir
• Hiçbir kişisel bilginiz bizim sunucularımıza gönderilmez
• Şifreleme teknolojileriyle verileriniz korunur

🍪 ÇEREZ POLİTİKASI:
• Ziyaret ettiğiniz web siteleriyle çerez alışverişi yapılabilir
• Bu çerezler sadece ilgili web sitesi ile paylaşılır
• Solar'a herhangi bir çerez verisi gönderilmez

🚫 TAKİP YAPMAYIZ:
• Tarayıcı, kullanıcı davranışlarını izlemez
• Üçüncü taraflarla veri paylaşımı yapmayız
• Reklam ağlarına bağlantı kurmayız

✉️ İletişim: support@browser.solar

Son güncelleme: 19 Haziran 2025
''';
        print('DEBUG: Turkish privacy policy length: ${text.length}');
        return text;
      case 'en':
        final text = '''
PRIVACY POLICY - NEW UPDATE

Solar Browser is extremely sensitive about protecting user data and respects your privacy.

🔒 DATA SECURITY:
• All data collected by the browser is stored and processed only on your device
• No personal information is sent to our servers
• Your data is protected with encryption technologies

🍪 COOKIE POLICY:
• Cookies may be exchanged with websites you visit
• These cookies are only shared with the relevant website
• No cookie data is sent to Solar

🚫 WE DON'T TRACK:
• The browser does not track user behavior
• We do not share data with third parties
• We do not connect to advertising networks

✉️ Contact: support@browser.solar

Last updated: June 19, 2025
''';
        print('DEBUG: English privacy policy length: ${text.length}');
        return text;
      default:
        final text = '''
PRIVACY POLICY - NEW UPDATE

Solar Browser is extremely sensitive about protecting user data and respects your privacy.

🔒 DATA SECURITY:
• All data collected by the browser is stored and processed only on your device
• No personal information is sent to our servers
• Your data is protected with encryption technologies

🍪 COOKIE POLICY:
• Cookies may be exchanged with websites you visit
• These cookies are only shared with the relevant website
• No cookie data is sent to Solar

🚫 WE DON'T TRACK:
• The browser does not track user behavior
• We do not share data with third parties
• We do not connect to advertising networks

✉️ Contact: support@browser.solar

Last updated: June 19, 2025
''';
        print('DEBUG: Default privacy policy length: ${text.length}');
        return text;
    }  }

  /// Get the terms of use text for the specified language
  static String getTermsOfUse(String languageCode) {
    print('DEBUG: Getting terms of use for language: $languageCode');
    switch (languageCode) {
      case 'tr':
        final text = '''
KULLANIM ŞARTLARI - YENİ GÜNCELLEME

1. 🚀 GİRİŞ
Bu Kullanım Şartları, Solar Browser'ı ("Tarayıcı", "biz", "bizim") kullanımınıza ilişkin güncel şartları açıklar. Tarayıcıyı indirerek, yükleyerek veya kullanarak bu şartları kabul etmiş olursunuz.

2. 🌐 HİZMET TANIMI
Solar Browser, modern web standartlarını destekleyen, hızlı ve güvenli bir internet tarayıcısıdır. Tarayıcı, gelişmiş güvenlik özellikleri ve kullanıcı dostu arayüzü ile web deneyiminizi iyileştirir.

3. ✅ KULLANIM KOŞULLARI
• Tarayıcıyı yalnızca yasal amaçlarla kullanabilirsiniz
• Zararlı yazılım yaymak, telif hakkı ihlali yapmak yasaktır
• Yasa dışı faaliyetlerde bulunmak kesinlikle yasaktır
• Tarayıcıyı tersine mühendislik yapmak yasaktır

4. 🔐 VERİ GİZLİLİĞİ VE GÜVENLİĞİ
Solar Browser, kullanıcı verilerini gizlilik politikasına uygun şekilde işler. Verilerinizin nasıl toplandığı ve kullanıldığı hakkında detaylı bilgi için gizlilik politikasını incelemelisiniz.

5. 🔄 GÜNCELLEMELER VE DEĞİŞİKLİKLER
Tarayıcı, yazılımı geliştirmek amacıyla düzenli olarak güncellenir. Güncellemeler yeni özellikler ekleyebilir veya mevcut özellikleri iyileştirebilir.

6. ⚠️ SORUMLULUK REDDİ
Tarayıcı "olduğu gibi" sunulmaktadır. Belirli bir amaç için uygunluk, hatasızlık veya kesintisiz çalışma garantisi verilmez.

7. 🚫 FESİH
Bu kullanım şartlarına uymamanız durumunda, tarayıcıyı kullanma hakkınız derhal sona erebilir.

8. 📧 İLETİŞİM
Sorularınız için: support@browser.solar

Son güncelleme: 19 Haziran 2025
''';
        print('DEBUG: Turkish terms length: ${text.length}');
        return text;
      case 'en':
        final text = '''
TERMS OF USE - NEW UPDATE

1. 🚀 INTRODUCTION
These Terms of Use explain the current terms related to your use of Solar Browser ("Browser", "we", "our"). By downloading, installing, or using the Browser, you accept these terms.

2. 🌐 SERVICE DESCRIPTION
Solar Browser is a fast and secure internet browser that supports modern web standards. The Browser improves your web experience with advanced security features and user-friendly interface.

3. ✅ TERMS OF USE
• You may use the Browser only for legal purposes
• Spreading malware, copyright infringement is prohibited
• Engaging in illegal activities is strictly prohibited
• Reverse engineering the Browser is prohibited

4. 🔐 DATA PRIVACY AND SECURITY
Solar Browser processes user data in accordance with the privacy policy. You should review the privacy policy for detailed information on how your data is collected and used.

5. 🔄 UPDATES AND CHANGES
The Browser is regularly updated to improve the software. Updates may add new features or improve existing ones.

6. ⚠️ DISCLAIMER
The Browser is provided "as is". No guarantee is given for suitability for any particular purpose, flawlessness, or uninterrupted operation.

7. 🚫 TERMINATION
If you do not comply with these terms of use, your right to use the Browser may immediately end.

8. 📧 CONTACT
For questions: support@browser.solar

Last updated: June 19, 2025
''';
        print('DEBUG: English terms length: ${text.length}');
        return text;
      default:
        final text = '''
TERMS OF USE - NEW UPDATE

1. 🚀 INTRODUCTION
These Terms of Use explain the current terms related to your use of Solar Browser ("Browser", "we", "our"). By downloading, installing, or using the Browser, you accept these terms.

2. 🌐 SERVICE DESCRIPTION
Solar Browser is a fast and secure internet browser that supports modern web standards. The Browser improves your web experience with advanced security features and user-friendly interface.

3. ✅ TERMS OF USE
• You may use the Browser only for legal purposes
• Spreading malware, copyright infringement is prohibited
• Engaging in illegal activities is strictly prohibited
• Reverse engineering the Browser is prohibited

4. 🔐 DATA PRIVACY AND SECURITY
Solar Browser processes user data in accordance with the privacy policy. You should review the privacy policy for detailed information on how your data is collected and used.

5. 🔄 UPDATES AND CHANGES
The Browser is regularly updated to improve the software. Updates may add new features or improve existing ones.

6. ⚠️ DISCLAIMER
The Browser is provided "as is". No guarantee is given for suitability for any particular purpose, flawlessness, or uninterrupted operation.

7. 🚫 TERMINATION
If you do not comply with these terms of use, your right to use the Browser may immediately end.

8. 📧 CONTACT
For questions: support@browser.solar

Last updated: June 19, 2025
''';
        print('DEBUG: Default terms length: ${text.length}');
        return text;
    }
  }
}
