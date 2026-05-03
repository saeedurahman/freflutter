import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileInitial());

  final ProfileRepository _repository;

  Future<void> loadProfile() async {
    emit(const ProfileLoading());
    try {
      final user = await _repository.getProfile();
      emit(ProfileLoaded(user));
    } on ProfileRepositoryException catch (e) {
      emit(ProfileFailure(e.message));
    } catch (_) {
      emit(const ProfileFailure('Could not load profile. Please try again.'));
    }
  }
}
