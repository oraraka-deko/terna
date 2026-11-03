import 'package:flutter/material.dart';
import 'package:terna/core/widgets/floating_bottom_nav_bar.dart';
import 'package:terna/core/widgets/mobile_frame_wrapper.dart';
import 'package:terna/features/chat_room/channel_broadcast_screen.dart';
import 'package:terna/features/chat_room/personal_chat_screen.dart';
import 'package:terna/features/chats/chats_screen.dart';
import 'package:terna/features/contacts/contacts_screen.dart';
import 'package:terna/features/profile/profile_info_screen.dart';
import 'package:terna/features/settings/settings_screen.dart';

class TelegramAppRoot extends StatefulWidget {
  final VoidCallback? onExitToDrawer;

  const TelegramAppRoot({super.key, this.onExitToDrawer});

  @override
  State<TelegramAppRoot> createState() => _TelegramAppRootState();
}

class _TelegramAppRootState extends State<TelegramAppRoot> {
  TelegramTab _currentTab = TelegramTab.chats;

  void _navigateToLiveChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MobileFrameWrapper(
          onExit: () => Navigator.of(context).pop(),
          child: ChannelBroadcastScreen(
            onBack: () => Navigator.of(context).pop(),
            onHeaderTap: () => _navigateToProfile(ProfileType.channel),
          ),
        ),
      ),
    );
  }

  void _navigateToPersonalChat([String recipientId = 'cat', String recipientName = 'Cat']) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MobileFrameWrapper(
          onExit: () => Navigator.of(context).pop(),
          child: PersonalChatScreen(
            recipientId: recipientId,
            recipientName: recipientName,
            onBack: () => Navigator.of(context).pop(),
            onHeaderProfileTap: () => _navigateToProfile(ProfileType.personal),
          ),
        ),
      ),
    );
  }

  void _navigateToChannel() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MobileFrameWrapper(
          onExit: () => Navigator.of(context).pop(),
          child: ChannelBroadcastScreen(
            onBack: () => Navigator.of(context).pop(),
            onHeaderTap: () => _navigateToProfile(ProfileType.channel),
          ),
        ),
      ),
    );
  }

  void _navigateToProfile(ProfileType type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MobileFrameWrapper(
          onExit: () => Navigator.of(context).pop(),
          darkStatusBar: type == ProfileType.personal,
          child: ProfileInfoScreen(
            type: type,
            onBack: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MobileFrameWrapper(
      onExit: widget.onExitToDrawer ?? () => Navigator.of(context).maybePop(),
      child: Scaffold(
        body: Stack(
          children: [
            // Current Tab Content
            Positioned.fill(
              child: IndexedStack(
                index: _currentTab.index,
                children: [
                  // Tab 0: Contacts
                  ContactsScreen(
                    onContactTap: (name) {
                      _navigateToPersonalChat(name.toLowerCase(), name);
                    },
                  ),

                  // Tab 1: Calls (placeholder list)
                  const Scaffold(
                    backgroundColor: Colors.white,
                    body: Center(
                      child: Text(
                        'Recent Calls',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ),
                  ),

                  // Tab 2: Chats
                  ChatsScreen(
                    onChatTap: (item) {
                      if (item.id == 'live_global_chat') {
                        _navigateToLiveChat();
                      } else if (item.id == '16bit_team') {
                        _navigateToChannel();
                      } else {
                        _navigateToPersonalChat();
                      }
                    },
                    onAvatarTap: (name) {
                      if (name.contains('Team') || name.contains('Channel')) {
                        _navigateToProfile(ProfileType.channel);
                      } else {
                        _navigateToProfile(ProfileType.personal);
                      }
                    },
                  ),

                  // Tab 3: Settings
                  SettingsScreen(
                    onMyProfileTap: () => _navigateToProfile(ProfileType.personal),
                  ),
                ],
              ),
            ),

            // Floating Glass Bottom Navigation Bar
            FloatingBottomNavBar(
              currentTab: _currentTab,
              onTabSelected: (tab) {
                setState(() {
                  _currentTab = tab;
                });
              },
              onSearchTap: () {
                // Focus search or show channel
                _navigateToChannel();
              },
            ),
          ],
        ),
      ),
    );
  }
}

