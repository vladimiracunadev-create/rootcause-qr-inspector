import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rootcause_qr_inspector/core/localization/app_localizations.dart';
import 'package:rootcause_qr_inspector/core/performance/cancellation_token.dart';
import 'package:rootcause_qr_inspector/features/result/scan_result_sheet.dart';
import 'package:rootcause_qr_inspector/features/scanner/data/mobile_scanner_engine.dart';
import 'package:rootcause_qr_inspector/features/scanner/data/native_file_code_decoder.dart';
import 'package:rootcause_qr_inspector/features/scanner/domain/file_inspection_coordinator.dart';
import 'package:rootcause_qr_inspector/features/scanner/domain/scanner_engine.dart';
import 'package:rootcause_qr_inspector/features/scanner/domain/scan_persistence_policy.dart';
import 'package:rootcause_qr_inspector/features/scanner/widgets/scan_status_bar.dart';
import 'package:rootcause_qr_inspector/features/scanner/widgets/scanner_overlay.dart';
import 'package:rootcause_qr_inspector/features/scanner/widgets/scanner_viewport_geometry.dart';
import 'package:rootcause_qr_inspector/models/app_settings.dart';
import 'package:rootcause_qr_inspector/models/scan_record.dart';
import 'package:rootcause_qr_inspector/services/pdf_page_renderer.dart';
import 'package:rootcause_qr_inspector/services/scan_feedback.dart';
import 'package:rootcause_qr_inspector/state/scan_store.dart';
import 'package:rootcause_qr_inspector/state/settings_store.dart';

