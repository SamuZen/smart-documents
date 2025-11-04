import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConfirmationDialog {
  /// Mostra um diálogo de confirmação
  /// 
  /// [context]: BuildContext necessário para mostrar o diálogo
  /// [title]: Título do diálogo
  /// [message]: Mensagem/descrição principal
  /// [confirmText]: Texto do botão de confirmação (padrão: "Confirmar")
  /// [cancelText]: Texto do botão de cancelamento (padrão: "Cancelar")
  /// [onConfirm]: Callback quando confirmar (obrigatório)
  /// [onCancel]: Callback opcional quando cancelar
  /// [isDestructive]: Flag para indicar ação destrutiva (muda cor do botão para vermelho)
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Shortcuts(
          shortcuts: {
            LogicalKeySet(LogicalKeyboardKey.enter): const _ConfirmIntent(),
            LogicalKeySet(LogicalKeyboardKey.escape): const _CancelIntent(),
          },
          child: Actions(
            actions: {
              _ConfirmIntent: CallbackAction<_ConfirmIntent>(
                onInvoke: (_) {
                  Navigator.of(context).pop(true);
                  onConfirm();
                  return null;
                },
              ),
              _CancelIntent: CallbackAction<_CancelIntent>(
                onInvoke: (_) {
                  Navigator.of(context).pop(false);
                  onCancel?.call();
                  return null;
                },
              ),
            },
            child: Focus(
              autofocus: true,
              child: AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                onCancel?.call();
              },
              child: Text(cancelText),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                onConfirm();
              },
              style: isDestructive
                  ? FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    )
                  : null,
              child: Text(confirmText),
            ),
          ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Intent para confirmar (Enter)
class _ConfirmIntent extends Intent {
  const _ConfirmIntent();
}

// Intent para cancelar (ESC)
class _CancelIntent extends Intent {
  const _CancelIntent();
}

