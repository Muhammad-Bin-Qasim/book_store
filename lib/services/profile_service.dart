import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_constants.dart';
import '../core/utils/error_handler.dart';

class ProfileService {
  ProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _firestore.collection('users').doc(uid);

  Future<ProfileData> loadProfile(String uid) async {
    final snapshot = await _user(uid).get();
    final data = snapshot.data() ?? <String, dynamic>{};
    return ProfileData(
      addresses: _mapList(data['addresses']),
      paymentMethods: _mapList(data['paymentMethods']),
    );
  }

  Future<void> saveAddress(String uid, Map<String, dynamic> address) async {
    await _mutateList(uid, 'addresses', (items) {
      final index = items.indexWhere((item) => item['id'] == address['id']);
      if (index < 0) {
        items.add(Map<String, dynamic>.from(address));
      } else {
        items[index] = Map<String, dynamic>.from(address);
      }
    });
  }

  Future<void> deleteAddress(String uid, String id) =>
      _mutateList(uid, 'addresses', (items) {
        items.removeWhere((item) => item['id'] == id);
      });

  Future<void> setDefaultAddress(String uid, String id) =>
      _mutateList(uid, 'addresses', (items) {
        for (final item in items) {
          item['isDefault'] = item['id'] == id;
        }
      });

  Future<void> savePaymentMethod(
    String uid,
    Map<String, dynamic> paymentMethod,
  ) async {
    await _mutateList(uid, 'paymentMethods', (items) {
      final index = items.indexWhere(
        (item) => item['id'] == paymentMethod['id'],
      );
      if (index < 0) {
        final isFirst = items.isEmpty;
        final method = Map<String, dynamic>.from(paymentMethod);
        method['isDefault'] = method['isDefault'] == true || isFirst;
        if (method['isDefault'] == true) {
          for (final item in items) {
            item['isDefault'] = false;
          }
        }
        items.add(method);
      } else {
        items[index] = Map<String, dynamic>.from(paymentMethod);
      }
    });
  }

  Future<void> deletePaymentMethod(String uid, String id) =>
      _mutateList(uid, 'paymentMethods', (items) {
        final wasDefault = items.any(
          (item) => item['id'] == id && item['isDefault'] == true,
        );
        items.removeWhere((item) => item['id'] == id);
        if (wasDefault && items.isNotEmpty) items.first['isDefault'] = true;
      });

  Future<void> setDefaultPaymentMethod(String uid, String id) =>
      _mutateList(uid, 'paymentMethods', (items) {
        for (final item in items) {
          item['isDefault'] = item['id'] == id;
        }
      });

  Future<void> _mutateList(
    String uid,
    String property,
    void Function(List<Map<String, dynamic>>) mutate,
  ) async {
    final reference = _user(uid);
    await _firestore.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) {
        throw const ProfileServiceException(AppStrings.profileNotFound);
      }
      final values = _mapList(snapshot.data()?[property]);
      mutate(values);
      transaction.update(reference, <String, dynamic>{property: values});
    });
  }

  String createId() => _firestore.collection('_generated_ids').doc().id;

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! Iterable) return <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: true);
  }

  static String friendlyMessage(Object error) {
    return ErrorHandler.message(error, fallback: AppStrings.profileSaveFailed);
  }
}

class ProfileServiceException implements Exception, UserFacingError {
  const ProfileServiceException(this.message);

  final String message;

  @override
  String get userMessage => message;

  @override
  String toString() => message;
}

class ProfileData {
  const ProfileData({required this.addresses, required this.paymentMethods});

  final List<Map<String, dynamic>> addresses;
  final List<Map<String, dynamic>> paymentMethods;
}
