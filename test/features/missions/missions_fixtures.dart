import 'package:proyecto_movil/features/missions/domain/entities/mission.dart';
import 'package:proyecto_movil/features/missions/domain/entities/missions_board.dart';
import 'package:proyecto_movil/features/missions/domain/entities/new_mission.dart';

const mission = Mission(
  id: 't1',
  title: 'Preparar la exposición',
  priority: MissionPriority.high,
  bucket: MissionBucket.high,
  xpReward: 30,
  coinReward: 9,
);

const board = MissionsBoard(missions: [mission]);
const emptyBoard = MissionsBoard(missions: []);
const newMission = NewMission(title: 'Leer');
