import 'package:shared_preferences/shared_preferences.dart';

/// Serviço para gerenciar configurações da aplicação
/// Armazena chaves de API e outras configurações usando SharedPreferences
class SettingsService {
  // Chaves para armazenamento no SharedPreferences
  static const String _keyApiKeyOpenAI = 'api_key_openai';
  static const String _keyApiKeyAnthropic = 'api_key_anthropic';
  static const String _keyApiKeyGoogle = 'api_key_google';

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
}

