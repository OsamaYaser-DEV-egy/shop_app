import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/usecases/update_profile.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required UpdateProfile updateProfile})
      : _updateProfile = updateProfile,
        super(const ProfileState());

  final UpdateProfile _updateProfile;

  Future<void> save({
    required String uid,
    required String name,
    required String phone,
    required String address,
  }) async {
    if (state.isSaving) return; // prevents duplicate submissions
    emit(const ProfileState(status: ProfileStatus.saving));
    try {
      await _updateProfile(uid: uid, name: name, phone: phone, address: address);
      if (isClosed) return;
      emit(const ProfileState(
        status: ProfileStatus.saved,
        message: 'Profile updated.',
      ));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(ProfileState(status: ProfileStatus.failure, message: f.message));
    } catch (_) {
      if (isClosed) return;
      emit(const ProfileState(
        status: ProfileStatus.failure,
        message: 'Could not update your profile. Please try again.',
      ));
    }
  }
}
