/// How a lot is expected to behave on a home game day.
enum GameDayLotState { open, fillingFast, permitOnly, full }

class GameDayLotStatus {
  const GameDayLotStatus({
    required this.lotId,
    required this.state,
    required this.note,
  });

  final String lotId;
  final GameDayLotState state;
  final String note;
}

class GameDayMilestone {
  const GameDayMilestone({
    required this.timeLabel,
    required this.title,
    required this.detail,
  });

  final String timeLabel;
  final String title;
  final String detail;
}

class GameDayPlan {
  const GameDayPlan({
    required this.title,
    required this.venue,
    required this.kickoffLabel,
    required this.lotsOpenLabel,
    required this.lotStatuses,
    required this.timeline,
    required this.tips,
    this.disclaimer,
  });

  final String title;
  final String venue;
  final String kickoffLabel;
  final String lotsOpenLabel;
  final List<GameDayLotStatus> lotStatuses;
  final List<GameDayMilestone> timeline;
  final List<String> tips;

  /// Shown under the hero when the plan is not from an official source.
  final String? disclaimer;
}
