import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/app/config/constants.dart';

void main() {
  test('H-04: solo se acepta una URL https para Supabase', () {
    expect(AppConstants.isSecureUrl('https://abc.supabase.co'), isTrue);
    expect(AppConstants.isSecureUrl('http://abc.supabase.co'), isFalse);
    expect(AppConstants.isSecureUrl('ftp://abc.supabase.co'), isFalse);
    expect(AppConstants.isSecureUrl('abc.supabase.co'), isFalse);
    expect(AppConstants.isSecureUrl(''), isFalse);
  });
}
