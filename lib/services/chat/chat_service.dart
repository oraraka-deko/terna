library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_assets.dart';
import '../../models/chat/chat_models.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal() {
    _initDemoState();
  }

  final String currentUserId = 'terna_player_me';
  final String currentUsername = '@terna_player';

  final ValueNotifier<List<FriendItem>> friends = ValueNotifier<List<FriendItem>>([]);
  final ValueNotifier<Map<String, List<ChatMessage>>> directMessages = ValueNotifier<Map<String, List<ChatMessage>>>({});
  final ValueNotifier<List<ChatMessage>> globalMessages = ValueNotifier<List<ChatMessage>>([]);
  final ValueNotifier<List<ChatGroup>> groups = ValueNotifier<List<ChatGroup>>([]);
  final ValueNotifier<GamerBioData> userBio = ValueNotifier<GamerBioData>(
    const GamerBioData(
      userId: 'terna_player_me',
      username: '@terna_player',
      avatar: AppAssets.avatarTravelDuckParis,
      playStyle: 'Tactical Striker 🎯',
      favoriteCharacter: 'Genesis Durov',
      postMatchReaction: 'Always ready for a rematch! 🔥',
      aboutMe: 'Arena Player & Telegram WebApp Pioneer 🚀',
      roundsPlayed: 168,
      roundsWon: 112,
      totalWagered: 1840.0,
      biggestWin: 420.0,
    ),
  );
  final ValueNotifier<int> onlineCount = ValueNotifier<int>(1482);

  void _initDemoState() {
    final now = DateTime.now();

    // 1. Initial Friends
    friends.value = [
      const FriendItem(
        id: 'fr_1',
        userId: 'terna_player_me',
        friendId: 'cat',
        friendUsername: 'Cat',
        friendAvatar: AppAssets.avatarCat,
        status: FriendStatus.accepted,
        isOnline: true,
        playStyle: 'Lucky Gambler 🎲',
      ),
      const FriendItem(
        id: 'fr_2',
        userId: 'terna_player_me',
        friendId: 'penguin',
        friendUsername: 'Penguin',
        friendAvatar: AppAssets.avatarPenguin,
        status: FriendStatus.accepted,
        isOnline: true,
        playStyle: 'High Roller Whale 🐋',
      ),
      const FriendItem(
        id: 'fr_3',
        userId: 'terna_player_me',
        friendId: 'dolphin',
        friendUsername: 'Dolphin',
        friendAvatar: AppAssets.avatarDolphin,
        status: FriendStatus.accepted,
        isOnline: true,
        playStyle: 'Tactical Striker 🎯',
      ),
      const FriendItem(
        id: 'fr_4',
        userId: 'terna_player_me',
        friendId: 'dog',
        friendUsername: 'Dog',
        friendAvatar: AppAssets.avatarDog,
        status: FriendStatus.accepted,
        isOnline: false,
        playStyle: 'Zen Defender 🛡️',
      ),
      const FriendItem(
        id: 'fr_5',
        userId: 'terna_player_me',
        friendId: 'pepe',
        friendUsername: 'Pepe',
        friendAvatar: AppAssets.avatarPepe,
        status: FriendStatus.accepted,
        isOnline: false,
        playStyle: 'Relic Hunter 💎',
      ),
      // Incoming request from area_game demo
      const FriendItem(
        id: 'fr_req_1',
        userId: 'genesis_durov',
        friendId: 'terna_player_me',
        friendUsername: 'Genesis Durov',
        friendAvatar: AppAssets.avatarTravelDuckParis,
        status: FriendStatus.pending,
        isOnline: true,
        playStyle: 'High Roller Whale 🐋',
      ),
    ];

    // 2. Direct Messages for 'cat'
    directMessages.value = {
      'cat': [
        ChatMessage(
          id: 'msg_cat_1',
          senderId: 'cat',
          senderName: 'Cat',
          senderAvatar: AppAssets.avatarCat,
          text: 'Hey! Ready for some Arena games today? 🎮',
          timestamp: now.subtract(const Duration(minutes: 12)),
          time: '9:38',
          isOutgoing: false,
          reactions: {'🔥': 2},
        ),
        ChatMessage(
          id: 'msg_cat_2',
          senderId: 'terna_player_me',
          senderName: 'You',
          text: 'Send a dice emoji to roll a die!',
          timestamp: now.subtract(const Duration(minutes: 8)),
          time: '9:40',
          isOutgoing: true,
        ),
        ChatMessage(
          id: 'msg_cat_3',
          senderId: 'cat',
          senderName: 'Cat',
          senderAvatar: AppAssets.avatarCat,
          text: '🎲 Rolled a 6!',
          timestamp: now.subtract(const Duration(minutes: 7)),
          time: '9:41',
          isOutgoing: false,
          isDice: true,
        ),
        ChatMessage(
          id: 'msg_cat_4',
          senderId: 'cat',
          senderName: 'Cat',
          senderAvatar: AppAssets.avatarCat,
          text: 'Video message note',
          timestamp: now.subtract(const Duration(minutes: 5)),
          time: '9:41',
          isOutgoing: false,
          isVideoNote: true,
        ),
      ],
    };

    // 3. Global Broadcast / Live Chat Messages
    globalMessages.value = [
      ChatMessage(
        id: 'g_msg_1',
        senderId: 'durov',
        senderName: 'Pavel Durov',
        senderAvatar: AppAssets.avatarTravelDuckParis,
        text: 'Welcome to the Terna Global Live Arena! Fast WebAssembly settlement and TON on-chain transfers are live. 🚀',
        timestamp: now.subtract(const Duration(minutes: 25)),
        time: '18:10',
        scope: 'global',
        isOutgoing: false,
        reactions: {'🔥': 148, '❤️': 89, '🚀': 120},
      ),
      ChatMessage(
        id: 'g_msg_2',
        senderId: 'crypto_whale',
        senderName: 'Crypto Whale 🐋',
        senderAvatar: AppAssets.avatarDolphin,
        text: 'Just won 25 TON on American Roulette straight-up on 17 Black! 🤑',
        timestamp: now.subtract(const Duration(minutes: 14)),
        time: '18:21',
        scope: 'global',
        isOutgoing: false,
        reactions: {'👏': 12, '🤑': 8},
      ),
      ChatMessage(
        id: 'g_msg_3',
        senderId: 'arena_master',
        senderName: 'Arena Master ⚔️',
        senderAvatar: AppAssets.avatarPepe,
        text: 'Next Territory slicing tournament starts in 30 minutes. Pool is 100 TON!',
        timestamp: now.subtract(const Duration(minutes: 5)),
        time: '18:30',
        scope: 'global',
        isOutgoing: false,
        reactions: {'⚔️': 24, '🔥': 19},
      ),
    ];

    // 4. Chat Groups
    groups.value = [
      const ChatGroup(
        id: 'grp_global',
        name: 'Terna Global Community',
        description: 'Official global chat room for all players and builders',
        icon: '💬',
        creatorId: 'durov',
        memberCount: 1482,
      ),
      const ChatGroup(
        id: 'grp_whales',
        name: 'High Roller VIPs 🐋',
        description: 'Exclusive private discussion for top tournament players',
        icon: '🐋',
        creatorId: 'crypto_whale',
        isPrivate: true,
        memberCount: 48,
      ),
      const ChatGroup(
        id: 'grp_arcade',
        name: 'Arcade & Tower Masters 🏆',
        description: 'Strategy discussions for Mines Arena and Tower climb',
        icon: '🏆',
        creatorId: 'arena_master',
        memberCount: 312,
      ),
    ];
  }

  // --------------------------------------------------------------------------
  // FRIENDS ACTIONS
  // --------------------------------------------------------------------------
  Future<bool> sendFriendRequest(String username) async {
    final clean = username.trim().replaceAll('@', '');
    if (clean.isEmpty) return false;

    await Future.delayed(const Duration(milliseconds: 600));

    // Check if already friends
    final existing = friends.value.any((f) => f.friendUsername.toLowerCase() == clean.toLowerCase());
    if (existing) return false;

    final newReq = FriendItem(
      id: 'fr_${DateTime.now().millisecondsSinceEpoch}',
      userId: currentUserId,
      friendId: clean.toLowerCase(),
      friendUsername: '@$clean',
      friendAvatar: AppAssets.avatarTravelDuckParis,
      status: FriendStatus.pending,
      isOnline: true,
      playStyle: 'Tactical Striker 🎯',
    );

    friends.value = [newReq, ...friends.value];
    return true;
  }

  void acceptFriendRequest(String id) {
    final list = List<FriendItem>.from(friends.value);
    final idx = list.indexWhere((f) => f.id == id);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(status: FriendStatus.accepted);
      friends.value = list;
    }
  }

  void declineFriendRequest(String id) {
    final list = List<FriendItem>.from(friends.value);
    list.removeWhere((f) => f.id == id);
    friends.value = list;
  }

  void removeFriend(String id) {
    final list = List<FriendItem>.from(friends.value);
    list.removeWhere((f) => f.id == id);
    friends.value = list;
  }

  // --------------------------------------------------------------------------
  // DIRECT CHAT ACTIONS
  // --------------------------------------------------------------------------
  void sendDirectMessage({
    required String recipientId,
    required String text,
    String? replyToId,
    String? replyText,
    ChatTransferData? transfer,
    bool isDice = false,
  }) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final newMsg = ChatMessage(
      id: 'dm_${now.millisecondsSinceEpoch}_${Random().nextInt(999)}',
      senderId: currentUserId,
      senderName: 'You',
      text: text,
      timestamp: now,
      time: timeStr,
      scope: 'direct',
      recipientId: recipientId,
      isOutgoing: true,
      replyToId: replyToId,
      replyText: replyText,
      transfer: transfer,
      isDice: isDice,
    );

    final map = Map<String, List<ChatMessage>>.from(directMessages.value);
    final currentList = map[recipientId] ?? [];
    map[recipientId] = [...currentList, newMsg];
    directMessages.value = map;

    // Graceful offline reply simulation if recipient is 'cat' or other bot
    if (recipientId == 'cat') {
      _scheduleAutoReply(recipientId, transfer != null);
    }
  }

  void _scheduleAutoReply(String recipientId, bool isTransfer) {
    Timer(const Duration(milliseconds: 1400), () {
      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      String replyText = 'Nice! Thanks for the message! Let’s play a round of Plinko! 🐱';
      if (isTransfer) {
        replyText = 'Whoa! Thank you so much for the transfer! You are the best! 💖🎁';
      }

      final autoMsg = ChatMessage(
        id: 'dm_reply_${now.millisecondsSinceEpoch}',
        senderId: recipientId,
        senderName: 'Cat',
        senderAvatar: AppAssets.avatarCat,
        text: replyText,
        timestamp: now,
        time: timeStr,
        scope: 'direct',
        recipientId: currentUserId,
        isOutgoing: false,
        reactions: {'❤️': 1},
      );

      final map = Map<String, List<ChatMessage>>.from(directMessages.value);
      final currentList = map[recipientId] ?? [];
      map[recipientId] = [...currentList, autoMsg];
      directMessages.value = map;
    });
  }

  // --------------------------------------------------------------------------
  // GLOBAL CHAT ACTIONS
  // --------------------------------------------------------------------------
  void sendGlobalMessage({
    required String text,
    String? replyToId,
    String? replyText,
    ChatTransferData? transfer,
  }) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final newMsg = ChatMessage(
      id: 'g_${now.millisecondsSinceEpoch}_${Random().nextInt(999)}',
      senderId: currentUserId,
      senderName: 'You (@terna_player)',
      text: text,
      timestamp: now,
      time: timeStr,
      scope: 'global',
      isOutgoing: true,
      replyToId: replyToId,
      replyText: replyText,
      transfer: transfer,
    );

    globalMessages.value = [...globalMessages.value, newMsg];
  }

  // --------------------------------------------------------------------------
  // REACTIONS
  // --------------------------------------------------------------------------
  void toggleReaction(String messageId, String emoji, {bool isGlobal = false, String? recipientId}) {
    if (isGlobal) {
      final list = List<ChatMessage>.from(globalMessages.value);
      final idx = list.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        final currentRx = Map<String, int>.from(list[idx].reactions);
        currentRx[emoji] = (currentRx[emoji] ?? 0) + 1;
        list[idx] = list[idx].copyWith(reactions: currentRx);
        globalMessages.value = list;
      }
    } else if (recipientId != null) {
      final map = Map<String, List<ChatMessage>>.from(directMessages.value);
      final list = List<ChatMessage>.from(map[recipientId] ?? []);
      final idx = list.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        final currentRx = Map<String, int>.from(list[idx].reactions);
        currentRx[emoji] = (currentRx[emoji] ?? 0) + 1;
        list[idx] = list[idx].copyWith(reactions: currentRx);
        map[recipientId] = list;
        directMessages.value = map;
      }
    }
  }

  // --------------------------------------------------------------------------
  // GROUPS
  // --------------------------------------------------------------------------
  void createGroup({
    required String name,
    required String description,
    required String icon,
    required bool isPrivate,
  }) {
    final newGroup = ChatGroup(
      id: 'grp_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      icon: icon,
      creatorId: currentUserId,
      isPrivate: isPrivate,
      memberCount: 1,
    );
    groups.value = [newGroup, ...groups.value];
  }

  // --------------------------------------------------------------------------
  // GAMER BIO LOOKUP
  // --------------------------------------------------------------------------
  GamerBioData getGamerBio(String userId, {String defaultName = 'Player'}) {
    if (userId == currentUserId) return userBio.value;
    if (userId == 'cat') {
      return const GamerBioData(
        userId: 'cat',
        username: 'Cat',
        avatar: AppAssets.avatarCat,
        playStyle: 'Lucky Gambler 🎲',
        favoriteCharacter: 'Space Cat 🐱',
        postMatchReaction: 'Always ready for a rematch! 🔥',
        aboutMe: 'Fast dice roller & arena champion.',
        roundsPlayed: 320,
        roundsWon: 210,
        totalWagered: 3500.0,
        biggestWin: 920.0,
      );
    }
    if (userId == 'penguin') {
      return const GamerBioData(
        userId: 'penguin',
        username: 'Penguin',
        avatar: AppAssets.avatarPenguin,
        playStyle: 'High Roller Whale 🐋',
        favoriteCharacter: 'Polar Duke 🐧',
        postMatchReaction: 'Winner takes all! 🏆',
        aboutMe: 'Whale trader on TON Network.',
        roundsPlayed: 540,
        roundsWon: 390,
        totalWagered: 12400.0,
        biggestWin: 2850.0,
      );
    }
    return GamerBioData(
      userId: userId,
      username: defaultName,
      aboutMe: 'Active Terna player',
    );
  }

  void updateBio({
    required String playStyle,
    required String favoriteCharacter,
    required String postMatchReaction,
    required String aboutMe,
  }) {
    userBio.value = userBio.value.copyWith(
      playStyle: playStyle,
      favoriteCharacter: favoriteCharacter,
      postMatchReaction: postMatchReaction,
      aboutMe: aboutMe,
    );
  }
}
