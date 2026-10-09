import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class RealtimeDatabaseService {
  RealtimeDatabaseService._();

  static final FirebaseDatabase database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://mitic-8cddc-default-rtdb.firebaseio.com/',
  );

  static Future<User> ensureSignedIn() async {
    final auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;
    if (currentUser != null) return currentUser;

    final credentials = await auth.signInAnonymously();
    return credentials.user ??
        (throw StateError('Firebase no devolvió un usuario autenticado.'));
  }

  static DatabaseReference ref(String path) => database.ref(path);
}
