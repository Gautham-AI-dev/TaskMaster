import 'package:url_launcher/url_launcher.dart';

/// Opens BookMyShow using its public web entry point. Android resolves the
/// URL to the installed app when its supported App Links are configured.
/// Otherwise the user's browser opens. No accessibility automation is used.
class BookMyShowLauncher {
  const BookMyShowLauncher();

  Future<bool> open() async {
    final uri = Uri.parse('https://in.bookmyshow.com/');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
