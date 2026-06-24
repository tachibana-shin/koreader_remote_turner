import 'package:flutter/material.dart';
import 'package:kaeru/kaeru.dart';
import 'package:kaeru_ui/kaeru_ui.dart';
import '../l10n/app_localizations.dart';
import '../models/server_state.dart';
import '../services/websocket_server.dart';
import '../widgets/connection_status.dart';

class HomePage extends KaeruWidget<HomePage> {
  final ServerState serverState;
  final WebSocketServer wsServer;
  final String forwardLabel;
  final String backwardLabel;

  const HomePage({
    super.key,
    required this.serverState,
    required this.wsServer,
    required this.forwardLabel,
    required this.backwardLabel,
  });

  @override
  Setup setup() {
    final ctx = useContext();
    final scrollController = useScrollController();

    useListen(serverState.logger.entries, () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    });

    return () {
      final t = AppLocalizations.of(ctx)!;
      final s = serverState;
      final entries = s.logger.entries.value;
      final connected = s.connectionState.value == ServerConnectionState.connected;

      return [
        IntrinsicHeight(
          child: [
            [
              ConnectionStatusIndicator(
                state: s.connectionState,
                deviceName: s.deviceName,
              ),
              8.vSpace,
              (s.serverRunning.value
                      ? t.serverInfo(s.serverAddress.value, s.serverPort.value)
                      : t.serverInfo('unknown', s.serverPort.value))
                  .text.gray(600).make(),
              16.vSpace,
              FilledButton.tonalIcon(
                onPressed: s.serverRunning.value
                    ? () => wsServer.stop()
                    : () => wsServer.start(),
                icon: Icon(
                  s.serverRunning.value ? Icons.stop : Icons.play_arrow,
                ),
                label: (s.serverRunning.value ? t.serverStop : t.serverStart).text.make(),
              ).width(double.infinity),
            ].column(crossAxisAlignment: CrossAxisAlignment.start).p(16).card().expand(),
            12.hSpace,
            [
              t.totalEvents(
                (s.totalForwardEvents.value + s.totalBackwardEvents.value).toString(),
              ).text.titleMedium.make(),
              4.vSpace,
              t.avgSpeed(s.avgSpeed.value.toStringAsFixed(1)).text.gray(600).make(),
            ].column(crossAxisAlignment: CrossAxisAlignment.start).p(16).card().expand(),
          ].row(crossAxisAlignment: CrossAxisAlignment.stretch),
        ),
        16.vSpace,
        entries.isEmpty
            ? t.logEmpty.text.gray(500).make().centered.p(24).card()
            : ListView.builder(
                controller: scrollController,
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final isGood = entry.status == 'success' || entry.status == 'sent';
                  return ListTile(
                    dense: true,
                    leading: (isGood ? Icons.check_circle : Icons.error).toIcon(
                      color: isGood ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    title: entry.event.text.size(12).make(),
                    subtitle: entry.detail?.text.size(10).gray(500).make(),
                    trailing:
                        '${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}:${entry.time.second.toString().padLeft(2, '0')}'
                            .text.size(10).gray(400).make(),
                  );
                },
              ).height(200).pt(8).card(),
        16.vSpace,
        [
          FilledButton.tonalIcon(
            onPressed: connected ? () => wsServer.sendAction('prev_page') : null,
            icon: const Icon(Icons.skip_previous),
            label: t.eventBackward.text.make(),
          ).expand(),
          12.hSpace,
          FilledButton.tonalIcon(
            onPressed: connected ? () => wsServer.sendAction('next_page') : null,
            icon: const Icon(Icons.skip_next),
            label: t.eventForward.text.make(),
          ).expand(),
        ].row(),
        8.vSpace,
        FilledButton.tonalIcon(
          onPressed: connected ? () => wsServer.sendAction('sleep') : null,
          icon: const Icon(Icons.power_settings_new),
          label: t.eventSleep.text.make(),
        ).width(double.infinity),
        16.vSpace,
        [
          Icons.info_outline.toIcon(color: Colors.amber[800]),
          8.hSpace,
          t.xiaomiNote.text.size(12).color(Colors.amber[900]!).make().expand(),
        ].row().p(12).box
          .bg(Colors.amber[50]!)
          .rounded(8)
          .border(color: Colors.amber[200]!)
          .make(),
      ].column(crossAxisAlignment: CrossAxisAlignment.stretch).p(16).scrollable();
    };
  }
}
