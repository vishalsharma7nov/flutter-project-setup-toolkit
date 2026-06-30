/// Embedded single-page UI for Quick Test Studio.
String quickTestStudioHtml() => r'''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Quick Test Studio</title>
  <style>
    :root {
      --bg: #0b0f1a;
      --surface: rgba(255, 255, 255, 0.06);
      --border: rgba(255, 255, 255, 0.12);
      --text: #f0f4ff;
      --muted: #8b95b0;
      --accent: #6c5ce7;
      --accent2: #00cec9;
      --danger: #ff6b6b;
      --success: #2ecc71;
      --radius: 16px;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: var(--bg);
      color: var(--text);
      min-height: 100vh;
      background-image:
        radial-gradient(ellipse 80% 50% at 20% -10%, rgba(108, 92, 231, 0.35), transparent),
        radial-gradient(ellipse 60% 40% at 90% 10%, rgba(0, 206, 201, 0.2), transparent);
    }
    .wrap { max-width: 960px; margin: 0 auto; padding: 2rem 1.5rem 3rem; }
    header { text-align: center; margin-bottom: 2rem; }
    .badge {
      display: inline-block; font-size: 0.72rem; font-weight: 600;
      letter-spacing: 0.12em; text-transform: uppercase; color: var(--accent2);
      background: rgba(0, 206, 201, 0.12); border: 1px solid rgba(0, 206, 201, 0.3);
      padding: 0.35rem 0.85rem; border-radius: 999px; margin-bottom: 1rem;
    }
    h1 {
      font-size: clamp(1.75rem, 4vw, 2.5rem); font-weight: 700;
      background: linear-gradient(135deg, #fff 30%, #a29bfe 100%);
      -webkit-background-clip: text; -webkit-text-fill-color: transparent;
    }
    .subtitle { color: var(--muted); margin-top: 0.5rem; font-size: 1rem; line-height: 1.5; }
    .panel {
      background: var(--surface); border: 1px solid var(--border);
      border-radius: var(--radius); padding: 1.25rem; margin-bottom: 1.25rem;
    }
    .panel h2 {
      font-size: 0.8rem; text-transform: uppercase; letter-spacing: 0.08em;
      color: var(--muted); margin-bottom: 0.85rem;
    }
    label { display: block; font-size: 0.8rem; color: var(--muted); margin-bottom: 0.35rem; }
    input, select, textarea {
      width: 100%; background: rgba(0,0,0,0.35); border: 1px solid var(--border);
      color: var(--text); padding: 0.65rem 0.85rem; border-radius: 10px;
      font-size: 0.95rem; outline: none;
    }
    input:focus, select:focus, textarea:focus { border-color: var(--accent); }
    .row { display: flex; gap: 0.85rem; flex-wrap: wrap; align-items: flex-end; }
    .field { flex: 1; min-width: 140px; }
    .field-wide { flex: 2; min-width: 280px; }
    button {
      font-family: inherit; cursor: pointer; border: none; border-radius: 10px;
      padding: 0.7rem 1.25rem; font-size: 0.95rem; font-weight: 600;
      background: linear-gradient(135deg, var(--accent), #5a4bd1);
      color: #fff; transition: opacity 0.2s;
    }
    button:hover { opacity: 0.9; }
    button:disabled { opacity: 0.45; cursor: not-allowed; }
    button.secondary { background: rgba(255,255,255,0.08); border: 1px solid var(--border); }
    button.android {
      background: linear-gradient(135deg, #3ddc84, #2bb86a);
      color: #04210f;
    }
    button.ios {
      background: linear-gradient(135deg, #0a84ff, #0066cc);
      color: #fff;
    }
    button.danger { background: rgba(255,107,107,0.2); color: var(--danger); border: 1px solid var(--danger); }
    .actions { display: flex; gap: 0.75rem; flex-wrap: wrap; align-items: center; margin-top: 1rem; }
    .banner {
      display: none; padding: 0.85rem 1rem; border-radius: 10px;
      margin-bottom: 1rem; font-size: 0.9rem; line-height: 1.45;
    }
    .banner.visible { display: block; }
    .banner.error { background: rgba(255,107,107,0.12); border: 1px solid var(--danger); color: #ffb4b4; }
    .banner.warn { background: rgba(255,193,7,0.1); border: 1px solid #ffc107; color: #ffe082; }
    .checks { list-style: none; font-size: 0.88rem; }
    .checks li { padding: 0.35rem 0; color: var(--muted); }
    .checks .pass { color: var(--success); }
    .checks .fail { color: var(--danger); }
    .checks .warn { color: #ffc107; }
    .device-list { display: flex; flex-direction: column; gap: 0.5rem; }
    .device-item {
      display: flex; align-items: center; gap: 0.65rem;
      padding: 0.5rem 0.65rem; border-radius: 8px;
      background: rgba(0,0,0,0.25); border: 1px solid var(--border);
    }
    .device-item input { width: auto; }
    .toggle-row { display: flex; align-items: center; gap: 0.5rem; margin: 0.5rem 0; font-size: 0.9rem; }
    .toggle-row input { width: auto; }
    .source-toggle { display: flex; gap: 0.75rem; margin-bottom: 0.85rem; flex-wrap: wrap; }
    .source-toggle label {
      display: flex; align-items: center; gap: 0.4rem;
      font-size: 0.88rem; color: var(--text); cursor: pointer;
    }
    .source-toggle input { width: auto; margin: 0; }
    .log-box {
      background: #05070f; border: 1px solid var(--border); border-radius: 10px;
      padding: 0.85rem; font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
      font-size: 0.78rem; line-height: 1.45; max-height: 360px; overflow-y: auto;
      white-space: pre-wrap; word-break: break-word; color: #c8d0e0;
    }
    .status-pill {
      display: inline-block; padding: 0.25rem 0.65rem; border-radius: 999px;
      font-size: 0.75rem; font-weight: 600; text-transform: uppercase;
    }
    .status-pill.idle { background: rgba(255,255,255,0.08); color: var(--muted); }
    .status-pill.running { background: rgba(108,92,231,0.25); color: #a29bfe; }
    .status-pill.succeeded { background: rgba(46,204,113,0.2); color: var(--success); }
    .status-pill.failed { background: rgba(255,107,107,0.2); color: var(--danger); }
    .artifacts { margin-top: 0.75rem; font-size: 0.85rem; }
    .artifacts a { color: var(--accent2); word-break: break-all; }
    .hidden { display: none !important; }
    details { margin-top: 0.75rem; }
    summary { cursor: pointer; color: var(--muted); font-size: 0.85rem; }
  </style>
</head>
<body>
  <div class="wrap">
    <header>
      <div class="badge">Git or local → device</div>
      <h1>Quick Test Studio</h1>
      <p class="subtitle">
        Use a local Flutter project folder or paste a Git repo URL, build APK and iOS artifacts,
        and install on connected devices. Plugins are built via their <code>example/</code> app.
      </p>
    </header>

    <div id="errorBanner" class="banner error"></div>
    <div id="warnBanner" class="banner warn"></div>

    <div class="panel">
      <h2>Project source</h2>
      <div class="source-toggle">
        <label><input type="radio" name="sourceMode" value="local" checked /> Local folder</label>
        <label><input type="radio" name="sourceMode" value="git" /> Git repository</label>
      </div>
      <div id="localSourcePanel">
        <div class="row">
          <div class="field-wide">
            <label for="projectPath">Flutter project path</label>
            <input id="projectPath" type="text" placeholder="/path/to/your/flutter/app" />
          </div>
          <div class="field" style="flex:0;min-width:auto">
            <label>&nbsp;</label>
            <button type="button" class="secondary" id="browseBtn">Browse…</button>
          </div>
        </div>
        <p class="subtitle" style="margin-top:0.5rem;font-size:0.85rem">
          Pick a folder on this machine or type a path manually.
        </p>
      </div>
      <div id="gitSourcePanel" class="hidden">
        <div class="field-wide" style="margin-bottom:0.75rem">
          <label for="gitUrl">Repository URL</label>
          <input id="gitUrl" type="url" placeholder="https://github.com/org/flutter-app.git" />
        </div>
        <div class="row">
          <div class="field">
            <label for="gitRef">Branch</label>
            <input id="gitRef" type="text" value="main" />
          </div>
          <div class="field">
            <label for="gitSubdir">Subdirectory (optional)</label>
            <input id="gitSubdir" type="text" placeholder="example for plugin-only" />
          </div>
          <div class="field">
            <label for="gitAuth">Auth</label>
            <select id="gitAuth">
              <option value="ssh">SSH</option>
              <option value="https">HTTPS (public)</option>
              <option value="https_token">HTTPS + token</option>
            </select>
          </div>
        </div>
        <div id="tokenRow" class="field-wide hidden" style="margin-top:0.75rem">
          <label for="gitToken">Personal access token (session only)</label>
          <input id="gitToken" type="password" autocomplete="off" />
        </div>
      </div>
      <div class="actions">
        <button type="button" id="checkBtn">Check project</button>
      </div>
    </div>

    <div id="afterPreflight" class="hidden">
      <div class="panel">
        <h2>Environment</h2>
        <div class="row">
          <div class="field">
            <label for="envSelect">Environment</label>
            <select id="envSelect"></select>
          </div>
        </div>
        <details id="envSecretsPanel">
          <summary>Env secrets (optional — only if the app uses dart-defines)</summary>
          <div style="margin-top:0.75rem">
            <label for="envSourceMode">Source</label>
            <select id="envSourceMode">
              <option value="local_file">Local file on this machine</option>
              <option value="paste">Paste .env content</option>
              <option value="session_values">Key-value pairs</option>
            </select>
            <div id="envLocalFile" style="margin-top:0.75rem">
              <label for="envSourceFile">Path to env file</label>
              <input id="envSourceFile" type="text" placeholder="/path/to/.env/dev.env" />
            </div>
            <div id="envPaste" class="hidden" style="margin-top:0.75rem">
              <label for="envPasteContent">Paste env file content</label>
              <textarea id="envPasteContent" rows="6"></textarea>
            </div>
            <div id="envKv" class="hidden" style="margin-top:0.75rem">
              <div id="envKvRows"></div>
              <button type="button" class="secondary" id="addKvBtn" style="margin-top:0.5rem">Add key</button>
            </div>
          </div>
        </details>
      </div>

      <div class="panel">
        <h2>Connected devices</h2>
        <div id="deviceList" class="device-list"></div>
        <p id="noDevices" class="subtitle hidden" style="margin-top:0.5rem;font-size:0.85rem">
          No devices connected — build only (install skipped).
        </p>
      </div>

      <div class="panel">
        <h2>Options</h2>
        <label class="toggle-row">
          <input type="checkbox" id="installToggle" checked />
          Install to connected devices
        </label>
        <label class="toggle-row" id="testflightRow">
          <input type="checkbox" id="testflightToggle" checked />
          Build TestFlight IPA (macOS — upload via Xcode Organizer, not USB install)
        </label>
      </div>

      <div class="panel">
        <h2>Preflight</h2>
        <ul id="checksList" class="checks"></ul>
      </div>

      <div class="panel">
        <h2>Run</h2>
        <div class="actions">
          <button type="button" id="installAndroidBtn" class="android">Install into Android</button>
          <button type="button" id="installIosBtn" class="ios">Install into iOS</button>
          <button type="button" id="runBtn" class="secondary">Run quick test (both)</button>
          <button type="button" id="cancelBtn" class="danger hidden">Cancel</button>
          <span id="statusPill" class="status-pill idle">Idle</span>
        </div>
        <p class="subtitle" style="margin-top:0.75rem;font-size:0.85rem">
          Platform buttons build and install on selected devices for that OS only.
          <strong>Run quick test</strong> builds both platforms and optional TestFlight IPA.
        </p>
        <div id="artifacts" class="artifacts hidden"></div>
      </div>
    </div>

    <div class="panel">
      <h2>Log</h2>
      <div id="logBox" class="log-box">Waiting…</div>
    </div>
  </div>

  <script>
    const $ = (id) => document.getElementById(id);
    let studioEnv = {};
    let preflightData = null;
    let pollTimer = null;
    let logOffset = 0;

    async function api(path, opts) {
      const res = await fetch(path, opts);
      const text = await res.text();
      let data = {};
      try { data = text ? JSON.parse(text) : {}; } catch (_) {}
      if (!res.ok) throw new Error(data.error || res.statusText || "Request failed");
      return data;
    }

    function sourceMode() {
      return document.querySelector('input[name="sourceMode"]:checked')?.value || "local";
    }

    function syncSourcePanels() {
      const git = sourceMode() === "git";
      $("localSourcePanel").classList.toggle("hidden", git);
      $("gitSourcePanel").classList.toggle("hidden", !git);
      $("tokenRow").classList.toggle("hidden", $("gitAuth").value !== "https_token");
    }
    window.syncSourcePanels = syncSourcePanels;

    function quickTestSourcePayload() {
      if (sourceMode() === "local") {
        return { type: "local", path: $("projectPath").value.trim() };
      }
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

    function validateSourceInput() {
      if (sourceMode() === "local") {
        const path = $("projectPath").value.trim();
        if (!path) throw new Error("Enter a Flutter project path on this machine.");
        return;
      }
      if (!$("gitUrl").value.trim()) {
        throw new Error("Enter a Git repository URL.");
      }
    }

    function envSourceMode() {
      return $("envSourceMode").value;
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
        const val = row.querySelector(".env-kv-val")?.value.trim() ?? "";
        if (key && val) values[key] = val;
      });
      if (Object.keys(values).length === 0) return null;
      return { mode: "session_values", values };
    }

    function fillEnvSelect(data) {
      const sel = $("envSelect");
      sel.innerHTML = "";
      const envs = data.environments || {};
      const keys = Object.keys(envs);
      if (keys.length === 0) {
        const opt = document.createElement("option");
        opt.value = "dev";
        opt.textContent = "dev";
        sel.appendChild(opt);
        return;
      }
      for (const k of keys) {
        const opt = document.createElement("option");
        opt.value = k;
        opt.textContent = k + (envs[k] ? " (" + envs[k] + ")" : "");
        sel.appendChild(opt);
      }
      if (data.default_environment) sel.value = data.default_environment;
    }

    function renderChecks(data) {
      const list = $("checksList");
      list.innerHTML = "";
      for (const c of data.checks || []) {
        const li = document.createElement("li");
        li.className = c.status || "";
        li.textContent = (c.status === "pass" ? "✓ " : c.status === "fail" ? "✗ " : "• ")
          + c.label + (c.detail ? " — " + c.detail : "");
        list.appendChild(li);
      }
      if (data.structure && !data.structure_complete) {
        const li = document.createElement("li");
        li.className = "warn";
        li.textContent = "⚠ Flutter structure incomplete — Setup Studio can repair";
        list.appendChild(li);
      }
    }

    function renderDevices(devices) {
      const list = $("deviceList");
      list.innerHTML = "";
      if (!devices || devices.length === 0) {
        $("noDevices").classList.remove("hidden");
        return;
      }
      $("noDevices").classList.add("hidden");
      for (const d of devices) {
        const div = document.createElement("label");
        div.className = "device-item";
        const cb = document.createElement("input");
        cb.type = "checkbox";
        cb.checked = d.available !== false;
        cb.dataset.id = d.id;
        cb.dataset.platform = d.platform;
        cb.className = "device-cb";
        if (!d.available) cb.disabled = true;
        const span = document.createElement("span");
        span.textContent = d.name + " (" + d.platform
          + (d.is_simulator ? ", simulator" : "")
          + ") — " + d.id;
        div.appendChild(cb);
        div.appendChild(span);
        list.appendChild(div);
      }
    }

    function selectedDeviceIds(platform) {
      return [...document.querySelectorAll(".device-cb:checked")]
        .filter((cb) => !platform || cb.dataset.platform === platform)
        .map((cb) => cb.dataset.id);
    }

    function setRunning(running) {
      $("runBtn").disabled = running;
      $("installAndroidBtn").disabled = running;
      $("installIosBtn").disabled = running;
      $("checkBtn").disabled = running;
      $("cancelBtn").classList.toggle("hidden", !running);
      if (!running) updatePlatformButtons();
    }

    function updatePlatformButtons() {
      const caps = studioEnv.capabilities || {};
      $("installAndroidBtn").disabled = caps.install_android === false;
      const iosOk = studioEnv.macos && caps.install_ios !== false;
      $("installIosBtn").style.display = iosOk ? "" : "none";
      $("installIosBtn").disabled = !iosOk;
    }

    function setStatus(status, label) {
      const pill = $("statusPill");
      pill.className = "status-pill " + status;
      pill.textContent = label || status;
    }

    function appendLogs(lines) {
      const box = $("logBox");
      if (box.textContent === "Waiting…") box.textContent = "";
      for (const line of lines) {
        box.textContent += line + "\n";
      }
      box.scrollTop = box.scrollHeight;
    }

    async function refreshEnvironment() {
      studioEnv = await api("/api/environment");
      const caps = studioEnv.capabilities || {};
      if (!studioEnv.macos) {
        $("testflightRow").classList.add("hidden");
        $("testflightToggle").checked = false;
      }
      updatePlatformButtons();
      const browseBtn = $("browseBtn");
      if (browseBtn) {
        browseBtn.disabled = false;
        browseBtn.title = caps.pick_folder === false
          ? "Folder picker unavailable on this host — type the path manually"
          : "Open folder picker on this machine";
      }
    }

    async function checkRepo() {
      $("errorBanner").classList.remove("visible");
      $("warnBanner").classList.remove("visible");
      $("checkBtn").disabled = true;
      try {
        validateSourceInput();
        const env = $("envSelect").value || "dev";
        const body = { source: quickTestSourcePayload(), env };
        const es = buildEnvSource();
        if (es) body.env_source = es;
        const data = await api("/api/quick-test/preflight", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(body),
        });
        preflightData = data;
        $("afterPreflight").classList.remove("hidden");
        fillEnvSelect(data);
        renderChecks(data);
        renderDevices(data.devices);
        const notes = [];
        if (data.is_plugin && data.build_dir) {
          notes.push(
            "Flutter plugin — builds run from example/ at " + data.build_dir
          );
        }
        if (!data.env_ready) {
          notes.push(
            "No env file found — Quick Test will build without dart-defines. " +
            "Add secrets below only if your app needs them."
          );
        }
        if (notes.length) {
          $("warnBanner").textContent = notes.join(" ");
          $("warnBanner").classList.add("visible");
        }
        if (data.env_help?.suggested_keys?.length) {
          $("envKvRows").innerHTML = "";
          for (const key of data.env_help.suggested_keys) {
            addKvRow(key, "");
          }
        }
      } catch (e) {
        $("errorBanner").textContent = e.message;
        $("errorBanner").classList.add("visible");
      } finally {
        $("checkBtn").disabled = false;
      }
    }

    function addKvRow(key, val) {
      const row = document.createElement("div");
      row.className = "row";
      row.innerHTML =
        '<input class="env-kv-key field" placeholder="KEY" value="' + (key || "") + '" />' +
        '<input class="env-kv-val field" placeholder="value" value="' + (val || "") + '" />';
      $("envKvRows").appendChild(row);
    }

    async function runQuickTest(platform) {
      if (!preflightData) {
        $("errorBanner").textContent = "Run Check project first.";
        $("errorBanner").classList.add("visible");
        return;
      }
      if (platform === "android" && selectedDeviceIds("android").length === 0) {
        $("errorBanner").textContent = "Select at least one Android device.";
        $("errorBanner").classList.add("visible");
        return;
      }
      if (platform === "ios" && selectedDeviceIds("ios").length === 0) {
        $("errorBanner").textContent = "Select at least one iOS device.";
        $("errorBanner").classList.add("visible");
        return;
      }
      $("errorBanner").classList.remove("visible");
      logOffset = 0;
      $("logBox").textContent = "";
      $("artifacts").classList.add("hidden");
      setRunning(true);
      const labels = { all: "Running", android: "Android", ios: "iOS" };
      setStatus("running", labels[platform] || "Running");
      try {
        const body = {
          source: quickTestSourcePayload(),
          env: $("envSelect").value || "dev",
          platform: platform,
          install_to_devices: platform === "all" ? $("installToggle").checked : true,
          include_testflight_ipa: platform === "all" ? $("testflightToggle").checked : false,
          selected_device_ids: selectedDeviceIds(
            platform === "all" ? null : platform
          ),
        };
        const es = buildEnvSource();
        if (es) body.env_source = es;
        await api("/api/quick-test/run", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(body),
        });
        startPolling();
      } catch (e) {
        setStatus("failed", "Error");
        $("errorBanner").textContent = e.message;
        $("errorBanner").classList.add("visible");
        setRunning(false);
      }
    }

    function startPolling() {
      if (pollTimer) clearInterval(pollTimer);
      pollTimer = setInterval(pollStatus, 1200);
      pollStatus();
    }

    async function pollStatus() {
      try {
        const data = await api("/api/quick-test/status?offset=" + logOffset);
        if (data.logs?.length) {
          appendLogs(data.logs);
          logOffset = data.log_total || logOffset + data.logs.length;
        }
        if (data.status === "running") return;
        clearInterval(pollTimer);
        pollTimer = null;
        setRunning(false);
        setStatus(data.status, data.status);
        if (data.artifact_paths?.length) {
          const art = $("artifacts");
          art.classList.remove("hidden");
          art.innerHTML = "<strong>Artifacts:</strong><br>" +
            data.artifact_paths.map((p) => '<span style="color:var(--muted)">' + p + '</span>').join("<br>");
        }
        if (data.error) {
          $("errorBanner").textContent = data.error;
          $("errorBanner").classList.add("visible");
        }
      } catch (e) {
        clearInterval(pollTimer);
        pollTimer = null;
        setRunning(false);
      }
    }

    async function cancelRun() {
      try {
        await api("/api/quick-test/cancel", { method: "POST" });
        setStatus("idle", "Cancelled");
        setRunning(false);
        if (pollTimer) { clearInterval(pollTimer); pollTimer = null; }
      } catch (e) {
        $("errorBanner").textContent = e.message;
        $("errorBanner").classList.add("visible");
      }
    }

    document.querySelectorAll('input[name="sourceMode"]').forEach((el) => {
      el.addEventListener("change", syncSourcePanels);
    });

    $("gitAuth").addEventListener("change", syncSourcePanels);

    $("envSourceMode").addEventListener("change", () => {
      const mode = envSourceMode();
      $("envLocalFile").classList.toggle("hidden", mode !== "local_file");
      $("envPaste").classList.toggle("hidden", mode !== "paste");
      $("envKv").classList.toggle("hidden", mode !== "session_values");
    });

    $("checkBtn").addEventListener("click", checkRepo);
    $("runBtn").addEventListener("click", () => runQuickTest("all"));
    $("installAndroidBtn").addEventListener("click", () => runQuickTest("android"));
    $("installIosBtn").addEventListener("click", () => runQuickTest("ios"));
    $("cancelBtn").addEventListener("click", cancelRun);
    $("addKvBtn").addEventListener("click", () => addKvRow("", ""));
    $("projectPath").addEventListener("keydown", (e) => {
      if (e.key === "Enter") checkRepo();
    });

    async function pickProjectFolder(inputId) {
      const input = document.getElementById(inputId || "projectPath");
      const storageKey = "rtk_studio_project_path";
      const saved = localStorage.getItem(storageKey) || "";
      const initial = (input && input.value ? input.value.trim() : "") || saved;
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
      if (!res.ok) {
        throw new Error(data.error || res.statusText || "Folder picker failed");
      }
      if (data.cancelled) return null;
      if (data.path) {
        if (input) input.value = data.path;
        localStorage.setItem(storageKey, data.path);
        return data.path;
      }
      return null;
    }

    async function browseProjectFolder() {
      $("errorBanner").classList.remove("visible");
      $("warnBanner").classList.remove("visible");
      $("browseBtn").disabled = true;
      try {
        $("warnBanner").textContent =
          "Opening folder picker on this Mac — if you do not see it, check Finder in the Dock (it may be behind Safari).";
        $("warnBanner").classList.add("visible");
        const path = await pickProjectFolder("projectPath");
        $("warnBanner").classList.remove("visible");
        if (path) {
          document.querySelector('input[name="sourceMode"][value="local"]').checked = true;
          syncSourcePanels();
        }
      } catch (e) {
        $("warnBanner").classList.remove("visible");
        $("errorBanner").textContent = e.message;
        $("errorBanner").classList.add("visible");
      } finally {
        $("browseBtn").disabled = false;
      }
    }

    $("browseBtn").addEventListener("click", browseProjectFolder);

    async function bootQuickTest() {
      syncSourcePanels();
      const params = new URLSearchParams(location.search);
      const queryProject = params.get("project");
      if (queryProject) {
        $("projectPath").value = queryProject;
        document.querySelector('input[name="sourceMode"][value="local"]').checked = true;
        syncSourcePanels();
        if (typeof rtkSaveProject === "function") rtkSaveProject(queryProject);
      } else if (typeof rtkSyncProjectInput === "function") {
        const path = await rtkSyncProjectInput();
        if (path) {
          document.querySelector('input[name="sourceMode"][value="local"]').checked = true;
          syncSourcePanels();
        }
      }
      await refreshEnvironment();
    }

    bootQuickTest();
  </script>
</body>
</html>
''';
