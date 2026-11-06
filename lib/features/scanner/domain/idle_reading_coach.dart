/// Qué decir cuando la cámara lleva rato analizando y no lee nada.
///
/// El motor ya pide `autoZoom` a la plataforma, así que acercar el encuadre no
/// es trabajo de la aplicación. Lo que faltaba es lo contrario: **decirlo**. Una
/// cámara que analiza sin encontrar nada se ve exactamente igual que una cámara
/// averiada, y ese silencio es el origen del reporte «se ve completo y no hace
/// nada».
///
/// Los dos avisos escalan de lo barato a lo seguro: primero acercarse —que
/// resuelve la mayoría de los casos—, y después la entrada por archivo, que
/// analiza una fotografía ya tomada y no depende de pulso, luz ni distancia.
///
/// No toca el zoom por su cuenta. Mover el encuadre mientras alguien apunta es
/// quitarle el control de la única cosa que estaba controlando.
abstract final class IdleReadingCoach {
  /// Nada que decir: la lectura acaba de empezar.
  static const int quiet = 0;

  /// Primer aviso: el encuadre o la distancia.
  static const int nudge = 1;

  /// Segundo aviso: la entrada por archivo.
  static const int fallback = 2;

  /// Cuándo aparece cada aviso desde que la cámara empieza a analizar.
  ///
  /// Siete segundos es deliberado: por debajo de cinco el aviso llegaría
  /// mientras la persona todavía está apuntando, y un consejo que interrumpe
  /// es ruido, no ayuda.
  static const List<Duration> schedule = <Duration>[
    Duration(seconds: 7),
    Duration(seconds: 16),
  ];

  /// Mensaje del nivel, o null si todavía no toca decir nada.
  ///
  /// Se mantiene corto a propósito: la línea secundaria de la barra de estado
  /// se recorta a un renglón, así que un texto largo saldría con puntos
  /// suspensivos justo donde está el consejo.
  static String? messageFor(int level) => switch (level) {
    nudge => 'Sin lecturas aún · acércate al código',
    fallback => 'Sigue sin leerse · prueba Analizar archivo',
    _ => null,
  };

  /// Nivel que corresponde al tiempo transcurrido analizando.
  static int levelFor(Duration scanningFor) {
    int level = quiet;
    for (int index = 0; index < schedule.length; index++) {
      if (scanningFor >= schedule[index]) level = index + 1;
    }
    return level;
  }
}
