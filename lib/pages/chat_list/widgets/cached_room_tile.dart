import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class CachedRoomTile extends StatefulWidget {
  final Room room;
  final Widget Function(Room) builder;
  
  const CachedRoomTile({
    super.key,
    required this.room,
    required this.builder,
  });
  
  @override
  State<CachedRoomTile> createState() => _CachedRoomTileState();
}

class _CachedRoomTileState extends State<CachedRoomTile> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.builder(widget.room);
  }
}
