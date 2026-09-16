enum AlertKind {
  reminder,
  overlap,
  invitation,
  friendRequest,
  timeChanged,
  digest,
  groupInvite
}

enum AlertPeriod { today, earlier }

enum AlertResponse {
  onMyWay,
  accepted,
  maybe,
  declined,
  acknowledged,
  joined,
  dismissed
}

class AppAlert {
  final String id;
  final AlertKind kind;
  final AlertPeriod period;
  final String title;
  final String description;
  final String timeLabel;
  final bool isRead;
  final AlertResponse? response;

  const AppAlert(
      {required this.id,
      required this.kind,
      required this.period,
      required this.title,
      required this.description,
      required this.timeLabel,
      this.isRead = false,
      this.response});

  bool get isPriority =>
      kind == AlertKind.reminder || kind == AlertKind.invitation;
  bool get isResolved => response != null;

  AppAlert copyWith({bool? isRead, AlertResponse? response}) => AppAlert(
      id: id,
      kind: kind,
      period: period,
      title: title,
      description: description,
      timeLabel: timeLabel,
      isRead: isRead ?? this.isRead,
      response: response ?? this.response);
}
