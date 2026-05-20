import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  static String generateKey() {
    return encrypt.Key.fromSecureRandom(32).base64;
  }

  static String encryptText(String plaintext, String keyBase64) {
    final key = encrypt.Key.fromBase64(keyBase64);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  static String decryptText(String ciphertext, String keyBase64) {
    final parts = ciphertext.split(':');
    if (parts.length != 2) return ciphertext;
    try {
      final key = encrypt.Key.fromBase64(keyBase64);
      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      return encrypter.decrypt64(parts[1], iv: iv);
    } catch (_) {
      return ciphertext;
    }
  }
}
