import 'package:rootcause_qr_inspector/core/investigation/qr_investigation.dart';

/// Textos de presentación separados del contrato forense.
///
/// Los exports conservan ids estables. Esta capa puede crecer a otros idiomas
/// sin alterar el formato de evidencia ni el motor de reglas.
abstract final class QrFindingText {
  static String title(String id) => switch (id) {
        'transport-http' => 'Conexión sin HTTPS',
        'authority-userinfo' => 'Credenciales dentro de la dirección',
        'host-punycode' => 'Dominio expresado con Punycode',
        'host-mixed-script' => 'Alfabetos mezclados en el dominio',
        'host-unicode' => 'Caracteres internacionales en el dominio',
        'host-ip-literal' => 'Dirección IP en vez de dominio',
        'host-private-or-local' => 'Destino local o privado',
        'host-shortener' => 'Acortador que oculta el destino',
        'host-deep-subdomains' => 'Cantidad inusual de subdominios',
        'host-trailing-dot' => 'Punto final en el dominio',
        'host-hyphen-density' => 'Dominio con muchos guiones',
        'host-empty' => 'Dominio ausente o inválido',
        'port-unusual' => 'Puerto de red poco habitual',
        'url-excessive-length' => 'Dirección inusualmente extensa',
        'url-control-character' => 'Caracteres de control en la dirección',
        'authority-obfuscated' => 'Autoridad web ofuscada',
        'encoded-separator' => 'Separadores codificados u ofuscados',
        'download-dangerous-extension' => 'Posible descarga ejecutable o comprimida',
        'credential-lure-path' => 'Ruta asociada a acceso o verificación',
        'tracking-excessive' => 'Seguimiento excesivo en la consulta',
        'redirect-nested-domain' => 'Redirección hacia otro dominio',
        'brand-domain-mismatch' => 'Marca fuera de su dominio autorizado',
        'scheme-blocked' => 'Esquema de aplicación no permitido',
        'sensitive-secret' => 'Secreto de autenticación',
        'payment-instruction' => 'Instrucción de pago',
        'opaque-binary-payload' => 'Carga binaria no interpretable',
        _ => id,
      };

  static String explanation(String id) => switch (id) {
        'transport-http' => 'El destino no cifra el transporte con HTTPS.',
        'authority-userinfo' => 'La parte anterior al dominio puede engañar sobre el destino real.',
        'host-punycode' => 'Punycode puede representar caracteres visualmente parecidos a los de otra marca.',
        'host-mixed-script' => 'El nombre combina alfabetos que pueden producir imitaciones visuales.',
        'host-unicode' => 'La escritura internacional es válida, pero requiere comprobar el nombre con cuidado.',
        'host-ip-literal' => 'No hay un nombre de dominio reconocible que el usuario pueda verificar.',
        'host-private-or-local' => 'El código intenta llegar al dispositivo o a un equipo de la red local.',
        'host-shortener' => 'El QR no revela el destino final sin seguir una redirección.',
        'host-deep-subdomains' => 'Muchos niveles pueden esconder el dominio registrable entre texto convincente.',
        'host-trailing-dot' => 'Algunas interfaces muestran el dominio con y sin el punto de forma distinta.',
        'host-hyphen-density' => 'Una densidad alta de guiones suele acompañar nombres imitativos o generados.',
        'host-empty' => 'La dirección no contiene un host web utilizable.',
        'port-unusual' => 'El destino usa un puerto distinto de los habituales para HTTP o HTTPS.',
        'url-excessive-length' => 'Una carga muy larga dificulta revisar manualmente su destino y parámetros.',
        'url-control-character' => 'La carga incluye controles crudos o porcentuales que pueden alterar cómo otra aplicación interpreta la URI.',
        'authority-obfuscated' => 'Barras invertidas, espacios o varios signos @ crean interpretaciones ambiguas.',
        'encoded-separator' => 'La autoridad contiene separadores codificados o doble codificación.',
        'download-dangerous-extension' => 'La ruta termina en un tipo de archivo que puede ejecutar o transportar código.',
        'credential-lure-path' => 'La ruta o consulta sugiere inicio de sesión, cuenta, banco o contraseña.',
        'tracking-excessive' => 'Varios identificadores de seguimiento reducen la claridad del enlace.',
        'redirect-nested-domain' => 'Un parámetro contiene otra URL cuyo host no coincide con el visible.',
        'brand-domain-mismatch' => 'La dirección menciona una marca configurada fuera de sus dominios permitidos.',
        'scheme-blocked' => 'La carga pide ejecutar un esquema que RootCause no entrega a otra aplicación.',
        'sensitive-secret' => 'El QR contiene material OTP; exponerlo puede permitir generar códigos de acceso.',
        'payment-instruction' => 'El QR contiene un destinatario o una dirección de pago que debe verificarse fuera del código.',
        'opaque-binary-payload' => 'La carga no puede explicarse como texto o estructura conocida.',
        _ => 'Se observó una condición que requiere revisión.',
      };

  static String recommendation(String id) => switch (id) {
        'payment-instruction' => 'Confirma destinatario, monto y moneda en una fuente independiente antes de pagar.',
        'sensitive-secret' => 'No compartas el QR ni su export; confirma quién emitió la configuración OTP.',
        'download-dangerous-extension' => 'No descargues ni instales el archivo desde este código.',
        'scheme-blocked' => 'Conserva la evidencia y no ejecutes la carga en otra aplicación.',
        'brand-domain-mismatch' => 'Abre el servicio desde su aplicación o escribe el dominio oficial manualmente.',
        'redirect-nested-domain' => 'No continúes hasta identificar y validar el dominio final.',
        'credential-lure-path' => 'No ingreses credenciales; abre el servicio desde un acceso conocido.',
        _ => 'Compara el dominio con una fuente independiente antes de continuar.',
      };

  static String evidenceLabel(String id) => switch (id) {
        'scheme' => 'Esquema',
        'host' => 'Host observado',
        'normalizedHost' => 'Host normalizado',
        'port' => 'Puerto',
        'extension' => 'Extensión',
        'subdomainLabels' => 'Etiquetas del dominio',
        'length' => 'Longitud',
        'redirectHost' => 'Host redirigido',
        'redirectParameter' => 'Parámetro de redirección',
        'brandId' => 'Marca configurada',
        'token' => 'Token observado',
        'trackingParameters' => 'Parámetros de seguimiento',
        'contentKind' => 'Tipo de contenido',
        _ => id,
      };

  static String limitationLabel(String id) => switch (id) {
        'no-remote-reputation' => 'reputación remota',
        'no-dns-resolution' => 'DNS efectivo',
        'no-certificate-validation' => 'certificado servido',
        'no-redirect-following' => 'cadena HTTP real',
        'no-domain-age-check' => 'edad o dueño del dominio',
        'no-visual-sticker-tamper-detection' => 'manipulación física de la etiqueta',
        'no-destination-safety-guarantee' => 'legitimidad del destino',
        _ => id,
      };

  static String severityLabel(QrSeverity severity) => switch (severity) {
        QrSeverity.normal => 'Normal',
        QrSeverity.warning => 'Advertencia',
        QrSeverity.critical => 'Crítico',
      };

  static String actionLabel(QrActionDecision action) => switch (action) {
        QrActionDecision.allow => 'acción disponible',
        QrActionDecision.confirm => 'confirmación obligatoria',
        QrActionDecision.inspectOnly => 'solo inspección',
        QrActionDecision.block => 'acción bloqueada',
      };
}
