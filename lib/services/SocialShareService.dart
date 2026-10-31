import 'package:flutter_telegram_miniapp/flutter_telegram_miniapp.dart';

class SocialShareService {
  static final _app = WebApp();

  /// Share to Telegram Story with custom clickable overlay widgets
  static void postStory({
    required String mediaUrl,
    required String caption,
    required String buttonText,
    required String appDeepLink,
  }) {
    _app.shareToStory(mediaUrl: 
      mediaUrl,storyShareParams:
      StoryShareParams(
        text: caption,
        widgetLink: StoryWidgetLink(
          url: appDeepLink,
          name: buttonText,
        ),
      ),
    );
  }

  /// Open pre-populated Telegram message picker
  static void shareInviteLink(String inviteUrl, String message) {
    final fullUrl = "https://t.me/share/url?url=${Uri.encodeComponent(inviteUrl)}&text=${Uri.encodeComponent(message)}";
    _app.openTelegramLink(url:fullUrl);
  }
}