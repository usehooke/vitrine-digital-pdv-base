/// Modelo de dados para um usuário do sistema.
/// Contém o nome, o PIN criptografado (hash) e a permissão de administrador.
class AppUser {
  final String name;
  final String pinHash;
  final bool isAdmin; // <-- NOVO: Campo para identificar o administrador.

  AppUser({
    required this.name,
    required this.pinHash,
    this.isAdmin = false, // Por padrão, um novo usuário não é admin.
  });

  /// Construtor de fábrica para criar um AppUser a partir de um JSON.
  /// Usado ao ler os dados do armazenamento seguro.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      name: json['name'],
      pinHash: json['pinHash'],
      isAdmin: json['isAdmin'] ?? false, // Garante compatibilidade com usuários antigos.
    );
  }

  /// Converte o objeto AppUser para um JSON.
  /// Usado ao salvar os dados no armazenamento seguro.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'pinHash': pinHash,
      'isAdmin': isAdmin, // <-- NOVO: Salva a permissão no JSON.
    };
  }
}
