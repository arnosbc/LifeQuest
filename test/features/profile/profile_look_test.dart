import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/features/profile/domain/entities/profile_look.dart';

void main() {
  test('el fondo propio es video según la extensión del archivo', () {
    ProfileLook look(String? path) => ProfileLook(backdropPath: path);
    expect(look('/d/backdrop_1.mp4').backdropIsVideo, isTrue);
    expect(look('/d/backdrop_1.mov').backdropIsVideo, isTrue);
    expect(look('/d/backdrop_1.gif').backdropIsVideo, isFalse);
    expect(look('/d/backdrop_1.jpg').backdropIsVideo, isFalse);
    expect(look(null).backdropIsVideo, isFalse);
  });
}
