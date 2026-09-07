import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('es', 'CL'),
    Locale('es'),
    Locale('en'),
    Locale('fr'),
    Locale('de'),
  ];

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      const AppLocalizations(Locale('es'));

  int? get _translationIndex => switch (locale.languageCode) {
    'en' => 0,
    'fr' => 1,
    'de' => 2,
    _ => null,
  };

  String get appTitle => 'RootCause QR Inspector';
  String get scan => translate('Escanear');
  String get inventory => translate('Inventario');
  String get generate => translate('Generar');
  String get history => translate('Historial');
  String get settings => translate('Ajustes');
  String get scannerTitle => translate('Inspector de seguridad QR');
  String get scannerSubtitle => translate(
    'Observa el destino, explica el riesgo y decide antes de actuar',
  );
  String get temporaryMode => translate('Modo temporal');
  String get recoveryCenter => translate('Centro de recuperación');
  String get retry => translate('Reintentar');
  String get cancel => translate('Cancelar');
  String get continueLabel => translate('Continuar');
  String get language => translate('Idioma');
  String get quickGuide => translate('Guía rápida de la aplicación');
  String get inventoryGuide => translate('Cómo usar Inventario');

  String tabTitle(int index) =>
      <String>[scan, inventory, generate, history, settings][index];

  String tabDescription(int index) => <List<String>>[
    const <String>[
      'Inspecciona un código con la cámara o desde un archivo local. RootCause lo explica antes de cualquier acción externa.',
      'Inspect a code with the camera or from a local file. RootCause explains it before any external action.',
      'Inspectez un code avec la caméra ou depuis un fichier local. RootCause l’explique avant toute action externe.',
      'Prüfen Sie einen Code mit der Kamera oder aus einer lokalen Datei. RootCause erklärt ihn vor jeder externen Aktion.',
    ],
    const <String>[
      'Cuenta productos repetidos por sesión. Cada lectura suma una unidad; cierra la sesión cuando termines el conteo.',
      'Count repeated products by session. Each scan adds one unit; close the session when the count is complete.',
      'Comptez des produits répétés par session. Chaque lecture ajoute une unité ; fermez la session lorsque le comptage est terminé.',
      'Zählen Sie wiederholte Produkte pro Sitzung. Jeder Scan fügt eine Einheit hinzu; schließen Sie die Sitzung nach dem Zählen.',
    ],
    const <String>[
      'Crea códigos QR y de barras localmente, revisa el contenido codificado y exporta PNG o SVG.',
      'Create QR and barcodes locally, review the encoded content, then export PNG or SVG.',
      'Créez localement des QR codes et codes-barres, vérifiez le contenu encodé, puis exportez en PNG ou SVG.',
      'Erstellen Sie QR- und Barcodes lokal, prüfen Sie den kodierten Inhalt und exportieren Sie PNG oder SVG.',
    ],
    const <String>[
      'Revisa inspecciones no sensibles, busca, marca favoritos y exporta o importa un respaldo.',
      'Review previous non-sensitive inspections, search, mark favorites, and export or import a backup.',
      'Consultez les inspections non sensibles, recherchez, ajoutez des favoris et exportez ou importez une sauvegarde.',
      'Prüfen Sie frühere nicht sensible Inspektionen, suchen Sie, markieren Sie Favoriten und importieren oder exportieren Sie Sicherungen.',
    ],
    const <String>[
      'Elige apariencia, idioma, privacidad, retención, accesibilidad y controles de datos locales.',
      'Choose appearance, language, privacy, retention, accessibility, and local data controls.',
      'Choisissez l’apparence, la langue, la confidentialité, la conservation, l’accessibilité et les contrôles des données locales.',
      'Wählen Sie Darstellung, Sprache, Datenschutz, Aufbewahrung, Barrierefreiheit und lokale Datensteuerung.',
    ],
  ][index][(_translationIndex ?? -1) + 1];

  String translate(String source) {
    final int? index = _translationIndex;
    if (index == null || source.isEmpty) return source;
    final List<String>? values = _translations[source];
    if (values != null) return values[index];
    return _translateDynamic(source, index);
  }

  String _translateDynamic(String source, int index) {
    Match? match = RegExp(
      r'^(\d+) códigos · (\d+) unidades · (.+)$',
    ).firstMatch(source);
    if (match != null) {
      return switch (index) {
        0 => '${match[1]} codes · ${match[2]} units · ${match[3]}',
        1 => '${match[1]} codes · ${match[2]} unités · ${match[3]}',
        _ => '${match[1]} Codes · ${match[2]} Einheiten · ${match[3]}',
      };
    }
    match = RegExp(
      r'^(\d+) códigos únicos · (\d+) unidades$',
    ).firstMatch(source);
    if (match != null) {
      return switch (index) {
        0 => '${match[1]} unique codes · ${match[2]} units',
        1 => '${match[1]} codes uniques · ${match[2]} unités',
        _ => '${match[1]} eindeutige Codes · ${match[2]} Einheiten',
      };
    }
    match = RegExp(r'^(\d+) registros guardados$').firstMatch(source);
    if (match != null) {
      return switch (index) {
        0 => '${match[1]} saved records',
        1 => '${match[1]} enregistrements sauvegardés',
        _ => '${match[1]} gespeicherte Einträge',
      };
    }
    match = RegExp(r'^(\d+) lecturas importadas\.$').firstMatch(source);
    if (match != null) {
      return switch (index) {
        0 => '${match[1]} inspections imported.',
        1 => '${match[1]} inspections importées.',
        _ => '${match[1]} Prüfungen importiert.',
      };
    }
    for (final (String, List<String>) prefix in _dynamicPrefixes) {
      if (source.startsWith(prefix.$1)) {
        return '${prefix.$2[index]}${translate(source.substring(prefix.$1.length))}';
      }
    }
    return source;
  }

  static const List<(String, List<String>)>
  _dynamicPrefixes = <(String, List<String>)>[
    ('Advertencia: ', <String>['Warning: ', 'Avertissement : ', 'Warnung: ']),
        ('Críticos: ', <String>['Critical: ', 'Critiques : ', 'Kritisch: ']),
        ('Duplicados: ', <String>['Duplicates: ', 'Doublons : ', 'Duplikate: ']),
        ('Rechazados: ', <String>['Rejected: ', 'Rejetés : ', 'Abgelehnt: ']),
        ('Registros válidos: ', <String>[
          'Valid records: ',
          'Enregistrements valides : ',
          'Gültige Einträge: ',
        ]),
    ('Códigos: ', <String>['Codes: ', 'Codes : ', 'Codes: ']),
    ('Únicos: ', <String>['Unique: ', 'Uniques : ', 'Eindeutig: ']),
    ('Archivos: ', <String>['Files: ', 'Fichiers : ', 'Dateien: ']),
    (
      'Páginas inspeccionadas: ',
      <String>['Pages inspected: ', 'Pages inspectées : ', 'Geprüfte Seiten: '],
    ),
    (
      'Páginas totales: ',
      <String>['Total pages: ', 'Pages totales : ', 'Seiten insgesamt: '],
    ),
    (
      'Sin código legible: ',
      <String>[
        'No readable code: ',
        'Sans code lisible : ',
        'Kein lesbarer Code: ',
      ],
    ),
    (
      'Sin hallazgos locales: ',
      <String>[
        'No local findings: ',
        'Aucun constat local : ',
        'Keine lokalen Befunde: ',
      ],
    ),
    ('Decisión: ', <String>['Decision: ', 'Décision : ', 'Entscheidung: ']),
    (
      'Acción sugerida: ',
      <String>[
        'Suggested action: ',
        'Action suggérée : ',
        'Empfohlene Aktion: ',
      ],
    ),
    (
      'No comprobado: ',
      <String>['Not verified: ', 'Non vérifié : ', 'Nicht geprüft: '],
    ),
    ('Hipótesis: ', <String>['Hypothesis: ', 'Hypothèse : ', 'Hypothese: ']),
  ];

  static const Map<String, List<String>> _translations = <String, List<String>>{
    'Escanear': <String>['Inspect', 'Inspecter', 'Prüfen'],
    'Inventario': <String>['Inventory', 'Inventaire', 'Inventar'],
    'Generar': <String>['Generate', 'Générer', 'Erstellen'],
    'Historial': <String>['History', 'Historique', 'Verlauf'],
    'Ajustes': <String>['Settings', 'Réglages', 'Einstellungen'],
    'Inspector de seguridad QR': <String>[
      'QR security inspector',
      'Inspecteur de sécurité QR',
      'QR-Sicherheitsinspektor',
    ],
    'Observa el destino, explica el riesgo y decide antes de actuar': <String>[
      'See the destination, understand the risk, and decide before acting',
      'Voyez la destination, comprenez le risque et décidez avant d’agir',
      'Ziel prüfen, Risiko verstehen und vor dem Handeln entscheiden',
    ],
    'Sistema': <String>['System', 'Système', 'System'],
    'Claro': <String>['Light', 'Clair', 'Hell'],
    'Oscuro': <String>['Dark', 'Sombre', 'Dunkel'],
    'Idioma': <String>['Language', 'Langue', 'Sprache'],
    'Apariencia': <String>['Appearance', 'Apparence', 'Darstellung'],
    'Inspección QR': <String>['QR inspection', 'Inspection QR', 'QR-Prüfung'],
    'Privacidad y seguridad': <String>[
      'Privacy and security',
      'Confidentialité et sécurité',
      'Datenschutz und Sicherheit',
    ],
    'Datos y compatibilidad': <String>[
      'Data and compatibility',
      'Données et compatibilité',
      'Daten und Kompatibilität',
    ],
    'Acerca de': <String>['About', 'À propos', 'Info'],
    'Alto contraste': <String>[
      'High contrast',
      'Contraste élevé',
      'Hoher Kontrast',
    ],
    'Controles más grandes': <String>[
      'Larger controls',
      'Commandes agrandies',
      'Größere Bedienelemente',
    ],
    'Aumenta las superficies táctiles sin reducir el tamaño del texto del sistema.':
        <String>[
          'Increases touch targets without reducing the system text size.',
          'Agrandit les zones tactiles sans réduire la taille du texte système.',
          'Vergrößert Touch-Ziele, ohne die Systemschrift zu verkleinern.',
        ],
    'Reducir movimiento': <String>[
      'Reduce motion',
      'Réduire les animations',
      'Bewegung reduzieren',
    ],
    'Marco de encuadre': <String>[
      'Aiming frame',
      'Cadre de visée',
      'Zielrahmen',
    ],
    'Dibuja la guía central. La lectura analiza toda la imagen, dentro y fuera del marco.': <String>[
      'Shows the central guide. Detection analyzes the whole image, inside and outside the frame.',
      'Affiche le guide central. La détection analyse toute l’image, dans et hors du cadre.',
      'Zeigt die mittlere Führung. Die Erkennung prüft das gesamte Bild innerhalb und außerhalb des Rahmens.',
    ],
    'Linterna al iniciar': <String>[
      'Torch on start',
      'Lampe au démarrage',
      'Licht beim Start',
    ],
    'Sonido de confirmación': <String>[
      'Confirmation sound',
      'Son de confirmation',
      'Bestätigungston',
    ],
    'Vibración': <String>['Vibration', 'Vibration', 'Vibration'],
    'Guardar historial': <String>[
      'Save history',
      'Enregistrer l’historique',
      'Verlauf speichern',
    ],
    'Modo temporal': <String>[
      'Temporary mode',
      'Mode temporaire',
      'Temporärer Modus',
    ],
    'Mientras esté activa, ninguna lectura se guarda.': <String>[
      'While enabled, no inspection is saved.',
      'Tant qu’il est actif, aucune inspection n’est enregistrée.',
      'Solange aktiviert, wird keine Prüfung gespeichert.',
    ],
    'Confirmar antes de abrir': <String>[
      'Confirm before opening',
      'Confirmer avant d’ouvrir',
      'Vor dem Öffnen bestätigen',
    ],
    'Ocultar valores sensibles': <String>[
      'Hide sensitive values',
      'Masquer les valeurs sensibles',
      'Sensible Werte ausblenden',
    ],
    'Protege contraseñas Wi-Fi, secretos OTP, pagos e identificaciones.': <String>[
      'Protects Wi-Fi passwords, OTP secrets, payments, and identification data.',
      'Protège les mots de passe Wi-Fi, secrets OTP, paiements et identifiants.',
      'Schützt WLAN-Passwörter, OTP-Geheimnisse, Zahlungen und Identitätsdaten.',
    ],
    'Bloqueo de la aplicación': <String>[
      'App lock',
      'Verrouillage de l’application',
      'App-Sperre',
    ],
    'Usa huella, rostro, PIN, patrón o código cuando la plataforma lo permite.':
        <String>[
          'Uses fingerprint, face, PIN, pattern, or passcode when supported.',
          'Utilise empreinte, visage, PIN, schéma ou code lorsque la plateforme le permet.',
          'Verwendet Fingerabdruck, Gesicht, PIN, Muster oder Code, wenn unterstützt.',
        ],
    'Borrar portapapeles': <String>[
      'Clear clipboard',
      'Effacer le presse-papiers',
      'Zwischenablage leeren',
    ],
    'El contenido copiado se elimina automáticamente si no cambió.': <String>[
      'Copied content is cleared automatically if it has not changed.',
      'Le contenu copié est effacé automatiquement s’il n’a pas changé.',
      'Kopierte Inhalte werden automatisch gelöscht, wenn sie unverändert sind.',
    ],
    'Nunca': <String>['Never', 'Jamais', 'Nie'],
    'Retención del historial': <String>[
      'History retention',
      'Conservation de l’historique',
      'Verlaufsaufbewahrung',
    ],
    'Elimina automáticamente las lecturas más antiguas al iniciar o cambiar esta opción.': <String>[
      'Automatically removes older inspections at startup or when this option changes.',
      'Supprime automatiquement les anciennes inspections au démarrage ou lors d’un changement.',
      'Entfernt ältere Prüfungen automatisch beim Start oder bei Änderung dieser Option.',
    ],
    'Sin límite': <String>['No limit', 'Sans limite', 'Unbegrenzt'],
    '30 días': <String>['30 days', '30 jours', '30 Tage'],
    '90 días': <String>['90 days', '90 jours', '90 Tage'],
    '1 año': <String>['1 year', '1 an', '1 Jahr'],
    'Formatos compatibles': <String>[
      'Supported formats',
      'Formats compatibles',
      'Unterstützte Formate',
    ],
    'Centro de recuperación': <String>[
      'Recovery center',
      'Centre de récupération',
      'Wiederherstellungscenter',
    ],
    'Revisa migraciones, registros dañados y diagnóstico privado.': <String>[
      'Review migrations, damaged records, and private diagnostics.',
      'Consultez les migrations, enregistrements endommagés et diagnostics privés.',
      'Prüfen Sie Migrationen, beschädigte Einträge und private Diagnosen.',
    ],
    'Rotar llave de cifrado': <String>[
      'Rotate encryption key',
      'Renouveler la clé de chiffrement',
      'Verschlüsselungsschlüssel wechseln',
    ],
    'Borrar todo el historial': <String>[
      'Delete all history',
      'Supprimer tout l’historique',
      'Gesamten Verlauf löschen',
    ],
    'Modo temporal activo': <String>[
      'Temporary mode active',
      'Mode temporaire actif',
      'Temporärer Modus aktiv',
    ],
    'Los datos persistentes no se están utilizando.': <String>[
      'Persistent data is not being used.',
      'Les données persistantes ne sont pas utilisées.',
      'Persistente Daten werden nicht verwendet.',
    ],
    'Guía rápida de la aplicación': <String>[
      'Quick app guide',
      'Guide rapide de l’application',
      'App-Kurzanleitung',
    ],
    'Consulta qué hace cada pestaña y cuándo usarla.': <String>[
      'See what each tab does and when to use it.',
      'Découvrez le rôle de chaque onglet et quand l’utiliser.',
      'Erfahren Sie, was jeder Tab macht und wann er sinnvoll ist.',
    ],
    'Inventario continuo': <String>[
      'Continuous inventory',
      'Inventaire continu',
      'Fortlaufendes Inventar',
    ],
    'Cómo usar Inventario': <String>[
      'How to use Inventory',
      'Comment utiliser Inventaire',
      'Inventar verwenden',
    ],
    'Cuenta unidades repetidas sin confundirlas con códigos únicos.': <String>[
      'Count repeated units without confusing them with unique codes.',
      'Comptez les unités répétées sans les confondre avec les codes uniques.',
      'Zählen Sie wiederholte Einheiten, ohne sie mit eindeutigen Codes zu verwechseln.',
    ],
    '1. Crea una sesión con un nombre reconocible.': <String>[
      '1. Create a session with a recognizable name.',
      '1. Créez une session avec un nom reconnaissable.',
      '1. Erstellen Sie eine Sitzung mit einem eindeutigen Namen.',
    ],
    '2. Escanea cada unidad física; el mismo código puede sumar varias veces.': <String>[
      '2. Scan each physical unit; the same code may be counted more than once.',
      '2. Scannez chaque unité physique ; un même code peut être compté plusieurs fois.',
      '2. Scannen Sie jede physische Einheit; derselbe Code kann mehrfach gezählt werden.',
    ],
    '3. Revisa cantidades, corrige notas y cierra la sesión al terminar.': <String>[
      '3. Review quantities, edit notes, and close the session when finished.',
      '3. Vérifiez les quantités, modifiez les notes et fermez la session à la fin.',
      '3. Prüfen Sie Mengen, bearbeiten Sie Notizen und schließen Sie die Sitzung.',
    ],
    '4. Exporta CSV, JSON o Excel para continuar el trabajo fuera de la app.': <String>[
      '4. Export CSV, JSON, or Excel to continue working outside the app.',
      '4. Exportez en CSV, JSON ou Excel pour poursuivre le travail hors de l’application.',
      '4. Exportieren Sie CSV, JSON oder Excel zur weiteren Bearbeitung außerhalb der App.',
    ],
    'Entendido': <String>['Got it', 'Compris', 'Verstanden'],
    'Nombre de la sesión': <String>[
      'Session name',
      'Nom de la session',
      'Sitzungsname',
    ],
    'Ej.: Bodega central agosto': <String>[
      'Example: Central warehouse August',
      'Ex. : Entrepôt central août',
      'Beispiel: Zentrallager August',
    ],
    'Iniciar inventario': <String>[
      'Start inventory',
      'Démarrer l’inventaire',
      'Inventar starten',
    ],
    'Importar JSON': <String>[
      'Import JSON',
      'Importer JSON',
      'JSON importieren',
    ],
    'Aún no existen sesiones de inventario.': <String>[
      'There are no inventory sessions yet.',
      'Aucune session d’inventaire pour le moment.',
      'Noch keine Inventarsitzungen vorhanden.',
    ],
    'Exportar CSV': <String>['Export CSV', 'Exporter CSV', 'CSV exportieren'],
    'Exportar JSON': <String>[
      'Export JSON',
      'Exporter JSON',
      'JSON exportieren',
    ],
    'Exportar Excel XLSX': <String>[
      'Export Excel XLSX',
      'Exporter Excel XLSX',
      'Excel XLSX exportieren',
    ],
    'Reabrir sesión': <String>[
      'Reopen session',
      'Rouvrir la session',
      'Sitzung erneut öffnen',
    ],
    'Eliminar': <String>['Delete', 'Supprimer', 'Löschen'],
    'Cerrar': <String>['Close', 'Fermer', 'Schließen'],
    'Escanea el primer producto para comenzar.': <String>[
      'Scan the first product to begin.',
      'Scannez le premier produit pour commencer.',
      'Scannen Sie das erste Produkt, um zu beginnen.',
    ],
    'Editar nota': <String>[
      'Edit note',
      'Modifier la note',
      'Notiz bearbeiten',
    ],
    'Quitar del inventario': <String>[
      'Remove from inventory',
      'Retirer de l’inventaire',
      'Aus Inventar entfernen',
    ],
    'Cerrar inventario': <String>[
      'Close inventory',
      'Fermer l’inventaire',
      'Inventar schließen',
    ],
    'La sesión quedará guardada y podrá exportarse, pero ya no aceptará nuevas lecturas.': <String>[
      'The session will remain saved and exportable, but it will no longer accept scans.',
      'La session restera enregistrée et exportable, mais n’acceptera plus de lectures.',
      'Die Sitzung bleibt gespeichert und exportierbar, nimmt aber keine Scans mehr an.',
    ],
    'Cerrar sesión': <String>[
      'Close session',
      'Fermer la session',
      'Sitzung schließen',
    ],
    'Cancelar': <String>['Cancel', 'Annuler', 'Abbrechen'],
    'Continuar': <String>['Continue', 'Continuer', 'Fortfahren'],
    'Guardar': <String>['Save', 'Enregistrer', 'Speichern'],
    'Copiar': <String>['Copy', 'Copier', 'Kopieren'],
    'Compartir': <String>['Share', 'Partager', 'Teilen'],
    'Exportar': <String>['Export', 'Exporter', 'Exportieren'],
    'Reintentar': <String>['Retry', 'Réessayer', 'Erneut versuchen'],
    'Analizar archivo': <String>[
      'Inspect file',
      'Inspecter un fichier',
      'Datei prüfen',
    ],
    'Archivo': <String>['File', 'Fichier', 'Datei'],
    'Elegir fuente': <String>[
      'Choose source',
      'Choisir la source',
      'Quelle wählen',
    ],
    'Elegir imagen': <String>[
      'Choose image',
      'Choisir une image',
      'Bild auswählen',
    ],
    'Elegir varias imágenes': <String>[
      'Choose multiple images',
      'Choisir plusieurs images',
      'Mehrere Bilder auswählen',
    ],
    'Elegir PDF': <String>['Choose PDF', 'Choisir un PDF', 'PDF auswählen'],
    'Fotografía o captura almacenada': <String>[
      'Stored photo or screenshot',
      'Photo ou capture enregistrée',
      'Gespeichertes Foto oder Bildschirmbild',
    ],
    'Hasta 20 imágenes': <String>[
      'Up to 20 images',
      'Jusqu’à 20 images',
      'Bis zu 20 Bilder',
    ],
    'Hasta 50 páginas y 50 MiB': <String>[
      'Up to 50 pages and 50 MiB',
      'Jusqu’à 50 pages et 50 Mio',
      'Bis zu 50 Seiten und 50 MiB',
    ],
    'Procesando localmente': <String>[
      'Processing locally',
      'Traitement local',
      'Lokale Verarbeitung',
    ],
    'Inspeccionar otro QR': <String>[
      'Inspect another code',
      'Inspecter un autre code',
      'Weiteren Code prüfen',
    ],
    'DESTINO INTERPRETADO': <String>[
      'INTERPRETED DESTINATION',
      'DESTINATION INTERPRÉTÉE',
      'INTERPRETIERTES ZIEL',
    ],
    'Qué se encontró': <String>[
      'What was found',
      'Élément trouvé',
      'Gefundener Inhalt',
    ],
    'Qué contiene': <String>[
      'What it contains',
      'Contenu',
      'Enthaltener Inhalt',
    ],
    'HOST REAL': <String>['ACTUAL HOST', 'HÔTE RÉEL', 'TATSÄCHLICHER HOST'],
    'Destino efectivo determinado localmente': <String>[
      'Effective destination determined locally',
      'Destination effective déterminée localement',
      'Lokal bestimmtes effektives Ziel',
    ],
    'Origen': <String>['Source', 'Source', 'Quelle'],
    'Decisión RootCause': <String>[
      'RootCause decision',
      'Décision RootCause',
      'RootCause-Entscheidung',
    ],
    'No se ha navegado ni resuelto una redirección remota.': <String>[
      'No remote navigation or redirect resolution was performed.',
      'Aucune navigation ni résolution de redirection distante n’a été effectuée.',
      'Es wurde weder navigiert noch eine entfernte Weiterleitung aufgelöst.',
    ],
    'CONTENIDO OBSERVADO': <String>[
      'OBSERVED CONTENT',
      'CONTENU OBSERVÉ',
      'BEOBACHTETER INHALT',
    ],
    'Evidencia': <String>['Evidence', 'Preuve', 'Nachweis'],
    'Confirmar acción': <String>[
      'Confirm action',
      'Confirmer l’action',
      'Aktion bestätigen',
    ],
    'acción disponible': <String>[
      'action available',
      'action disponible',
      'Aktion verfügbar',
    ],
    'confirmación obligatoria': <String>[
      'confirmation required',
      'confirmation obligatoire',
      'Bestätigung erforderlich',
    ],
    'solo inspección': <String>[
      'inspection only',
      'inspection uniquement',
      'nur Prüfung',
    ],
    'acción bloqueada': <String>[
      'action blocked',
      'action bloquée',
      'Aktion blockiert',
    ],
    'Normal': <String>['Normal', 'Normal', 'Normal'],
    'Advertencia': <String>['Warning', 'Avertissement', 'Warnung'],
    'Crítico': <String>['Critical', 'Critique', 'Kritisch'],
    'Todos': <String>['All', 'Tous', 'Alle'],
    'Favoritos': <String>['Favorites', 'Favoris', 'Favoriten'],
    'Generador': <String>['Generator', 'Générateur', 'Generator'],
    'Crea códigos verificables sin enviar los datos a un servidor.': <String>[
      'Create verifiable codes without sending data to a server.',
      'Créez des codes vérifiables sans envoyer les données à un serveur.',
      'Erstellen Sie prüfbare Codes, ohne Daten an einen Server zu senden.',
    ],
    'Contenido codificado': <String>[
      'Encoded content',
      'Contenu encodé',
      'Kodierter Inhalt',
    ],
    'Corrección de errores alta': <String>[
      'High error correction',
      'Correction d’erreurs élevée',
      'Hohe Fehlerkorrektur',
    ],
    'No hay elementos pendientes': <String>[
      'No pending items',
      'Aucun élément en attente',
      'Keine ausstehenden Elemente',
    ],
    'Borrar': <String>['Delete', 'Supprimer', 'Löschen'],
    'Borrar historial': <String>[
      'Delete history',
      'Supprimer l’historique',
      'Verlauf löschen',
    ],
    'Combinar': <String>['Merge', 'Fusionner', 'Zusammenführen'],
    'Compartir contenido': <String>[
      'Share content',
      'Partager le contenu',
      'Inhalt teilen',
    ],
    'Compartir información sensible': <String>[
      'Share sensitive information',
      'Partager les informations sensibles',
      'Sensible Informationen teilen',
    ],
    'Copiar carga sensible': <String>[
      'Copy sensitive payload',
      'Copier la charge sensible',
      'Sensible Nutzlast kopieren',
    ],
    'Copiar contenido': <String>[
      'Copy content',
      'Copier le contenu',
      'Inhalt kopieren',
    ],
    'Copiar diagnóstico privado': <String>[
      'Copy private diagnostics',
      'Copier le diagnostic privé',
      'Private Diagnose kopieren',
    ],
    'Datos copiados.': <String>[
      'Data copied.',
      'Données copiées.',
      'Daten kopiert.',
    ],
    'Desbloquear': <String>['Unlock', 'Déverrouiller', 'Entsperren'],
    'Descartar': <String>['Discard', 'Ignorer', 'Verwerfen'],
    'Descartar elemento': <String>[
      'Discard item',
      'Ignorer l’élément',
      'Element verwerfen',
    ],
    'Descartar registro afectado': <String>[
      'Discard affected record',
      'Ignorer l’enregistrement affecté',
      'Betroffenen Eintrag verwerfen',
    ],
    'Diagnóstico copiado.': <String>[
      'Diagnostics copied.',
      'Diagnostic copié.',
      'Diagnose kopiert.',
    ],
    'Diagnóstico privado': <String>[
      'Private diagnostics',
      'Diagnostic privé',
      'Private Diagnose',
    ],
    'El archivo de inventario no es válido.': <String>[
      'The inventory file is invalid.',
      'Le fichier d’inventaire n’est pas valide.',
      'Die Inventardatei ist ungültig.',
    ],
    'El respaldo no es válido o no pudo leerse.': <String>[
      'The backup is invalid or could not be read.',
      'La sauvegarde est invalide ou illisible.',
      'Die Sicherung ist ungültig oder konnte nicht gelesen werden.',
    ],
    'Exportar historial completo': <String>[
      'Export full history',
      'Exporter tout l’historique',
      'Gesamten Verlauf exportieren',
    ],
    'Importar como copia': <String>[
      'Import as a copy',
      'Importer comme copie',
      'Als Kopie importieren',
    ],
    'Importar respaldo JSON': <String>[
      'Import JSON backup',
      'Importer une sauvegarde JSON',
      'JSON-Sicherung importieren',
    ],
    'Inventario importado correctamente.': <String>[
      'Inventory imported successfully.',
      'Inventaire importé avec succès.',
      'Inventar erfolgreich importiert.',
    ],
    'Limpiar elementos resueltos': <String>[
      'Clear resolved items',
      'Effacer les éléments résolus',
      'Gelöste Elemente löschen',
    ],
    'Marcar revisado': <String>[
      'Mark as reviewed',
      'Marquer comme vérifié',
      'Als geprüft markieren',
    ],
    'No fue posible abrir el contenido.': <String>[
      'The content could not be opened.',
      'Impossible d’ouvrir le contenu.',
      'Der Inhalt konnte nicht geöffnet werden.',
    ],
    'No fue posible analizar el documento PDF.': <String>[
      'The PDF document could not be inspected.',
      'Impossible d’inspecter le document PDF.',
      'Das PDF-Dokument konnte nicht geprüft werden.',
    ],
    'No fue posible analizar una o más imágenes.': <String>[
      'One or more images could not be inspected.',
      'Impossible d’inspecter une ou plusieurs images.',
      'Ein oder mehrere Bilder konnten nicht geprüft werden.',
    ],
    'Nota del producto': <String>[
      'Product note',
      'Note du produit',
      'Produktnotiz',
    ],
    'Notas y etiquetas': <String>[
      'Notes and tags',
      'Notes et étiquettes',
      'Notizen und Tags',
    ],
    'Omitir duplicados': <String>[
      'Skip duplicates',
      'Ignorer les doublons',
      'Duplikate überspringen',
    ],
    'Paquete de recuperación copiado.': <String>[
      'Recovery package copied.',
      'Paquet de récupération copié.',
      'Wiederherstellungspaket kopiert.',
    ],
    'Reemplazar': <String>['Replace', 'Remplacer', 'Ersetzen'],
    'Reencriptando datos localmente…': <String>[
      'Re-encrypting data locally…',
      'Réencryption locale des données…',
      'Daten werden lokal neu verschlüsselt…',
    ],
    'Reintentar migración': <String>[
      'Retry migration',
      'Réessayer la migration',
      'Migration erneut versuchen',
    ],
    'Reintentar migración del historial': <String>[
      'Retry history migration',
      'Réessayer la migration de l’historique',
      'Verlaufsmigration erneut versuchen',
    ],
    'Reintentar recuperación': <String>[
      'Retry recovery',
      'Réessayer la récupération',
      'Wiederherstellung erneut versuchen',
    ],
    'Sesión privada': <String>[
      'Private session',
      'Session privée',
      'Private Sitzung',
    ],
    'Vista previa de importación': <String>[
      'Import preview',
      'Aperçu de l’importation',
      'Importvorschau',
    ],
    'Vista previa de inventario': <String>[
      'Inventory preview',
      'Aperçu de l’inventaire',
      'Inventarvorschau',
    ],
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      <String>{'es', 'en', 'fr', 'de'}.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppStringsContext on BuildContext {
  AppLocalizations get strings => AppLocalizations.of(this);
}

/// Drop-in text widget that translates known interface copy while leaving
/// payloads and user-provided values untouched when no message is registered.
class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    super.key,
  });

  final String data;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) => Text(
    context.strings.translate(data),
    style: style,
    strutStyle: strutStyle,
    textAlign: textAlign,
    textDirection: textDirection,
    softWrap: softWrap,
    overflow: overflow,
    textScaler: textScaler,
    maxLines: maxLines,
    semanticsLabel: semanticsLabel,
    textWidthBasis: textWidthBasis,
    textHeightBehavior: textHeightBehavior,
    selectionColor: selectionColor,
  );
}
