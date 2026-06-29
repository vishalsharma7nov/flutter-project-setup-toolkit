/// How to authenticate when talking to a Git remote.
enum GitAuthMode {
  ssh('ssh'),
  httpsPublic('https'),
  httpsToken('https_token');

  const GitAuthMode(this.id);

  final String id;

  static GitAuthMode? parse(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final mode in GitAuthMode.values) {
      if (mode.id == value || mode.name == value) return mode;
    }
    return null;
  }
}
