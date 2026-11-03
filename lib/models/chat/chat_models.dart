library;

enum FriendStatus { accepted, pending, blocked }

class FriendItem {
  final String id;
  final String userId;
  final String friendId;
  final String friendUsername;
  final String? friendAvatar;
  final FriendStatus status;
  final bool isOnline;
  final String? playStyle;

  const FriendItem({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.friendUsername,
    this.friendAvatar,
    this.status = FriendStatus.accepted,
    this.isOnline = false,
    this.playStyle,
  });

  FriendItem copyWith({
    String? id,
    String? userId,
    String? friendId,
    String? friendUsername,
    String? friendAvatar,
    FriendStatus? status,
    bool? isOnline,
    String? playStyle,
  }) {
    return FriendItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      friendUsername: friendUsername ?? this.friendUsername,
      friendAvatar: friendAvatar ?? this.friendAvatar,
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      playStyle: playStyle ?? this.playStyle,
    );
  }
}

class ChatTransferData {
  final String type; // 'TON', 'STARS', 'GIFT'
  final double amount;
  final String? giftId;
  final String? giftName;
  final String? giftAsset;
  final String? editionNumber;
  final String status; // 'CONFIRMED', 'PENDING'
  final String? txHash;

  const ChatTransferData({
    required this.type,
    this.amount = 0.0,
    this.giftId,
    this.giftName,
    this.giftAsset,
    this.editionNumber,
    this.status = 'CONFIRMED',
    this.txHash,
  });
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String text;
  final DateTime timestamp;
  final String time;
  final String scope; // 'global', 'group', 'direct'
  final String? recipientId;
  final bool isOutgoing;
  final String? replyToId;
  final String? replyText;
  final Map<String, int> reactions;
  final ChatTransferData? transfer;
  final bool isDice;
  final bool isVideoNote;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.text,
    required this.timestamp,
    required this.time,
    this.scope = 'direct',
    this.recipientId,
    required this.isOutgoing,
    this.replyToId,
    this.replyText,
    this.reactions = const {},
    this.transfer,
    this.isDice = false,
    this.isVideoNote = false,
  });

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? text,
    DateTime? timestamp,
    String? time,
    String? scope,
    String? recipientId,
    bool? isOutgoing,
    String? replyToId,
    String? replyText,
    Map<String, int>? reactions,
    ChatTransferData? transfer,
    bool? isDice,
    bool? isVideoNote,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      time: time ?? this.time,
      scope: scope ?? this.scope,
      recipientId: recipientId ?? this.recipientId,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      replyToId: replyToId ?? this.replyToId,
      replyText: replyText ?? this.replyText,
      reactions: reactions ?? this.reactions,
      transfer: transfer ?? this.transfer,
      isDice: isDice ?? this.isDice,
      isVideoNote: isVideoNote ?? this.isVideoNote,
    );
  }
}

class GamerBioData {
  final String userId;
  final String username;
  final String? avatar;
  final String playStyle;
  final String favoriteCharacter;
  final String postMatchReaction;
  final String aboutMe;
  final int roundsPlayed;
  final int roundsWon;
  final double totalWagered;
  final double biggestWin;

  const GamerBioData({
    required this.userId,
    required this.username,
    this.avatar,
    this.playStyle = 'Tactical Striker 🎯',
    this.favoriteCharacter = 'Genesis Durov',
    this.postMatchReaction = 'Always ready for a rematch! 🔥',
    this.aboutMe = 'Arena Player & Telegram WebApp Pioneer',
    this.roundsPlayed = 142,
    this.roundsWon = 94,
    this.totalWagered = 1420.0,
    this.biggestWin = 380.0,
  });

  int get winRate => roundsPlayed > 0 ? ((roundsWon / roundsPlayed) * 100).round() : 0;

  GamerBioData copyWith({
    String? userId,
    String? username,
    String? avatar,
    String? playStyle,
    String? favoriteCharacter,
    String? postMatchReaction,
    String? aboutMe,
    int? roundsPlayed,
    int? roundsWon,
    double? totalWagered,
    double? biggestWin,
  }) {
    return GamerBioData(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      playStyle: playStyle ?? this.playStyle,
      favoriteCharacter: favoriteCharacter ?? this.favoriteCharacter,
      postMatchReaction: postMatchReaction ?? this.postMatchReaction,
      aboutMe: aboutMe ?? this.aboutMe,
      roundsPlayed: roundsPlayed ?? this.roundsPlayed,
      roundsWon: roundsWon ?? this.roundsWon,
      totalWagered: totalWagered ?? this.totalWagered,
      biggestWin: biggestWin ?? this.biggestWin,
    );
  }
}

class ChatGroup {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String creatorId;
  final bool isPrivate;
  final int memberCount;
  final bool isMuted;

  const ChatGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.creatorId,
    this.isPrivate = false,
    this.memberCount = 1,
    this.isMuted = false,
  });

  ChatGroup copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? creatorId,
    bool? isPrivate,
    int? memberCount,
    bool? isMuted,
  }) {
    return ChatGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      creatorId: creatorId ?? this.creatorId,
      isPrivate: isPrivate ?? this.isPrivate,
      memberCount: memberCount ?? this.memberCount,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}

