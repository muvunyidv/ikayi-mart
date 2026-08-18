import 'package:flutter_test/flutter_test.dart';
import 'package:ikayi_mart/core/api/ikayi_api.dart';
import 'package:ikayi_mart/main.dart';
import 'package:ikayi_mart/state/auth_state.dart';
import 'package:ikayi_mart/state/catalog_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('IKAYI MART storefront loads', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final api = IkayiApi();
    final auth = AuthState(api);
    auth.restoring = false;
    final catalog = CatalogState(api);

    await tester.pumpWidget(
      IkayiMartApp(api: api, auth: auth, catalog: catalog),
    );
    await tester.pump();

    expect(find.textContaining('IKAYI MART'), findsWidgets);
  });
}
