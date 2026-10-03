import '../../domain/entities/app_alert.dart';
import '../../domain/repositories/alerts_repository.dart';

/// In-memory demonstration only. No invitations or messages leave the app.
class MockAlertsRepository implements AlertsRepository {
  List<AppAlert> _alerts;
  MockAlertsRepository({bool includeActivityPreviews = true})
      : _alerts = _samples.where((alert) => includeActivityPreviews || alert.studySessionId == null).toList();

  @override
  Future<List<AppAlert>> getAlerts() async => List.unmodifiable(_alerts);

  @override
  Future<List<AppAlert>> markAllRead() async {
    _alerts = [for (final alert in _alerts) alert.copyWith(isRead: true)];
    return List.unmodifiable(_alerts);
  }

  @override
  Future<List<AppAlert>> respond(String id, AlertResponse response) async {
    final index = _alerts.indexWhere((alert) => alert.id == id);
    if (index < 0 || _alerts[index].isResolved) {
      throw StateError('This alert is no longer available.');
    }
    _alerts[index] = _alerts[index].copyWith(isRead: true, response: response);
    return List.unmodifiable(_alerts);
  }
}

const _samples = [
  AppAlert(
      id: 'overlap',
      kind: AlertKind.overlap,
      period: AlertPeriod.today,
      title: 'Mutual Free Window with Sarah Jenkins',
      timeLabel: '14:15',
      description:
          'Both of you are completely free between 17:00 – 18:30 near Central Engineering Garden.'),
  AppAlert(
      id: 'friend',
      kind: AlertKind.friendRequest,
      period: AlertPeriod.today,
      title: 'Carlos Mendoza',
      timeLabel: '09:12',
      description:
          'Systems Engineering • Shared: Algoritmos & Estructuras de Datos'),
  AppAlert(
      id: 'reminder',
      studySessionId: 'linear-algebra',
      kind: AlertKind.reminder,
      period: AlertPeriod.today,
      title: 'Study Session: Álgebra Lineal & Cálculo',
      timeLabel: '15:40',
      description:
          'Biblioteca Central • Sala 3B (Mesa 4)\nSofía, Mateo & Camila are already on campus.'),
  AppAlert(
      id: 'invitation',
      kind: AlertKind.invitation,
      period: AlertPeriod.today,
      title: 'Repaso Parcial II: Cálculo Multivariado',
      timeLabel: '11:30',
      description:
          'Sofía Gómez invited you.\n“Traigan los ejercicios de integrales dobles y la calculadora.”\nMañana, 10:00 – 12:00 • Edificio C, Cubículo 12'),
  AppAlert(
      id: 'time-change',
      kind: AlertKind.timeChanged,
      period: AlertPeriod.earlier,
      title: 'Roomies Calle 45: Grocery & Dinner',
      timeLabel: 'Yesterday',
      isRead: true,
      description:
          'Mateo moved the plan from 19:00 to 20:15 so everyone can finish afternoon labs.'),
  AppAlert(
      id: 'digest',
      kind: AlertKind.digest,
      period: AlertPeriod.earlier,
      title: '2 pending plans awaiting your RSVP',
      timeLabel: '2 days ago',
      isRead: true,
      description:
          '• Fútbol 5 & Tercer Tiempo (Viernes 19:30)\n• Taller de Git & GitHub Campus (Sábado 14:00)'),
  AppAlert(
      id: 'group',
      kind: AlertKind.groupInvite,
      period: AlertPeriod.earlier,
      title: 'Ingeniería de Sistemas • Cohorte 2026',
      timeLabel: '3 days ago',
      isRead: true,
      description:
          'Marcus Thorne invited you to synchronize semester schedules with 28 classmates.'),
];
