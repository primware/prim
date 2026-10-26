import 'package:flutter_test/flutter_test.dart';
import 'package:primware/API/user.api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    UserData.id = 99;
    UserData.name = 'Existing session';
    UserData.organizations = [];
  });

  test('valid cached data loads as before', () async {
    SharedPreferences.setMockInitialValues({
      'UserData_id': 7,
      'UserData_name': 'Cached user',
      'UserData_clients': '[{"id": 1}]',
      'UserData_organizations': '[{"id": 2}]',
    });
    await UserData.loadFromCache();
    expect(UserData.id, 7);
    expect(UserData.name, 'Cached user');
    expect(UserData.organizations.single['id'], 2);
  });

  for (final invalid in [
    {'UserData_clients': 'broken JSON'},
    {'UserData_imageBytes': '%%%invalid base64'},
    {'UserData_organizations': '[42]'},
  ]) {
    test(
      'invalid ${invalid.keys.single} does not partially replace session or erase stored values',
      () async {
        SharedPreferences.setMockInitialValues({'UserData_id': 7, ...invalid});
        await expectLater(UserData.loadFromCache(), throwsA(anything));
        expect(UserData.id, 99);
        expect(UserData.name, 'Existing session');
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(invalid.keys.single), invalid.values.single);
      },
    );
  }
}
