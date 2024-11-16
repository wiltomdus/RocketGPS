enum DeviceState { disconnected, connecting, connected, error }

extension DeviceStateExt on DeviceState {
  int toInt() {
    switch (this) {
      case DeviceState.disconnected:
        return 0;
      case DeviceState.connecting:
        return 1;
      case DeviceState.connected:
        return 2;
      case DeviceState.error:
        return 3;
    }
  }

  static DeviceState fromInt(int value) {
    switch (value) {
      case 0:
        return DeviceState.disconnected;
      case 1:
        return DeviceState.connecting;
      case 2:
        return DeviceState.connected;
      case 3:
        return DeviceState.error;
      default:
        return DeviceState.disconnected;
    }
  }
}
