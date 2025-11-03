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

  /// Conta recursivamente todos os descendentes (filhos, netos, etc.)
  int countAllDescendants() {
    int count = children.length;
    for (final child in children) {
      count += child.countAllDescendants();
    }
    return count;
  }

  /// Adiciona um filho ao node
  void addChild(Node child) {
    children.add(child);
  }

  /// Remove um filho pelo ID e retorna novo Node
  Node removeChildById(String nodeId) {
    final newChildren = children
        .where((child) => child.id != nodeId)
        .map((child) => child.removeChildById(nodeId))
        .toList();
    return copyWith(children: newChildren);
  }

  /// Insere um filho em uma posição específica e retorna novo Node
  Node insertChild(int index, Node child) {
    final newChildren = List<Node>.from(children);
    newChildren.insert(index.clamp(0, newChildren.length), child);
    return copyWith(children: newChildren);
  }

  /// Move um filho de uma posição para outra e retorna novo Node
  Node moveChild(int fromIndex, int toIndex) {
    if (fromIndex < 0 ||
        fromIndex >= children.length ||
        toIndex < 0 ||
        toIndex >= children.length) {
      return this;
    }
    final newChildren = List<Node>.from(children);
    final child = newChildren.removeAt(fromIndex);
    newChildren.insert(toIndex, child);
    return copyWith(children: newChildren);
  }

  /// Encontra o parent de um node na árvore (retorna null se não encontrado ou se for a raiz)
  static Node? findParent(Node root, String nodeId) {
    // Se o node procurado é a raiz, não tem parent
    if (root.id == nodeId) {
      return null;
    }

    // Verifica se algum filho direto é o node procurado
    for (final child in root.children) {
      if (child.id == nodeId) {
        return root;
      }
    }

    // Procura recursivamente nos filhos
    for (final child in root.children) {
      final parent = findParent(child, nodeId);
      if (parent != null) {
        return parent;
      }
    }

    return null;
  }

  /// Verifica se um node é descendente de outro na árvore (método estático)
  /// Retorna true se o node com nodeId é descendente (ou igual) ao node com ancestorId
  static bool isDescendantOf(Node root, String ancestorId, String nodeId) {
    // Se o ancestorId é igual ao nodeId, então nodeId é descendente de si mesmo
    if (ancestorId == nodeId) {
      return true;
    }
    
    // Encontra o ancestor node
    final ancestorNode = root.findById(ancestorId);
    if (ancestorNode == null) {
      return false;
    }
    
    // Verifica recursivamente se nodeId está entre os descendentes do ancestor
    bool checkInNode(Node node) {
      if (node.id == nodeId) {
        return true;
      }
      for (final child in node.children) {
        if (checkInNode(child)) {
          return true;
        }
      }
      return false;
    }
    
    return checkInNode(ancestorNode);
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

