/// Qué parte del sistema produjo la incidencia.
///
/// Solo `history` e `inventory` tienen un registro reparable; `migration`,
/// `database` y `startup` describen un problema de proceso, y por eso
/// `RecoveryService.retry` los rechaza en vez de fingir una recuperación.
enum RecoveryEntityType { history, inventory, migration, database, startup }

/// Ciclo de vida de una incidencia. Solo `unresolved` ofrece acciones.
enum RecoveryIssueState { unresolved, recovered, deleted }

/// Un registro aislado por no poder leerse, con su carga aún cifrada.
///
/// Contiene metadatos técnicos y, cuando existe, [encryptedPayload]: el sobre
/// original tal cual estaba. Nunca contiene texto claro ni la llave, de modo
/// que el paquete de recuperación pueda compartirse con soporte sin revelar el
/// contenido escaneado.
///
/// [id] es determinista —SHA-256 truncado de `tipo|entidad|código`— para que el
/// mismo fallo repetido no genere una lista creciente de duplicados.
class RecoveryIssue {
  const RecoveryIssue({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.detectedAt,
    required this.code,
    required this.state,
    this.encryptedPayload,
  });

  final String id;
  final RecoveryEntityType entityType;
  final String entityId;
  final DateTime detectedAt;
  final String code;
  final RecoveryIssueState state;
  final String? encryptedPayload;

  RecoveryIssue copyWith({RecoveryIssueState? state}) => RecoveryIssue(
        id: id,
        entityType: entityType,
        entityId: entityId,
        detectedAt: detectedAt,
        code: code,
        state: state ?? this.state,
        encryptedPayload: encryptedPayload,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'entityType': entityType.name,
        'entityId': entityId,
        'detectedAt': detectedAt.toIso8601String(),
        'code': code,
        'state': state.name,
        'encryptedPayload': encryptedPayload,
      };

  factory RecoveryIssue.fromJson(Map<String, Object?> json) => RecoveryIssue(
        id: json['id'] as String,
        entityType: RecoveryEntityType.values.byName(json['entityType'] as String),
        entityId: json['entityId'] as String,
        detectedAt: DateTime.parse(json['detectedAt'] as String),
        code: json['code'] as String,
        state: RecoveryIssueState.values.byName(json['state'] as String),
        encryptedPayload: json['encryptedPayload'] as String?,
      );
}
