class Transacao {
  final int? id;
  final int usuarioId;
  final int categoriaId;
  final String tipo; 
  final double valor;
  final String data;
  final String? descricao;

  Transacao({
    this.id,
    required this.usuarioId,
    required this.categoriaId,
    required this.tipo,
    required this.valor,
    required this.data,
    this.descricao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'categoria_id': categoriaId,
      'tipo': tipo,
      'valor': valor,
      'data': data,
      'descricao': descricao,
    };
  }

  factory Transacao.fromMap(Map<String, dynamic> map) {
    return Transacao(
      id: map['id'],
      usuarioId: map['usuario_id'],
      categoriaId: map['categoria_id'],
      tipo: map['tipo'],
      valor: map['valor'],
      data: map['data'],
      descricao: map['descricao'],
    );
  }
}