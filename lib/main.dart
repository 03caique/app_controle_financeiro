import 'package:flutter/material.dart';
import 'screens/login/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/notification_service.dart';
import 'services/preferencias_service.dart';
import 'repositories/usuario_repository.dart';
import 'models/usuario.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().inicializar();
  await NotificationService().solicitarPermissao();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle Financeiro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TelaInicial(),
    );
  }
}

/// Decide se o usuário vai direto pra Home (sessão salva) ou pro Login.
class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  Future<Usuario?> _verificarSessao() async {
    final usuarioId = await PreferenciasService().obterUsuarioLogado();
    if (usuarioId == null) return null;
    return UsuarioRepository().buscarPorId(usuarioId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Usuario?>(
      future: _verificarSessao(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != null) {
          return HomeScreen(usuario: snapshot.data!);
        }
        return const LoginScreen();
      },
    );
  }
}