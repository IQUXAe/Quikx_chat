import 'dart:async';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ChatListSearchController {
  final Client client;
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final void Function() onUpdate;
  
  bool isSearchMode = false;
  bool isSearching = false;
  String? searchServer;
  
  SearchUserDirectoryResponse? userSearchResult;
  QueryPublicRoomsResponse? roomSearchResult;
  
  Timer? _searchDebouncer;
  
  ChatListSearchController({
    required this.client,
    required this.onUpdate,
    this.searchServer,
  });
  
  void startSearch() {
    isSearchMode = true;
    focusNode.requestFocus();
    onUpdate();
    _debounceSearch();
  }
  
  void onSearchChanged(String text) {
    if (text.isEmpty) {
      cancelSearch(unfocus: false);
      return;
    }
    
    isSearchMode = true;
    onUpdate();
    _debounceSearch();
  }
  
  void _debounceSearch() {
    _searchDebouncer?.cancel();
    _searchDebouncer = Timer(const Duration(milliseconds: 300), _performSearch);
  }
  
  Future<void> _performSearch() async {
    if (!isSearchMode) return;
    
    isSearching = true;
    onUpdate();
    
    final searchQuery = textController.text.trim();
    
    try {
      final roomResult = await client.queryPublicRooms(
        server: searchServer,
        filter: PublicRoomQueryFilter(genericSearchTerm: searchQuery),
        limit: 20,
      );
      
      if (searchQuery.isValidMatrixId && searchQuery.sigil == '#') {
        if (!roomResult.chunk.any((r) => r.canonicalAlias == searchQuery)) {
          try {
            final response = await client.getRoomIdByAlias(searchQuery);
            if (response.roomId != null) {
              roomResult.chunk.add(PublicRoomsChunk(
                name: searchQuery,
                guestCanJoin: false,
                numJoinedMembers: 0,
                roomId: response.roomId!,
                worldReadable: false,
                canonicalAlias: searchQuery,
              ),);
            }
          } catch (_) {}
        }
      }
      
      final userResult = await client.searchUserDirectory(searchQuery, limit: 20);
      
      if (isSearchMode) {
        roomSearchResult = roomResult;
        userSearchResult = userResult;
      }
    } catch (e) {
      Logs().w('Search failed', e);
    } finally {
      isSearching = false;
      onUpdate();
    }
  }
  
  void cancelSearch({bool unfocus = true}) {
    textController.clear();
    isSearchMode = false;
    roomSearchResult = null;
    userSearchResult = null;
    isSearching = false;
    if (unfocus) focusNode.unfocus();
    onUpdate();
  }
  
  void dispose() {
    _searchDebouncer?.cancel();
    textController.dispose();
    focusNode.dispose();
  }
}
