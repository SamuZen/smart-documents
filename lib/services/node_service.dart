import '../models/node.dart';

class NodeService {
  /// Cria uma estrutura de exemplo com 2-3 níveis
  static Node createExampleStructure() {
    // Nível 1: Raiz
    final root = Node(
      id: 'root',
      name: 'Documentação',
    );

    // Nível 2: Seções principais
    final secao1 = Node(
      id: 'secao1',
      name: 'Introdução',
    );

    final secao2 = Node(
      id: 'secao2',
      name: 'Desenvolvimento',
    );

    final secao3 = Node(
      id: 'secao3',
      name: 'Conclusão',
    );

    // Nível 3: Subitens da seção 1
    final item1_1 = Node(
      id: 'item1_1',
      name: 'Visão Geral',
    );

    final item1_2 = Node(
      id: 'item1_2',
      name: 'Objetivos',
    );

    // Nível 3: Subitens da seção 2
    final item2_1 = Node(
      id: 'item2_1',
      name: 'Implementação',
    );

    final item2_2 = Node(
      id: 'item2_2',
      name: 'Testes',
    );

    final item2_3 = Node(
      id: 'item2_3',
      name: 'Deploy',
    );

    // Nível 3: Subitens da seção 3
    final item3_1 = Node(
      id: 'item3_1',
      name: 'Resumo',
    );

    // Adiciona filhos
    secao1.addChild(item1_1);
    secao1.addChild(item1_2);

    secao2.addChild(item2_1);
    secao2.addChild(item2_2);
    secao2.addChild(item2_3);

    secao3.addChild(item3_1);

    root.addChild(secao1);
    root.addChild(secao2);
    root.addChild(secao3);

    return root;
  }
}

