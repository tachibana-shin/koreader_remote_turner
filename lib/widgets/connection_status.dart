import 'package:flutter/material.dart';
import 'package:kaeru/kaeru.dart';
import 'package:kaeru_ui/kaeru_ui.dart';
import '../l10n/app_localizations.dart';
import '../models/server_state.dart';

class ConnectionStatusIndicator extends KaeruWidget<ConnectionStatusIndicator> {
  final Ref<ServerConnectionState> state;
  final Ref<String> deviceName;

  const ConnectionStatusIndicator({
    super.key,
    required this.state,
    required this.deviceName,
  });

  @override
  Setup setup() {
    final ctx = useContext();

    return () {
      final connectionState = state.value;
      final name = deviceName.value;
      final t = AppLocalizations.of(ctx)!;

      Color dotColor;
      String statusText;

      switch (connectionState) {
        case ServerConnectionState.connected:
          dotColor = Colors.green;
          statusText = t.connectionStatusConnected(name);
        case ServerConnectionState.waiting:
          dotColor = Colors.orange;
          statusText = t.connectionStatusWaiting;
        case ServerConnectionState.off:
          dotColor = Colors.red;
          statusText = t.connectionStatusOff;
      }

      return [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        8.hSpace,
        Flexible(child: statusText.text.size(14).make()),
      ].row(mainAxisSize: MainAxisSize.min);
    };
  }
}
