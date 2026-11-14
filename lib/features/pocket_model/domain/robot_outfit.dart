import 'package:equatable/equatable.dart';

/// What the robot wears on its head (plan 9.9). Each carries the bead that glows in the temperature's colour.
enum RobotHat {
  /// The fez, its bead on a tassel: what it has always worn.
  fez(0),

  /// No hat: an antenna with the bead at its tip.
  antenna(0),

  /// A knitted beanie, the bead its pom-pom.
  beanie(2),

  /// A graduation cap, the bead at the end of its tassel.
  mortarboard(4),

  /// A turban, the bead a jewel at its front.
  turban(6),

  /// A wizard's hat, the bead a star at its tip.
  wizard(8),

  /// A top hat, the bead a gem on its band.
  topHat(10),

  /// A crown, the bead its middle gem.
  crown(12);

  const RobotHat(this.level);

  /// The level the pocket model reaches to unlock it.
  final int level;

  /// Whether the bead hangs on a cord that can swing round.
  bool get tassel => this == fez || this == mortarboard;
}

/// The shape of the robot's head, round its screen.
enum RobotHead {
  /// A rounded screen.
  classic(0),

  /// A round head, as an egg on its side.
  dome(3),

  /// An old television in a wooden case, with two knobs.
  tv(5),

  /// Cat ears on the classic screen.
  ears(7),

  /// A space helmet's glass round the screen.
  visor(11);

  const RobotHead(this.level);

  final int level;
}

/// What the robot wears on its body.
enum RobotBody {
  /// Its own navy body.
  classic(0),

  /// An embroidered bazaar vest.
  vest(1),

  /// A hoodie, its hood behind the head.
  hoodie(3),

  /// A white lab coat with a pen in its pocket.
  labCoat(5),

  /// A long kaftan with a gold sash.
  kaftan(7),

  /// A suit and a bow tie.
  suit(9),

  /// A space suit.
  astronaut(13);

  const RobotBody(this.level);

  final int level;
}

/// The robot's outfit: its hat, its head and its body (plan 9.9). Each part unlocks at a level of the pocket model; a
/// part above the model's level (after it started over) is not worn until the model reaches it again ([within]).
final class RobotOutfit extends Equatable {
  const RobotOutfit({this.hat = RobotHat.fez, this.head = RobotHead.classic, this.body = RobotBody.classic});

  /// What it wears before anything is chosen.
  static const initial = RobotOutfit();

  final RobotHat hat;
  final RobotHead head;
  final RobotBody body;

  RobotOutfit copyWith({RobotHat? hat, RobotHead? head, RobotBody? body}) =>
      RobotOutfit(hat: hat ?? this.hat, head: head ?? this.head, body: body ?? this.body);

  /// The outfit a model at [level] wears: each part it has not unlocked is its first.
  RobotOutfit within(int level) => RobotOutfit(
    hat: hat.level <= level ? hat : RobotHat.fez,
    head: head.level <= level ? head : RobotHead.classic,
    body: body.level <= level ? body : RobotBody.classic,
  );

  /// The parts that unlock exactly at [level].
  static List<Enum> unlockedAt(int level) => [
    for (final hat in RobotHat.values)
      if (hat.level == level && level > 0) hat,
    for (final head in RobotHead.values)
      if (head.level == level && level > 0) head,
    for (final body in RobotBody.values)
      if (body.level == level && level > 0) body,
  ];

  @override
  List<Object?> get props => [hat, head, body];
}
