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
  window.rtkPickProjectFolder = async function (inputId) {
    const input = document.getElementById(inputId || "projectPath");
    const saved = rtkLoadProject();
    const initial = (input && input.value ? input.value.trim() : "") || saved || "";
    if (typeof window.rtkNativePickFolder === "function") {
      const path = await window.rtkNativePickFolder(initial);
      if (path) {
        if (input) input.value = path;
        rtkSaveProject(path);
      }
      return path || null;
    }
    const qs = initial ? "?initial=" + encodeURIComponent(initial) : "";
    let res;
    try {
      res = await fetch("/api/pick-folder", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        credentials: "same-origin",
        body: JSON.stringify({ initial_path: initial || null }),
      });
    } catch (_) {
      res = await fetch("/api/pick-folder" + qs, {
        method: "GET",
        headers: { "Accept": "application/json" },
        credentials: "same-origin",
      });
    }
    const text = await res.text();
    let data = {};
    try { data = text ? JSON.parse(text) : {}; } catch (_) {}
    if (!res.ok) throw new Error(data.error || res.statusText || "Folder picker failed");
    if (data.cancelled) return null;
    if (data.path) {
      if (input) input.value = data.path;
      rtkSaveProject(data.path);
      return data.path;
    }
    return null;
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
  if (!html.contains('window.rtkSaveProject = function')) {
    html = html.replaceFirst('<body>', '<body>$studioProjectScript');
  }
  return html;
}
