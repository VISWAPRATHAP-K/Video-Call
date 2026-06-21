import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';

class ContactsState {
  final bool isLoading;
  final List<UserModel> users;
  final String? error;

  ContactsState({
    required this.isLoading,
    required this.users,
    this.error,
  });

  factory ContactsState.initial() => ContactsState(isLoading: false, users: []);
  factory ContactsState.loading() => ContactsState(isLoading: true, users: []);
  factory ContactsState.success(List<UserModel> users) => ContactsState(isLoading: false, users: users);
  factory ContactsState.error(String error) => ContactsState(isLoading: false, users: [], error: error);
}

class ContactsNotifier extends StateNotifier<ContactsState> {
  final ApiService _apiService = ApiService();

  ContactsNotifier() : super(ContactsState.initial());

  /// Fetch registered contacts from backend
  Future<void> fetchContacts() async {
    state = ContactsState.loading();
    try {
      final response = await _apiService.getAllUsers();
      if (response.statusCode == 200) {
        final List<dynamic> usersData = response.data['users'] ?? [];
        final usersList = usersData.map((data) => UserModel.fromJson(data)).toList();
        state = ContactsState.success(usersList);
      } else {
        state = ContactsState.error(response.data['message'] ?? 'Failed to load contacts');
      }
    } catch (e) {
      state = ContactsState.error(e.toString());
    }
  }
}

// Global Contacts Provider
final contactsProvider = StateNotifierProvider<ContactsNotifier, ContactsState>((ref) {
  return ContactsNotifier();
});
