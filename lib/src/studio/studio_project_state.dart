import 'dart:io';

/// Active Flutter project for the running Toolkit Studio session.
class StudioProjectState {
  StudioProjectState({Directory? initial});

  Directory? _root;

  Directory? get root => _root;

  String? get path => _root?.path;

  void setRoot(Directory root) {
    _root = root.absolute;
  }

  void clear() {
    _root = null;
  }

  void setInitial(Directory? dir) {
    if (dir != null) {
      _root = dir.absolute;
    }
  }
}
