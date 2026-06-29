/// Embedded single-page UI for Distribution Studio.
String distributionStudioHtml() => r'''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Distribution Studio</title>
  <style>
    :root {
      --bg: #0b0f1a;
      --surface: rgba(255, 255, 255, 0.06);
      --surface-hover: rgba(255, 255, 255, 0.1);
      --border: rgba(255, 255, 255, 0.12);
      --text: #f0f4ff;
      --muted: #8b95b0;
      --accent: #6c5ce7;
      --accent2: #00cec9;
      --android: #3ddc84;
      --ios: #0a84ff;
      --danger: #ff6b6b;
      --success: #2ecc71;
      --radius: 16px;
      --shadow: 0 24px 80px rgba(0, 0, 0, 0.45);
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: var(--bg);
      color: var(--text);
      min-height: 100vh;
      background-image:
        radial-gradient(ellipse 80% 50% at 20% -10%, rgba(108, 92, 231, 0.35), transparent),
        radial-gradient(ellipse 60% 40% at 90% 10%, rgba(0, 206, 201, 0.2), transparent),
        radial-gradient(ellipse 50% 30% at 50% 100%, rgba(108, 92, 231, 0.15), transparent);
    }
    .wrap { max-width: 1100px; margin: 0 auto; padding: 2rem 1.5rem 3rem; }
    header { text-align: center; margin-bottom: 2.5rem; }
    .badge {
      display: inline-block;
      font-size: 0.72rem;
      font-weight: 600;
      letter-spacing: 0.12em;
      text-transform: uppercase;
      color: var(--accent2);
      background: rgba(0, 206, 201, 0.12);
      border: 1px solid rgba(0, 206, 201, 0.3);
      padding: 0.35rem 0.85rem;
      border-radius: 999px;
      margin-bottom: 1rem;
    }
    h1 {
      font-size: clamp(2rem, 5vw, 2.75rem);
      font-weight: 700;
      letter-spacing: -0.03em;
      background: linear-gradient(135deg, #fff 30%, #a29bfe 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
    }
    .subtitle { color: var(--muted); margin-top: 0.6rem; font-size: 1.05rem; }
    .panel {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      backdrop-filter: blur(20px);
      padding: 1.5rem;
      margin-bottom: 1.5rem;
      box-shadow: var(--shadow);
    }
    .panel h2 { font-size: 0.85rem; text-transform: uppercase; letter-spacing: 0.08em; color: var(--muted); margin-bottom: 1rem; }
    .row { display: flex; gap: 1rem; flex-wrap: wrap; align-items: flex-end; }
    label { display: block; font-size: 0.8rem; color: var(--muted); margin-bottom: 0.4rem; }
    input, select {
      width: 100%;
      background: rgba(0, 0, 0, 0.35);
      border: 1px solid var(--border);
      color: var(--text);
      padding: 0.75rem 1rem;
      border-radius: 10px;
      font-size: 0.95rem;
      outline: none;
      transition: border-color 0.2s;
    }
    input:focus, select:focus { border-color: var(--accent); }
    .field { flex: 1; min-width: 220px; }
    .meta { display: flex; gap: 1.5rem; flex-wrap: wrap; margin-top: 1rem; font-size: 0.85rem; color: var(--muted); }
    .meta span strong { color: var(--text); }
    .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 1.25rem; margin-bottom: 1.5rem; }
    .card {
      position: relative;
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 1.75rem;
      cursor: pointer;
      transition: transform 0.2s, border-color 0.2s, background 0.2s;
      overflow: hidden;
    }
    .card::before {
      content: "";
      position: absolute;
      inset: 0;
      opacity: 0;
      transition: opacity 0.25s;
      border-radius: inherit;
    }
    .card.android::before { background: linear-gradient(135deg, rgba(61, 220, 132, 0.15), transparent 60%); }
    .card.ios::before { background: linear-gradient(135deg, rgba(10, 132, 255, 0.15), transparent 60%); }
    .card:hover { transform: translateY(-3px); background: var(--surface-hover); }
    .card:hover::before { opacity: 1; }
    .card.selected { border-color: var(--accent); box-shadow: 0 0 0 1px var(--accent); }
    .card.android.selected { border-color: var(--android); box-shadow: 0 0 0 1px var(--android); }
    .card.ios.selected { border-color: var(--ios); box-shadow: 0 0 0 1px var(--ios); }
    .card-icon { font-size: 2.25rem; margin-bottom: 0.75rem; }
    .card h3 { font-size: 1.15rem; margin-bottom: 0.4rem; }
    .card p { font-size: 0.88rem; color: var(--muted); line-height: 1.5; }
    .actions { display: flex; gap: 1rem; flex-wrap: wrap; align-items: center; margin-bottom: 1.5rem; }
    button {
      font-family: inherit;
      font-size: 0.95rem;
      font-weight: 600;
      border: none;
      border-radius: 12px;
      padding: 0.85rem 1.5rem;
      cursor: pointer;
      transition: transform 0.15s, opacity 0.15s;
    }
    button:disabled { opacity: 0.45; cursor: not-allowed; }
    button:not(:disabled):hover { transform: scale(1.02); }
    .btn-primary {
      background: linear-gradient(135deg, var(--accent), #a29bfe);
      color: #fff;
      box-shadow: 0 8px 32px rgba(108, 92, 231, 0.4);
    }
    .btn-both {
      background: linear-gradient(135deg, var(--accent2), #55efc4);
      color: #0b0f1a;
      box-shadow: 0 8px 32px rgba(0, 206, 201, 0.35);
    }
    .btn-ghost {
      background: transparent;
      color: var(--muted);
      border: 1px solid var(--border);
    }
    .btn-danger {
      background: rgba(255, 107, 107, 0.15);
      color: var(--danger);
      border: 1px solid rgba(255, 107, 107, 0.4);
    }
    .status-pill {
      display: inline-flex;
      align-items: center;
      gap: 0.45rem;
      font-size: 0.82rem;
      font-weight: 600;
      padding: 0.4rem 0.85rem;
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.06);
      border: 1px solid var(--border);
    }
    .status-pill .dot {
      width: 8px; height: 8px; border-radius: 50%;
      background: var(--muted);
    }
    .status-pill.running .dot { background: var(--accent2); animation: pulse 1s infinite; }
    .status-pill.succeeded .dot { background: var(--success); }
    .status-pill.failed .dot { background: var(--danger); }
    @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.35; } }
    .terminal {
      background: #050810;
      border: 1px solid var(--border);
      border-radius: var(--radius);
      min-height: 280px;
      max-height: 420px;
      overflow-y: auto;
      font-family: "SF Mono", "Fira Code", Menlo, monospace;
      font-size: 0.78rem;
      line-height: 1.55;
      padding: 1rem 1.25rem;
      color: #c8d3f5;
      white-space: pre-wrap;
      word-break: break-all;
    }
    .terminal .placeholder { color: var(--muted); font-style: italic; }
    .artifacts { margin-top: 1rem; }
    .artifacts a {
      display: block;
      color: var(--accent2);
      font-size: 0.85rem;
      margin-top: 0.35rem;
      word-break: break-all;
    }
    .error-banner {
      background: rgba(255, 107, 107, 0.12);
      border: 1px solid rgba(255, 107, 107, 0.35);
      color: #ffb4b4;
      padding: 0.85rem 1rem;
      border-radius: 10px;
      margin-bottom: 1rem;
      font-size: 0.9rem;
      display: none;
    }
    .error-banner.visible { display: block; }
    .ios-disabled { opacity: 0.55; pointer-events: none; }
    .source-toggle { display: flex; gap: 0.75rem; margin-bottom: 1rem; flex-wrap: wrap; }
    .source-toggle label { display: flex; align-items: center; gap: 0.4rem; font-size: 0.88rem; color: var(--text); cursor: pointer; }
    .source-toggle input { width: auto; margin: 0; }
    .hidden { display: none !important; }
    .preflight-list { margin-top: 0.75rem; font-size: 0.82rem; }
    .preflight-list li { margin: 0.35rem 0; color: var(--muted); }
    .preflight-list li.pass { color: var(--success); }
    .preflight-list li.fail { color: var(--danger); }
    .preflight-list li.warn { color: #ffb26b; }
    details.env-secrets { margin-top: 1rem; }
    details.env-secrets summary { cursor: pointer; color: var(--muted); font-size: 0.85rem; }
  </style>
</head>
<body>
  <div class="wrap">
    <header>
      <div class="badge">Flutter Project Setup Toolkit</div>
      <h1>Distribution Studio</h1>
      <p class="subtitle">Build beta APK &amp; TestFlight IPA — one click, live logs.</p>
    </header>

    <div class="panel">
      <h2>Project source</h2>
      <div class="source-toggle">
        <label><input type="radio" name="sourceMode" value="local" checked /> Local folder</label>
        <label><input type="radio" name="sourceMode" value="git" /> Git repository</label>
      </div>
      <div id="localSourcePanel">
        <div class="row">
          <div class="field" style="flex: 3">
            <label for="projectPath">Flutter project path</label>
            <input id="projectPath" type="text" placeholder="/path/to/your/flutter/app" />
          </div>
          <div class="field" style="flex: 0">
            <label>&nbsp;</label>
            <button type="button" class="btn-ghost" id="loadBtn">Load</button>
          </div>
        </div>
      </div>
      <div id="gitSourcePanel" class="hidden">
        <div class="field">
          <label for="gitUrl">Repository URL</label>
          <input id="gitUrl" type="text" placeholder="git@github.com:org/app.git or https://github.com/org/app.git" />
        </div>
        <div class="row">
          <div class="field"><label for="gitRef">Branch / tag / commit</label><input id="gitRef" value="main" /></div>
          <div class="field"><label for="gitSubdir">Subdirectory (optional)</label><input id="gitSubdir" placeholder="apps/mobile" /></div>
        </div>
        <div class="row">
          <div class="field">
            <label for="gitAuth">Authentication</label>
            <select id="gitAuth">
              <option value="ssh">SSH</option>
              <option value="https">HTTPS (public)</option>
              <option value="https_token">HTTPS + token</option>
            </select>
          </div>
          <div class="field hidden" id="gitTokenField">
            <label for="gitToken">Personal access token</label>
            <input id="gitToken" type="password" placeholder="ghp_…" autocomplete="off" />
          </div>
        </div>
        <button type="button" class="btn-ghost" id="testGitBtn">Test access &amp; load</button>
      </div>
      <div class="row" style="margin-top:1rem">
        <div class="field">
          <label for="envSelect">Environment</label>
          <select id="envSelect"><option value="">Load project first…</option></select>
        </div>
      </div>
      <details class="env-secrets" id="envSecretsPanel">
        <summary>Environment secrets (session only — not saved to repo)</summary>
        <div style="margin-top:0.75rem">
          <div class="source-toggle" style="margin-bottom:0.75rem">
            <label><input type="radio" name="envSourceMode" value="local_file" checked /> Local file</label>
            <label><input type="radio" name="envSourceMode" value="paste" /> Paste .env</label>
            <label><input type="radio" name="envSourceMode" value="session_values" /> Key / value</label>
          </div>
          <div id="envSourceLocal">
            <label for="envSourceFile">Import local env file</label>
            <input id="envSourceFile" type="text" placeholder="/Users/me/.secrets/myapp/prod.env" />
          </div>
          <div id="envSourcePaste" class="hidden">
            <label for="envPasteContent">Paste env file contents</label>
            <textarea id="envPasteContent" rows="6" style="width:100%;background:rgba(0,0,0,0.35);border:1px solid var(--border);color:var(--text);padding:0.75rem;border-radius:10px;font-family:Menlo,monospace;font-size:0.8rem"></textarea>
          </div>
          <div id="envSourceKv" class="hidden">
            <label>Key / value pairs</label>
            <div id="envKvRows"></div>
            <button type="button" class="btn-ghost" id="addEnvKvBtn" style="margin-top:0.5rem">Add row</button>
          </div>
          <p style="font-size:0.78rem;color:var(--muted);margin-top:0.35rem">Used when the env file is missing from the project or clone.</p>
        </div>
      </details>
      <ul class="preflight-list hidden" id="preflightList"></ul>
      <div class="meta" id="projectMeta"></div>
    </div>

    <div class="panel" id="flavorPanel">
      <h2>Build options</h2>
      <div class="row">
        <div class="field">
          <label for="androidFlavor">Android flavor (optional)</label>
          <input id="androidFlavor" type="text" placeholder="e.g. staging" />
        </div>
        <div class="field">
          <label for="iosFlavor">iOS flavor (optional)</label>
          <input id="iosFlavor" type="text" placeholder="e.g. staging" />
        </div>
        <div class="field">
          <label for="iosScheme">Xcode scheme</label>
          <select id="iosScheme"><option value="">Load project first…</option></select>
        </div>
      </div>
      <p id="iosSchemeHint" style="font-size:0.78rem;color:var(--muted);margin-top:0.35rem"></p>
      <label style="display:flex;align-items:center;gap:0.5rem;margin-top:0.75rem;font-size:0.85rem">
        <input id="openOrganizer" type="checkbox" checked />
        Open Xcode Organizer after iOS archive
      </label>
    </div>

    <details class="panel" id="configPanel">
      <summary>release-toolkit.config.json</summary>
      <p style="font-size:0.78rem;color:var(--muted);margin:0.75rem 0">Edit env paths and build defaults for this project. Builds can save these changes before running.</p>
      <div class="field">
        <label for="defaultEnvironment">Default environment</label>
        <select id="defaultEnvironment"><option value="">Load project first…</option></select>
      </div>
      <div class="field">
        <label for="envPath">Env file path (selected environment)</label>
        <input id="envPath" type="text" placeholder=".secrets/rider.prod.env" />
      </div>
      <div class="field">
        <label for="configJsonPreview">Config preview</label>
        <textarea id="configJsonPreview" rows="8" readonly style="width:100%;font-family:ui-monospace,monospace;font-size:0.78rem"></textarea>
      </div>
      <div class="row" style="margin-top:0.75rem">
        <button type="button" class="btn-ghost" id="saveConfigBtn">Save config</button>
        <label style="display:flex;align-items:center;gap:0.5rem;font-size:0.85rem">
          <input id="saveConfigBeforeBuild" type="checkbox" checked />
          Save config before build
        </label>
      </div>
      <p id="configSaveStatus" style="font-size:0.78rem;color:var(--muted);margin-top:0.35rem"></p>
    </details>

    <div class="cards">
      <div class="card android" data-target="androidApk" id="cardAndroid">
        <div class="card-icon">🤖</div>
        <h3>Android APK</h3>
        <p>Release APK for internal testers, Firebase App Distribution, or sideloading.</p>
      </div>
      <div class="card android" data-target="androidAab" id="cardAndroidAab">
        <div class="card-icon">📦</div>
        <h3>Android AAB</h3>
        <p>Release App Bundle for Google Play Store upload.</p>
      </div>
      <div class="card ios" data-target="iosTestFlight" id="cardIos">
        <div class="card-icon">🍎</div>
        <h3>iOS TestFlight</h3>
        <p>Release IPA &amp; Xcode archive — ready to upload to App Store Connect.</p>
      </div>
    </div>

    <div class="actions">
      <button type="button" class="btn-primary" id="buildSelectedBtn" disabled>Build selected</button>
      <button type="button" class="btn-both" id="buildBothBtn" disabled>Build both platforms</button>
      <button type="button" class="btn-danger hidden" id="cancelBtn">Cancel build</button>
      <span class="status-pill" id="statusPill"><span class="dot"></span><span id="statusText">Idle</span></span>
    </div>

    <div class="error-banner" id="errorBanner"></div>

    <div class="panel">
      <h2>Build output</h2>
      <div class="terminal" id="terminal"><span class="placeholder">Logs appear here when a build runs…</span></div>
      <div class="artifacts" id="artifacts"></div>
    </div>
  </div>

  <script>
    const $ = (id) => document.getElementById(id);
    let selectedTarget = "androidApk";
    let logOffset = 0;
    let pollTimer = null;
    let projectInfo = null;
    let gitWorkDir = null;
    let studioEnv = { macos: true, flutter: { installed: true } };
    let configEnvironments = {};

    function sourceMode() {
      return document.querySelector('input[name="sourceMode"]:checked')?.value || "local";
    }

    function syncSourcePanels() {
      const git = sourceMode() === "git";
      $("localSourcePanel").classList.toggle("hidden", git);
      $("gitSourcePanel").classList.toggle("hidden", !git);
      $("gitTokenField").classList.toggle("hidden", $("gitAuth").value !== "https_token");
    }

    document.querySelectorAll('input[name="sourceMode"]').forEach((el) => {
      el.addEventListener("change", syncSourcePanels);
    });
    $("gitAuth").addEventListener("change", syncSourcePanels);
    syncSourcePanels();

    function envSourceMode() {
      return document.querySelector('input[name="envSourceMode"]:checked')?.value || "local_file";
    }

    function syncEnvSourcePanels() {
      const mode = envSourceMode();
      $("envSourceLocal").classList.toggle("hidden", mode !== "local_file");
      $("envSourcePaste").classList.toggle("hidden", mode !== "paste");
      $("envSourceKv").classList.toggle("hidden", mode !== "session_values");
    }

    document.querySelectorAll('input[name="envSourceMode"]').forEach((el) => {
      el.addEventListener("change", syncEnvSourcePanels);
    });
    syncEnvSourcePanels();

    function addEnvKvRow(key = "", value = "") {
      const row = document.createElement("div");
      row.className = "row";
      row.style.marginBottom = "0.5rem";
      row.innerHTML =
        '<input class="env-kv-key" placeholder="KEY" value="' + key.replace(/"/g, "&quot;") + '" style="flex:1" />' +
        '<input class="env-kv-val" placeholder="value" value="' + value.replace(/"/g, "&quot;") + '" style="flex:2" />' +
        '<button type="button" class="btn-ghost env-kv-remove">✕</button>';
      row.querySelector(".env-kv-remove").addEventListener("click", () => row.remove());
      $("envKvRows").appendChild(row);
    }

    $("addEnvKvBtn").addEventListener("click", () => addEnvKvRow());
    addEnvKvRow("APP_VERSION_NAME", "");
    addEnvKvRow("APP_VERSION_CODE", "");

    function renderPreflight(data) {
      const list = $("preflightList");
      const checks = data.checks || [];
      if (!checks.length) {
        list.classList.add("hidden");
        return;
      }
      list.classList.remove("hidden");
      list.innerHTML = checks.map((c) =>
        `<li class="${c.status}">${c.label}: ${c.detail || c.status}</li>`
      ).join("");
      if (data.env_help) {
        $("envSecretsPanel").open = true;
      }
    }

    function fillEnvSelect(info) {
      $("envSelect").innerHTML = "";
      const envs = Object.keys(info.environments || {});
      configEnvironments = { ...(info.environments || {}) };
      envs.forEach((name) => {
        const opt = document.createElement("option");
        opt.value = name;
        opt.textContent = name + " → " + info.environments[name];
        if (name === info.default_environment) opt.selected = true;
        $("envSelect").appendChild(opt);
      });
      fillDefaultEnvironmentSelect(info);
      syncEnvPathField();
      refreshConfigPreview();
    }

    function fillDefaultEnvironmentSelect(info) {
      const select = $("defaultEnvironment");
      select.innerHTML = "";
      const envs = Object.keys(configEnvironments);
      envs.forEach((name) => {
        const opt = document.createElement("option");
        opt.value = name;
        opt.textContent = name;
        if (name === (info.default_environment || envs[0])) opt.selected = true;
        select.appendChild(opt);
      });
    }

    function syncEnvPathField() {
      const env = $("envSelect").value;
      if (env && configEnvironments[env] != null) {
        $("envPath").value = configEnvironments[env];
      }
    }

    function collectConfigPayload() {
      const selectedEnv = $("envSelect").value;
      const envPath = $("envPath").value.trim();
      if (selectedEnv && envPath) configEnvironments[selectedEnv] = envPath;
      return {
        environments: { ...configEnvironments },
        default_environment: $("defaultEnvironment").value || $("envSelect").value,
        env: selectedEnv,
        env_path: envPath,
        android_flavor: $("androidFlavor").value.trim() || null,
        ios_flavor: $("iosFlavor").value.trim() || null,
        ios_scheme: $("iosScheme").value.trim() || null,
        open_organizer: $("openOrganizer").checked,
      };
    }

    function refreshConfigPreview() {
      const payload = collectConfigPayload();
      $("configJsonPreview").value = JSON.stringify({
        default_environment: payload.default_environment,
        environments: payload.environments,
        build: {
          android_flavor: payload.android_flavor,
          ios_flavor: payload.ios_flavor,
          ios_scheme: payload.ios_scheme,
          open_organizer: payload.open_organizer,
        },
      }, null, 2);
    }

    async function saveConfig(showAlertOnSuccess) {
      const path = $("projectPath").value.trim();
      if (!path) {
        if (showAlertOnSuccess) alert("Enter a local project path to save config");
        return false;
      }
      $("saveConfigBtn").disabled = true;
      try {
        const payload = collectConfigPayload();
        const result = await api("/api/distribution/config", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ project: path, ...payload }),
        });
        configEnvironments = { ...(result.environments || payload.environments) };
        $("configSaveStatus").textContent = "Saved " + (result.config_path || "release-toolkit.config.json");
        projectInfo = await api("/api/project?path=" + encodeURIComponent(path));
        fillEnvSelect(projectInfo);
        applyProjectMeta(projectInfo);
        refreshConfigPreview();
        return true;
      } catch (e) {
        $("configSaveStatus").textContent = "Save failed: " + e.message;
        if (showAlertOnSuccess) alert(e.message);
        return false;
      } finally {
        $("saveConfigBtn").disabled = false;
      }
    }

    function fillIosSchemeSelect(info) {
      const select = $("iosScheme");
      select.innerHTML = "";
      const schemes = info.ios_schemes?.length
        ? info.ios_schemes
        : (info.ios_scheme ? [info.ios_scheme] : ["Runner"]);
      schemes.forEach((name) => {
        const opt = document.createElement("option");
        opt.value = name;
        opt.textContent = name;
        if (name === info.ios_scheme) opt.selected = true;
        select.appendChild(opt);
      });
      const hint = $("iosSchemeHint");
      if (info.ios_archive_name && info.ios_archive_name !== info.ios_scheme) {
        hint.textContent = "Archive will be named " + info.ios_archive_name + ".xcarchive";
      } else {
        hint.textContent = "Must match a shared scheme under ios/*.xcodeproj/xcshareddata/xcschemes/";
      }
    }

    function applyProjectMeta(info) {
      projectInfo = info;
      $("projectMeta").innerHTML =
        "<span><strong>Flutter</strong> " + (info.flutter_version || "unknown") + "</span>" +
        (info.is_macos
          ? "<span><strong>macOS</strong> iOS builds available</span>"
          : "<span><strong>iOS</strong> requires macOS</span>") +
        (info.ios_scheme
          ? "<span><strong>iOS scheme</strong> " + info.ios_scheme +
            (info.ios_archive_name && info.ios_archive_name !== info.ios_scheme
              ? " (archive: " + info.ios_archive_name + ")"
              : "") +
            "</span>"
          : "");
      if (info.android_flavor) $("androidFlavor").value = info.android_flavor;
      if (info.ios_flavor) $("iosFlavor").value = info.ios_flavor;
      $("openOrganizer").checked = info.open_organizer !== false;
      fillIosSchemeSelect(info);
      const iosCard = $("cardIos");
      if (!info.is_macos) iosCard.classList.add("ios-disabled");
      else iosCard.classList.remove("ios-disabled");
      const canBuild = info.flutter_installed !== false;
      $("buildSelectedBtn").disabled = !canBuild;
      $("buildBothBtn").disabled = !canBuild || !info.is_macos;
      refreshConfigPreview();
    }

    function gitSourcePayload() {
      const payload = {
        type: "git",
        url: $("gitUrl").value.trim(),
        ref: $("gitRef").value.trim() || "main",
        subdir: $("gitSubdir").value.trim(),
        auth: $("gitAuth").value,
      };
      if ($("gitAuth").value === "https_token") {
        payload.token = $("gitToken").value;
      }
      return payload;
    }

    function buildEnvSource() {
      const mode = envSourceMode();
      if (mode === "local_file") {
        const path = $("envSourceFile").value.trim();
        if (!path) return null;
        return { mode: "local_file", path };
      }
      if (mode === "paste") {
        const content = $("envPasteContent").value.trim();
        if (!content) return null;
        return { mode: "paste", content };
      }
      const values = {};
      $("envKvRows").querySelectorAll(".row").forEach((row) => {
        const key = row.querySelector(".env-kv-key")?.value.trim();
        const val = row.querySelector(".env-kv-val")?.value ?? "";
        if (key) values[key] = val;
      });
      if (!Object.keys(values).length) return null;
      return { mode: "session_values", values };
    }

    function setBuildControlsRunning(running) {
      $("buildSelectedBtn").disabled = running;
      $("buildBothBtn").disabled = running || !projectInfo?.is_macos;
      $("cancelBtn").classList.toggle("hidden", !running);
    }

    function setStatus(status, text) {
      const pill = $("statusPill");
      pill.className = "status-pill" + (status && status !== "idle" ? " " + status : "");
      $("statusText").textContent = text || status || "Idle";
    }

    function selectCard(target) {
      selectedTarget = target;
      document.querySelectorAll(".card").forEach((c) => {
        c.classList.toggle("selected", c.dataset.target === target);
      });
    }

    document.querySelectorAll(".card").forEach((card) => {
      card.addEventListener("click", () => selectCard(card.dataset.target));
    });
    selectCard("androidApk");

    async function api(path, opts) {
      const res = await fetch(path, opts);
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || res.statusText);
      return data;
    }

    async function loadProject() {
      const path = $("projectPath").value.trim();
      if (!path) return alert("Enter a project path");
      $("loadBtn").disabled = true;
      try {
        projectInfo = await api("/api/project?path=" + encodeURIComponent(path));
        gitWorkDir = null;
        fillEnvSelect(projectInfo);
        applyProjectMeta(projectInfo);
        const pf = await api("/api/preflight?path=" + encodeURIComponent(path)
          + "&env=" + encodeURIComponent($("envSelect").value || "dev")
          + "&ios_scheme=" + encodeURIComponent($("iosScheme").value || ""));
        renderPreflight(pf);
        $("errorBanner").classList.remove("visible");
      } catch (e) {
        $("errorBanner").textContent = e.message;
        $("errorBanner").classList.add("visible");
      } finally {
        $("loadBtn").disabled = false;
      }
    }

    async function testGitAccess() {
      const url = $("gitUrl").value.trim();
      if (!url) return alert("Enter a repository URL");
      $("testGitBtn").disabled = true;
      try {
        const env = $("envSelect").value || "dev";
        const data = await api("/api/distribution/repo/preflight", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            source: gitSourcePayload(),
            env,
            android_flavor: $("androidFlavor").value.trim() || null,
            ios_flavor: $("iosFlavor").value.trim() || null,
            ios_scheme: $("iosScheme").value.trim() || null,
          }),
        });
        gitWorkDir = data.work_dir;
        fillEnvSelect(data);
        applyProjectMeta({
          environments: data.environments,
          default_environment: data.default_environment,
          flutter_version: "from clone",
          is_macos: studioEnv.macos === true,
          flutter_installed: studioEnv.flutter?.installed !== false,
          ios_scheme: data.ios_scheme,
          ios_schemes: data.ios_schemes,
          ios_archive_name: data.ios_archive_name,
        });
        renderPreflight(data);
        $("errorBanner").classList.remove("visible");
      } catch (e) {
        $("errorBanner").textContent = e.message;
        $("errorBanner").classList.add("visible");
      } finally {
        $("testGitBtn").disabled = false;
      }
    }

    $("loadBtn").addEventListener("click", loadProject);
    $("testGitBtn").addEventListener("click", testGitAccess);
    $("saveConfigBtn").addEventListener("click", () => saveConfig(true));
    $("envSelect").addEventListener("change", () => { syncEnvPathField(); refreshConfigPreview(); });
    $("envPath").addEventListener("input", refreshConfigPreview);
    $("defaultEnvironment").addEventListener("change", refreshConfigPreview);
    ["androidFlavor", "iosFlavor", "iosScheme", "openOrganizer"].forEach((id) => {
      $(id).addEventListener("input", refreshConfigPreview);
      $(id).addEventListener("change", refreshConfigPreview);
    });
    $("projectPath").addEventListener("keydown", (e) => {
      if (e.key === "Enter") loadProject();
    });

    function appendLogs(lines) {
      const term = $("terminal");
      const ph = term.querySelector(".placeholder");
      if (ph) ph.remove();
      if (!lines.length) return;
      term.textContent += lines.join("\n") + "\n";
      term.scrollTop = term.scrollHeight;
    }

    function startPolling() {
      if (pollTimer) clearInterval(pollTimer);
      pollTimer = setInterval(pollStatus, 800);
    }

    async function pollStatus() {
      try {
        const data = await api("/api/status?offset=" + logOffset);
        if (data.logs && data.logs.length) {
          appendLogs(data.logs);
          logOffset = data.log_total;
        }
        if (data.status === "running") {
          setStatus("running", "Building…");
          setBuildControlsRunning(true);
        } else if (data.status === "succeeded") {
          setStatus("succeeded", "Build succeeded");
          clearInterval(pollTimer);
          pollTimer = null;
          setBuildControlsRunning(false);
          if (data.artifact_paths?.length) {
            $("artifacts").innerHTML = "<strong style='font-size:0.85rem;color:var(--muted)'>Artifacts</strong>" +
              data.artifact_paths.map((p) => "<span style='display:block;font-size:0.85rem;color:var(--accent2);margin-top:0.35rem'>" + p + "</span>").join("");
          }
        } else if (data.status === "failed") {
          setStatus("failed", "Build failed");
          clearInterval(pollTimer);
          pollTimer = null;
          setBuildControlsRunning(false);
          if (data.error) {
            $("errorBanner").textContent = data.error;
            $("errorBanner").classList.add("visible");
          }
        }
      } catch (_) {}
    }

    async function startBuild(target) {
      const env = $("envSelect").value;
      if (!env) return alert("Load project and select environment");
      const git = sourceMode() === "git";
      const path = $("projectPath").value.trim();
      if (!git && !path) return alert("Enter a project path or use Git source");
      if (git && !$("gitUrl").value.trim()) return alert("Enter a repository URL");
      logOffset = 0;
      $("terminal").textContent = "";
      $("artifacts").innerHTML = "";
      $("errorBanner").classList.remove("visible");
      setStatus("running", "Starting…");
      setBuildControlsRunning(true);
      const body = {
        env,
        target,
        android_flavor: $("androidFlavor").value.trim() || null,
        ios_flavor: $("iosFlavor").value.trim() || null,
        ios_scheme: $("iosScheme").value.trim() || null,
        open_organizer: $("openOrganizer").checked,
        save_config: $("saveConfigBeforeBuild").checked,
        ...collectConfigPayload(),
      };
      const envSource = buildEnvSource();
      if (envSource) body.env_source = envSource;
      if (git) {
        body.source = gitSourcePayload();
      } else {
        body.project = path;
      }
      try {
        await api("/api/build", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(body),
        });
        startPolling();
      } catch (e) {
        setStatus("failed", "Error");
        $("errorBanner").textContent = e.message;
        $("errorBanner").classList.add("visible");
        setBuildControlsRunning(false);
      }
    }

    async function cancelBuild() {
      try {
        await api("/api/build/cancel", { method: "POST" });
        setStatus("idle", "Cancelled");
        setBuildControlsRunning(false);
        if (pollTimer) { clearInterval(pollTimer); pollTimer = null; }
      } catch (e) {
        $("errorBanner").textContent = e.message;
        $("errorBanner").classList.add("visible");
      }
    }

    $("buildSelectedBtn").addEventListener("click", () => startBuild(selectedTarget));
    $("buildBothBtn").addEventListener("click", () => startBuild("both"));
    $("cancelBtn").addEventListener("click", cancelBuild);

    (async () => {
      try {
        studioEnv = await api("/api/environment");
      } catch (_) {}
      try {
        const boot = await api("/api/bootstrap");
        if (boot.project_path) {
          $("projectPath").value = boot.project_path;
          await loadProject();
        }
      } catch (_) {}
    })();
  </script>
</body>
</html>
''';
