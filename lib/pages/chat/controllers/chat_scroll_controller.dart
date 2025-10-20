import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:matrix/matrix.dart';
import '../../../config/themes.dart';

class ChatScrollController {
  final AutoScrollController controller = AutoScrollController();
  final Timeline? timeline;
  final void Function(bool) onScrolledUpChanged;
  final void Function() onRequestFuture;
  
  bool _scrolledUp = false;
  bool get scrolledUp => _scrolledUp;
  
  ChatScrollController({
    required this.timeline,
    required this.onScrolledUpChanged,
    required this.onRequestFuture,
  }) {
    controller.addListener(_onScroll);
  }
  
  void _onScroll() {
    if (!controller.hasClients) return;
    
    final atBottom = controller.position.pixels <= 0;
    final shouldBeScrolledUp = !atBottom || timeline?.allowNewEvent == false;
    
    if (shouldBeScrolledUp != _scrolledUp) {
      _scrolledUp = shouldBeScrolledUp;
      onScrolledUpChanged(_scrolledUp);
    }
    
    if (atBottom || controller.position.pixels == 64) {
      onRequestFuture();
    }
  }
  
  Future<void> scrollToIndex(int index) async {
    await controller.scrollToIndex(
      index,
      duration: QuikxChatThemes.animationDuration,
      preferPosition: AutoScrollPosition.middle,
    );
  }
  
  void jumpToBottom() {
    controller.jumpTo(0);
  }
  
  void dispose() {
    controller.dispose();
  }
}
