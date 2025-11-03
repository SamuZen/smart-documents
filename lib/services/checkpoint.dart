import '../models/node.dart';

/// Representa um checkpoint (snapshot) do estado da árvore
class Checkpoint {
  final String id;
  final String? name;
  final DateTime timestamp;
  final Node treeSnapshot;
  final Map<String, dynamic> metadata;

  Checkpoint({
    required this.id,
    this.name,
    required this.timestamp,
    required this.treeSnapshot,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'timestamp': timestamp.toIso8601String(),
      'treeSnapshot': treeSnapshot.toJson(),
      'metadata': metadata,
    };
  }

  factory Checkpoint.fromJson(Map<String, dynamic> json) {
    return Checkpoint(
      id: json['id'] as String,
      name: json['name'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      treeSnapshot: Node.fromJson(json['treeSnapshot'] as Map<String, dynamic>),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}

