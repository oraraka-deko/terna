library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_assets.dart';
import '../../models/chat/chat_models.dart';
import '../api/gateway_api_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal() {
    refreshChatData();
  }

  String get currentUserId => GatewayApiService().currentUserId;
  String get currentUsername => GatewayApiService().currentUsername;

  final ValueNotifier<List<FriendItem>> friends = ValueNotifier<List<FriendItem>>([]);
  final ValueNotifier<Map<String, List<ChatMessage>>> directMessages = ValueNotifier<Map<String, List<ChatMessage>>>({});
  final ValueNotifier<List<ChatMessage>> globalMessages = ValueNotifier<List<ChatMessage>>([]);
  final ValueNotifier<List<ChatGroup>> groups = ValueNotifier<List<ChatGroup>>([]);
  final ValueNotifier<GamerBioData> userBio = ValueNotifier<GamerBioData>(
    const GamerBioData(
      userId: 'demo_user_1',
      username: '@terna_player',
      avatar: AppAssets.avatarTravelDuckParis,
      playStyle: 'Tactical Striker 🎯',
      favoriteCharacter: 'Genesis Durov',
      postMatchReaction: 'Always ready for a rematch! 🔥',
      aboutMe: 'Arena Player & Telegram WebApp Pioneer 🚀',
      roundsPlayed: 0,
      roundsWon: 0,
      totalWagered: 0.0,
      biggestWin: 0.0,
    ),
  );
  final ValueNotifier<int> onlineCount = ValueNotifier<int>(1);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  /// Synchronize chat messages, friends, and gamer bio with the backend
  Future<void> refreshChatData() async {
    try {
      isLoading.value = true;
      final api = GatewayApiService();

      // 1. Fetch Global Live Chat messages
      final rawGlobal = await api.getChatMessages(scope: 'global', limit: 50);
      if (rawGlobal.isNotEmpty) {
        final parsedGlobal = <ChatMessage>[];
        for (final item in rawGlobal) {
          if (item is Map<String, dynamic>) {
            parsedGlobal.add(_parseBackendMessage(item));
          }
        }
        globalMessages.value = parsedGlobal;
      }

      // 2. Fetch friends & social list
      final rawFriends = await api.getFriends();
      if (rawFriends.isNotEmpty) {
        final parsedFriends = <FriendItem>[];
        for (final item in rawFriends) {
          if (item is Map<String, dynamic>) {
            parsedFriends.add(
              FriendItem(
                id: item['id']?.toString() ?? 'fr_${item['friendId']}',
                userId: item['userId']?.toString() ?? currentUserId,
                friendId: item['friendId']?.toString() ?? '',
                friendUsername: item['friendUsername']?.toString() ?? item['username']?.toString() ?? 'Player',
                friendAvatar: item['friendAvatar']?.toString() ?? item['avatar']?.toString() ?? AppAssets.avatarDino,
                status: item['status'] == 'pending' ? FriendStatus.pending : FriendStatus.accepted,
                isOnline: item['isOnline'] == true,
                playStyle: item['playStyle']?.toString() ?? 'Gamer 🎮',
              ),
            );
          }
        }
        friends.value = parsedFriends;
      }

      // 3. Fetch user bio
      final rawBio = await api.getGamerBio(currentUserId);
      if (rawBio.isNotEmpty) {
        userBio.value = GamerBioData(
          userId: currentUserId,
          username: rawBio['nickname']?.toString().isNotEmpty == true
              ? rawBio['nickname'].toString()
              : currentUsername,
          avatar: rawBio['avatar']?.toString() ?? AppAssets.avatarTravelDuckParis,
          playStyle: rawBio['playStyle']?.toString() ?? 'Tactical Striker 🎯',
          favoriteCharacter: rawBio['favoriteGame']?.toString() ?? 'Genesis Durov',
          postMatchReaction: rawBio['postMatchReaction']?.toString() ?? 'Always ready for a rematch! 🔥',
          aboutMe: rawBio['bioText']?.toString() ?? '',
          roundsPlayed: (rawBio['roundsPlayed'] as num?)?.toInt() ?? 0,
          roundsWon: (rawBio['roundsWon'] as num?)?.toInt() ?? 0,
          totalWagered: (rawBio['totalWagered'] as num?)?.toDouble() ?? 0.0,
          biggestWin: (rawBio['biggestWin'] as num?)?.toDouble() ?? 0.0,
        );
      }
    } catch (e) {
      debugPrint('[ChatService] refreshChatData offline fallback: $e');
    } finally {
      isLoading.value = false;
    }
  }

  ChatMessage _parseBackendMessage(Map<String, dynamic> item) {
    final ts = item['timestamp'] != null
        ? DateTime.fromMillisecondsSinceEpoch((item['timestamp'] as num).toInt())
        : DateTime.now();
    final timeStr = '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';

    final senderId = item['senderId']?.toString() ?? '';
    final isOut = senderId == currentUserId;

    Map<String, int> reactions = {};
    if (item['reactions'] is Map) {
      (item['reactions'] as Map).forEach((k, v) {
        if (v is num) {
          reactions[k.toString()] = v.toInt();
        } else if (v is List) {
          reactions[k.toString()] = v.length;
        }
      });
    }

    return ChatMessage(
      id: item['id']?.toString() ?? 'msg_${ts.millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: item['sender']?.toString() ?? item['senderName']?.toString() ?? 'Player',
      senderAvatar: item['avatar']?.toString() ?? item['senderAvatar']?.toString() ?? AppAssets.avatarDino,
      text: item['text']?.toString() ?? '',
      timestamp: ts,
      time: timeStr,
      scope: item['scope']?.toString() ?? 'global',
      recipientId: item['recipientId']?.toString(),
            isOutgoing: isOut,
      replyToId: item['replyToId']?.toString(),
      replyText: item['replyPreview']?.toString() ?? item['replyText']?.toString(),
      reactions: reactions,
    );
  }

  // --------------------------------------------------------------------------
  // FRIENDS ACTIONS
  // --------------------------------------------------------------------------
  Future<bool> sendFriendRequest(String username) async {
    final clean = username.trim().replaceAll('@', '');
    if (clean.isEmpty) return false;

    try {
      final ok = await GatewayApiService().sendFriendRequest(clean);
      if (ok) {
        final newReq = FriendItem(
          id: 'fr_${DateTime.now().millisecondsSinceEpoch}',
          userId: currentUserId,
          friendId: clean.toLowerCase(),
          friendUsername: '@$clean',
          friendAvatar: AppAssets.avatarDino,
          status: FriendStatus.pending,
          isOnline: true,
          playStyle: 'Tactical Striker 🎯',
        );
        friends.value = [newReq, ...friends.value];
        return true;
      }
    } catch (_) {}

    return false;
  }

  Future<void> acceptFriendRequest(String id) async {
    final list = List<FriendItem>.from(friends.value);
    final idx = list.indexWhere((f) => f.id == id);
    if (idx != -1) {
      final friend = list[idx];
      try {
        await GatewayApiService().respondFriendRequest(friend.friendId, true);
      } catch (_) {}
      list[idx] = list[idx].copyWith(status: FriendStatus.accepted);
      friends.value = list;
    }
  }

  void declineFriendRequest(String id) {
    final list = List<FriendItem>.from(friends.value);
    final idx = list.indexWhere((f) => f.id == id);
    if (idx != -1) {
      final friend = list[idx];
      try {
        GatewayApiService().respondFriendRequest(friend.friendId, false);
      } catch (_) {}
      list.removeAt(idx);
      friends.value = list;
    }
  }

  void removeFriend(String id) {
    final list = List<FriendItem>.from(friends.value);
    list.removeWhere((f) => f.id == id);
    friends.value = list;
  }

  // --------------------------------------------------------------------------
  // DIRECT CHAT ACTIONS
  // --------------------------------------------------------------------------
  Future<void> fetchDirectMessages(String recipientId) async {
    try {
      final raw = await GatewayApiService().getChatMessages(scope: 'direct', targetId: recipientId);
      final list = <ChatMessage>[];
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          list.add(_parseBackendMessage(item));
        }
      }
      final map = Map<String, List<ChatMessage>>.from(directMessages.value);
      map[recipientId] = list;
      directMessages.value = map;
    } catch (e) {
      debugPrint('[ChatService] fetchDirectMessages error: $e');
    }
  }

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

    // Optimistically update UI
    final map = Map<String, List<ChatMessage>>.from(directMessages.value);
    final currentList = map[recipientId] ?? [];
    map[recipientId] = [...currentList, newMsg];
    directMessages.value = map;

    // Post to backend asynchronously
    final api = GatewayApiService();
    api.postChatMessage(
      text: text,
      scope: 'direct',
      recipientId: recipientId,
      replyToId: replyToId,
      replyPreview: replyText,
    ).catchError((_) => <String, dynamic>{});

    // If transfer attached, execute backend transfer
    if (transfer != null) {
      api.executeChatTransfer(
        recipientId: recipientId,
        recipientName: recipientId,
        type: transfer.type,
        amount: transfer.amount,
        giftId: transfer.giftId,
        giftName: transfer.giftName,
      ).catchError((_) => <String, dynamic>{});
    }
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
      senderName: 'You ($currentUsername)',
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

    // Post to backend
    GatewayApiService().postChatMessage(
      text: text,
      scope: 'global',
      replyToId: replyToId,
      replyPreview: replyText,
    ).catchError((_) => <String, dynamic>{});
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

    GatewayApiService().toggleChatReaction(messageId: messageId, emoji: emoji).catchError((_) => <String, dynamic>{});
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
    return GamerBioData(
      userId: userId,
      username: defaultName,
      aboutMe: 'Active Terna player',
    );
  }

  Future<void> updateBio({
    required String playStyle,
    required String favoriteCharacter,
    required String postMatchReaction,
    required String aboutMe,
  }) async {
    userBio.value = userBio.value.copyWith(
      playStyle: playStyle,
      favoriteCharacter: favoriteCharacter,
      postMatchReaction: postMatchReaction,
      aboutMe: aboutMe,
    );

    try {
      await GatewayApiService().updateGamerBio({
        'nickname': userBio.value.username,
        'bioText': aboutMe,
        'playStyle': playStyle,
        'favoriteGame': favoriteCharacter,
        'postMatchReaction': postMatchReaction,
      });
    } catch (_) {}
  }
}
