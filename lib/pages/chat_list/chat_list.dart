import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:app_links/app_links.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_shortcuts_new/flutter_shortcuts_new.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart' as sdk;
import 'package:matrix/matrix.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'package:simplemessenger/config/app_config.dart';
import 'package:simplemessenger/l10n/l10n.dart';
import 'package:simplemessenger/pages/chat_list/chat_list_view.dart';
import 'package:simplemessenger/utils/error_reporter.dart';
import 'package:simplemessenger/utils/localized_exception_extension.dart';
import 'package:simplemessenger/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:simplemessenger/utils/platform_infos.dart';
import 'package:simplemessenger/utils/show_scaffold_dialog.dart';
import 'package:simplemessenger/utils/show_update_snackbar.dart';
import 'package:simplemessenger/widgets/adaptive_dialogs/show_modal_action_popup.dart';
import 'package:simplemessenger/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'package:simplemessenger/widgets/adaptive_dialogs/show_text_input_dialog.dart';
import 'package:simplemessenger/widgets/avatar.dart';
import 'package:simplemessenger/widgets/future_loading_dialog.dart';
import 'package:simplemessenger/widgets/share_scaffold_dialog.dart';
import '../../../utils/account_bundles.dart';
import '../../config/setting_keys.dart';
import '../../utils/url_launcher.dart';
import '../../widgets/matrix.dart';
import '../bootstrap/bootstrap_dialog.dart';

import 'package:simplemessenger/utils/tor_stub.dart'
    if (dart.library.html) 'package:tor_detector_web/tor_detector_web.dart';

enum PopupMenuAction {
  settings,
  invite,
  newGroup,
  newSpace,
  setStatus,
  archive,
}

enum ActiveFilter {
  allChats,
  messages,
  groups,
  unread,
  spaces,
}

extension LocalizedActiveFilter on ActiveFilter {
  String toLocalizedString(BuildContext context) {
    switch (this) {
      case ActiveFilter.allChats:
        return L10n.of(context).all;
      case ActiveFilter.messages:
        return L10n.of(context).messages;
      case ActiveFilter.unread:
        return L10n.of(context).unread;
      case ActiveFilter.groups:
        return L10n.of(context).groups;
      case ActiveFilter.spaces:
        return L10n.of(context).spaces;
    }
  }
}

class ChatList extends StatefulWidget {
  static BuildContext? contextForVoip;
  final String? activeChat;
  final bool displayNavigationRail;

  const ChatList({
    super.key,
    required this.activeChat,
    this.displayNavigationRail = false,
  });

  @override
  ChatListController createState() => ChatListController();
}

