import 'package:flutter/material.dart';
import '../../repositories/usuario_repository.dart';
import '../cadastro/cadastro_screen.dart';
import '../home/home_screen.dart';
import '../../services/preferencias_service.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  final _usuarioRepository = UsuarioRepository();

  bool _carregando = false;
  bool _manterConectado = true;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    final usuario = await _usuarioRepository.login(
      _emailController.text.trim(),
      _senhaController.text,
    );

    setState(() => _carregando = false);
    if (!mounted) return;

    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email ou senha inválidos.')),
      );
      return;
    }

    if (_manterConectado) {
      await PreferenciasService().salvarUsuarioLogado(usuario.id!);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(usuario: usuario)),
    );
  }

  void _irParaCadastro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CadastroScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  _Emblem(),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                    decoration: BoxDecoration(
                      color: AppColors.parchment,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Controle Financeiro',
                            textAlign: TextAlign.center,
                            style: AppTypography.eyebrow,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Fazer Login',
                            textAlign: TextAlign.center,
                            style: textTheme.displaySmall,
                          ),
                          const SizedBox(height: 18),
                          const LedgerRule(),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'EMAIL',
                              prefixIcon: Icon(
                                Icons.mail_outline,
                                color: AppColors.mutedInk,
                                size: 20,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            style: textTheme.bodyLarge,
                            cursorColor: AppColors.brass,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Informe seu email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),
                          TextFormField(
                            controller: _senhaController,
                            decoration: const InputDecoration(
                              labelText: 'SENHA',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppColors.mutedInk,
                                size: 20,
                              ),
                            ),
                            obscureText: true,
                            style: textTheme.bodyLarge,
                            cursorColor: AppColors.brass,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe sua senha';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            value: _manterConectado,
                            onChanged: (valor) => setState(
                              () => _manterConectado = valor ?? true,
                            ),
                            title: Text(
                              'Manter conectado',
                              style: textTheme.bodyMedium,
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _carregando ? null : _login,
                            child: _carregando
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        AppColors.inkNavy,
                                      ),
                                    ),
                                  )
                                : const Text('ENTRAR'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _irParaCadastro,
                    child: const Text('Não tem conta? Cadastre-se'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Emblem extends StatelessWidget {
  const _Emblem();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.brass, width: 1.6),
      ),
      child: const Icon(
        Icons.savings_outlined,
        color: AppColors.brass,
        size: 26,
      ),
    );
  }
}
