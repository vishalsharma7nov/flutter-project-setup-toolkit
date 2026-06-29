import 'studio_branding.dart';

/// Hub landing page for [studioProductName].
String studioHubHtml() {
  return _studioHubHtmlTemplate.replaceAll(
    '__STUDIO_PRODUCT_NAME__',
    studioProductName,
  );
}

const _studioHubHtmlTemplate = r'''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>__STUDIO_PRODUCT_NAME__</title>
  <style>
    :root {
      --bg: #080c14; --surface: rgba(255,255,255,0.05); --border: rgba(255,255,255,0.1);
      --text: #f0f4ff; --muted: #8b95b0; --accent: #6c5ce7; --teal: #4ecdc4;
      --orange: #ff7b54; --success: #2ecc71; --warn: #ffb26b; --danger: #ff6b6b;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: var(--bg); color: var(--text); min-height: 100vh;
      background-image:
        radial-gradient(ellipse 70% 50% at 15% -5%, rgba(108,92,231,0.3), transparent),
        radial-gradient(ellipse 50% 40% at 90% 5%, rgba(78,205,196,0.15), transparent);
    }
    .wrap { max-width: 1000px; margin: 0 auto; padding: 2rem 1.25rem 3rem; }
    .badge {
      display: inline-block; font-size: 0.7rem; font-weight: 700; letter-spacing: 0.12em;
      text-transform: uppercase; color: var(--teal); border: 1px solid rgba(78,205,196,0.35);
      background: rgba(78,205,196,0.1); padding: 0.35rem 0.85rem; border-radius: 999px; margin-bottom: 0.85rem;
    }
    h1 {
      font-size: clamp(2rem, 4vw, 2.6rem); font-weight: 700; letter-spacing: -0.03em;
      background: linear-gradient(135deg, #fff 25%, #a29bfe 100%);
      -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text;
    }
    .subtitle { color: var(--muted); margin: 0.5rem 0 1.5rem; }
    .env-bar {
      display: flex; flex-wrap: wrap; gap: 0.75rem; align-items: center;
      background: var(--surface); border: 1px solid var(--border); border-radius: 12px;
      padding: 0.75rem 1rem; margin-bottom: 1rem; font-size: 0.82rem;
    }
    .pill { padding: 0.25rem 0.65rem; border-radius: 999px; border: 1px solid var(--border); }
    .pill.ok { color: var(--success); border-color: rgba(46,204,113,0.4); }
    .pill.bad { color: var(--danger); border-color: rgba(255,107,107,0.4); }
    .banner {
      display: none; padding: 0.85rem 1rem; border-radius: 10px; margin-bottom: 1rem; font-size: 0.88rem;
      background: rgba(255,178,107,0.12); border: 1px solid rgba(255,178,107,0.35); color: #ffe0c0;
    }
    .banner.visible { display: block; }
    .panel {
      background: var(--surface); border: 1px solid var(--border); border-radius: 16px;
      padding: 1.25rem; margin-bottom: 1.25rem;
    }
    label { display: block; font-size: 0.78rem; color: var(--muted); margin-bottom: 0.35rem; }
    .row { display: flex; gap: 0.75rem; flex-wrap: wrap; align-items: flex-end; }
    input {
      flex: 1; min-width: 200px; background: rgba(0,0,0,0.35); border: 1px solid var(--border);
      color: var(--text); padding: 0.75rem 1rem; border-radius: 10px; font-size: 0.92rem;
    }
    button {
      font-family: inherit; font-weight: 600; border: none; border-radius: 10px;
      padding: 0.75rem 1.2rem; cursor: pointer; background: var(--surface); color: var(--text);
      border: 1px solid var(--border);
    }
    button.primary { background: linear-gradient(135deg, var(--accent), #a29bfe); color: #fff; border: none; }
    button:disabled { opacity: 0.4; cursor: not-allowed; }
    .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 1rem; }
    .card {
      background: rgba(0,0,0,0.25); border: 1px solid var(--border); border-radius: 16px;
      padding: 1.5rem; text-decoration: none; color: inherit; transition: 0.15s;
      display: block; cursor: pointer;
    }
    .card:hover:not(.disabled) { transform: translateY(-2px); border-color: var(--accent); }
    .card.disabled { opacity: 0.45; pointer-events: none; cursor: not-allowed; }
    .card.recommended { border-color: var(--orange); box-shadow: 0 0 0 1px rgba(255,123,84,0.35); }
    .card-icon { font-size: 2rem; margin-bottom: 0.5rem; }
    .card h3 { margin-bottom: 0.35rem; }
    .card p { font-size: 0.85rem; color: var(--muted); line-height: 1.45; }
    .entry-paths { margin-bottom: 1.25rem; }
    .entry-paths h2 { font-size: 0.85rem; color: var(--muted); margin-bottom: 0.75rem; text-transform: uppercase; letter-spacing: 0.06em; }
    .entry-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 0.75rem; }
    .entry-card {
      background: rgba(0,0,0,0.2); border: 1px solid var(--border); border-radius: 12px;
      padding: 1rem; font-size: 0.85rem;
    }
    .entry-card strong { display: block; margin-bottom: 0.35rem; }
    .entry-card a { color: var(--teal); text-decoration: none; font-weight: 600; }
    .soon { margin-top: 1.5rem; }
    .soon h2 { font-size: 0.8rem; text-transform: uppercase; letter-spacing: 0.08em; color: var(--muted); margin-bottom: 0.75rem; }
    .soon-grid { display: flex; gap: 0.5rem; flex-wrap: wrap; }
    .soon-pill {
      font-size: 0.78rem; color: var(--muted); padding: 0.4rem 0.75rem; border-radius: 999px;
      border: 1px dashed var(--border); opacity: 0.7;
    }
  </style>
</head>
<body>
  <div class="wrap">
    <header style="text-align:center;margin-bottom:1.5rem">
      <div class="badge">__STUDIO_PRODUCT_NAME__</div>
      <h1>__STUDIO_PRODUCT_NAME__</h1>
      <p class="subtitle">Guided onboarding for new and brownfield Flutter apps — setup, scaffold, build, and ship.</p>
    </header>

    <div class="entry-paths panel">
      <h2>Start here</h2>
      <div class="entry-grid">
        <div class="entry-card">
          <strong>New Flutter app</strong>
          Create a project below, load it, then open <a href="/setup">Setup</a>.
        </div>
        <div class="entry-card">
          <strong>Existing app (no config)</strong>
          Load your project path, then run <a href="/setup">Setup</a> to generate config and scripts.
        </div>
        <div class="entry-card">
          <strong>Quick Test only</strong>
          No project required — <a href="/quick-test">paste a Git URL</a> and install on a device.
        </div>
      </div>
    </div>

    <div id="flutterBanner" class="banner"></div>

    <div class="env-bar" id="envBar">Loading environment…</div>

    <div class="panel">
      <label for="projectPath">Flutter project</label>
      <div class="row">
        <input id="projectPath" type="text" placeholder="/path/to/your/flutter/app" />
        <button type="button" class="primary" id="loadBtn">Load project</button>
      </div>
      <p id="projectMeta" style="margin-top:0.75rem;font-size:0.85rem;color:var(--muted)"></p>
      <details style="margin-top:1rem">
        <summary style="cursor:pointer;color:var(--muted)">Create new Flutter project</summary>
        <div style="margin-top:0.75rem">
          <label for="createParent">Parent folder path</label>
          <input id="createParent" type="text" placeholder="/path/to/parent" style="width:100%;margin:0.35rem 0 0.75rem" />
          <label for="createName">Project name</label>
          <input id="createName" type="text" placeholder="my_flutter_app" style="width:100%;margin:0.35rem 0 0.75rem" />
          <button type="button" id="createBtn">Create project</button>
        </div>
      </details>
    </div>

    <div class="cards" id="cards">
      <a class="card" id="cardSetup" href="/setup">
        <div class="card-icon">⚙️</div>
        <h3>Setup flutter project</h3>
        <p>Env files, config, scripts, architecture preset, API protocol, and state management.</p>
      </a>
      <a class="card" id="cardBuild" href="/build">
        <div class="card-icon">🚀</div>
        <h3>Build APK &amp; IPA</h3>
        <p>TestFlight IPA and beta APK — local folder or GitHub remote, with secure env overlay.</p>
      </a>
      <a class="card" id="cardQuickTest" href="/quick-test">
        <div class="card-icon">⚡</div>
        <h3>Quick Test</h3>
        <p>Paste a Git repo, build APK/IPA, install on connected devices.</p>
      </a>
      <a class="card" id="cardFeature" href="/feature">
        <div class="card-icon">📁</div>
        <h3>Add feature</h3>
        <p>Scaffold feature folders with configurable architecture and API protocol.</p>
      </a>
      <a class="card" id="cardVersion" href="/version">
        <div class="card-icon">📈</div>
        <h3>Bump version</h3>
        <p>Classify the latest commit and update version keys in env files.</p>
      </a>
      <a class="card" id="cardDoctor" href="/doctor">
        <div class="card-icon">🩺</div>
        <h3>Project doctor</h3>
        <p>Dart/Flutter, config, env files, signing hints, and architecture audit summary.</p>
      </a>
    </div>

    <div class="soon">
      <h2>Coming soon</h2>
      <div class="soon-grid">
        <span class="soon-pill">Release notes</span>
      </div>
    </div>
  </div>

  <script>
    const STORAGE_KEY = "rtk_studio_project_path";
    let capabilities = {};
    let projectLoaded = false;

    async function api(path) {
      const res = await fetch(path);
      return res.json();
    }

    function savePath(path) {
      if (path) localStorage.setItem(STORAGE_KEY, path);
    }

    function loadSavedPath() {
      return localStorage.getItem(STORAGE_KEY) || "";
    }

    async function refreshEnvironment() {
      const env = await api("/api/environment");
      capabilities = env.capabilities || {};
      const bar = document.getElementById("envBar");
      const dart = env.dart?.installed ? "Dart ✓" : "Dart ✗";
      const flutter = env.flutter?.installed
        ? "Flutter ✓ " + (env.flutter.version || "")
        : "Flutter ✗";
      const xcode = env.macos
        ? (env.xcode?.installed ? "Xcode ✓" : "Xcode ✗")
        : "iOS: macOS only";
      bar.innerHTML =
        `<span class="pill ${env.dart?.installed ? "ok" : "bad"}">${dart}</span>` +
        `<span class="pill ${env.flutter?.installed ? "ok" : "bad"}">${flutter}</span>` +
        `<span class="pill">${xcode}</span>` +
        `<button type="button" id="refreshEnv" style="margin-left:auto">Refresh</button>`;
      document.getElementById("refreshEnv").onclick = refreshEnvironment;

      const banner = document.getElementById("flutterBanner");
      if (!env.dart?.installed) {
        banner.textContent =
          "Dart SDK not found — install Dart to use __STUDIO_PRODUCT_NAME__.";
        banner.classList.add("visible");
      } else if (!env.flutter?.installed) {
        banner.textContent =
          "Flutter not found on this device — Setup and Add feature still work. " +
          "Install Flutter (flutter doctor) to build APK/IPA.";
        banner.classList.add("visible");
      } else {
        banner.classList.remove("visible");
      }

      updateCards();
    }

    function updateCards() {
      const build = document.getElementById("cardBuild");
      if (!capabilities.build_android) {
        build.classList.add("disabled");
      } else {
        build.classList.remove("disabled");
      }
      const quickTest = document.getElementById("cardQuickTest");
      if (!capabilities.quick_test) {
        quickTest.classList.add("disabled");
      } else {
        quickTest.classList.remove("disabled");
      }
      const version = document.getElementById("cardVersion");
      if (!capabilities.version_bump) {
        version.classList.add("disabled");
      } else {
        version.classList.remove("disabled");
      }
      document.querySelectorAll(".card").forEach((c) => {
        if (c.id === "cardQuickTest") {
          if (!capabilities.quick_test) c.classList.add("disabled");
          else c.classList.remove("disabled");
          return;
        }
        if (!projectLoaded) c.classList.add("disabled");
        else if (c.id === "cardBuild" && !capabilities.build_android) {
          c.classList.add("disabled");
        } else if (c.id === "cardVersion" && !capabilities.version_bump) {
          c.classList.add("disabled");
        } else {
          c.classList.remove("disabled");
        }
      });
    }

    async function registerProject(path, repair = false) {
      const res = await fetch("/api/project", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ project: path, repair }),
      });
      const data = await res.json();
      if (!res.ok) {
        const env = await api("/api/environment");
        if (!repair && data.can_repair && env.flutter?.installed) {
          const issues = (data.analysis?.issues || []).join("\n• ");
          if (confirm(
            "This folder is missing Flutter structure:\n• " + issues +
            "\n\nRepair it with flutter create?"
          )) {
            return registerProject(path, true);
          }
        }
        throw new Error(data.error || "Invalid project");
      }
      return data;
    }

    async function loadProject() {
      const path = document.getElementById("projectPath").value.trim();
      if (!path) return alert("Enter a Flutter project path");
      savePath(path);
      document.getElementById("loadBtn").disabled = true;
      try {
        const analysisRes = await fetch("/api/project/analyze?path=" + encodeURIComponent(path));
        const analysis = await analysisRes.json();
        if (!analysisRes.ok) throw new Error(analysis.error);
        const env = await api("/api/environment");

        if (!analysis.compatible) {
          if (analysis.can_repair && env.flutter?.installed) {
            const issues = (analysis.issues || []).join("\n• ");
            if (!confirm(
              "This folder is missing Flutter structure:\n• " + issues +
              "\n\nRepair it with flutter create?"
            )) {
              throw new Error("Project not loaded");
            }
            await registerProject(path, true);
          } else {
            throw new Error(
              (analysis.issues || ["Not a Flutter project"]).join("\n") +
              (env.flutter?.installed
                ? "\n\nUse Create new Flutter project below."
                : "\n\nInstall Flutter to repair or create projects.")
            );
          }
        } else {
          await registerProject(path, false);
        }

        await refreshEnvironment();
        const detect = await fetch("/api/detect?path=" + encodeURIComponent(path));
        const detectData = await detect.json();
        if (!detect.ok) throw new Error(detectData.error);
        projectLoaded = true;
        const hasConfig = detectData.has_existing_config;
        document.getElementById("projectMeta").textContent =
          analysis.compatible
            ? (hasConfig
                ? "Compatible Flutter project — ready to build or add features."
                : "Compatible Flutter project — Setup is recommended first.")
            : "Flutter project loaded after structure repair.";
        const setup = document.getElementById("cardSetup");
        setup.classList.toggle("recommended", !hasConfig);
        updateCards();
      } catch (e) {
        alert(e.message);
        projectLoaded = false;
        updateCards();
      } finally {
        document.getElementById("loadBtn").disabled = false;
      }
    }

    async function createProject() {
      const parent = document.getElementById("createParent").value.trim();
      const name = document.getElementById("createName").value.trim() || "my_flutter_app";
      if (!parent) return alert("Enter parent folder path");
      const env = await api("/api/environment");
      if (!env.flutter?.installed) {
        return alert("Flutter is not installed on this device. Install Flutter before creating a project.");
      }
      document.getElementById("createBtn").disabled = true;
      try {
        const res = await fetch("/api/project/create", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ parent_path: parent, project_name: name }),
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || "Create failed");
        document.getElementById("projectPath").value = data.project_path;
        await loadProject();
      } catch (e) {
        alert(e.message);
      } finally {
        document.getElementById("createBtn").disabled = false;
      }
    }

    document.querySelectorAll(".card").forEach((card) => {
      card.addEventListener("click", (e) => {
        if (card.id === "cardQuickTest") return;
        if (card.id === "cardDoctor") return;
        if (!projectLoaded) {
          e.preventDefault();
          alert("Load a Flutter project before opening this workflow.");
          return;
        }
        if (card.id === "cardBuild" && !capabilities.build_android) {
          e.preventDefault();
          alert(
            "Flutter is not set up on this device. Install Flutter and run flutter doctor, then refresh."
          );
        }
        if (card.id === "cardVersion" && !capabilities.version_bump) {
          e.preventDefault();
          alert("Git is required for version bump. Install Git and refresh.");
        }
      });
    });

    document.getElementById("loadBtn").addEventListener("click", loadProject);
    document.getElementById("createBtn").addEventListener("click", createProject);
    document.getElementById("projectPath").addEventListener("keydown", (e) => {
      if (e.key === "Enter") loadProject();
    });

    (async () => {
      await refreshEnvironment();
      const boot = await api("/api/bootstrap");
      const saved = boot.project_path || loadSavedPath();
      if (saved) {
        document.getElementById("projectPath").value = saved;
      }
    })().catch(console.error);
  </script>
</body>
</html>
''';
