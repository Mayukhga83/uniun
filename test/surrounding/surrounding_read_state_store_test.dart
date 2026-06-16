import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniun/data/datasources/surrounding_read_state_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SurroundingReadStateStore> freshStore() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // guarantee isolation across tests
    return SurroundingReadStateStore(prefs);
  }

  test('defaults to epoch 0 when unset', () async {
    final store = await freshStore();
    expect(store.lastReadReceivedAt, DateTime.fromMillisecondsSinceEpoch(0));
  });

  test('advanceTo moves the watermark forward', () async {
    final store = await freshStore();
    final t = DateTime.fromMillisecondsSinceEpoch(1000);
    await store.advanceTo(t);
    expect(store.lastReadReceivedAt, t);
  });

  test('advanceTo never moves the watermark backward', () async {
    final store = await freshStore();
    await store.advanceTo(DateTime.fromMillisecondsSinceEpoch(2000));
    await store.advanceTo(DateTime.fromMillisecondsSinceEpoch(1000));
    expect(store.lastReadReceivedAt, DateTime.fromMillisecondsSinceEpoch(2000));
  });

  test('advanceTo is a no-op when ts equals the current watermark', () async {
    final store = await freshStore();
    await store.advanceTo(DateTime.fromMillisecondsSinceEpoch(1000));
    await store.advanceTo(DateTime.fromMillisecondsSinceEpoch(1000)); // same
    expect(store.lastReadReceivedAt, DateTime.fromMillisecondsSinceEpoch(1000));
  });
}
