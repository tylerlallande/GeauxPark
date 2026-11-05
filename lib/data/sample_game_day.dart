import '../models/game_day.dart';

/// Placeholder game-day plan until the server provides event data.
const sampleGameDayPlan = GameDayPlan(
  title: 'Saturday home game',
  venue: 'Tiger Stadium',
  kickoffLabel: '6:30 PM',
  lotsOpenLabel: '7:00 AM',
  disclaimer: 'Sample schedule. Confirm official times before you go.',
  lotStatuses: [
    GameDayLotStatus(
      lotId: 'union-square-garage',
      state: GameDayLotState.fillingFast,
      note: 'Usually full about 3 hours before kickoff.',
    ),
    GameDayLotStatus(
      lotId: 'west-stadium-lot',
      state: GameDayLotState.permitOnly,
      note: 'Valid event permit required before kickoff.',
    ),
    GameDayLotStatus(
      lotId: 'nicholson-gateway',
      state: GameDayLotState.open,
      note: 'Best bet for late arrivals. Campus transit nearby.',
    ),
  ],
  timeline: [
    GameDayMilestone(
      timeLabel: '7:00 AM',
      title: 'Lots open',
      detail: 'Event rates start when gates open.',
    ),
    GameDayMilestone(
      timeLabel: '2:30 PM',
      title: 'Roads start closing',
      detail: 'Expect closures on roads around the stadium.',
    ),
    GameDayMilestone(
      timeLabel: '6:30 PM',
      title: 'Kickoff',
      detail: 'Most garages near the stadium are full by now.',
    ),
    GameDayMilestone(
      timeLabel: 'Post-game',
      title: 'Plan your exit',
      detail: 'Leave by the nearest main road to avoid stadium traffic.',
    ),
  ],
  tips: [
    'Arrive early. Lots near the stadium fill hours before kickoff.',
    'Bring a card and cash for event rates.',
    'Save your lot so you can find it after the game.',
  ],
);
