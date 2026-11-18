import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../main.dart';
import '../services/daily_ad_service.dart';

/// Screen displayed after 20 app opens when the user hasn't yet watched
/// their single daily video ad for the day.
///
/// Prevents entry to the app until the user watches 1 video ad.
/// Explains why CPAL uses a 1-ad-per-day model instead of continuous ads.
class DailyAdGatePage extends StatefulWidget {
  const DailyAdGatePage({super.key});

  @override
  State<DailyAdGatePage> createState() => _DailyAdGatePageState();
}

class _DailyAdGatePageState extends State<DailyAdGatePage> {
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;
  bool _isLoadingAd = false;
  bool _rewardEarned = false;
  String? _adErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
  }

  void _loadRewardedAd() {
    if (_isLoadingAd) return;

    setState(() {
      _isLoadingAd = true;
      _adErrorMessage = null;
    });

    RewardedAd.load(
      adUnitId: DailyAdService.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('DailyAdGatePage: Rewarded ad loaded successfully');
          if (mounted) {
            setState(() {
              _rewardedAd = ad;
              _isRewardedAdReady = true;
              _isLoadingAd = false;
              _adErrorMessage = null;
            });
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('DailyAdGatePage: Failed to load rewarded ad: $error');
          if (mounted) {
            setState(() {
              _isRewardedAdReady = false;
              _isLoadingAd = false;
              _adErrorMessage =
                  'Failed to load video ad. Please check your internet connection.';
            });
          }
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd == null || !_isRewardedAdReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video ad is still loading. Please wait a moment...'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _rewardEarned = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (_rewardEarned) {
          _onAdRewardGranted();
        } else {
          // If the ad was dismissed early without earning the reward
          _loadRewardedAd();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Please watch the full video ad to unlock CPAL for the day.',
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('DailyAdGatePage: Failed to show rewarded ad: $error');
        ad.dispose();
        _loadRewardedAd();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to play ad. Please try again.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint(
            'DailyAdGatePage: Reward earned: ${reward.amount} ${reward.type}');
        _rewardEarned = true;
      },
    );
  }

  Future<void> _onAdRewardGranted() async {
    // Record today as unlocked
    await DailyAdService.instance.markDailyAdWatchedToday();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Daily access unlocked! Enjoy CPAL for the whole day without ads.',
        ),
        backgroundColor: Colors.deepPurple,
        duration: Duration(seconds: 3),
      ),
    );

    // Proceed into the main app
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ColorPalettePage()),
    );
  }

  Future<void> _handleBackPress() async {
    final exitApp = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit CPAL?'),
        content: const Text(
          'Watching one quick video ad unlocks CPAL for the entire day. '
          'Are you sure you want to exit the app?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Watch Ad'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit App'),
          ),
        ],
      ),
    );

    if (exitApp == true) {
      SystemNavigator.pop();
    }
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Daily Ad Access',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Exit App',
              onPressed: _handleBackPress,
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),

                // Hero Icon / Badge
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withAlpha(25),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.deepPurple, width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_filled_rounded,
                      size: 54,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                const Text(
                  'One-Time Daily Ad',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Subtitle Highlight Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.deepPurple.shade200),
                  ),
                  child: const Text(
                    '1 Ad = Use the app the whole day ad-free',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Main Explanation Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.deepPurple.shade700, size: 22),
                            const SizedBox(width: 8),
                            const Text(
                              'Why only 1 ad for the whole day?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Most apps constantly interrupt you with popups and banners every few minutes while you are searching colors, comparing palettes, or drawing on the canvas.\n\n'
                          'We believe in giving you a smooth, clean, and uninterrupted experience. Instead of annoying ads all day long, you only need to watch ONE quick video ad per day.\n\n'
                          'Once watched, you unlock full access to all features and color libraries for the entire day with zero interruptions!',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: Colors.black87,
                          ),
                        ),
                        const Divider(height: 24),
                        _buildFeatureItem(
                          Icons.check_circle_outline,
                          'One ad gives you access for the whole day',
                        ),
                        const SizedBox(height: 8),
                        _buildFeatureItem(
                          Icons.check_circle_outline,
                          'No more ads or popups while exploring or drawing',
                        ),
                        const SizedBox(height: 8),
                        _buildFeatureItem(
                          Icons.check_circle_outline,
                          'Full access to Asian, Opus, Wood, NCS & all palettes',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Error Message if failed to load
                if (_adErrorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _adErrorMessage!,
                            style: TextStyle(
                              color: Colors.red[800],
                              fontSize: 13,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadRewardedAd,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Video Ad Button (Like in About Page)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isRewardedAdReady ? _showRewardedAd : null,
                    icon: _isLoadingAd
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_circle_outline, size: 24),
                    label: Text(
                      _isLoadingAd
                          ? 'Loading Video Ad...'
                          : (_isRewardedAdReady
                              ? 'Watch Video Ad to Enter'
                              : 'Waiting for Ad...'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Clarification note that ad is NOT automatically started
                Text(
                  'Tap the button above when you are ready. The ad will not start automatically.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.green[700], size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
