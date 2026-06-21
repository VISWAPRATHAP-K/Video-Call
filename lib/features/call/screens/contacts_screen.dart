import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/call_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  @override
  void initState() {
    super.initState();
    // Load contacts immediately on startup
    Future.microtask(() {
      ref.read(contactsProvider.notifier).fetchContacts();
    });
  }

  void _callUser(UserModel targetUser, bool isVideo) {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    // Generate a unique deterministic channel ID for the call session
    final channelName = 'channel_${currentUser.id}_${targetUser.id}';
    
    ref.read(callProvider.notifier).startOutgoingCall(
      context: context,
      channelId: channelName,
      isVideo: isVideo,
      receiverId: targetUser.id,
    );
  }

  void _showProfileDialog() async {
    final currentUser = ref.read(authProvider).user;
    final serverUrl = await ApiService().getServerUrl();

    if (currentUser == null || !mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28.0,
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    currentUser.username.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser.username,
                        style: const TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        currentUser.email,
                        style: const TextStyle(color: Colors.white60, fontSize: 13.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 24.0),
            const Text('Connected Server:', style: TextStyle(color: Colors.white60, fontSize: 11.0)),
            Text(serverUrl, style: const TextStyle(color: Colors.blueAccent, fontSize: 12.0, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12.0),
            const Text('FCM Registered Status:', style: TextStyle(color: Colors.white60, fontSize: 11.0)),
            Text(
              currentUser.fcmToken != null ? 'Yes' : 'No (Requires Firebase Setup)',
              style: TextStyle(
                color: currentUser.fcmToken != null ? Colors.greenAccent : Colors.amberAccent,
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            icon: const Icon(Icons.logout, size: 16.0, color: Colors.white),
            label: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactsState = ref.watch(contactsProvider);
    final currentUser = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFF121214),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        title: GestureDetector(
          onTap: _showProfileDialog,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18.0,
                backgroundColor: Colors.blueAccent.withOpacity(0.2),
                child: Text(
                  currentUser != null && currentUser.username.isNotEmpty
                      ? currentUser.username.substring(0, 1).toUpperCase()
                      : 'U',
                  style: const TextStyle(color: Colors.blueAccent, fontSize: 14.0, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentUser?.username ?? 'Loading...',
                    style: const TextStyle(color: Colors.white, fontSize: 15.0, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6.0,
                        height: 6.0,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      const Text(
                        'Online',
                        style: TextStyle(color: Colors.white54, fontSize: 10.0),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Refresh Contacts',
            onPressed: () => ref.read(contactsProvider.notifier).fetchContacts(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Sign Out',
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(contactsProvider.notifier).fetchContacts(),
        color: Colors.blueAccent,
        backgroundColor: const Color(0xFF1C1C1E),
        child: Builder(
          builder: (context) {
            if (contactsState.isLoading) {
              return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
            }

            if (contactsState.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 48.0),
                      const SizedBox(height: 16.0),
                      Text(
                        'Error loading contacts:',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14.0),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        contactsState.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 13.0),
                      ),
                      const SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: () => ref.read(contactsProvider.notifier).fetchContacts(),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                        child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              );
            }

            final users = contactsState.users;

            if (users.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, color: Colors.white.withOpacity(0.2), size: 64.0),
                        const SizedBox(height: 16.0),
                        const Text(
                          'No contacts found',
                          style: TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Register another user on the backend to begin testing calls.',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12.0),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              itemCount: users.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12.0),
              itemBuilder: (context, index) {
                final user = users[index];
                return _buildContactCard(user);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildContactCard(UserModel user) {
    Color statusColor = Colors.grey;
    if (user.status == 'online') {
      statusColor = Colors.greenAccent;
    } else if (user.status == 'busy') {
      statusColor = Colors.amberAccent;
    }

    final hasFcm = user.fcmToken != null && user.fcmToken!.isNotEmpty;

    return Card(
      color: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            // Contact circular avatar with online status badge indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 24.0,
                  backgroundColor: Colors.blueGrey,
                  child: Text(
                    user.username.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12.0,
                    height: 12.0,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1C1C1E), width: 2.0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16.0),

            // Contact Name and Email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    user.email,
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12.0),
                  ),
                  if (!hasFcm) ...[
                    const SizedBox(height: 4.0),
                    Text(
                      'No Push Token (Offline calling unavailable)',
                      style: TextStyle(color: Colors.amber.withOpacity(0.8), fontSize: 9.0),
                    ),
                  ]
                ],
              ),
            ),

            // Video and Audio Call Actions
            Row(
              children: [
                // Audio Call Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.phone, color: Colors.blueAccent, size: 20.0),
                    onPressed: () => _callUser(user, false),
                    tooltip: 'Audio Call',
                  ),
                ),
                const SizedBox(width: 8.0),
                
                // Video Call Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.videocam, color: Colors.greenAccent, size: 20.0),
                    onPressed: () => _callUser(user, true),
                    tooltip: 'Video Call',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
