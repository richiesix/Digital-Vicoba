import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegistrationDraft {
  const RegistrationDraft({
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
  });

  final String phoneNumber;
  final String firstName;
  final String lastName;
}

final registrationDraftProvider = StateProvider<RegistrationDraft?>((ref) => null);
