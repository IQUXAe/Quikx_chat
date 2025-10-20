import 'package:matrix/matrix.dart';
import '../chat_list.dart';

class ChatListFilterController {
  ActiveFilter _activeFilter;
  String? _activeSpaceId;
  
  List<Room>? _cachedRooms;
  ActiveFilter? _lastFilter;
  String? _lastSpaceId;
  int? _lastRoomsHash;
  
  ChatListFilterController(this._activeFilter);
  
  ActiveFilter get activeFilter => _activeFilter;
  String? get activeSpaceId => _activeSpaceId;
  
  void setFilter(ActiveFilter filter, void Function() onUpdate) {
    if (_activeFilter != filter) {
      _activeFilter = filter;
      _invalidateCache();
      onUpdate();
    }
  }
  
  void setActiveSpace(String spaceId, void Function() onUpdate) {
    _activeSpaceId = spaceId;
    _invalidateCache();
    onUpdate();
  }
  
  void clearActiveSpace(void Function() onUpdate) {
    _activeSpaceId = null;
    _invalidateCache();
    onUpdate();
  }
  
  List<Room> getFilteredRooms(List<Room> allRooms) {
    final currentHash = allRooms.length.hashCode ^ 
                       allRooms.map((r) => r.id).join().hashCode;
    
    if (_cachedRooms == null ||
        _lastFilter != _activeFilter ||
        _lastSpaceId != _activeSpaceId ||
        _lastRoomsHash != currentHash) {
      _cachedRooms = allRooms.where(_getRoomFilter()).toList();
      _lastFilter = _activeFilter;
      _lastSpaceId = _activeSpaceId;
      _lastRoomsHash = currentHash;
    }
    
    return _cachedRooms!;
  }
  
  bool Function(Room) _getRoomFilter() {
    switch (_activeFilter) {
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
  
  void _invalidateCache() {
    _cachedRooms = null;
  }
}
