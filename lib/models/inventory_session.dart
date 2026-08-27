/// Una línea de conteo dentro de una sesión de inventario.
///
/// La clave del producto es [code], la carga cruda del código leído: dos
/// lecturas del mismo código suman [quantity] en vez de crear otra línea.
/// [firstScannedAt] no se modifica nunca; [lastScannedAt] sí, y ordena la
/// lista visible de la pantalla de inventario.
class InventoryItem {
  const InventoryItem({
    required this.code,
    required this.format,
    required this.label,
    required this.quantity,
    required this.firstScannedAt,
    required this.lastScannedAt,
    this.notes = '',
  });

  final String code;
  final String format;
  final String label;
  final int quantity;
  final DateTime firstScannedAt;
  final DateTime lastScannedAt;
  final String notes;

  InventoryItem copyWith({int? quantity, DateTime? lastScannedAt, String? notes}) => InventoryItem(
        code: code,
        format: format,
        label: label,
        quantity: quantity ?? this.quantity,
        firstScannedAt: firstScannedAt,
        lastScannedAt: lastScannedAt ?? this.lastScannedAt,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code,
        'format': format,
        'label': label,
        'quantity': quantity,
        'firstScannedAt': firstScannedAt.toIso8601String(),
        'lastScannedAt': lastScannedAt.toIso8601String(),
        'notes': notes,
      };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        code: json['code'] as String,
        format: json['format'] as String? ?? 'Desconocido',
        label: json['label'] as String? ?? 'Producto',
        quantity: json['quantity'] as int? ?? 1,
        firstScannedAt: DateTime.parse(json['firstScannedAt'] as String),
        lastScannedAt: DateTime.parse(json['lastScannedAt'] as String),
        notes: json['notes'] as String? ?? '',
      );
}

/// Sesión de conteo continuo, cifrada como una sola carga en la base local.
///
/// Una sesión está abierta mientras [closedAt] sea nulo; solo una sesión
/// abierta acepta lecturas. Cerrarla conserva los datos y su exportación, pero
/// impide seguir sumando unidades. `InventoryStore.reopenSession` puede
/// devolverla al estado abierto.
///
/// El mapa [items] usa la carga del código como clave, de modo que el
/// documento serializado no depende del orden de lectura.
class InventorySession {
  const InventorySession({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.items,
    this.closedAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? closedAt;
  final Map<String, InventoryItem> items;

  bool get isOpen => closedAt == null;
  int get totalUnits => items.values.fold(0, (int sum, InventoryItem item) => sum + item.quantity);

  InventorySession copyWith({Map<String, InventoryItem>? items, DateTime? closedAt}) => InventorySession(
        id: id,
        name: name,
        createdAt: createdAt,
        closedAt: closedAt ?? this.closedAt,
        items: items ?? this.items,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'closedAt': closedAt?.toIso8601String(),
        'items': items.map((String key, InventoryItem value) => MapEntry(key, value.toJson())),
      };

  factory InventorySession.fromJson(Map<String, dynamic> json) => InventorySession(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        closedAt: json['closedAt'] == null ? null : DateTime.parse(json['closedAt'] as String),
        items: (json['items'] as Map<String, dynamic>? ?? <String, dynamic>{}).map(
          (String key, dynamic value) => MapEntry(key, InventoryItem.fromJson(Map<String, dynamic>.from(value as Map))),
        ),
      );
}
