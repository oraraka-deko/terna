# telegram_ios_ui_kit

A Telegram iOS-style Flutter UI Kit with:

- Telegram-inspired light/dark color tokens
- Reusable chat UI widgets (chat list tile, bubbles, input bar)
- iOS-style settings cells, segmented control, and tab bar
- Mini App action button variants (`Web App`, `Text Commands`, `Close App`)
- A runnable example app in `example/`

## Design Source

This package is implemented against the public Figma community file:

- Telegram iOS UI Kit (Community)

It focuses on reusable components and design tokens so you can quickly build Telegram-like interfaces in Flutter.

## Features

- `TelegramThemeData`, `TelegramColors`, `TelegramTheme`
- `TelegramAvatar`, `TelegramBadge`
- `TelegramChatListTile`, `TelegramChatBubble`, `TelegramMessageInputBar`, `TelegramChatHeader`
- `TelegramDateSeparator`, `TelegramUnreadSeparator`, `TelegramPinnedMessageBar`, `TelegramTypingIndicator`
- `TelegramQuickRepliesBar`, `TelegramReactionBar`
- `TelegramSwipeActions`, `TelegramContextMenu`, `TelegramNoticeBanner`
- `TelegramLargeTitleHeader`, `TelegramCollapsibleLargeTitle`
- `TelegramAttachmentPanel`, `TelegramReplyPreviewBar`
- `TelegramInlineKeyboard`, `TelegramFileMessageTile`, `TelegramPollCard`
- `TelegramVoiceMessageTile`, `TelegramReferenceMessageCard`, `TelegramChatActionToolbar`
- `TelegramLinkPreviewCard`, `TelegramLocationMessageTile`, `TelegramContactMessageTile`
- `TelegramChatBackground`, `TelegramMediaAlbumMessage`, `TelegramScheduleTimeline`
- `TelegramChatWallpaper`, `TelegramMessageSelectionWrapper`
- `TelegramReadReceipt`, `TelegramReadReceiptsStrip`
- `TelegramStickyDateHeader`
- `TelegramExpandableMessageInputBar`
- `TelegramServiceMessageBubble`
- `TelegramJumpToBottomButton`
- `TelegramChannelInfoHeader`, `TelegramChannelStatsGrid`
- `TelegramAdminMember`, `TelegramAdminMemberTile`
- `TelegramPermissionToggle`, `TelegramPermissionsPanel`
- `TelegramModerationRequest`, `TelegramModerationQueueCard`
- `TelegramAdminAuditLog`, `TelegramAdminAuditLogTile`
- `TelegramModerationDetailCard`
- `TelegramAdminAuditFilter`, `TelegramAdminAuditFilterBar`
- `TelegramModerationDetailDrawer`
- `TelegramBannedMember`, `TelegramBannedMemberTile`
- `TelegramBulkBanActionBar`
- `TelegramSearchResult`, `TelegramSearchResultTile`
- `TelegramSearchEmptyState`, `TelegramRecentSearchesBar`
- `TelegramSearchScope`, `TelegramSearchScopesBar`
- `TelegramSearchSuggestionTile`
- `TelegramSearchFilterOption`, `TelegramSearchFiltersSheet`
- `TelegramActiveSearchFiltersBar`
- `TelegramSearchResultGroup`, `TelegramSearchGroupHeader`
- `TelegramStickySearchGroupHeader`, `TelegramHighlightedText`
- `TelegramSearchSortOption`, `TelegramSearchSortBar`
- `TelegramSearchResultStatsBar`, `TelegramSearchHistorySheet`
- `TelegramSavedSearch`, `TelegramSavedSearchesBar`, `TelegramSavedSearchCard`
- `TelegramSearchAlert`, `TelegramSearchAlertTile`, `TelegramSearchAlertsSheet`
- `TelegramSearchCommand`, `TelegramSearchCommandTile`, `TelegramSearchCommandsSheet`
- `TelegramSearchDateRange`, `TelegramSearchDateRangesBar`, `TelegramSearchDateRangesSheet`
- `TelegramSearchOperator`, `TelegramSearchOperatorsBar`, `TelegramSearchOperatorsSheet`
- `TelegramSearchQueryToken`, `TelegramSearchQueryTokensBar`, `TelegramSearchQueryInspectorCard`
- `TelegramSearchResultAction`, `TelegramSearchResultActionBar`, `TelegramSearchSelectionSummaryCard`
- `TelegramSearchExecution`, `TelegramSearchExecutionTile`, `TelegramSearchExecutionStatusCard`, `TelegramSearchExecutionsSheet`
- `TelegramSearchBar`, `TelegramStoriesStrip`, `TelegramStoryAvatar`
- `TelegramChatFoldersBar`
- `TelegramContactListTile`, `TelegramCallListTile`, `TelegramProfileHeader`
- `TelegramMediaGrid`
- `TelegramActionSheet`, `TelegramToast`, `TelegramComposeFab`
- `TelegramSettingsCell`, `TelegramSettingsGroup`, `TelegramSectionHeader`
- `TelegramSettingsCollapsibleSection`, `TelegramSettingsSectionFooter`
- `TelegramSettingsOption`, `TelegramSettingsOptionTile`, `TelegramSettingsOptionsSheet`
- `TelegramSettingsAccountCard`
- `TelegramSettingsConnectedApp`, `TelegramSettingsConnectedAppsCard`
- `TelegramSettingsAutoDownloadPreset`, `TelegramSettingsAutoDownloadCard`
- `TelegramSettingsCleanupSuggestion`, `TelegramSettingsCleanupSuggestionsCard`
- `TelegramSettingsDataUsageItem`, `TelegramSettingsDataUsageCard`
- `TelegramSettingsNetworkPolicy`, `TelegramSettingsNetworkPoliciesCard`
- `TelegramSettingsPrivacyException`, `TelegramSettingsPrivacyExceptionsCard`
- `TelegramSettingsQuickAction`, `TelegramSettingsQuickActionsBar`
- `TelegramSettingsQuietHoursPreset`, `TelegramSettingsQuietHoursCard`
- `TelegramSettingsSecurityAction`, `TelegramSettingsTwoStepCard`
- `TelegramSettingsSecurityEvent`, `TelegramSettingsSecurityEventsCard`
- `TelegramSettingsSession`, `TelegramSettingsSessionsCard`
- `TelegramSettingsUsageSegment`, `TelegramSettingsUsageCard`
- `TelegramSettingsSyncStatusItem`, `TelegramSettingsSyncStatusCard`
- `TelegramSettingsShortcut`, `TelegramSettingsShortcutTile`, `TelegramSettingsShortcutsGrid`
- `TelegramSegmentedControl`
- `TelegramNavigationBar`, `TelegramBottomTabBar`
- `TelegramMiniAppButton`
- Telegram color map helpers: `TelegramColors.fromTelegramTheme()`, `toTelegramThemeMap()`

