import 'package:flutter/material.dart';
import 'package:kaeru/kaeru.dart';
import 'package:kaeru_ui/kaeru_ui.dart';
import '../l10n/app_localizations.dart';
import '../models/server_state.dart';

class LogsPage extends KaeruWidget<LogsPage> {
  final ServerState serverState;

  const LogsPage({super.key, required this.serverState});

  @override
  Setup setup() {
    final ctx = useContext();
    final scrollController = useScrollController();

    onMounted(() => _scrollToEnd(scrollController));

    useListen(serverState.logger.entries, () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToEnd(scrollController);
      });
    });

    return () {
      final t = AppLocalizations.of(ctx)!;
      final entries = serverState.logger.entries.value;

      return [
        t.logTitle.text.headlineSmall.make().p(16),
        entries.isEmpty
            ? t.logEmpty.text.make().centered
            : ListView.builder(
                controller: scrollController,
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final isSuccess =
                      entry.status == 'success' || entry.status == 'sent';
                  return ListTile(
                    dense: true,
                    leading: (isSuccess ? Icons.check_circle : Icons.error).toIcon(
                      color: isSuccess ? Colors.green : Colors.red,
                      size: 18,
                    ),
                    title: entry.event.text.size(13).make(),
                    subtitle: entry.detail?.text.size(11).gray(600).make(),
                    trailing:
                        '${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}:${entry.time.second.toString().padLeft(2, '0')}'
                            .text.size(11).gray(500).make(),
                  );
                },
              ).expand(),
      ].column(crossAxisAlignment: CrossAxisAlignment.start);
    };
  }

  void _scrollToEnd(ScrollController controller) {
    if (controller.hasClients) {
      controller.animateTo(
        controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }
}
