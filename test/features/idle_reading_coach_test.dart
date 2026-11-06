import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_qr_inspector/features/scanner/domain/idle_reading_coach.dart';

void main() {
  test('says nothing while the reading has just started', () {
    expect(IdleReadingCoach.levelFor(Duration.zero), IdleReadingCoach.quiet);
    expect(
      IdleReadingCoach.levelFor(const Duration(seconds: 6)),
      IdleReadingCoach.quiet,
    );
    expect(IdleReadingCoach.messageFor(IdleReadingCoach.quiet), isNull);
  });

  test('escalates from the framing advice to the file entry', () {
    expect(
      IdleReadingCoach.levelFor(const Duration(seconds: 7)),
      IdleReadingCoach.nudge,
    );
    expect(
      IdleReadingCoach.levelFor(const Duration(seconds: 15)),
      IdleReadingCoach.nudge,
    );
    expect(
      IdleReadingCoach.levelFor(const Duration(seconds: 16)),
      IdleReadingCoach.fallback,
    );
    expect(
      IdleReadingCoach.levelFor(const Duration(minutes: 3)),
      IdleReadingCoach.fallback,
    );

    expect(
      IdleReadingCoach.messageFor(IdleReadingCoach.nudge),
      contains('acércate'),
    );
    // El segundo aviso ofrece la vía que no depende de pulso, luz ni
    // distancia: analizar una fotografía ya tomada.
    expect(
      IdleReadingCoach.messageFor(IdleReadingCoach.fallback),
      contains('Analizar archivo'),
    );
  });

  test('no advice interrupts someone who is still aiming', () {
    expect(
      IdleReadingCoach.schedule.first,
      greaterThanOrEqualTo(const Duration(seconds: 5)),
    );
    for (int index = 1; index < IdleReadingCoach.schedule.length; index++) {
      expect(
        IdleReadingCoach.schedule[index],
        greaterThan(IdleReadingCoach.schedule[index - 1]),
      );
    }
  });

  test('every scheduled step has something to say', () {
    for (int level = 1; level <= IdleReadingCoach.schedule.length; level++) {
      final String? message = IdleReadingCoach.messageFor(level);
      expect(message, isNotNull);
      // La línea secundaria de la barra de estado se recorta a un renglón.
      expect(message!.length, lessThanOrEqualTo(46));
    }
  });
}
