class Categoria {
  final int? id;
  final String nome;
  final String tipo;
  final double? limite;

  Categoria({
    this.id,
    required this.nome,
    required this.tipo,
    this.limite,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'tipo': tipo,
      'limite': limite,
    };
  }

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'],
      nome: map['nome'],
      tipo: map['tipo'],
      limite: map['limite'],
    );
  }
}