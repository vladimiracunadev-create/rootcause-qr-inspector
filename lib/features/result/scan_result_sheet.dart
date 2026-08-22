import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rootcause_qr_inspector/core/investigation/qr_evidence_exporter.dart';
import 'package:rootcause_qr_inspector/core/investigation/qr_finding_text.dart';
import 'package:rootcause_qr_inspector/core/investigation/qr_investigation.dart';
import 'package:rootcause_qr_inspector/core/security/scan_security_analyzer.dart';
import 'package:rootcause_qr_inspector/models/parsed_content.dart';
import 'package:rootcause_qr_inspector/models/scan_record.dart';
import 'package:rootcause_qr_inspector/services/clipboard_service.dart';
import 'package:rootcause_qr_inspector/state/settings_store.dart';
import 'package:url_launcher/url_launcher.dart';

class ScanResultsSheet extends StatelessWidget {
  const ScanResultsSheet({required this.records, required this.settings, super.key});

  final List<ScanRecord> records;
  final SettingsStore settings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.86),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(Icons.shield_outlined, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'INSPECCIÓN COMPLETADA',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.15,
                              ),
                        ),
                        Text(
                          records.length == 1 ? 'Resultado de seguridad QR' : '${records.length} resultados de seguridad QR',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'RootCause separa lo observado de lo que todavía debes comprobar.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: records.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) => ScanRecordCard(record: records[index], settings: settings),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Inspeccionar otro QR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScanRecordCard extends StatefulWidget {
  const ScanRecordCard({required this.record, required this.settings, this.compact = false, super.key});

  final ScanRecord record;
  final SettingsStore settings;
  final bool compact;

  @override
  State<ScanRecordCard> createState() => _ScanRecordCardState();
}

class _ScanRecordCardState extends State<ScanRecordCard> {
  bool _revealed = false;

  ScanRecord get record => widget.record;

