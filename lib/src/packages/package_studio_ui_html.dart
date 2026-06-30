/// Package Studio single-page UI for pub.dev search and install.
String packageStudioHtml() => r'''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Package Studio</title>
  <style>
    :root {
      --bg: #0b0f1a; --surface: rgba(255,255,255,0.06); --border: rgba(255,255,255,0.12);
      --text: #f0f4ff; --muted: #8b95b0; --accent: #6c5ce7; --teal: #4ecdc4;
      --success: #2ecc71; --danger: #ff6b6b; --warn: #ffb26b;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: var(--bg); color: var(--text); min-height: 100vh;
      background-image:
        radial-gradient(ellipse 70% 50% at 15% -5%, rgba(108,92,231,0.3), transparent),
        radial-gradient(ellipse 50% 40% at 90% 5%, rgba(78,205,196,0.15), transparent);
    }
    .wrap { max-width: 980px; margin: 0 auto; padding: 2rem 1.25rem 3rem; }
    h1 { font-size: 1.85rem; margin-bottom: 0.35rem; }
    .subtitle { color: var(--muted); margin-bottom: 1.5rem; line-height: 1.5; }
    .panel {
      background: var(--surface); border: 1px solid var(--border);
      border-radius: 14px; padding: 1.25rem; margin-bottom: 1rem;
    }
    .panel h2 {
      font-size: 0.78rem; text-transform: uppercase; letter-spacing: 0.08em;
      color: var(--muted); margin-bottom: 0.75rem;
    }
    label { display: block; font-size: 0.8rem; color: var(--muted); margin-bottom: 0.35rem; }
    input, select {
      width: 100%; background: rgba(0,0,0,0.35); border: 1px solid var(--border);
      color: var(--text); padding: 0.65rem 0.85rem; border-radius: 10px; font-size: 0.92rem;
    }
    input:focus, select:focus { outline: none; border-color: var(--accent); }
    button {
      font-family: inherit; font-weight: 600; border: none; border-radius: 10px;
      padding: 0.7rem 1.1rem; cursor: pointer;
      background: linear-gradient(135deg, var(--accent), #a29bfe); color: #fff;
    }
    button.secondary { background: rgba(255,255,255,0.08); border: 1px solid var(--border); color: var(--text); }
    button:disabled { opacity: 0.4; cursor: not-allowed; }
    .row { display: flex; gap: 0.75rem; flex-wrap: wrap; align-items: flex-end; margin-top: 0.5rem; }
    .field { flex: 1; min-width: 200px; }
    .hidden { display: none !important; }
    .banner {
      padding: 0.75rem 1rem; border-radius: 10px; margin-bottom: 1rem; font-size: 0.88rem;
      background: rgba(255,178,107,0.12); border: 1px solid rgba(255,178,107,0.35); color: #ffe0c0;
    }
    .banner.error { background: rgba(255,107,107,0.12); border-color: rgba(255,107,107,0.35); color: #ffd0d0; }
    .banner.success { background: rgba(46,204,113,0.12); border-color: rgba(46,204,113,0.35); color: #c8f7dc; }
    .project-bar {
      font-size: 0.85rem; color: var(--muted); margin-bottom: 1rem;
      padding: 0.65rem 0.85rem; border-radius: 10px;
      background: rgba(0,0,0,0.25); border: 1px solid var(--border);
    }
    .project-bar strong { color: var(--teal); }
    .results { list-style: none; max-height: 320px; overflow-y: auto; }
    .result-item {
      padding: 0.75rem 0.85rem; border-radius: 10px; margin-bottom: 0.5rem;
      background: rgba(0,0,0,0.25); border: 1px solid var(--border); cursor: pointer;
      transition: border-color 0.15s;
    }
    .result-item:hover, .result-item.selected { border-color: var(--accent); }
    .result-item h3 { font-size: 0.95rem; margin-bottom: 0.25rem; }
    .result-item p { font-size: 0.82rem; color: var(--muted); line-height: 1.4; }
    .result-meta { font-size: 0.75rem; color: var(--muted); margin-top: 0.35rem; }
    .detail-grid { display: grid; gap: 0.65rem; font-size: 0.88rem; }
    .detail-grid dt { color: var(--muted); font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.06em; }
    .detail-grid dd { margin-bottom: 0.5rem; word-break: break-word; }
    .detail-grid a { color: var(--teal); }
    .toggle-row { display: flex; gap: 1rem; flex-wrap: wrap; margin: 0.75rem 0; font-size: 0.88rem; }
    .toggle-row label { display: flex; align-items: center; gap: 0.4rem; margin: 0; color: var(--text); cursor: pointer; }
    .toggle-row input { width: auto; }
    .log-box {
      background: #05070f; border: 1px solid var(--border); border-radius: 10px;
      padding: 0.85rem; font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
      font-size: 0.78rem; line-height: 1.45; max-height: 240px; overflow-y: auto;
      white-space: pre-wrap; word-break: break-word; color: #c8d0e0;
    }
    .badge-installed {
      display: inline-block; font-size: 0.72rem; font-weight: 600;
      padding: 0.2rem 0.55rem; border-radius: 999px;
      background: rgba(46,204,113,0.15); color: var(--success);
      border: 1px solid rgba(46,204,113,0.35); margin-left: 0.5rem;
    }
    .empty { color: var(--muted); font-size: 0.88rem; padding: 0.5rem 0; }
    .checks { list-style: none; font-size: 0.85rem; margin-top: 0.75rem; }
    .checks li { padding: 0.35rem 0; color: var(--muted); }
    .checks li.ok { color: var(--success); }
    .checks li.fail { color: var(--danger); }
    .source-tabs { display: flex; gap: 0.5rem; margin-bottom: 1rem; flex-wrap: wrap; }
    .source-tab {
      padding: 0.45rem 0.9rem; border-radius: 999px; font-size: 0.82rem; font-weight: 600;
      border: 1px solid var(--border); background: rgba(0,0,0,0.2); color: var(--muted); cursor: pointer;
    }
    .source-tab.active { border-color: var(--accent); color: #fff; background: rgba(108,92,231,0.25); }
  </style>
</head>
<body>
  <div class="wrap">
    <h1>Package Studio</h1>
    <p class="subtitle">Search pub.dev, paste a package link, or install from GitHub — with validation before install.</p>

    <div class="source-tabs">
      <button type="button" class="source-tab active" data-source="pub">pub.dev</button>
      <button type="button" class="source-tab" data-source="git">GitHub / Git</button>
    </div>

    <div id="projectBar" class="project-bar">Loading project…</div>
    <div id="banner" class="banner hidden"></div>

    <div id="pubPanels">
    <div class="panel">
      <h2>Paste link or package name</h2>
      <label for="pasteInput">pub.dev URL, name, or name:version</label>
      <div class="row">
        <div class="field">
          <input id="pasteInput" type="text" placeholder="https://pub.dev/packages/http or http" />
        </div>
        <button type="button" id="resolveBtn" class="secondary">Resolve</button>
      </div>
    </div>

    <div class="panel">
      <h2>Search pub.dev</h2>
      <label for="searchInput">Search query</label>
      <input id="searchInput" type="text" placeholder="state management, dio, riverpod…" />
      <ul id="searchResults" class="results" style="margin-top:0.85rem"></ul>
      <p id="searchEmpty" class="empty hidden">No results yet — type to search.</p>
    </div>
    </div>

    <div id="gitPanels" class="hidden">
    <div class="panel">
      <h2>Install from GitHub</h2>
      <p style="font-size:0.85rem;color:var(--muted);margin-bottom:0.85rem;line-height:1.45">
        Paste a GitHub URL. The package is shallow-cloned and checked (pubspec, lib/, pub get) before install.
      </p>
      <label for="gitUrl">Git repository URL</label>
      <input id="gitUrl" type="text" placeholder="https://github.com/org/my_package" style="margin-bottom:0.75rem" />
      <div class="row">
        <div class="field">
          <label for="gitRef">Branch / tag / ref</label>
          <input id="gitRef" type="text" value="main" placeholder="main" />
        </div>
        <div class="field">
          <label for="gitPath">Path in repo (monorepo)</label>
          <input id="gitPath" type="text" placeholder="packages/my_pkg (optional)" />
        </div>
      </div>
      <label for="gitPackageName" style="margin-top:0.75rem">Dependency name in pubspec.yaml</label>
      <input id="gitPackageName" type="text" placeholder="my_package" style="margin-bottom:0.75rem" />
      <div class="toggle-row">
        <label><input type="radio" name="gitDepKind" value="regular" checked /> Regular dependency</label>
        <label><input type="radio" name="gitDepKind" value="dev" /> Dev dependency</label>
      </div>
      <div class="row">
        <button type="button" id="validateGitBtn" class="secondary">Validate package</button>
        <button type="button" id="installGitBtn" disabled>Install from Git</button>
      </div>
      <ul id="gitChecks" class="checks hidden"></ul>
    </div>
    </div>

    <div id="detailPanel" class="panel hidden">
      <h2>Package detail</h2>
      <div id="detailHeader"></div>
      <dl class="detail-grid" id="detailGrid"></dl>
      <label for="versionSelect">Version (optional — defaults to latest compatible)</label>
      <select id="versionSelect" style="margin-top:0.35rem;margin-bottom:0.75rem"></select>
      <div class="toggle-row">
        <label><input type="radio" name="depKind" value="regular" checked /> Regular dependency</label>
        <label><input type="radio" name="depKind" value="dev" /> Dev dependency</label>
      </div>
      <div class="row">
        <button type="button" id="installBtn">Install package</button>
        <a id="pubDevLink" href="#" target="_blank" rel="noopener" class="secondary" style="padding:0.7rem 1.1rem;text-decoration:none;border-radius:10px">View on pub.dev</a>
      </div>
    </div>

    <div id="logPanel" class="panel hidden">
      <h2>Install output</h2>
      <pre id="logBox" class="log-box"></pre>
    </div>
  </div>

  <script>
    let projectPath = "";
    let selectedPackage = null;
    let searchTimer = null;
    let activeSource = "pub";
    let gitValidated = false;
    let gitValidatedName = null;

    function setSource(source) {
      activeSource = source;
      document.querySelectorAll(".source-tab").forEach((tab) => {
        tab.classList.toggle("active", tab.dataset.source === source);
      });
      document.getElementById("pubPanels").classList.toggle("hidden", source !== "pub");
      document.getElementById("gitPanels").classList.toggle("hidden", source !== "git");
      document.getElementById("detailPanel").classList.toggle("hidden", source !== "pub" || !selectedPackage);
    }

    document.querySelectorAll(".source-tab").forEach((tab) => {
      tab.addEventListener("click", () => setSource(tab.dataset.source));
    });

    function showBanner(text, kind) {
      const el = document.getElementById("banner");
      el.textContent = text;
      el.className = "banner" + (kind ? " " + kind : "");
      el.classList.remove("hidden");
    }

    function hideBanner() {
      document.getElementById("banner").classList.add("hidden");
    }

    async function loadProject() {
      const boot = await fetch("/api/bootstrap").then((r) => r.json()).catch(() => ({}));
      projectPath = boot.project_path || (window.rtkLoadProject && rtkLoadProject()) || "";
      const bar = document.getElementById("projectBar");
      if (projectPath) {
        bar.innerHTML = "Target project: <strong>" + projectPath + "</strong>";
      } else {
        bar.innerHTML = "No project loaded — go to the <a href=\"/\" style=\"color:var(--teal)\">hub</a> and load a Flutter project first.";
        showBanner("Load a Flutter project from the hub before installing packages.", "error");
      }
    }

    function renderSearchResults(packages) {
      const list = document.getElementById("searchResults");
      const empty = document.getElementById("searchEmpty");
      list.innerHTML = "";
      if (!packages || packages.length === 0) {
        empty.classList.remove("hidden");
        empty.textContent = "No packages found.";
        return;
      }
      empty.classList.add("hidden");
      packages.forEach((pkg) => {
        const li = document.createElement("li");
        li.className = "result-item" + (selectedPackage === pkg.name ? " selected" : "");
        li.dataset.name = pkg.name;
        const meta = [];
        if (pkg.latest_version) meta.push("v" + pkg.latest_version);
        if (pkg.likes != null) meta.push("♥ " + pkg.likes);
        if (pkg.pub_points != null) meta.push(pkg.pub_points + " pts");
        li.innerHTML =
          "<h3>" + pkg.name + "</h3>" +
          (pkg.description ? "<p>" + pkg.description + "</p>" : "") +
          (meta.length ? "<div class=\"result-meta\">" + meta.join(" · ") + "</div>" : "");
        li.onclick = () => selectPackage(pkg.name);
        list.appendChild(li);
      });
    }

    async function runSearch(query) {
      if (!query.trim()) {
        document.getElementById("searchResults").innerHTML = "";
        document.getElementById("searchEmpty").classList.remove("hidden");
        document.getElementById("searchEmpty").textContent = "No results yet — type to search.";
        return;
      }
      try {
        const res = await fetch("/api/packages/search?q=" + encodeURIComponent(query.trim()));
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || "Search failed");
        renderSearchResults(data.packages || []);
      } catch (e) {
        showBanner(e.message, "error");
      }
    }

    async function selectPackage(name) {
      selectedPackage = name;
      document.querySelectorAll(".result-item").forEach((el) => {
        el.classList.toggle("selected", el.dataset.name === name);
      });
      await loadDetail(name);
    }

    async function loadDetail(name) {
      hideBanner();
      const qs = new URLSearchParams({ name });
      if (projectPath) qs.set("project", projectPath);
      const res = await fetch("/api/packages/detail?" + qs.toString());
      const data = await res.json();
      if (!res.ok) {
        showBanner(data.error || "Failed to load package", "error");
        return;
      }

      document.getElementById("detailPanel").classList.remove("hidden");
      const installed = data.already_installed
        ? "<span class=\"badge-installed\">Already installed</span>"
        : "";
      document.getElementById("detailHeader").innerHTML =
        "<h3 style=\"font-size:1.1rem;margin-bottom:0.5rem\">" + data.name + installed + "</h3>" +
        "<p style=\"color:var(--muted);font-size:0.88rem;line-height:1.45\">" + (data.description || "") + "</p>";

      const grid = document.getElementById("detailGrid");
      grid.innerHTML = "";
      function addRow(label, value, isLink) {
        if (!value) return;
        const dt = document.createElement("dt");
        dt.textContent = label;
        const dd = document.createElement("dd");
        if (isLink) {
          const a = document.createElement("a");
          a.href = value;
          a.target = "_blank";
          a.rel = "noopener";
          a.textContent = value;
          dd.appendChild(a);
        } else {
          dd.textContent = value;
        }
        grid.appendChild(dt);
        grid.appendChild(dd);
      }
      addRow("Latest", data.latest_version);
      if (data.likes != null) addRow("Likes", String(data.likes));
      if (data.pub_points != null) addRow("Pub points", String(data.pub_points));
      if (data.publisher) addRow("Publisher", data.publisher);
      addRow("Homepage", data.homepage, true);
      addRow("Repository", data.repository, true);
      if (data.is_discontinued) addRow("Status", "Discontinued" + (data.replaced_by ? " → " + data.replaced_by : ""));

      const versionSelect = document.getElementById("versionSelect");
      versionSelect.innerHTML = "<option value=\"\">Latest compatible (^constraint)</option>";
      (data.versions || []).forEach((v) => {
        const opt = document.createElement("option");
        opt.value = v;
        opt.textContent = v;
        versionSelect.appendChild(opt);
      });

      const pubLink = document.getElementById("pubDevLink");
      pubLink.href = data.url || ("https://pub.dev/packages/" + data.name);
    }

    async function resolveInput() {
      const input = document.getElementById("pasteInput").value.trim();
      if (!input) return alert("Enter a package name or pub.dev URL");
      try {
        const res = await fetch("/api/packages/resolve?input=" + encodeURIComponent(input));
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || "Could not resolve input");
        if (data.source === "git") {
          setSource("git");
          document.getElementById("gitUrl").value = data.git_url || "";
          document.getElementById("gitRef").value = data.git_ref || "main";
          document.getElementById("gitPath").value = data.git_path || "";
          document.getElementById("gitPackageName").value = data.suggested_name || "";
          gitValidated = false;
          document.getElementById("installGitBtn").disabled = true;
          document.getElementById("gitChecks").classList.add("hidden");
          return;
        }
        selectedPackage = data.name;
        if (data.version) {
          await loadDetail(data.name);
          document.getElementById("versionSelect").value = data.version;
        } else {
          await loadDetail(data.name);
        }
        document.getElementById("searchInput").value = data.name;
      } catch (e) {
        showBanner(e.message, "error");
      }
    }

    function renderGitChecks(checks) {
      const list = document.getElementById("gitChecks");
      list.innerHTML = "";
      (checks || []).forEach((check) => {
        const li = document.createElement("li");
        li.className = check.ok ? "ok" : "fail";
        li.textContent = (check.ok ? "✓ " : "✗ ") + check.message;
        list.appendChild(li);
      });
      list.classList.remove("hidden");
    }

    async function validateGitPackage() {
      const gitUrl = document.getElementById("gitUrl").value.trim();
      if (!gitUrl) return alert("Enter a Git repository URL");
      const btn = document.getElementById("validateGitBtn");
      btn.disabled = true;
      gitValidated = false;
      document.getElementById("installGitBtn").disabled = true;
      hideBanner();
      try {
        const res = await fetch("/api/packages/git/validate", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            git_url: gitUrl,
            git_ref: document.getElementById("gitRef").value.trim() || "main",
            git_path: document.getElementById("gitPath").value.trim(),
          }),
        });
        const data = await res.json();
        renderGitChecks(data.checks || []);
        if (!res.ok) throw new Error(data.error || "Validation request failed");
        if (data.valid) {
          gitValidated = true;
          gitValidatedName = data.package_name;
          if (data.package_name && !document.getElementById("gitPackageName").value.trim()) {
            document.getElementById("gitPackageName").value = data.package_name;
          }
          document.getElementById("installGitBtn").disabled = false;
          showBanner(
            "Package looks good" +
              (data.package_name ? " (" + data.package_name + ")" : "") +
              " — ready to install.",
            "success"
          );
        } else {
          showBanner(data.error || "Package validation failed — fix issues before installing.", "error");
        }
      } catch (e) {
        showBanner(e.message, "error");
      } finally {
        btn.disabled = false;
      }
    }

    async function installGitPackage() {
      if (!projectPath) {
        return alert("Load a Flutter project from the hub first.");
      }
      if (!gitValidated) {
        return alert("Validate the Git package first.");
      }
      const packageName = document.getElementById("gitPackageName").value.trim() ||
        gitValidatedName;
      if (!packageName) {
        return alert("Enter the dependency name for pubspec.yaml");
      }
      const btn = document.getElementById("installGitBtn");
      btn.disabled = true;
      hideBanner();
      try {
        const res = await fetch("/api/packages/install", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            source: "git",
            project: projectPath,
            name: packageName,
            git_url: document.getElementById("gitUrl").value.trim(),
            git_ref: document.getElementById("gitRef").value.trim() || "main",
            git_path: document.getElementById("gitPath").value.trim() || null,
            dev: document.querySelector('input[name="gitDepKind"]:checked').value === "dev",
          }),
        });
        const data = await res.json();
        document.getElementById("logPanel").classList.remove("hidden");
        document.getElementById("logBox").textContent =
          (data.command ? "$ " + data.command + "\n\n" : "") +
          (data.stdout || "") +
          (data.stderr ? "\n" + data.stderr : "");
        if (!res.ok) throw new Error(data.error || "Install failed");
        if (data.skipped) {
          showBanner(data.detail || "Package already in pubspec.yaml", "error");
        } else if (data.applied) {
          showBanner(data.detail || "Git package installed successfully", "success");
          gitValidated = false;
          btn.disabled = true;
        }
      } catch (e) {
        showBanner(e.message, "error");
        if (gitValidated) btn.disabled = false;
      }
    }

    async function installPackage() {
      if (!projectPath) {
        return alert("Load a Flutter project from the hub first.");
      }
      if (!selectedPackage) {
        return alert("Select or resolve a package first.");
      }
      const version = document.getElementById("versionSelect").value.trim() || null;
      const dev = document.querySelector('input[name="depKind"]:checked').value === "dev";
      const btn = document.getElementById("installBtn");
      btn.disabled = true;
      hideBanner();
      try {
        const res = await fetch("/api/packages/install", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            project: projectPath,
            name: selectedPackage,
            version: version,
            dev: dev,
          }),
        });
        const data = await res.json();
        document.getElementById("logPanel").classList.remove("hidden");
        const log = document.getElementById("logBox");
        log.textContent =
          (data.command ? "$ " + data.command + "\n\n" : "") +
          (data.stdout || "") +
          (data.stderr ? "\n" + data.stderr : "");
        if (!res.ok) throw new Error(data.error || "Install failed");
        if (data.skipped) {
          showBanner(data.detail || "Package already in pubspec.yaml", "error");
        } else if (data.applied) {
          showBanner(data.detail || "Package installed successfully", "success");
          await loadDetail(selectedPackage);
        }
      } catch (e) {
        showBanner(e.message, "error");
      } finally {
        btn.disabled = false;
      }
    }

    document.getElementById("resolveBtn").addEventListener("click", resolveInput);
    document.getElementById("pasteInput").addEventListener("keydown", (e) => {
      if (e.key === "Enter") resolveInput();
    });
    document.getElementById("installBtn").addEventListener("click", installPackage);
    document.getElementById("validateGitBtn").addEventListener("click", validateGitPackage);
    document.getElementById("installGitBtn").addEventListener("click", installGitPackage);
    ["gitUrl", "gitRef", "gitPath", "gitPackageName"].forEach((id) => {
      document.getElementById(id).addEventListener("input", () => {
        gitValidated = false;
        document.getElementById("installGitBtn").disabled = true;
        document.getElementById("gitChecks").classList.add("hidden");
      });
    });
    document.getElementById("searchInput").addEventListener("input", (e) => {
      clearTimeout(searchTimer);
      const q = e.target.value;
      searchTimer = setTimeout(() => runSearch(q), 300);
    });

    (async () => {
      if (window.rtkSyncProjectInput) await rtkSyncProjectInput();
      await loadProject();
    })().catch(console.error);
  </script>
</body>
</html>
''';
