class Node {
  final String id;
  final String name;
  final List<Node> children;

  Node({
    required this.id,
    required this.name,
    List<Node>? children,
  }) : children = children ?? [];

  /// Verifica se o node é uma folha (não tem filhos)
  bool get isLeaf => children.isEmpty;

  /// Adiciona um filho ao node
  void addChild(Node child) {
    children.add(child);
  }

  /// Encontra um node por ID na árvore recursivamente
  Node? findById(String searchId) {
    if (id == searchId) {
      return this;
    }

    for (final child in children) {
      final found = child.findById(searchId);
      if (found != null) {
        return found;
      }
    }

    return null;
  }

  /// Cria uma cópia do node
  Node copyWith({
    String? id,
    String? name,
    List<Node>? children,
  }) {
    return Node(
      id: id ?? this.id,
      name: name ?? this.name,
      children: children ?? this.children.map((e) => e.copyWith()).toList(),
    );
  }
}