  @override
  Widget build(BuildContext context) {
    final bool conceal = record.isSensitive && widget.settings.value.hideSensitiveValues && !_revealed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _SecurityResultHeader(
              record: record,
              icon: _iconForKind(record.parsed.kind),
              conceal: conceal,
              onToggleVisibility: record.isSensitive ? () => setState(() => _revealed = !_revealed) : null,
            ),
            if (!widget.compact) ...<Widget>[
              const SizedBox(height: 16),
              _RiskBanner(record: record),
            ],
            const SizedBox(height: 16),
            Text(
              'CONTENIDO OBSERVADO',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.05,
                  ),
            ),
            const SizedBox(height: 10),
            ...record.parsed.fields.entries.map((MapEntry<String, String> field) {
              final bool sensitiveField = record.parsed.sensitive &&
                  <String>{'Contraseña', 'Secreto', 'Consulta', 'Dirección', 'IBAN', 'Carga'}
                      .contains(field.key);
              final String value = conceal && sensitiveField ? '••••••••' : field.value;
              if (value.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.72)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(field.key, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                    SelectableText(value),
                  ],
                ),
              );
            }),
            if (!widget.compact) ...<Widget>[
              const SizedBox(height: 8),
              Divider(color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () => _copy(context),
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copiar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => unawaited(_shareRecord(context)),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Compartir'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => unawaited(_shareEvidence()),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Evidencia'),
                  ),
                  if (_actionUri(record) != null)
                    FilledButton.icon(
                      onPressed: () => unawaited(_openRecord(context)),
                      icon: const Icon(Icons.open_in_new),
                      label: Text('${_actionLabel(record.parsed.kind)} con confirmación'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    if (record.isSensitive) {
      final bool confirmed = await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) => AlertDialog(
              icon: const Icon(Icons.content_paste_go_outlined),
              title: const Text('Copiar carga sensible'),
              content: const Text(
                'El portapapeles puede quedar visible para otras aplicaciones. '
                'RootCause copiará el valor completo y aplicará el tiempo de borrado configurado.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Copiar'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;
    }
    if (!context.mounted) return;
    await ClipboardService.copy(
      record.rawValue,
      clearAfterSeconds: widget.settings.value.clearClipboardSeconds,
    );
    if (context.mounted) {
      final int seconds = widget.settings.value.clearClipboardSeconds;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(seconds <= 0 ? 'Contenido copiado.' : 'Contenido copiado; se borrará en $seconds segundos.'),
        ),
      );
    }
  }

  Future<void> _shareRecord(BuildContext context) async {
    if (record.isSensitive) {
      final bool confirmed = await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) => AlertDialog(
              icon: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Compartir información sensible'),
              content: const Text('El contenido puede incluir contraseñas, secretos, información de pago o identificación. Revisa el destino antes de compartir.'),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
                FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Compartir')),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;
    }

    if (record.parsed.kind == ContentKind.contact || record.parsed.kind == ContentKind.event) {
      final bool contact = record.parsed.kind == ContentKind.contact;
      final String extension = contact ? 'vcf' : 'ics';
      final String mimeType = contact ? 'text/vcard' : 'text/calendar';
      await SharePlus.instance.share(
        ShareParams(
          title: contact ? 'Contacto escaneado' : 'Evento escaneado',
          files: <XFile>[
            XFile.fromData(
              Uint8List.fromList(utf8.encode(record.rawValue)),
              mimeType: mimeType,
            ),
          ],
          fileNameOverrides: <String>['${contact ? 'contacto' : 'evento'}.$extension'],
        ),
      );
      return;
    }
    await SharePlus.instance.share(ShareParams(text: record.rawValue));
  }

  Future<void> _shareEvidence() async {
    final Uint8List bytes = Uint8List.fromList(
      utf8.encode(QrEvidenceExporter.toJson(record)),
    );
    await SharePlus.instance.share(ShareParams(
      title: 'Evidencia RootCause QR',
      files: <XFile>[
        XFile.fromData(bytes, mimeType: 'application/json'),
      ],
      fileNameOverrides: <String>['rootcause-qr-evidence-${record.id}.json'],
    ));
  }

  Future<void> _openRecord(BuildContext context) async {
    final Uri? uri = _actionUri(record);
    if (uri == null) return;
    final bool shouldConfirm = record.investigation.action == QrActionDecision.confirm ||
        widget.settings.value.confirmBeforeOpen ||
        record.riskLevel != RiskLevel.low;
    if (shouldConfirm) {
      final bool confirmed = await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) => AlertDialog(
              icon: Icon(record.riskLevel == RiskLevel.high ? Icons.warning_amber_rounded : Icons.open_in_new),
              title: const Text('Confirmar acción'),
              content: Text(
                record.riskLevel == RiskLevel.high
                    ? 'RootCause observó señales críticas (${record.investigation.score}/100). Comprueba el dominio con una fuente independiente antes de continuar.'
                    : 'La aplicación abrirá este contenido mediante una aplicación externa. Revisa los datos antes de continuar.',
              ),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
                FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Continuar')),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;
    }
    try {
      final bool opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No existe una aplicación compatible para esta acción.')));
      }
    } on Object {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No fue posible abrir el contenido.')));
    }
  }

  Uri? _actionUri(ScanRecord record) {
    if (record.investigation.action == QrActionDecision.block) return null;
    if (record.canOpen) return ScanSecurityAnalyzer.normalizedActionUri(record.rawValue);
    return switch (record.parsed.kind) {
      ContentKind.phone || ContentKind.email || ContentKind.sms || ContentKind.geo => Uri.tryParse(record.rawValue),
      _ => null,
    };
  }

  String _actionLabel(ContentKind kind) => switch (kind) {
        ContentKind.phone => 'Llamar',
        ContentKind.email => 'Correo',
        ContentKind.sms => 'SMS',
        ContentKind.geo => 'Mapa',
        _ => 'Abrir',
      };

  IconData _iconForKind(ContentKind kind) => switch (kind) {
        ContentKind.url => Icons.link,
        ContentKind.wifi => Icons.wifi,
        ContentKind.contact => Icons.person_outline,
        ContentKind.event => Icons.event_outlined,
        ContentKind.email => Icons.email_outlined,
        ContentKind.phone => Icons.phone_outlined,
        ContentKind.sms => Icons.sms_outlined,
        ContentKind.geo => Icons.location_on_outlined,
        ContentKind.otp => Icons.key_outlined,
        ContentKind.gs1 => Icons.qr_code_2,
        ContentKind.isbn => Icons.menu_book_outlined,
        ContentKind.product => Icons.inventory_2_outlined,
        ContentKind.payment => Icons.payments_outlined,
        ContentKind.crypto => Icons.currency_bitcoin,
        ContentKind.identity => Icons.badge_outlined,
        ContentKind.binary => Icons.data_object,
        ContentKind.text => Icons.text_snippet_outlined,
  };
}

class _SecurityResultHeader extends StatelessWidget {
  const _SecurityResultHeader({
    required this.record,
    required this.icon,
    required this.conceal,
    required this.onToggleVisibility,
  });

