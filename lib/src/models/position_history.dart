import 'dart:collection';
import 'package:geolocator/geolocator.dart';

class PositionHistory {
  static const maxHistorySize = 1000;
  final Queue<Position> _positionHistory;

  PositionHistory() : _positionHistory = Queue<Position>();

  void add(Position position) {
    _positionHistory.addFirst(position);
    if (_positionHistory.length > maxHistorySize) {
      _positionHistory.removeLast();
    }
  }

  List<Position> get history => _positionHistory.toList();

  void clear() {
    _positionHistory.clear();
  }

  bool get isEmpty => _positionHistory.isEmpty;

  bool get isNotEmpty => _positionHistory.isNotEmpty;

  int get length => _positionHistory.length;

  Position? get last => _positionHistory.isNotEmpty ? _positionHistory.first : null;

  Position? get first => _positionHistory.isNotEmpty ? _positionHistory.last : null;
}