class ChatListController extends State<ChatList>
    with TickerProviderStateMixin, RouteAware, WidgetsBindingObserver {
  StreamSubscription? _intentDataStreamSubscription;

  StreamSubscription? _intentFileStreamSubscription;

  StreamSubscription? _intentUriStreamSubscription;

  ActiveFilter activeFilter = AppConfig.separateChatTypes
      ? ActiveFilter.messages
      : ActiveFilter.allChats;

  String? _activeSpaceId;
  String? get activeSpaceId => _activeSpaceId;

  void setActiveSpace(String spaceId) async {
    await Matrix.of(context).client.getRoomById(spaceId)!.postLoad();

    setState(() {
      _activeSpaceId = spaceId;
    });
  }

  void clearActiveSpace() => setState(() {
        _activeSpaceId = null;
      });

  void onChatTap(Room room) async {
    if (room.membership == Membership.invite) {
      final joinResult = await showFutureLoadingDialog(
        context: context,
        future: () async {
          final waitForRoom = room.client.waitForRoomInSync(
            room.id,
            join: true,
          );
          await room.join();
          await waitForRoom;
        },
        exceptionContext: ExceptionContext.joinRoom,
      );
      if (joinResult.error != null) return;
    }

    if (room.membership == Membership.ban) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.of(context).youHaveBeenBannedFromThisChat),
        ),
      );
      return;
    }

    if (room.membership == Membership.leave) {
      context.go('/rooms/archive/${room.id}');
      return;
    }

    if (room.isSpace) {
      setActiveSpace(room.id);
      return;
    }

    context.go('/rooms/${room.id}');
  }

  bool Function(Room) getRoomFilterByActiveFilter(ActiveFilter activeFilter) {
    switch (activeFilter) {
      case ActiveFilter.allChats:
        return (room) => true;
      case ActiveFilter.messages:
        return (room) => !room.isSpace && room.isDirectChat;
      case ActiveFilter.groups:
        return (room) => !room.isSpace && !room.isDirectChat;
      case ActiveFilter.unread:
        return (room) => room.isUnreadOrInvited;
      case ActiveFilter.spaces:
        return (room) => room.isSpace;
    }
  }

  List<Room>? _cachedFilteredRooms;
  ActiveFilter? _lastFilter;
  int? _lastRoomsHash;
  
  List<Room> get filteredRooms {
    final rooms = Matrix.of(context).client.rooms;
    final currentHash = rooms.length.hashCode ^ rooms.map((r) => r.id).join().hashCode;
    
    if (_cachedFilteredRooms == null || 
        _lastFilter != activeFilter || 
        _lastRoomsHash != currentHash) {
      _cachedFilteredRooms = rooms
          .where(getRoomFilterByActiveFilter(activeFilter))
          .toList();
      _lastFilter = activeFilter;
      _lastRoomsHash = currentHash;
    }
    return _cachedFilteredRooms!;
  }
  
  void _invalidateRoomsCache() {
    _cachedFilteredRooms = null;
  }

  bool isSearchMode = false;
  Future<QueryPublicRoomsResponse>? publicRoomsResponse;
  String? searchServer;
  Timer? _coolDown;
  Timer? _searchDebouncer;
  SearchUserDirectoryResponse? userSearchResult;
  QueryPublicRoomsResponse? roomSearchResult;

  bool isSearching = false;
  static const String _serverStoreNamespace = 'im.fluffychat.search.server';

  void setServer() async {
    final newServer = await showTextInputDialog(
      useRootNavigator: false,
      title: L10n.of(context).changeTheHomeserver,
      context: context,
      okLabel: L10n.of(context).ok,
      cancelLabel: L10n.of(context).cancel,
      prefixText: 'https://',
      hintText: Matrix.of(context).client.homeserver?.host,
      initialText: searchServer,
      keyboardType: TextInputType.url,
      autocorrect: false,
      validator: (server) => server.contains('.') == true
          ? null
          : L10n.of(context).invalidServerName,
    );
    if (newServer == null) return;
    Matrix.of(context).store.setString(_serverStoreNamespace, newServer);
    setState(() {
      searchServer = newServer;
    });
    _coolDown?.cancel();
    _coolDown = Timer(const Duration(milliseconds: 500), _search);
  }

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  void _search() async {
    final client = Matrix.of(context).client;
    if (!isSearching) {
      setState(() {
        isSearching = true;
      });
    }
    SearchUserDirectoryResponse? userSearchResult;
    QueryPublicRoomsResponse? roomSearchResult;
    final searchQuery = searchController.text.trim();
    try {
      roomSearchResult = await client.queryPublicRooms(
        server: searchServer,
        filter: PublicRoomQueryFilter(genericSearchTerm: searchQuery),
        limit: 20,
      );

      if (searchQuery.isValidMatrixId &&
          searchQuery.sigil == '#' &&
          roomSearchResult.chunk
                  .any((room) => room.canonicalAlias == searchQuery) ==
              false) {
        final response = await client.getRoomIdByAlias(searchQuery);
        final roomId = response.roomId;
        if (roomId != null) {
          roomSearchResult.chunk.add(
            PublicRoomsChunk(
              name: searchQuery,
              guestCanJoin: false,
              numJoinedMembers: 0,
              roomId: roomId,
              worldReadable: false,
              canonicalAlias: searchQuery,
            ),
          );
        }
      }
      userSearchResult = await client.searchUserDirectory(
        searchController.text,
        limit: 20,
      );
    } catch (e, s) {
      Logs().w('Searching has crashed', e, s);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toLocalizedString(context),
          ),
        ),
      );
    }
    if (!isSearchMode) return;
    setState(() {
      isSearching = false;
      this.roomSearchResult = roomSearchResult;
      this.userSearchResult = userSearchResult;
    });
  }

  void onSearchEnter(String text, {bool globalSearch = true}) {
    if (text.isEmpty) {
      cancelSearch(unfocus: false);
      return;
    }

    setState(() {
      isSearchMode = true;
    });
    
    _searchDebouncer?.cancel();
    if (globalSearch) {
      _searchDebouncer = Timer(const Duration(milliseconds: 300), _search);
    }
  }

  void startSearch() {
    setState(() {
      isSearchMode = true;
    });
    searchFocusNode.requestFocus();
    _coolDown?.cancel();
    _coolDown = Timer(const Duration(milliseconds: 500), _search);
  }

  void cancelSearch({bool unfocus = true}) {
    setState(() {
      searchController.clear();
      isSearchMode = false;
      roomSearchResult = userSearchResult = null;
      isSearching = false;
    });
    if (unfocus) searchFocusNode.unfocus();
  }

  bool isTorBrowser = false;

  BoxConstraints? snappingSheetContainerSize;

  final ScrollController scrollController = ScrollController();
  final ValueNotifier<bool> scrolledToTop = ValueNotifier(true);

  final StreamController<Client> _clientStream = StreamController.broadcast();

  Stream<Client> get clientStream => _clientStream.stream;

  void addAccountAction() => context.go('/rooms/settings/account');

  void _onScroll() {
    final newScrolledToTop = scrollController.position.pixels <= 0;
    if (newScrolledToTop != scrolledToTop.value) {
      scrolledToTop.value = newScrolledToTop;
    }
  }

  void editSpace(BuildContext context, String spaceId) async {
    await Matrix.of(context).client.getRoomById(spaceId)!.postLoad();
    if (mounted) {
      context.push('/rooms/$spaceId/details');
    }
  }

  // Needs to match GroupsSpacesEntry for 'separate group' checking.
  List<Room> get spaces =>
      Matrix.of(context).client.rooms.where((r) => r.isSpace).toList();

  String? get activeChat => widget.activeChat;

  void _processIncomingSharedMedia(List<SharedMediaFile> files) {
    if (files.isEmpty) return;

    showScaffoldDialog(
      context: context,
      builder: (context) => ShareScaffoldDialog(
        items: files.map(
          (file) {
            if ({
              SharedMediaType.text,
              SharedMediaType.url,
            }.contains(file.type)) {
              return TextShareItem(file.path);
            }
            return FileShareItem(
              XFile(
                file.path.replaceFirst('file://', ''),
                mimeType: file.mimeType,
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  void _processIncomingUris(Uri? uri) async {
    if (uri == null) return;
    context.go('/rooms');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UrlLauncher(context, uri.toString()).openMatrixToUrl();
    });
  }

  void _initReceiveSharingIntent() {
    if (!PlatformInfos.isMobile) return;

    // For sharing images coming from outside the app while the app is in the memory
    _intentFileStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(_processIncomingSharedMedia, onError: print);

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then(_processIncomingSharedMedia);

    // For receiving shared Uris
    _intentUriStreamSubscription =
        AppLinks().uriLinkStream.listen(_processIncomingUris);

    if (PlatformInfos.isAndroid) {
      final shortcuts = FlutterShortcuts();
      shortcuts.initialize().then(
            (_) => shortcuts.listenAction((action) {
              if (!mounted) return;
              UrlLauncher(context, action).launchUrl();
            }),
          );
    }
  }

  @override
  void initState() {
    _initReceiveSharingIntent();
    WidgetsBinding.instance.addObserver(this);

    scrollController.addListener(_onScroll);
    _waitForFirstSync();
    _hackyWebRTCFixForWeb();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        searchServer =
            Matrix.of(context).store.getString(_serverStoreNamespace);
        Matrix.of(context).backgroundPush?.setupPush();
        UpdateNotifier.showUpdateSnackBar(context);
        
        // Восстанавливаем сохраненный статус при запуске
        final client = Matrix.of(context).client;
        final store = Matrix.of(context).store;
        if (client.isLogged() && AppConfig.showPresences) {
          try {
            final savedStatus = store.getString('user_status_msg');
            final savedPresence = PresenceType.values.firstWhere(
              (p) => p.name == store.getString('user_presence_type'),
              orElse: () => PresenceType.online,
            );
            await client.setPresence(
              client.userID!,
              savedPresence,
              statusMsg: savedStatus?.isEmpty == true ? null : savedStatus,
            );
          } catch (e) {
            Logs().w('Failed to restore presence', e);
          }
        }
      }

      // Workaround for system UI overlay style not applied on app start
      SystemChrome.setSystemUIOverlayStyle(
        Theme.of(context).appBarTheme.systemOverlayStyle!,
      );
    });

    _checkTorBrowser();

    ErrorReporter(context).consumeTemporaryErrorLogFile();

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _intentDataStreamSubscription?.cancel();
    _intentFileStreamSubscription?.cancel();
    _intentUriStreamSubscription?.cancel();
    _searchDebouncer?.cancel();
    scrollController.removeListener(_onScroll);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final client = Matrix.of(context).client;
    final store = Matrix.of(context).store;
    
    if (!client.isLogged() || !AppConfig.showPresences) return;
    
    // Получаем сохраненное статусное сообщение
    final savedStatusMsg = store.getString('user_status_msg');
    final statusMsg = savedStatusMsg?.isEmpty == true ? null : savedStatusMsg;
    
    switch (state) {
      case AppLifecycleState.resumed:
        client.setPresence(client.userID!, PresenceType.online, statusMsg: statusMsg).catchError((e) {
          Logs().w('Failed to set online presence', e);
        });
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        client.setPresence(client.userID!, PresenceType.unavailable, statusMsg: statusMsg).catchError((e) {
          Logs().w('Failed to set away presence', e);
        });
        break;
      case AppLifecycleState.detached:
        client.setPresence(client.userID!, PresenceType.offline, statusMsg: statusMsg).catchError((e) {
          Logs().w('Failed to set offline presence', e);
        });
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void chatContextAction(
    Room room,
    BuildContext posContext, [
    Room? space,
  ]) async {
    final overlay =
        Overlay.of(posContext).context.findRenderObject() as RenderBox;

    final button = posContext.findRenderObject() as RenderBox;

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(const Offset(0, -65), ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero) + const Offset(-50, 0),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final displayname =
        room.getLocalizedDisplayname(MatrixLocals(L10n.of(context)));

    final spacesWithPowerLevels = room.client.rooms
        .where(
          (space) =>
              space.isSpace &&
              space.canChangeStateEvent(EventTypes.SpaceChild) &&
              !space.spaceChildren.any((c) => c.roomId == room.id),
        )
        .toList();

    final action = await showMenu<ChatContextAction>(
      context: posContext,
      position: position,
      items: [
        PopupMenuItem(
          value: ChatContextAction.open,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 12.0,
            children: [
              Avatar(
                mxContent: room.avatar,
                name: displayname,
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 128),
                child: Text(
                  displayname,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        if (space != null)
          PopupMenuItem(
            value: ChatContextAction.goToSpace,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Avatar(
                  mxContent: space.avatar,
                  size: Avatar.defaultSize / 2,
                  name: space.getLocalizedDisplayname(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    L10n.of(context).goToSpace(space.getLocalizedDisplayname()),
                  ),
                ),
              ],
            ),
          ),
        if (room.membership == Membership.join) ...[
          PopupMenuItem(
            value: ChatContextAction.mute,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  room.pushRuleState == PushRuleState.notify
                      ? Icons.notifications_off_outlined
                      : Icons.notifications_off,
                ),
                const SizedBox(width: 12),
                Text(
                  room.pushRuleState == PushRuleState.notify
                      ? L10n.of(context).muteChat
                      : L10n.of(context).unmuteChat,
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: ChatContextAction.markUnread,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  room.markedUnread
                      ? Icons.mark_as_unread
                      : Icons.mark_as_unread_outlined,
                ),
                const SizedBox(width: 12),
                Text(
                  room.markedUnread
                      ? L10n.of(context).markAsRead
                      : L10n.of(context).markAsUnread,
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: ChatContextAction.favorite,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  room.isFavourite ? Icons.push_pin : Icons.push_pin_outlined,
                ),
                const SizedBox(width: 12),
                Text(
                  room.isFavourite
                      ? L10n.of(context).unpin
                      : L10n.of(context).pin,
                ),
              ],
            ),
          ),
          if (spacesWithPowerLevels.isNotEmpty)
            PopupMenuItem(
              value: ChatContextAction.addToSpace,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.group_work_outlined),
                  const SizedBox(width: 12),
                  Text(L10n.of(context).addToSpace),
                ],
              ),
            ),
        ],
        PopupMenuItem(
          value: ChatContextAction.leave,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_outlined,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 12),
              Text(
                room.membership == Membership.invite
                    ? L10n.of(context).delete
                    : L10n.of(context).leave,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        ),
        if (room.membership == Membership.invite)
          PopupMenuItem(
            value: ChatContextAction.block,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.block_outlined,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Text(
                  L10n.of(context).block,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    if (action == null) return;
    if (!mounted) return;

    switch (action) {
      case ChatContextAction.open:
        onChatTap(room);
        return;
      case ChatContextAction.goToSpace:
        setActiveSpace(space!.id);
        return;
      case ChatContextAction.favorite:
        await showFutureLoadingDialog(
          context: context,
          future: () => room.setFavourite(!room.isFavourite),
        );
        return;
      case ChatContextAction.markUnread:
        await showFutureLoadingDialog(
          context: context,
          future: () => room.markUnread(!room.markedUnread),
        );
        return;
      case ChatContextAction.mute:
        await showFutureLoadingDialog(
          context: context,
          future: () => room.setPushRuleState(
            room.pushRuleState == PushRuleState.notify
                ? PushRuleState.mentionsOnly
                : PushRuleState.notify,
          ),
        );
        return;
      case ChatContextAction.block:
        final inviteEvent = room.getState(
          EventTypes.RoomMember,
          room.client.userID!,
        );
        context.go(
          '/rooms/settings/security/ignorelist',
          extra: inviteEvent?.senderId,
        );
      case ChatContextAction.leave:
        final confirmed = await showOkCancelAlertDialog(
          context: context,
          title: L10n.of(context).areYouSure,
          message: L10n.of(context).archiveRoomDescription,
          okLabel: L10n.of(context).leave,
          cancelLabel: L10n.of(context).cancel,
          isDestructive: true,
        );
        if (confirmed == OkCancelResult.cancel) return;
        if (!mounted) return;

        await showFutureLoadingDialog(context: context, future: room.leave);

        return;
      case ChatContextAction.addToSpace:
        final space = await showModalActionPopup(
          context: context,
          title: L10n.of(context).space,
          actions: spacesWithPowerLevels
              .map(
                (space) => AdaptiveModalAction(
                  value: space,
                  label: space
                      .getLocalizedDisplayname(MatrixLocals(L10n.of(context))),
                ),
              )
              .toList(),
        );
        if (space == null) return;
        await showFutureLoadingDialog(
          context: context,
          future: () => space.setSpaceChild(room.id),
        );
    }
  }

  void dismissStatusList() async {
    final result = await showOkCancelAlertDialog(
      title: L10n.of(context).hidePresences,
      context: context,
    );
    if (result == OkCancelResult.ok) {
      await Matrix.of(context).store.setBool(SettingKeys.showPresences, false);
      AppConfig.showPresences = false;
      setState(() {});
    }
  }

  void setStatus() async {
    final client = Matrix.of(context).client;
    final store = Matrix.of(context).store;
    
    var currentStatus = store.getString('user_status_msg') ?? '';
    var currentPresence = PresenceType.values.firstWhere(
      (p) => p.name == store.getString('user_presence_type'),
      orElse: () => PresenceType.online,
    );
    
    try {
      final presence = await client.fetchCurrentPresence(client.userID!);
      currentStatus = presence.statusMsg ?? currentStatus;
      currentPresence = presence.presence ?? currentPresence;
    } catch (e) {
      Logs().w('Failed to get current status: $e');
    }
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _StatusDialog(
        currentStatus: currentStatus,
        currentPresence: currentPresence,
      ),
    );
    
    if (result == null || !mounted) return;
    
    final statusMsg = result['status'] as String?;
    final presenceType = result['presence'] as PresenceType;
    
    // Save to SharedPreferences
    await store.setString('user_status_msg', statusMsg ?? '');
    await store.setString('user_presence_type', presenceType.name);
    
    await showFutureLoadingDialog(
      context: context,
      future: () => client.setPresence(
        client.userID!,
        presenceType,
        statusMsg: statusMsg?.isEmpty == true ? null : statusMsg,
      ),
    );
  }

  bool waitForFirstSync = false;

  Future<void> _waitForFirstSync() async {
    final router = GoRouter.of(context);
    final client = Matrix.of(context).client;
    await client.roomsLoading;
    await client.accountDataLoading;
    await client.userDeviceKeysLoading;
    if (client.prevBatch == null) {
      await client.onSyncStatus.stream
          .firstWhere((status) => status.status == SyncStatus.finished);

      if (!mounted) return;
      setState(() {
        waitForFirstSync = true;
      });

      // Display first login bootstrap if enabled
      if (client.encryption?.keyManager.enabled == true) {
        if (await client.encryption?.keyManager.isCached() == false ||
            await client.encryption?.crossSigning.isCached() == false ||
            client.isUnknownSession && !mounted) {
          await BootstrapDialog(client: client).show(context);
        }
      }
    }
    if (!mounted) return;
    setState(() {
      waitForFirstSync = true;
    });

    if (client.userDeviceKeys[client.userID!]?.deviceKeys.values
            .any((device) => !device.verified && !device.blocked) ??
        false) {
      late final ScaffoldFeatureController controller;
      final theme = Theme.of(context);
      controller = ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 15),
          showCloseIcon: true,
          backgroundColor: theme.colorScheme.errorContainer,
          closeIconColor: theme.colorScheme.onErrorContainer,
          content: Text(
            L10n.of(context).oneOfYourDevicesIsNotVerified,
            style: TextStyle(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          action: SnackBarAction(
            onPressed: () {
              controller.close();
              router.go('/rooms/settings/devices');
            },
            textColor: theme.colorScheme.onErrorContainer,
            label: L10n.of(context).settings,
          ),
        ),
      );
    }
  }

  void setActiveFilter(ActiveFilter filter) {
    if (activeFilter != filter) {
      _invalidateRoomsCache();
      setState(() {
        activeFilter = filter;
      });
    }
  }

  void setActiveClient(Client client) {
    context.go('/rooms');
    setState(() {
      activeFilter = ActiveFilter.allChats;
      _activeSpaceId = null;
      Matrix.of(context).setActiveClient(client);
    });
    _clientStream.add(client);
  }

  void setActiveBundle(String bundle) {
    context.go('/rooms');
    setState(() {
      _activeSpaceId = null;
      Matrix.of(context).activeBundle = bundle;
      if (!Matrix.of(context)
          .currentBundle!
          .any((client) => client == Matrix.of(context).client)) {
        Matrix.of(context)
            .setActiveClient(Matrix.of(context).currentBundle!.first);
      }
    });
  }

  void editBundlesForAccount(String? userId, String? activeBundle) async {
    final l10n = L10n.of(context);
    final client = Matrix.of(context)
        .widget
        .clients[Matrix.of(context).getClientIndexByMatrixId(userId!)];
    final action = await showModalActionPopup<EditBundleAction>(
      context: context,
      title: L10n.of(context).editBundlesForAccount,
      cancelLabel: L10n.of(context).cancel,
      actions: [
        AdaptiveModalAction(
          value: EditBundleAction.addToBundle,
          label: L10n.of(context).addToBundle,
        ),
        if (activeBundle != client.userID)
          AdaptiveModalAction(
            value: EditBundleAction.removeFromBundle,
            label: L10n.of(context).removeFromBundle,
          ),
      ],
    );
    if (action == null) return;
    switch (action) {
      case EditBundleAction.addToBundle:
        final bundle = await showTextInputDialog(
          context: context,
          title: l10n.bundleName,
          hintText: l10n.bundleName,
        );
        if (bundle == null || bundle.isEmpty) return;
        await showFutureLoadingDialog(
          context: context,
          future: () => client.setAccountBundle(bundle),
        );
        break;
      case EditBundleAction.removeFromBundle:
        await showFutureLoadingDialog(
          context: context,
          future: () => client.removeFromAccountBundle(activeBundle!),
        );
    }
  }

  bool get displayBundles =>
      Matrix.of(context).hasComplexBundles &&
      Matrix.of(context).accountBundles.keys.length > 1;

  String? get secureActiveBundle {
    if (Matrix.of(context).activeBundle == null ||
        !Matrix.of(context)
            .accountBundles
            .keys
            .contains(Matrix.of(context).activeBundle)) {
      return Matrix.of(context).accountBundles.keys.first;
    }
    return Matrix.of(context).activeBundle;
  }

  void resetActiveBundle() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        Matrix.of(context).activeBundle = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) => ChatListView(this);

  void _hackyWebRTCFixForWeb() {
    ChatList.contextForVoip = context;
  }

  Future<void> _checkTorBrowser() async {
    if (!kIsWeb) return;
    final isTor = await TorBrowserDetector.isTorBrowser;
    isTorBrowser = isTor;
  }

  Future<void> dehydrate() => Matrix.of(context).dehydrateAction(context);
}