/// Pantalla principal: cámara, estado visible y entrada por imagen o PDF.
///
/// Reúne tres responsabilidades que en esta app no pueden separarse:
///
/// - **ciclo de vida de la cámara.** El controlador lo crea esta pantalla, así
///   que `MobileScanner` no lo gestiona: sin `didChangeAppLifecycleState`, al
///   volver del segundo plano —o del diálogo de permisos— la vista previa
///   quedaba congelada.
/// - **estado observable.** Cada fallo del controlador se traduce a una de las
///   cuatro fases de `ScanPhase` en vez de propagarse como excepción, y la
///   barra de estado siempre dice si se está leyendo.
/// - **lotes cancelables.** Galería y PDF detienen la cámara, muestran
///   progreso, aceptan cancelación y la reanudan al terminar.
///
/// Una lectura repetida en menos de dos segundos se descarta: sin ese filtro,
/// el mismo QR delante del lente reabriría la hoja de resultado sin parar.
///
/// Los registros sensibles nunca llegan al historial, aunque el usuario tenga
/// activado guardarlo: `_persistAndShow` los filtra antes de escribir y aun
/// así los muestra en el resultado inmediato.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({required this.store, required this.settings, super.key});

  final ScanStore store;
  final SettingsStore settings;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  late ScannerEngine _engine;
  final ImagePicker _imagePicker = ImagePicker();
  final ScanFeedback _feedback = ScanFeedback();

  /// Rebuilding the [MobileScanner] with a new key forces it to attach to the
  /// freshly created controller. A controller that failed to start cannot be
  /// reused, so "restart the camera" means "build a new one".
  Key _previewKey = UniqueKey();

  bool _handlingResult = false;
  bool _paused = false;
  String? _startFailure;
  String? _lastSignature;
  DateTime? _lastDetectedAt;
  double _zoom = 0;

  /// Transient explanation shown when the same code is skipped as a repeat.
  String? _repeatNotice;
  Timer? _repeatNoticeTimer;

  /// How long the same payload keeps being treated as a repetition.
  ///
  /// The clock restarts on every frame that still shows the code, so the
  /// window is measured from the moment the code leaves the camera, not from
  /// the first read. Pointing at the same QR again therefore works as soon as
  /// the person moves away and comes back, and a different code is never
  /// delayed.
  static const Duration _repeatWindow = Duration(milliseconds: 2500);

  AppSettings get _settings => widget.settings.value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _createEngine();
    // Building the audio player costs several platform round trips. Doing it
    // now means the first successful read is confirmed on time instead of
    // after a silent pause.
    unawaited(_feedback.warmUp());
  }

  void _createEngine() {
    _engine = MobileScannerEngine(torchEnabled: _settings.autoTorch);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _repeatNoticeTimer?.cancel();
    unawaited(_engine.dispose());
    unawaited(_feedback.dispose());
    super.dispose();
  }

  /// The scanner owns its controller, so `MobileScanner` deliberately leaves
  /// lifecycle handling to this screen. Without this, coming back from the
  /// background — or from the system camera permission dialog — left the
  /// preview frozen with no way to recover other than leaving the tab.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_paused && !_handlingResult) unawaited(_startCamera());
      case AppLifecycleState.inactive:
        unawaited(_stopCamera());
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Every call into the controller can throw: it may be disposed, still
  /// starting, or not yet attached to a widget. A failure here must leave the
  /// screen in a state the user can act on, never in an exception.
  Future<void> _startCamera() async {
    try {
      await _engine.start();
      if (mounted) setState(() => _startFailure = null);
    } on MobileScannerException catch (error) {
      if (mounted) setState(() => _startFailure = _describe(error));
    } on Object {
      if (mounted) {
        setState(() => _startFailure = 'No fue posible iniciar la cámara.');
      }
    }
  }

  Future<void> _stopCamera() async {
    try {
      await _engine.stop();
    } on Object {
      // Stopping an already stopped or disposed camera is not an error here.
    }
  }

  String _describe(MobileScannerException error) => switch (error.errorCode) {
    MobileScannerErrorCode.permissionDenied =>
      'Falta el permiso de cámara. Actívalo en los ajustes del sistema y vuelve a intentarlo.',
    MobileScannerErrorCode.unsupported =>
      'Este dispositivo no permite leer códigos con la cámara.',
    _ => 'La cámara no pudo iniciarse. Toca «Reintentar».',
  };

  /// Replaces the controller and the preview widget. This is the recovery path
  /// offered to the user whenever the camera does not come up.
  Future<void> _restartCamera() async {
    // The old controller is released before the new one exists: both share a
    // single platform camera session, and disposing it afterwards would tear
    // down the session the new controller has just claimed.
    await _stopCamera();
    try {
      await _engine.dispose();
    } on Object {
      // An already disposed controller is exactly the state we want.
    }
    if (!mounted) return;
    setState(() {
      _createEngine();
      _previewKey = UniqueKey();
      _startFailure = null;
      _paused = false;
      _zoom = 0;
      // A manual restart is an explicit «try again»: the repetition filter
      // must not keep ignoring the code the person is pointing at.
      _lastSignature = null;
      _lastDetectedAt = null;
      _repeatNotice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints viewport) {
        final bool compactHeader = viewport.maxHeight < 700;
        final bool compactFileAction =
            viewport.maxWidth < 430 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        return Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                compactHeader ? 10 : 18,
                20,
                compactHeader ? 8 : 14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const _RootCauseMark(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            AppText(
                              'ROOTCAUSE · SEGURIDAD QR',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.25,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            AppText(
                              context.strings.scannerTitle,
                              style: compactHeader
                                  ? Theme.of(context).textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800)
                                  : Theme.of(context).textTheme.titleLarge,
                            ),
                            if (!compactHeader) ...<Widget>[
                              const SizedBox(height: 3),
                              AppText(
                                context.strings.scannerSubtitle,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        button: true,
                        label: kIsWeb
                            ? 'Analizar archivo, planificado para web'
                            : 'Analizar archivo local: imagen o PDF',
                        child: OutlinedButton.icon(
                          onPressed: kIsWeb ? null : _showFileSourcePicker,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: AppText(
                            compactFileAction ? 'Archivo' : 'Analizar archivo',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!compactHeader) ...<Widget>[
                    const SizedBox(height: 12),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _SecurityCapability(
                          icon: Icons.phonelink_lock_outlined,
                          label: 'Análisis local',
                        ),
                        _SecurityCapability(
                          icon: Icons.rule_outlined,
                          label: '26 señales',
                        ),
                        _SecurityCapability(
                          icon: Icons.visibility_off_outlined,
                          label: 'Telemetría cero',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[
                        Color(0xFF26D9BC),
                        Color(0xFF087A6D),
                        Color(0xFF112B27),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(29),
                      child: LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          final ScannerViewportGeometry geometry =
                              ScannerViewportGeometry.forSize(
                                Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                ),
                              );
                          final bool compactPreview = geometry.compact;
                          final Rect window = geometry.scanWindow;
                          return ValueListenableBuilder<MobileScannerState>(
                            valueListenable: _engine.state,
                            builder:
                                (
                                  BuildContext context,
                                  MobileScannerState state,
                                  Widget? child,
                                ) {
                                  final ScanPhase phase = _phaseFor(state);
                                  final bool scanning =
                                      phase == ScanPhase.scanning;
                                  return Stack(
                                    fit: StackFit.expand,
                                    children: <Widget>[
                                      MobileScanner(
                                        key: _previewKey,
                                        controller: _engine.controller,
                                        // No `scanWindow`: the frame is a guide, not a
                                        // gate. As a gate it discarded every code whose
                                        // bounding box fell outside the central square,
                                        // and it did so in silence — a QR the person could
                                        // read perfectly well on screen simply produced
                                        // nothing. Detection now covers the whole preview
                                        // and the frame only helps to aim.
                                        tapToFocus: true,
                                        onDetect: (BarcodeCapture capture) =>
                                            unawaited(
                                              _handleCapture(
                                                capture,
                                                source: 'Cámara',
                                              ),
                                            ),
                                        errorBuilder:
                                            (
                                              BuildContext context,
                                              MobileScannerException error,
                                            ) => _ScannerError(
                                              error: error,
                                              onRetry: _restartCamera,
                                            ),
                                      ),
                                      if (_settings.useScanWindow &&
                                          phase != ScanPhase.unavailable)
                                        ScannerOverlay(
                                          scanWindow: window,
                                          // A captured code keeps the frame lit but still:
                                          // the sweep means «analysing», and analysis is
                                          // over.
                                          active:
                                              scanning ||
                                              phase == ScanPhase.captured,
                                          animate:
                                              !_settings.reduceMotion &&
                                              phase != ScanPhase.captured,
                                        ),
                                      if (phase == ScanPhase.paused)
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child: ColoredBox(
                                              color: Colors.black.withValues(
                                                alpha: 0.35,
                                              ),
                                            ),
                                          ),
                                        ),
                                      Positioned(
                                        top: compactPreview ? 10 : 18,
                                        left: compactPreview ? 10 : 18,
                                        right: compactPreview ? 10 : 18,
                                        child: ScanStatusBar(
                                          phase: phase,
                                          message: _messageFor(phase),
                                          animate: !_settings.reduceMotion,
                                        ),
                                      ),
                                      Positioned(
                                        left: 18,
                                        right: 18,
                                        bottom: compactPreview ? 76 : 82,
                                        child: Row(
                                          children: <Widget>[
                                            const Icon(
                                              Icons.zoom_out,
                                              color: Colors.white,
                                            ),
                                            Expanded(
                                              child: Slider(
                                                value: _zoom,
                                                onChanged: (double value) {
                                                  setState(() => _zoom = value);
                                                  unawaited(
                                                    _engine.setZoomScale(value),
                                                  );
                                                },
                                              ),
                                            ),
                                            const Icon(
                                              Icons.zoom_in,
                                              color: Colors.white,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        left: 12,
                                        right: 12,
                                        bottom: compactPreview ? 10 : 18,
                                        // Wrap, not Row: with large controls or a big text
                                        // scale these four actions do not fit on one line,
                                        // and a second line is better than a clipped one.
                                        child: Wrap(
                                          alignment: WrapAlignment.center,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: 10,
                                          runSpacing: 8,
                                          children: <Widget>[
                                            _CameraButton(
                                              tooltip: 'Linterna',
                                              onPressed:
                                                  state.torchState ==
                                                      TorchState.unavailable
                                                  ? null
                                                  : _engine.toggleTorch,
                                              icon:
                                                  state.torchState ==
                                                      TorchState.on
                                                  ? Icons.flash_on
                                                  : Icons.flash_off,
                                            ),
                                            FilledButton.icon(
                                              onPressed: switch (phase) {
                                                ScanPhase.scanning ||
                                                ScanPhase.paused =>
                                                  _togglePause,
                                                ScanPhase.unavailable =>
                                                  _restartCamera,
                                                ScanPhase.starting ||
                                                ScanPhase.captured => null,
                                              },
                                              style: FilledButton.styleFrom(
                                                backgroundColor: scanning
                                                    ? Colors.white
                                                    : Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                foregroundColor: scanning
                                                    ? Colors.black
                                                    : Theme.of(
                                                        context,
                                                      ).colorScheme.onPrimary,
                                              ),
                                              icon: Icon(switch (phase) {
                                                ScanPhase.scanning =>
                                                  Icons.pause,
                                                ScanPhase.captured =>
                                                  Icons.check_circle,
                                                ScanPhase.paused =>
                                                  Icons.play_arrow,
                                                ScanPhase.unavailable =>
                                                  Icons.refresh,
                                                ScanPhase.starting =>
                                                  Icons.hourglass_top,
                                              }),
                                              label: AppText(switch (phase) {
                                                ScanPhase.scanning => 'Pausar',
                                                ScanPhase.captured => 'Leído',
                                                ScanPhase.paused => 'Reanudar',
                                                ScanPhase.unavailable =>
                                                  'Reintentar',
                                                ScanPhase.starting =>
                                                  'Preparando',
                                              }),
                                            ),
                                            _CameraButton(
                                              tooltip: 'Cambiar cámara',
                                              onPressed: () =>
                                                  _engine.switchCamera(),
                                              icon: Icons.cameraswitch_outlined,
                                            ),
                                            _CameraButton(
                                              tooltip: 'Reiniciar cámara',
                                              onPressed: _restartCamera,
                                              icon: Icons.refresh,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  ScanPhase _phaseFor(MobileScannerState state) {
    if (_startFailure != null || state.error != null) {
      return ScanPhase.unavailable;
    }
    // A read in progress is announced as a capture, not as a pause: the two
    // states are opposite in meaning and used to share the same wording.
    if (_handlingResult) return ScanPhase.captured;
    if (_paused) return ScanPhase.paused;
    if (state.isRunning) return ScanPhase.scanning;
    return ScanPhase.starting;
  }

  String _messageFor(ScanPhase phase) => switch (phase) {
    ScanPhase.starting => 'Iniciando cámara',
    ScanPhase.scanning =>
      _repeatNotice ?? 'Lectura automática en toda la imagen',
    ScanPhase.captured => 'Abriendo el análisis local',
    ScanPhase.paused => 'Lectura detenida',
    ScanPhase.unavailable =>
      _startFailure ?? 'Revisa el permiso de cámara y vuelve a intentarlo.',
  };

  /// Explains a skipped repetition instead of leaving the screen silent.
  ///
  /// The timer restarts while the code stays in front of the lens, so the
  /// message lasts as long as the situation it describes.
  void _showRepeatNotice() {
    if (!mounted) return;
    _repeatNoticeTimer?.cancel();
    _repeatNoticeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _repeatNotice = null);
    });
    if (_repeatNotice == null) {
      setState(
        () => _repeatNotice =
            'Ese código ya se inspeccionó; aparta y apunta otra vez',
      );
    }
  }

  Future<void> _resumeScanning() async {
    if (mounted) setState(() => _paused = false);
    await _startCamera();
  }

  Future<void> _togglePause() async {
    if (_paused) {
      await _resumeScanning();
      return;
    }
    await _stopCamera();
    if (mounted) setState(() => _paused = true);
  }

  Future<void> _showFileSourcePicker() async {
    final String? source = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppText(
                'Elegir fuente',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const AppText('Elegir imagen'),
                subtitle: const AppText('Fotografía o captura almacenada'),
                onTap: () => Navigator.of(context).pop('image'),
              ),
              ListTile(
                leading: const Icon(Icons.collections_outlined),
                title: const AppText('Elegir varias imágenes'),
                subtitle: const AppText('Hasta 20 imágenes'),
                onTap: () => Navigator.of(context).pop('images'),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const AppText('Elegir PDF'),
                subtitle: const AppText('Hasta 50 páginas y 50 MiB'),
                onTap: () => Navigator.of(context).pop('pdf'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (source == 'image') unawaited(_scanSingleImage());
    if (source == 'images') unawaited(_scanFromGallery());
    if (source == 'pdf') unawaited(_scanFromPdf());
  }

  Future<void> _scanSingleImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: FileInspectionLimits.maxImageDimension.toDouble(),
      maxHeight: FileInspectionLimits.maxImageDimension.toDouble(),
      imageQuality: 100,
    );
    if (image != null) await _inspectImages(<XFile>[image]);
  }

  Future<void> _scanFromGallery() async {
    final List<XFile> images = await _imagePicker.pickMultiImage(
      limit: FileInspectionLimits.maxImages,
      maxWidth: FileInspectionLimits.maxImageDimension.toDouble(),
      maxHeight: FileInspectionLimits.maxImageDimension.toDouble(),
      imageQuality: 100,
    );
    if (images.isEmpty || !mounted) return;
    await _inspectImages(images);
  }

  Future<void> _inspectImages(List<XFile> images) async {
    if (!mounted) return;
    final CancellationToken token = CancellationToken();
    int imagesInspected = 0;
    final BatchProgress progress = BatchProgress(label: 'Preparando imágenes')
      ..update(total: images.length);
    try {
      final FileInspectionResult
      result = await _runBatchDialog<FileInspectionResult>(
        progress: progress,
        token: token,
        operation: () async {
          await _stopCamera();
          try {
            if (images.length > FileInspectionLimits.maxImages) {
              throw const FormatException(
                'El lote supera el límite de 20 imágenes.',
              );
            }
            for (final XFile image in images) {
              if (!FileInspectionInputValidator.isSupportedImageName(
                image.name,
              )) {
                throw const FormatException(
                  'Una imagen no tiene una extensión compatible.',
                );
              }
              if (image.mimeType != null &&
                  !image.mimeType!.toLowerCase().startsWith('image/')) {
                throw const FormatException(
                  'El tipo declarado del archivo no coincide con una imagen.',
                );
              }
              if (!FileInspectionInputValidator.isAllowedFileSize(
                await image.length(),
              )) {
                throw const FormatException(
                  'Una imagen supera el límite local de 50 MiB.',
                );
              }
            }
            final List<FileInspectionUnit> units = <FileInspectionUnit>[
              for (int index = 0; index < images.length; index++)
                FileInspectionUnit(
                  imagePath: images[index].path,
                  source: 'Imagen · ${index + 1}',
                ),
            ];
            return FileInspectionCoordinator(
              decoder: NativeFileCodeDecoder(_engine),
            ).inspect(
              units,
              cancellationToken: token,
              onProgress: (FileInspectionProgress state) {
                if (state.completed) imagesInspected = state.current;
                progress.update(
                  label:
                      'Analizando imagen ${state.current} de ${state.total} · ${state.codesFound} códigos encontrados',
                  current: state.current,
                  total: state.total,
                );
              },
            );
          } finally {
            if (mounted && !_paused) await _startCamera();
          }
        },
      );
      if (!mounted) return;
      if (result.records.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(
              images.length == 1
                  ? 'No encontramos códigos legibles en esta imagen. Prueba una imagen de mayor resolución y comprueba que el código completo sea visible.'
                  : 'No encontramos códigos compatibles en las ${images.length} imágenes. Prueba archivos de mayor resolución y comprueba que cada código completo sea visible.',
            ),
          ),
        );
      } else {
        await _persistAndShow(
          result.records,
          batchSummary: ScanBatchSummary(
            files: images.length,
            pagesInspected: 0,
            unitsWithoutCodes: result.unitsWithoutCodes,
          ),
        );
      }
    } on OperationCancelledException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(
              'Análisis cancelado: se inspeccionaron $imagesInspected de ${images.length} imágenes. No se modificó el historial.',
            ),
          ),
        );
      }
    } on FormatException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: AppText(error.message)));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AppText('No fue posible analizar una o más imágenes.'),
          ),
        );
      }
    }
  }

  Future<void> _scanFromPdf() async {
    if (kIsWeb) return;
    final CancellationToken token = CancellationToken();
    final BatchProgress progress = BatchProgress(
      label: 'Seleccionando documento',
    );
    final List<RenderedPdfPage> pages = <RenderedPdfPage>[];
    PdfRenderBatch? renderedBatch;
    int pdfPagesInspected = 0;
    int pdfPagesPlanned = 0;
    try {
      final FileInspectionResult?
      result = await _runBatchDialog<FileInspectionResult?>(
        progress: progress,
        token: token,
        operation: () async {
          await _stopCamera();
          try {
            final PdfRenderBatch batch = await PdfPageRenderer.pickAndRender(
              maxPages: FileInspectionLimits.maxPdfPages,
              cancellationToken: token,
              onProgress: (int current, int total) => progress.update(
                label: 'Renderizando página $current de $total',
                current: current,
                total: total * 2,
              ),
              onDocumentOpened: (int total, int inspected) {
                pdfPagesPlanned = inspected;
                progress.update(
                  label: total > inspected
                      ? 'Documento de $total páginas · se inspeccionarán las primeras $inspected'
                      : 'Documento de $total páginas · se inspeccionarán todas',
                  total: inspected * 2,
                );
              },
            );
            if (!batch.selected) return null;
            renderedBatch = batch;
            pages.addAll(batch.pages);
            final List<FileInspectionUnit> units = pages
                .map(
                  (RenderedPdfPage page) => FileInspectionUnit(
                    imagePath: page.imagePath,
                    source: 'PDF · página ${page.pageNumber}',
                  ),
                )
                .toList(growable: false);
            return FileInspectionCoordinator(
              decoder: NativeFileCodeDecoder(_engine),
            ).inspect(
              units,
              cancellationToken: token,
              onProgress: (FileInspectionProgress state) {
                if (state.completed) pdfPagesInspected = state.current;
                progress.update(
                  label:
                      'Analizando página ${state.current} de ${state.total} · ${state.codesFound} códigos encontrados',
                  current: pages.length + state.current,
                  total: pages.length * 2,
                );
              },
            );
          } finally {
            await PdfPageRenderer.cleanup(pages);
            if (mounted && !_paused) await _startCamera();
          }
        },
      );
      if (!mounted) return;
      if (result == null) return;
      if (result.records.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(
              (renderedBatch?.truncated ?? false)
                  ? 'No se encontraron códigos compatibles en las ${result.unitsInspected} páginas inspeccionadas. El documento tiene ${renderedBatch!.totalPages} páginas y se aplicó el límite de ${renderedBatch!.inspectedPages}.'
                  : 'No se encontraron códigos compatibles en las ${result.unitsInspected} páginas inspeccionadas.',
            ),
          ),
        );
      } else {
        await _persistAndShow(
          result.records,
          batchSummary: ScanBatchSummary(
            files: 1,
            pagesInspected: result.unitsInspected,
            unitsWithoutCodes: result.unitsWithoutCodes,
            totalPages: renderedBatch?.totalPages,
          ),
        );
      }
    } on OperationCancelledException {
      if (mounted) {
        final String inspected = pdfPagesPlanned > 0
            ? ' Se inspeccionaron $pdfPagesInspected de $pdfPagesPlanned páginas.'
            : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(
              'Análisis de PDF cancelado.$inspected No se modificó el historial.',
            ),
          ),
        );
      }
    } on FormatException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: AppText(error.message)));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AppText('No fue posible analizar el documento PDF.'),
          ),
        );
      }
    }
  }

  Future<T> _runBatchDialog<T>({
    required BatchProgress progress,
    required CancellationToken token,
    required Future<T> Function() operation,
  }) async {
    bool dialogOpen = true;
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    final Future<void> dialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          _BatchProgressDialog(progress: progress, token: token),
    ).whenComplete(() => dialogOpen = false);
    await Future<void>.delayed(Duration.zero);
    try {
      return await operation();
    } finally {
      if (dialogOpen && navigator.mounted) navigator.pop();
      await dialog;
      progress.dispose();
      token.dispose();
    }
  }

  Future<void> _handleCapture(
    BarcodeCapture capture, {
    required String source,
  }) async {
    if (_handlingResult || _paused || !mounted) return;
    final Map<String, Barcode> unique = <String, Barcode>{};
    for (final Barcode barcode in capture.barcodes) {
      final String raw = ScanRecord.payloadForBarcode(barcode);
      if (raw.isNotEmpty) unique.putIfAbsent(raw, () => barcode);
    }
    if (unique.isEmpty) return;

    final List<String> signature = unique.keys.toList()..sort();
    final String joined = signature.join('|');
    final DateTime now = DateTime.now();
    if (_lastSignature == joined &&
        _lastDetectedAt != null &&
        now.difference(_lastDetectedAt!) < _repeatWindow) {
      // Keep the cooldown alive while the code is still in view, and say so.
      // Silence here was indistinguishable from a broken scanner.
      _lastDetectedAt = now;
      _showRepeatNotice();
      return;
    }
    _lastSignature = joined;
    _lastDetectedAt = now;
    _repeatNoticeTimer?.cancel();
    if (mounted) {
      setState(() {
        _handlingResult = true;
        _repeatNotice = null;
      });
    }

    try {
      await _stopCamera();
      // Not awaited: the tone and the vibration confirm the read, but making
      // the result wait for the audio plugin is what made a successful scan
      // feel like nothing had happened.
      unawaited(
        _feedback.success(
          sound: _settings.soundEnabled,
          vibration: _settings.vibrationEnabled,
        ),
      );
      final List<ScanRecord> records = unique.values
          .map(
            (Barcode barcode) =>
                ScanRecord.fromBarcode(barcode, source: source, scannedAt: now),
          )
          .toList(growable: false);
      await _persistAndShow(records);
    } finally {
      // Restart the window when the sheet closes, so a code left in front of
      // the camera does not immediately reopen its own result.
      _lastDetectedAt = DateTime.now();
      if (mounted) setState(() => _handlingResult = false);
      if (mounted && !_paused) await _startCamera();
    }
  }

  Future<void> _persistAndShow(
    List<ScanRecord> records, {
    ScanBatchSummary? batchSummary,
  }) async {
    if (_settings.saveHistory && !_settings.privateMode) {
      final List<ScanRecord> persistent = ScanPersistencePolicy.eligible(
        records,
      );
      await widget.store.addAll(persistent);
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (BuildContext context) => ScanResultsSheet(
        records: records,
        settings: widget.settings,
        batchSummary: batchSummary,
      ),
    );
  }
}

