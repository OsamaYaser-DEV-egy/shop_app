import 'package:equatable/equatable.dart';

enum ProfileStatus { idle, saving, saved, failure }

class ProfileState extends Equatable {
  const ProfileState({this.status = ProfileStatus.idle, this.message});

  final ProfileStatus status;
  final String? message;

  bool get isSaving => status == ProfileStatus.saving;

  @override
  List<Object?> get props => [status, message];
}