class _StatusDialog extends StatefulWidget {
  final String currentStatus;
  final PresenceType currentPresence;
  
  const _StatusDialog({
    required this.currentStatus,
    required this.currentPresence,
  });
  
  @override
  State<_StatusDialog> createState() => _StatusDialogState();
}

class _StatusDialogState extends State<_StatusDialog> {
  late TextEditingController _controller;
  late PresenceType _selectedPresence;
  
  final List<String> _quickStatuses = [
    '🏠 Working from home',
    '🏢 At the office', 
    '🍕 At lunch',
    '☕ Coffee break',
    '🚗 Commuting',
    '🎯 Focused',
    '📱 Available',
    '😴 Do not disturb',
  ];
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentStatus);
    _selectedPresence = widget.currentPresence;
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text(L10n.of(context).setStatus),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Presence',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<PresenceType>(
              segments: const [
                ButtonSegment(
                  value: PresenceType.online,
                  label: Text('🟢 Online'),
                ),
                ButtonSegment(
                  value: PresenceType.unavailable,
                  label: Text('🟡 Away'),
                ),
                ButtonSegment(
                  value: PresenceType.offline,
                  label: Text('⚫ Offline'),
                ),
              ],
              selected: {_selectedPresence},
              onSelectionChanged: (Set<PresenceType> selection) {
                setState(() {
                  _selectedPresence = selection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Status Message',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLength: 100,
              decoration: InputDecoration(
                hintText: L10n.of(context).statusExampleMessage,
                border: const OutlineInputBorder(),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Text(
              'Quick Status',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 4,
                ),
                itemCount: _quickStatuses.length,
                itemBuilder: (context, index) {
                  final status = _quickStatuses[index];
                  return OutlinedButton(
                    onPressed: () {
                      _controller.text = status;
                      setState(() {});
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(L10n.of(context).cancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop({
              'status': _controller.text.trim(),
              'presence': _selectedPresence,
            });
          },
          child: Text(L10n.of(context).ok),
        ),
      ],
    );
  }
}

enum EditBundleAction { addToBundle, removeFromBundle }

enum InviteActions {
  accept,
  decline,
  block,
}

enum ChatContextAction {
  open,
  goToSpace,
  favorite,
  markUnread,
  mute,
  leave,
  addToSpace,
  block,
}
