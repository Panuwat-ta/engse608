// lib/services/hash_service.dart
// Password hashing using bcrypt (adaptive, auto-salted)
//
// Why bcrypt over SHA-256 / MD5?
//   • Salt built-in  — ป้องกัน rainbow-table attack
//   • Work factor    — ยิ่งเวลาผ่านไปเพิ่ม cost ได้ ป้องกัน brute-force
//   • Industry standard — ใช้กันทั่วไปในระบบ production
//
// Package: https://pub.dev/packages/bcrypt

import 'package:bcrypt/bcrypt.dart';

class HashService {
  HashService._();

  /// Hash a plain-text password using bcrypt with auto-generated salt.
  /// [cost] controls work factor (10–12 recommended; higher = slower but safer).
  /// Returns a 60-character bcrypt hash string.
  static String hashPassword(String password, {int cost = 10}) {
    final salt = BCrypt.gensalt(logRounds: cost);
    return BCrypt.hashpw(password, salt);
  }

  /// Verify a plain-text password against a stored bcrypt hash.
  /// Returns true if the password matches.
  static bool verify(String inputPassword, String storedHash) {
    // storedHash must be a valid bcrypt hash; return false if empty/malformed
    if (storedHash.isEmpty || !storedHash.startsWith(r'$2')) return false;
    try {
      return BCrypt.checkpw(inputPassword, storedHash);
    } catch (_) {
      return false;
    }
  }
}
