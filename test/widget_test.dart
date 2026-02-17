import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_recipe_app/main.dart';

void main() {
  test('formatAmount trims trailing zeros', () {
    expect(formatAmount(10), '10');
    expect(formatAmount(12.5), '12.5');
    expect(formatAmount(12.34), '12.34');
  });

  test('parseAmount supports comma and dot', () {
    expect(parseAmount('123.4'), 123.4);
    expect(parseAmount('123,4'), 123.4);
    expect(parseAmount(''), null);
  });
}
