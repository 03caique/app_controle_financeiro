import 'dart:convert';
import 'package:crypto/crypto.dart';

class SenhaUtils {

  static String gerarHash(String senha) {
    final bytes = utf8.encode(senha);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
}