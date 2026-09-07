import 'package:flutter/material.dart';
import 'package:rootcause_qr_inspector/core/localization/app_localizations.dart';

/// Short, local-only onboarding for the five primary destinations.
class TabGuideScreen extends StatelessWidget {
  const TabGuideScreen({this.focusInventory = false, super.key});

  final bool focusInventory;

  static const List<IconData> _icons = <IconData>[
    Icons.shield_outlined,
    Icons.inventory_2_outlined,
    Icons.qr_code_2_outlined,
    Icons.history_outlined,
    Icons.settings_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return Scaffold(
      appBar: AppBar(title: AppText(strings.quickGuide)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: <Widget>[
          AppText(
            'Consulta qué hace cada pestaña y cuándo usarla.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          for (int index = 0; index < _icons.length; index++) ...<Widget>[
            Card(
              color: focusInventory && index == 1
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: ListTile(
                leading: Icon(_icons[index]),
                title: AppText(
                  strings.tabTitle(index),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: AppText(strings.tabDescription(index)),
                ),
              ),
            ),
            if (index == 1) const _InventorySteps(),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _InventorySteps extends StatelessWidget {
  const _InventorySteps();

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppText(
              'Cómo usar Inventario',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const AppText(
              'Cuenta unidades repetidas sin confundirlas con códigos únicos.',
            ),
            const SizedBox(height: 10),
            const AppText('1. Crea una sesión con un nombre reconocible.'),
            const SizedBox(height: 6),
            const AppText(
              '2. Escanea cada unidad física; el mismo código puede sumar varias veces.',
            ),
            const SizedBox(height: 6),
            const AppText(
              '3. Revisa cantidades, corrige notas y cierra la sesión al terminar.',
            ),
            const SizedBox(height: 6),
            const AppText(
              '4. Exporta CSV, JSON o Excel para continuar el trabajo fuera de la app.',
            ),
          ],
        ),
      ),
    );
  }
}
