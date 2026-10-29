import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/app_notification.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  const NotificationRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.notifications);

  /// Sorting is done locally, so no composite index is needed.
  Stream<List<AppNotification>> watchNotifications(String uid) {
    return _collection.where('userId', isEqualTo: uid).snapshots().map(
      (snapshot) {
        final notifications = snapshot.docs
            .map((doc) => NotificationModel.tryFromMap(doc.id, doc.data()))
            .whereType<AppNotification>()
            .toList();
        notifications.sort(_newestFirst);
        return notifications;
      },
    );
  }

  Future<void> markRead(List<String> ids) async {
    final batch = _firestore.batch();
    for (final id in ids) {
      batch.update(_collection.doc(id), {'isRead': true});
    }
    await batch.commit();
  }

  static int _newestFirst(AppNotification a, AppNotification b) {
    final ta = a.createdAt;
    final tb = b.createdAt;
    if (ta == null || tb == null) {
      if (ta == tb) return 0;
      return ta == null ? -1 : 1;
    }
    return tb.compareTo(ta);
  }
}
