import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FullScreenColorPage extends StatelessWidget {
  final String colorHex;
  final String colorName;

  const FullScreenColorPage({
    super.key,
    required this.colorHex,
    required this.colorName,
  });

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) => FullScreenColorContent(
        colorHex: colorHex,
        colorName: colorName,
      ),
    );
  }
}

class FullScreenColorContent extends StatefulWidget {
  final String colorHex;
  final String colorName;

  const FullScreenColorContent({
    super.key,
    required this.colorHex,
    required this.colorName,
  });

  @override
  State<FullScreenColorContent> createState() => _FullScreenColorContentState();
}

class _FullScreenColorContentState extends State<FullScreenColorContent> {
  final GlobalKey _closeKey = GlobalKey();
  final GlobalKey _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTutorial();
    });
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasShownTutorial =
        prefs.getBool('hasShownFullScreenTutorial') ?? false;

    if (!hasShownTutorial && mounted) {
      ShowCaseWidget.of(context).startShowCase([
        _contentKey,
        _closeKey,
      ]);
      await prefs.setBool('hasShownFullScreenTutorial', true);
    }
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Showcase(
          key: _contentKey,
          description:
              'Tap anywhere on the screen to close the full screen view',
          child: Container(
            color: _hexToColor(widget.colorHex),
            child: Stack(
              children: [
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Showcase(
                        key: _closeKey,
                        description: 'Tap to close',
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Text(
                        widget.colorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.fullscreen_exit,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Text(
                    widget.colorHex,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