class _RootCauseMark extends StatelessWidget {
  const _RootCauseMark();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[colors.primary, const Color(0xFF19BDA4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(
        Icons.qr_code_2_rounded,
        color: colors.onPrimary,
        size: 27,
        semanticLabel: 'RootCause QR',
      ),
    );
  }
}

class _SecurityCapability extends StatelessWidget {
  const _SecurityCapability({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.8)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: colors.primary),
          const SizedBox(width: 6),
          AppText(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _CameraButton extends StatelessWidget {
  const _CameraButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });
  final String tooltip;
  final Future<void> Function()? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed == null ? null : () => unawaited(onPressed!()),
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.black.withValues(alpha: 0.35),
      ),
      icon: Icon(icon),
    );
  }
}

class _BatchProgressDialog extends StatelessWidget {
  const _BatchProgressDialog({required this.progress, required this.token});
  final BatchProgress progress;
  final CancellationToken token;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const AppText('Procesando localmente'),
      content: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[progress, token]),
        builder: (BuildContext context, Widget? child) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            LinearProgressIndicator(value: progress.fraction),
            const SizedBox(height: 12),
            AppText(progress.label, textAlign: TextAlign.center),
            if (progress.total > 0)
              AppText(
                '${progress.current}/${progress.total}',
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton.icon(
          onPressed: token.isCancelled ? null : token.cancel,
          icon: const Icon(Icons.cancel_outlined),
          label: const AppText('Cancelar'),
        ),
      ],
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error, required this.onRetry});
  final MobileScannerException error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.no_photography_outlined, size: 54),
              const SizedBox(height: 14),
              AppText(
                'No se pudo iniciar la cámara',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              AppText(
                error.errorCode == MobileScannerErrorCode.permissionDenied
                    ? 'Concede el permiso de cámara en los ajustes del sistema y vuelve a intentarlo.'
                    : 'Cierra otras aplicaciones que estén usando la cámara y reinicia la lectura.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => unawaited(onRetry()),
                icon: const Icon(Icons.refresh),
                label: const AppText('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