## Installation

```yaml
dependencies:
  telegram_ios_ui_kit: ^2.26.0
```

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:telegram_ios_ui_kit/telegram_ios_ui_kit.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final telegramTheme = TelegramThemeData.light();
    return TelegramTheme(
      data: telegramTheme,
      child: MaterialApp(
        theme: telegramTheme.toThemeData(),
        home: const Scaffold(
          body: Center(child: Text('Hello Telegram UI Kit')),
        ),
      ),
    );
  }
}
```

## Example

Run the bundled example app:

```bash
cd example
flutter pub get
flutter run
```

The example contains multi-tab Telegram-style pages:

- Contacts
- Calls
- Chats (stories + conversation screen)
- UI Kit (swipe actions / context menu / notice banners / large titles)
- Mini Apps
- Settings

And includes advanced demos for:

- Chat folders
- Unread separators
- Reactions and quick replies
- Attachment panel / inline keyboard / reply preview
- Poll card and file message tile
- Voice message tile / reference card / action toolbar
- Link preview / location card / contact card
- Chat background / media album / schedule timeline
- Wallpaper config / long-press selection wrapper
- Read receipts strip / sticky date header
- Expandable message input bar
- Service message bubble / jump-to-bottom button
- Channel profile header / stats grid
- Admin member list / permissions panel / moderation queue
- Admin audit logs / moderation detail / banned members
- Audit filter bar / moderation drawer / bulk ban action bar
- Search result tiles / empty state / recent search chips
- Search scope chips / quick suggestions
- Search filters sheet / active filters bar
- Search keyword highlighting / grouped sticky search headers
- Search sort chips / result stats / history manager sheet
- Saved search presets / one-tap search state restore cards
- Search alert rules / alert management bottom sheet
- Search actions sheet for one-tap command workflows
- Search date range chips / date range sheet filtering
- Search operator chips / operator sheet / token-driven filtering
- Query token chips / query inspector metadata card
- Search result selection mode / bulk action bar
- Search execution status card / execution history sheet / retry replay flow
- Action sheets and toasts
- Grouped settings sections
- Collapsible settings sections / section helper footers
- Settings option picker sheets
- Settings account card / profile quick action bar
- Settings auto-download preset card
- Settings storage cleanup suggestions card
- Settings quiet-hours schedule card
- Settings connected apps card / revoke actions
- Settings data usage card / reset stats action
- Settings network policies card / switch controls
- Settings sync status card / manual sync action
- Settings privacy exceptions card / override badges
- Settings two-step verification card / security action list
- Settings security events card / risk summary badge
- Settings active sessions card / session status badges
- Settings storage usage card / usage segment legends
- Settings quick access shortcuts grid

## Publishing

For maintainers:

```bash
flutter pub publish --dry-run
flutter pub publish
```
