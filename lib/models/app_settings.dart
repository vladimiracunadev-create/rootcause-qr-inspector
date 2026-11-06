import 'package:flutter/material.dart';
import 'package:rootcause_qr_inspector/core/feature_flags/feature_flags.dart';

enum AppLanguage { system, esCl, es, en, fr, de }

/// Preferencias del usuario, inmutables y sin datos sensibles.
///
/// Se guardan con `SharedPreferencesAsync` —no en la base cifrada— porque
/// ninguna de ellas contiene carga escaneada. Los valores por defecto están
/// elegidos para el modo más conservador: se pide confirmación antes de abrir,
/// se ocultan los valores sensibles y el portapapeles se borra a los 30
/// segundos.
///
/// `historyRetentionDays == 0` significa «sin límite», no «borrar todo».
/// [featureFlags] mantiene apagadas las capacidades que aún no forman parte
/// del contrato estable.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.language = AppLanguage.system,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.saveHistory = true,
    this.privateMode = false,
    this.autoTorch = false,
    this.useScanWindow = true,
    this.readingAreaScale = 0,
    this.confirmBeforeOpen = true,
    this.hideSensitiveValues = true,
    this.biometricLock = false,
    this.highContrast = false,
    this.largeControls = false,
    this.reduceMotion = false,
    this.clearClipboardSeconds = 30,
    this.historyRetentionDays = 0,
    this.featureFlags = const FeatureFlags(),
  });

  final ThemeMode themeMode;
  final AppLanguage language;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool saveHistory;
  final bool privateMode;
  final bool autoTorch;

  /// Whether the aiming frame is drawn over the camera preview.
  ///
  /// It is a visual guide only. It used to be handed to the scanner as a hard
  /// filter, which discarded — in silence — every code whose bounding box fell
  /// outside the central square, including codes the person could read
  /// perfectly well on screen. The preference key is unchanged so existing
  /// installations keep their choice.
  final bool useScanWindow;

  /// How wide the reading area is, from 0 (smallest frame) to 1 (full screen).
  ///
  /// It is set with the gesture the phone already uses for this —pinch out to
  /// maximise, pinch in to minimise— over the camera preview, and the chosen
  /// amount is remembered: someone inspecting codes on a wall or on a receipt
  /// wants the same framing on the next read. Past the maximised threshold of
  /// `ScannerViewportGeometry` the header folds away and the preview takes over
  /// the whole tab.
  ///
  /// It is stored as a number, not as a maximised/minimised flag, because the
  /// gesture is continuous: the percentage shown while pinching is this value.
  final double readingAreaScale;
  final bool confirmBeforeOpen;
  final bool hideSensitiveValues;
  final bool biometricLock;
  final bool highContrast;
  final bool largeControls;
  final bool reduceMotion;
  final int clearClipboardSeconds;
  final int historyRetentionDays;
  final FeatureFlags featureFlags;

  Locale? get locale => switch (language) {
    AppLanguage.system => null,
    AppLanguage.esCl => const Locale('es', 'CL'),
    AppLanguage.es => const Locale('es'),
    AppLanguage.en => const Locale('en'),
    AppLanguage.fr => const Locale('fr'),
    AppLanguage.de => const Locale('de'),
  };

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppLanguage? language,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? saveHistory,
    bool? privateMode,
    bool? autoTorch,
    bool? useScanWindow,
    double? readingAreaScale,
    bool? confirmBeforeOpen,
    bool? hideSensitiveValues,
    bool? biometricLock,
    bool? highContrast,
    bool? largeControls,
    bool? reduceMotion,
    int? clearClipboardSeconds,
    int? historyRetentionDays,
    FeatureFlags? featureFlags,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    language: language ?? this.language,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    saveHistory: saveHistory ?? this.saveHistory,
    privateMode: privateMode ?? this.privateMode,
    autoTorch: autoTorch ?? this.autoTorch,
    useScanWindow: useScanWindow ?? this.useScanWindow,
    readingAreaScale: readingAreaScale ?? this.readingAreaScale,
    confirmBeforeOpen: confirmBeforeOpen ?? this.confirmBeforeOpen,
    hideSensitiveValues: hideSensitiveValues ?? this.hideSensitiveValues,
    biometricLock: biometricLock ?? this.biometricLock,
    highContrast: highContrast ?? this.highContrast,
    largeControls: largeControls ?? this.largeControls,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    clearClipboardSeconds: clearClipboardSeconds ?? this.clearClipboardSeconds,
    historyRetentionDays: historyRetentionDays ?? this.historyRetentionDays,
    featureFlags: featureFlags ?? this.featureFlags,
  );
}