  final ScanRecord record;
  final IconData icon;
  final bool conceal;
  final VoidCallback? onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: colors.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(record.parsed.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                '${record.format} · ${record.source}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
              if (record.parsed.summary?.isNotEmpty == true) ...<Widget>[
                const SizedBox(height: 5),
                Text(record.parsed.summary!, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
        if (onToggleVisibility != null)
          IconButton.filledTonal(
            tooltip: conceal ? 'Mostrar datos sensibles' : 'Ocultar datos sensibles',
            onPressed: onToggleVisibility,
            icon: Icon(conceal ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          ),
      ],
    );
  }
}

class _RiskBanner extends StatelessWidget {
  const _RiskBanner({required this.record});
  final ScanRecord record;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final QrInvestigation investigation = record.investigation;
    final (Color, Color, IconData) style = switch (record.riskLevel) {
      RiskLevel.low => (colors.primaryContainer, colors.onPrimaryContainer, Icons.verified_user_outlined),
      RiskLevel.caution => (colors.tertiaryContainer, colors.onTertiaryContainer, Icons.info_outline),
      RiskLevel.high => (colors.errorContainer, colors.onErrorContainer, Icons.warning_amber_rounded),
    };
    final String title = switch (record.riskLevel) {
      RiskLevel.low => 'Sin señales locales observadas',
      RiskLevel.caution => 'Revisar antes de continuar',
      RiskLevel.high => 'Señales críticas observadas',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: style.$1,
        border: Border.all(color: style.$2.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: style.$2.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(style.$3, color: style.$2),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: TextStyle(color: style.$2, fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(
                      'Decisión: ${QrFindingText.actionLabel(investigation.action)}',
                      style: TextStyle(color: style.$2.withValues(alpha: 0.82), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: style.$2,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      '${investigation.score}',
                      style: TextStyle(color: style.$1, fontWeight: FontWeight.w900, fontSize: 19, height: 1),
                    ),
                    Text(
                      '/ 100',
                      style: TextStyle(color: style.$1.withValues(alpha: 0.85), fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            investigation.findings.isEmpty
                ? 'No se observaron señales locales. Esto no demuestra que el destino sea seguro.'
                : '${investigation.findings.length} ${investigation.findings.length == 1 ? 'señal requiere' : 'señales requieren'} revisión antes de actuar.',
            style: TextStyle(color: style.$2, height: 1.35),
          ),
          if (investigation.findings.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                iconColor: style.$2,
                collapsedIconColor: style.$2,
                title: Text(
                  'Ver señales, evidencia y recomendaciones',
                  style: TextStyle(color: style.$2, fontWeight: FontWeight.w800),
                ),
                children: <Widget>[
                  for (final QrFinding finding in investigation.findings)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: style.$2.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(QrFindingText.title(finding.id), style: TextStyle(color: style.$2, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(QrFindingText.explanation(finding.id), style: TextStyle(color: style.$2)),
                          const SizedBox(height: 5),
                          Text(
                            'Acción sugerida: ${QrFindingText.recommendation(finding.id)}',
                            style: TextStyle(color: style.$2, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            finding.id,
                            style: TextStyle(color: style.$2.withValues(alpha: 0.72), fontFamily: 'monospace', fontSize: 11),
                          ),
                          for (final QrEvidenceFact fact in finding.evidence)
                            Text(
                              '${QrFindingText.evidenceLabel(fact.id)}: ${fact.value}',
                              style: TextStyle(color: style.$2.withValues(alpha: 0.88), fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  if (investigation.hypotheses.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Hipótesis: ${investigation.hypotheses.map(_hypothesisLabel).join(' · ')}',
                        style: TextStyle(color: style.$2, fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 7),
          Text(
            'No comprobado: ${investigation.limitations.map(QrFindingText.limitationLabel).join(' · ')}',
            style: TextStyle(color: style.$2.withValues(alpha: 0.78), fontSize: 11, height: 1.25),
          ),
        ],
      ),
    );
  }

  static String _hypothesisLabel(String id) => switch (id) {
        'qr-phishing-suspected' => 'posible phishing por QR',
        'credential-theft-suspected' => 'posible robo de credenciales',
        'malware-delivery-suspected' => 'posible entrega de software malicioso',
        'payment-substitution-review' => 'revisar sustitución de pago',
        'local-network-lure' => 'destino en red local',
        'unsafe-uri-execution' => 'ejecución de URI no permitida',
        _ => id,
      };
}
