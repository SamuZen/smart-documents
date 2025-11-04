import '../models/prompt.dart';

/// Serviço para gerenciar prompts em memória (CRUD)
class PromptManagerService {
  final List<Prompt> _prompts = [];

  /// Retorna todos os prompts
  List<Prompt> getAllPrompts() {
    return List<Prompt>.from(_prompts);
  }

  /// Retorna prompts filtrados por ordem
  List<Prompt> getPromptsByOrder(PromptOrder order) {
    return _prompts.where((p) => p.order == order).toList()
      ..sort((a, b) => a.index.compareTo(b.index));
  }

  /// Adiciona um novo prompt
  void addPrompt(Prompt prompt) {
    _prompts.add(prompt);
  }

  /// Remove um prompt pelo ID
  bool removePrompt(String promptId) {
    final index = _prompts.indexWhere((p) => p.id == promptId);
    if (index != -1) {
      _prompts.removeAt(index);
      return true;
    }
    return false;
  }

  /// Atualiza um prompt existente
  bool updatePrompt(String promptId, Prompt updatedPrompt) {
    final index = _prompts.indexWhere((p) => p.id == promptId);
    if (index != -1) {
      _prompts[index] = updatedPrompt;
      return true;
    }
    return false;
  }

  /// Encontra um prompt pelo ID
  Prompt? findPromptById(String promptId) {
    try {
      return _prompts.firstWhere((p) => p.id == promptId);
    } catch (e) {
      return null;
    }
  }

  /// Reordena um prompt dentro da sua categoria
  /// Move o prompt para uma nova posição (index) dentro da mesma categoria
  bool reorderPrompt(String promptId, int newIndex) {
    final prompt = findPromptById(promptId);
    if (prompt == null) return false;

    // Obtém todos os prompts da mesma categoria
    final sameOrderPrompts = getPromptsByOrder(prompt.order);
    
    // Remove o prompt da lista
    sameOrderPrompts.removeWhere((p) => p.id == promptId);
    
    // Valida o novo índice
    final clampedIndex = newIndex.clamp(0, sameOrderPrompts.length);
    
    // Insere o prompt na nova posição
    sameOrderPrompts.insert(clampedIndex, prompt);
    
    // Atualiza os índices de todos os prompts da categoria
    for (int i = 0; i < sameOrderPrompts.length; i++) {
      final p = sameOrderPrompts[i];
      final index = _prompts.indexWhere((prompt) => prompt.id == p.id);
      if (index != -1) {
        _prompts[index] = p.copyWith(index: i);
      }
    }
    
    return true;
  }

  /// Carrega prompts de uma lista (útil ao carregar do storage)
  void loadPrompts(List<Prompt> prompts) {
    _prompts.clear();
    _prompts.addAll(prompts);
  }

  /// Limpa todos os prompts
  void clearPrompts() {
    _prompts.clear();
  }

  /// Retorna a quantidade de prompts
  int get count => _prompts.length;
}

