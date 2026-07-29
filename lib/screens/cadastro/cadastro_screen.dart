import 'package:flutter/material.dart';
import '../../models/usuario.dart';
import '../../repositories/usuario_repository.dart';
import '../../theme/app_theme.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  final _usuarioRepository = UsuarioRepository();

  bool _carregando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    final emailExistente = await _usuarioRepository.buscarPorEmail(
      _emailController.text.trim(),
    );

    if (emailExistente != null) {
      setState(() => _carregando = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este email já está cadastrado.')),
      );
      return;
    }

    final novoUsuario = Usuario(
      nome: _nomeController.text.trim(),
      email: _emailController.text.trim(),
      senha: _senhaController.text,
    );

    await _usuarioRepository.cadastrar(novoUsuario);

    setState(() => _carregando = false);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cadastro realizado com sucesso!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
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
                            'Novo Registro',
                            textAlign: TextAlign.center,
                            style: AppTypography.eyebrow,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Criar Conta',
                            textAlign: TextAlign.center,
                            style: textTheme.displaySmall,
                          ),
                          const SizedBox(height: 18),
                          const LedgerRule(),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: _nomeController,
                            decoration: const InputDecoration(
                              labelText: 'NOME',
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: AppColors.mutedInk,
                                size: 20,
                              ),
                            ),
                            style: textTheme.bodyLarge,
                            cursorColor: AppColors.brass,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Informe seu nome';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),
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
                              final emailValido = RegExp(
                                r'^[^@]+@[^@]+\.[^@]+$',
                              ).hasMatch(value.trim());
                              if (!emailValido) {
                                return 'Informe um email válido';
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
                                return 'Informe uma senha';
                              }
                              if (value.length < 6) {
                                return 'A senha deve ter no mínimo 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),
                          TextFormField(
                            controller: _confirmarSenhaController,
                            decoration: const InputDecoration(
                              labelText: 'CONFIRMAR SENHA',
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
                              if (value != _senhaController.text) {
                                return 'As senhas não coincidem';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),
                          ElevatedButton(
                            onPressed: _carregando ? null : _cadastrar,
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
                                : const Text('CADASTRAR'),
                          ),
                        ],
                      ),
                    ),
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