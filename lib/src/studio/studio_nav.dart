const studioNavStyles = '''
.studio-nav { margin-bottom: 1rem; }
.studio-back {
  color: #8b95b0; text-decoration: none; font-size: 0.9rem;
  display: inline-flex; align-items: center; gap: 0.35rem;
}
.studio-back:hover { color: #f0f4ff; }
''';

const studioBackNavHtml = '''
<nav class="studio-nav">
  <a href="/" class="studio-back">← Back to hub</a>
</nav>
''';

/// Shared project-path sync for hub and sub-pages.
const studioProjectScript = r'''
<script>
(function () {
  const STORAGE_KEY = "rtk_studio_project_path";

  window.rtkSaveProject = function (path) {
    if (path) localStorage.setItem(STORAGE_KEY, path);
  };
  window.rtkLoadProject = function () {
    return localStorage.getItem(STORAGE_KEY) || "";
  };
  window.rtkSyncProjectInput = async function () {
    const input = document.getElementById("projectPath");
    if (!input) return rtkLoadProject();
    const boot = await fetch("/api/bootstrap").then((r) => r.json()).catch(() => ({}));
    const path = boot.project_path || rtkLoadProject();
    if (path) {
      input.value = path;
      rtkSaveProject(path);
    }
    return path;
  };
  window.rtkRequireProject = function () {
    const input = document.getElementById("projectPath");
    const path = (input && input.value.trim()) || rtkLoadProject();
    if (!path) {
      alert("Select a Flutter project first (hub → Load project).");
      return null;
    }
    return path;
  };
})();
</script>
''';

String wrapStudioPage(String innerHtml) {
  if (innerHtml.contains('studio-nav')) {
    return innerHtml;
  }
  var html = innerHtml;
  if (!html.contains('studio-back')) {
    html = html.replaceFirst('<body>', '<body>$studioBackNavHtml');
  }
  if (!html.contains('.studio-nav')) {
    html = html.replaceFirst('</style>', '$studioNavStyles</style>');
  }
  if (!html.contains('rtkSaveProject')) {
    html = html.replaceFirst('</body>', '$studioProjectScript</body>');
  }
  return html;
}
