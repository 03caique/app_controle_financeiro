import 'package:shared_preferences/shared_preferences.dart';

class PreferenciasService {
  static const _chaveUsuarioId = 'usuario_id_logado';

  Future<void> salvarUsuarioLogado(int usuarioId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_chaveUsuarioId, usuarioId);
  }

  Future<int?> obterUsuarioLogado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_chaveUsuarioId);
  }

  Future<void> limparSessao() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chaveUsuarioId);
  }
}