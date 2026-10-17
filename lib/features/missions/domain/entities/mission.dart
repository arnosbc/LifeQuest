class Mission {
  const Mission({
    required this.title,
    required this.description,
    required this.due,
    required this.duration,
    required this.priority,
    required this.xp,
    required this.coins,
    this.started = false,
    this.highlight = false,
  });

  final String title;
  final String description;
  final String due;
  final String duration;
  final String priority;
  final int xp;
  final int coins;
  final bool started;
  final bool highlight;

  Mission copyWith({bool? started}) => Mission(
    title: title,
    description: description,
    due: due,
    duration: duration,
    priority: priority,
    xp: xp,
    coins: coins,
    started: started ?? this.started,
    highlight: highlight,
  );
}
