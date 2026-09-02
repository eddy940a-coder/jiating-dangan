import 'package:flutter_test/flutter_test.dart';
import 'package:family_archive/data/models/family_member.dart';

void main() {
  test('家庭成员关系选项包含弟弟和妹妹，不再包含兄弟和姐妹', () {
    expect(memberRelations, containsAll(['弟弟', '妹妹']));
    expect(memberRelations, isNot(contains('兄弟')));
    expect(memberRelations, isNot(contains('姐妹')));
  });
}
