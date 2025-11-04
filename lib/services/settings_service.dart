import 'package:shared_preferences/shared_preferences.dart';

/// Serviço para gerenciar configurações da aplicação
/// Armazena chaves de API e outras configurações usando SharedPreferences
class SettingsService {
  // Chaves para armazenamento no SharedPreferences
  static const String _keyApiKeyOpenAI = 'api_key_openai';
  static const String _keyApiKeyAnthropic = 'api_key_anthropic';
  static const String _keyApiKeyGoogle = 'api_key_google';
  static const String _keyApiKeyGrok = 'api_key_grok';
  static const String _keyLastLLMProvider = 'last_llm_provider';
  static const String _keyLastLLMModel = 'last_llm_model';

  /// Salva a chave de API da OpenAI
  static Future<void> setOpenAIKey(String? apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (apiKey == null || apiKey.trim().isEmpty) {
        await prefs.remove(_keyApiKeyOpenAI);
      } else {
        await prefs.setString(_keyApiKeyOpenAI, apiKey.trim());
      }
    } catch (e) {
      print('Erro ao salvar chave OpenAI: $e');
      rethrow;
    }
  }

  /// Recupera a chave de API da OpenAI
  static Future<String?> getOpenAIKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyApiKeyOpenAI);
    } catch (e) {
      print('Erro ao ler chave OpenAI: $e');
      return null;
    }
  }

  /// Salva a chave de API da Anthropic
  static Future<void> setAnthropicKey(String? apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (apiKey == null || apiKey.trim().isEmpty) {
        await prefs.remove(_keyApiKeyAnthropic);
      } else {
        await prefs.setString(_keyApiKeyAnthropic, apiKey.trim());
      }
    } catch (e) {
      print('Erro ao salvar chave Anthropic: $e');
      rethrow;
    }
  }

  /// Recupera a chave de API da Anthropic
  static Future<String?> getAnthropicKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyApiKeyAnthropic);
    } catch (e) {
      print('Erro ao ler chave Anthropic: $e');
      return null;
    }
  }

  /// Salva a chave de API do Google
  static Future<void> setGoogleKey(String? apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (apiKey == null || apiKey.trim().isEmpty) {
        await prefs.remove(_keyApiKeyGoogle);
      } else {
        await prefs.setString(_keyApiKeyGoogle, apiKey.trim());
      }
    } catch (e) {
      print('Erro ao salvar chave Google: $e');
      rethrow;
    }
  }

  /// Recupera a chave de API do Google
  static Future<String?> getGoogleKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyApiKeyGoogle);
    } catch (e) {
      print('Erro ao ler chave Google: $e');
      return null;
    }
  }

  /// Salva a chave de API do Grok
  static Future<void> setGrokKey(String? apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (apiKey == null || apiKey.trim().isEmpty) {
        await prefs.remove(_keyApiKeyGrok);
      } else {
        await prefs.setString(_keyApiKeyGrok, apiKey.trim());
      }
    } catch (e) {
      print('Erro ao salvar chave Grok: $e');
      rethrow;
    }
  }

  /// Recupera a chave de API do Grok
  static Future<String?> getGrokKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyApiKeyGrok);
    } catch (e) {
      print('Erro ao ler chave Grok: $e');
      return null;
    }
  }

  /// Verifica se uma chave de API está salva
  static Future<bool> hasApiKey(String service) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String key;
      switch (service.toLowerCase()) {
        case 'openai':
          key = _keyApiKeyOpenAI;
          break;
        case 'anthropic':
          key = _keyApiKeyAnthropic;
          break;
        case 'google':
          key = _keyApiKeyGoogle;
          break;
        case 'grok':
          key = _keyApiKeyGrok;
          break;
        default:
          return false;
      }
      final value = prefs.getString(key);
      return value != null && value.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar chave de API: $e');
      return false;
    }
  }

  /// Salva o último provider LLM usado
  static Future<void> setLastLLMProvider(String provider) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastLLMProvider, provider);
    } catch (e) {
      print('Erro ao salvar último provider LLM: $e');
    }
  }

  /// Recupera o último provider LLM usado
  static Future<String?> getLastLLMProvider() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyLastLLMProvider);
    } catch (e) {
      print('Erro ao ler último provider LLM: $e');
      return null;
    }
  }

  /// Salva o último modelo LLM usado
  static Future<void> setLastLLMModel(String model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastLLMModel, model);
    } catch (e) {
      print('Erro ao salvar último modelo LLM: $e');
    }
  }

  /// Recupera o último modelo LLM usado
  static Future<String?> getLastLLMModel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyLastLLMModel);
    } catch (e) {
      print('Erro ao ler último modelo LLM: $e');
      return null;
    }
  }
}

