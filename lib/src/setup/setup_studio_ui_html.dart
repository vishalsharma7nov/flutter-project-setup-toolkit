/// Embedded single-page UI for Setup Studio.
String setupStudioHtml() => r'''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Setup Studio</title>
  <style>
    :root {
      --bg: #0a0e17;
      --surface: rgba(255,255,255,0.05);
      --surface2: rgba(255,255,255,0.08);
      --border: rgba(255,255,255,0.1);
      --text: #f4f7ff;
      --muted: #8d98b3;
      --accent: #ff7b54;
      --accent2: #ffb26b;
      --teal: #4ecdc4;
      --success: #2ecc71;
      --danger: #ff6b6b;
      --radius: 16px;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: var(--bg);
      color: var(--text);
      min-height: 100vh;
      background-image:
        radial-gradient(ellipse 70% 50% at 10% -5%, rgba(255,123,84,0.28), transparent),
        radial-gradient(ellipse 50% 40% at 95% 5%, rgba(78,205,196,0.18), transparent);
    }
    .wrap { max-width: 960px; margin: 0 auto; padding: 2rem 1.25rem 3rem; }
    header { text-align: center; margin-bottom: 2rem; }
    .badge {
      display: inline-block; font-size: 0.7rem; font-weight: 700; letter-spacing: 0.14em;
      text-transform: uppercase; color: var(--accent2);
      background: rgba(255,178,107,0.12); border: 1px solid rgba(255,178,107,0.35);
      padding: 0.35rem 0.9rem; border-radius: 999px; margin-bottom: 0.85rem;
    }
    h1 {
      font-size: clamp(1.9rem, 4.5vw, 2.6rem); font-weight: 700; letter-spacing: -0.03em;
      background: linear-gradient(135deg, #fff 20%, var(--accent2) 100%);
      -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text;
    }
    .subtitle { color: var(--muted); margin-top: 0.5rem; }
    .steps {
      display: flex; gap: 0.35rem; margin-bottom: 1.5rem; flex-wrap: wrap; justify-content: center;
    }
    .step-dot {
      display: flex; align-items: center; gap: 0.45rem; font-size: 0.78rem; color: var(--muted);
      padding: 0.45rem 0.75rem; border-radius: 999px; border: 1px solid transparent;
    }
    .step-dot.active { color: var(--text); background: var(--surface2); border-color: var(--border); }
    .step-dot.done { color: var(--teal); }
    .panel {
      background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius);
      padding: 1.5rem; margin-bottom: 1rem; backdrop-filter: blur(16px);
    }
    .panel h2 { font-size: 1.05rem; margin-bottom: 1rem; }
    .panel p.hint { font-size: 0.88rem; color: var(--muted); margin-bottom: 1rem; line-height: 1.5; }
    label { display: block; font-size: 0.78rem; color: var(--muted); margin-bottom: 0.35rem; }
    input, select, textarea {
      width: 100%; background: rgba(0,0,0,0.35); border: 1px solid var(--border);
      color: var(--text); padding: 0.7rem 0.9rem; border-radius: 10px; font-size: 0.92rem;
      outline: none; font-family: inherit;
    }
    input:focus, select:focus, textarea:focus { border-color: var(--accent); }
    .grid2 { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
    @media (max-width: 640px) { .grid2 { grid-template-columns: 1fr; } }
    .field { margin-bottom: 1rem; }
    .row { display: flex; gap: 0.75rem; flex-wrap: wrap; align-items: flex-end; }
    .choice {
      flex: 1; min-width: 140px; padding: 0.9rem; border-radius: 12px; border: 1px solid var(--border);
      background: rgba(0,0,0,0.2); cursor: pointer; transition: 0.15s;
    }
    .choice:hover { border-color: var(--accent); }
    .choice.selected { border-color: var(--accent); background: rgba(255,123,84,0.12); }
    .choice strong { display: block; font-size: 0.9rem; margin-bottom: 0.25rem; }
    .choice span { font-size: 0.78rem; color: var(--muted); }
    .env-table { width: 100%; border-collapse: collapse; font-size: 0.85rem; margin-top: 0.5rem; }
    .env-table th { text-align: left; color: var(--muted); font-weight: 600; padding: 0.5rem; border-bottom: 1px solid var(--border); }
    .env-table td { padding: 0.45rem 0.5rem; border-bottom: 1px solid rgba(255,255,255,0.04); }
    .env-table input { padding: 0.45rem 0.6rem; font-size: 0.82rem; }
    .toggle { display: flex; align-items: center; gap: 0.6rem; margin-bottom: 0.75rem; font-size: 0.9rem; }
    .toggle input { width: auto; accent-color: var(--accent); }
    .nav { display: flex; justify-content: space-between; gap: 1rem; margin-top: 1rem; }
    button {
      font-family: inherit; font-size: 0.92rem; font-weight: 600; border: none; border-radius: 11px;
      padding: 0.75rem 1.35rem; cursor: pointer; transition: 0.15s;
    }
    button:disabled { opacity: 0.4; cursor: not-allowed; }
    .btn-primary { background: linear-gradient(135deg, var(--accent), var(--accent2)); color: #1a1020; }
    .btn-teal { background: linear-gradient(135deg, var(--teal), #7ee8e2); color: #0a1a18; }
    .btn-ghost { background: transparent; color: var(--muted); border: 1px solid var(--border); }
    .hidden { display: none !important; }
    .alert {
      padding: 0.85rem 1rem; border-radius: 10px; font-size: 0.88rem; margin-bottom: 1rem;
      background: rgba(255,107,107,0.12); border: 1px solid rgba(255,107,107,0.35); color: #ffc9c9;
    }
    .alert.info { background: rgba(78,205,196,0.1); border-color: rgba(78,205,196,0.35); color: #b8f0ec; }
    .alert.warn { background: rgba(255,178,107,0.12); border-color: rgba(255,178,107,0.35); color: #ffe0c0; }
    .preview-box {
      background: #060a12; border: 1px solid var(--border); border-radius: 12px;
      padding: 1rem; font-family: "SF Mono", Menlo, monospace; font-size: 0.75rem;
      max-height: 220px; overflow: auto; white-space: pre-wrap; color: #b8c4e8;
    }
    .terminal {
      background: #050810; border: 1px solid var(--border); border-radius: var(--radius);
      min-height: 200px; max-height: 320px; overflow-y: auto;
      font-family: "SF Mono", Menlo, monospace; font-size: 0.76rem; line-height: 1.5;
      padding: 1rem; color: #c8d3f5; white-space: pre-wrap;
    }
    .status-pill {
      display: inline-flex; align-items: center; gap: 0.4rem; font-size: 0.8rem; font-weight: 600;
      padding: 0.35rem 0.8rem; border-radius: 999px; background: var(--surface2); border: 1px solid var(--border);
    }
    .status-pill .dot { width: 7px; height: 7px; border-radius: 50%; background: var(--muted); }
    .status-pill.running .dot { background: var(--teal); animation: pulse 1s infinite; }
    .status-pill.succeeded .dot { background: var(--success); }
    .status-pill.failed .dot { background: var(--danger); }
    @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.35} }
    .result-list { font-size: 0.88rem; color: var(--muted); margin-top: 0.75rem; }
    .result-list li { margin: 0.35rem 0; }
  </style>
</head>
<body>
  <div class="wrap">
    <header>
      <div class="badge">Flutter Project Setup Toolkit</div>
      <h1>Setup Studio</h1>
      <p class="subtitle">Configure env files, version keys, scripts &amp; toolkit — visually.</p>
    </header>

    <div class="steps" id="stepBar"></div>
    <div id="alertBox" class="alert hidden"></div>

    <!-- Step 0: Project -->
    <section class="panel step-panel" data-step="0">
      <h2>Flutter project</h2>
      <p class="hint">Point at your app root (folder with <code>pubspec.yaml</code>).</p>
      <div class="field">
        <label for="projectPath">Project path</label>
        <input id="projectPath" type="text" placeholder="/path/to/your/flutter/app" />
      </div>
      <div class="nav">
        <span></span>
        <button type="button" class="btn-primary" id="loadProjectBtn">Load project</button>
      </div>
    </section>

    <!-- Step 1: Environments -->
    <section class="panel step-panel hidden" data-step="1">
      <h2>Environments</h2>
      <p class="hint">Choose which env files to scaffold and where they live.</p>
      <div class="field">
        <label>Preset</label>
        <div class="row" id="envPresetChoices">
          <div class="choice selected" data-preset="dev-prod"><strong>dev + prod</strong><span>Typical two-env setup</span></div>
          <div class="choice" data-preset="dev-staging-prod"><strong>dev + staging + prod</strong><span>Three environments</span></div>
          <div class="choice" data-preset="custom"><strong>Custom names</strong><span>Comma-separated list</span></div>
        </div>
      </div>
      <div class="field hidden" id="customNamesField">
        <label for="customEnvNames">Custom environment names</label>
        <input id="customEnvNames" type="text" value="dev,prod" />
      </div>
      <div class="field">
        <label>Env file directory</label>
        <div class="row" id="envDirChoices">
          <div class="choice selected" data-style="dotEnv"><strong>.env/</strong><span>Recommended</span></div>
          <div class="choice" data-style="dotSecrets"><strong>.secrets/</strong><span>Gitignored secrets</span></div>
          <div class="choice" data-style="custom"><strong>Custom</strong><span>Your own prefix</span></div>
        </div>
      </div>
      <div class="field hidden" id="customPrefixField">
        <label for="envCustomPrefix">Directory prefix</label>
        <input id="envCustomPrefix" type="text" value="config/env" />
      </div>
      <table class="env-table" id="envTable">
        <thead><tr><th>Environment</th><th>File path</th></tr></thead>
        <tbody></tbody>
      </table>
      <div class="nav">
        <button type="button" class="btn-ghost nav-back">Back</button>
        <button type="button" class="btn-primary nav-next">Next</button>
      </div>
    </section>

    <!-- Step 2: Version & flavors -->
    <section class="panel step-panel hidden" data-step="2">
      <h2>Versions &amp; flavors</h2>
      <div class="field">
        <label for="defaultEnv">Default working environment</label>
        <select id="defaultEnv"></select>
      </div>
      <label class="toggle"><input type="checkbox" id="useDefaultVersionKeys" checked /> Use default version key names (APP_VERSION_NAME, etc.)</label>
      <div class="grid2 hidden" id="versionKeysGrid">
        <div class="field"><label>Android name key</label><input id="vkAndroidName" value="APP_VERSION_NAME" /></div>
        <div class="field"><label>Android code key</label><input id="vkAndroidCode" value="APP_VERSION_CODE" /></div>
        <div class="field"><label>iOS marketing key</label><input id="vkIosMarketing" value="BUNDLE_VERSION_STRING" /></div>
        <div class="field"><label>iOS build key</label><input id="vkIosBuild" value="BUNDLE_VERSION" /></div>
      </div>
      <div class="grid2">
        <div class="field"><label for="iosFlavor">iOS flavor (optional)</label><input id="iosFlavor" placeholder="e.g. staging" /></div>
        <div class="field"><label for="androidFlavor">Android flavor (optional)</label><input id="androidFlavor" placeholder="e.g. staging" /></div>
      </div>
      <div id="mainDartRulesBox" class="hidden">
        <label class="toggle"><input type="checkbox" id="includeMainDartRules" checked /> Add detected <code>main.dart</code> env rules to config</label>
        <div class="preview-box" id="mainDartRulesPreview"></div>
      </div>
      <div class="nav">
        <button type="button" class="btn-ghost nav-back">Back</button>
        <button type="button" class="btn-primary nav-next">Next</button>
      </div>
    </section>

    <!-- Step 3: Toolkit -->
    <section class="panel step-panel hidden" data-step="3">
      <h2>Toolkit &amp; scaffolding</h2>
      <div class="field">
        <label>How will you run the toolkit?</label>
        <div class="row" id="toolkitChoices">
          <div class="choice selected" data-mode="devDependency"><strong>Dev dependency</strong><span>dart pub add (recommended)</span></div>
          <div class="choice" data-mode="localClone"><strong>Local clone</strong><span>Path to toolkit repo</span></div>
          <div class="choice" data-mode="globalCli"><strong>Pub global</strong><span>dart pub global activate</span></div>
        </div>
      </div>
      <div class="field hidden" id="localToolkitField">
        <label for="localToolkitPath">Path to flutter-project-setup-toolkit</label>
        <input id="localToolkitPath" type="text" value="../flutter-project-setup-toolkit" />
      </div>
      <div class="field">
        <label for="architecturePreset">Architecture preset</label>
        <select id="architecturePreset"></select>
      </div>
      <div class="field">
        <label for="apiProtocol">API protocol</label>
        <select id="apiProtocol"></select>
      </div>
      <div class="hidden" id="externalSdkFields">
        <div class="field"><label for="externalSdkPackage">External SDK package name</label><input id="externalSdkPackage" placeholder="vendor_sdk" /></div>
        <div class="field"><label for="externalSdkGitUrl">Git repository URL</label><input id="externalSdkGitUrl" placeholder="https://github.com/org/sdk.git" /></div>
        <div class="grid2">
          <div class="field"><label for="externalSdkGitRef">Git ref (optional)</label><input id="externalSdkGitRef" placeholder="main" /></div>
          <div class="field"><label for="externalSdkGitPath">Package path in repo (optional)</label><input id="externalSdkGitPath" placeholder="lib" /></div>
        </div>
      </div>
      <div class="hidden" id="customTemplateFields">
        <div class="field">
          <label for="customTemplatePath">Custom template JSON path</label>
          <input id="customTemplatePath" placeholder="templates/architecture/custom_feature.example.json" />
          <p style="font-size:0.78rem;color:var(--muted);margin-top:0.35rem">
            Mason-style template with <code>{{feature}}</code>, <code>{{prefix}}</code>, <code>{{Prefix}}</code> variables.
          </p>
        </div>
      </div>
      <div class="field">
        <label>Core modules (optional stubs under <code>lib/core/</code>)</label>
        <div class="row" style="flex-wrap:wrap;gap:0.5rem 1.25rem">
          <label class="toggle"><input type="checkbox" id="coreModulesErrors" /> Errors (failures/exceptions)</label>
          <label class="toggle"><input type="checkbox" id="coreModulesLogging" /> Logging</label>
          <label class="toggle"><input type="checkbox" id="coreModulesTheme" /> Theme</label>
          <label class="toggle"><input type="checkbox" id="coreModulesConnectivity" /> Connectivity</label>
        </div>
      </div>
      <div class="field">
        <label>Bootstrap extras</label>
        <label class="toggle"><input type="checkbox" id="bootstrapFlavorMains" /> Flavor entrypoints (<code>main_&lt;env&gt;.dart</code>)</label>
        <label class="toggle"><input type="checkbox" id="bootstrapScaffoldTestMirror" /> Mirror feature tests under <code>test/</code></label>
      </div>
      <div class="field">
        <select id="stateManagement">
          <option value="none">none</option>
          <option value="bloc">bloc</option>
          <option value="riverpod">riverpod</option>
          <option value="provider">provider</option>
          <option value="getx">getx</option>
        </select>
      </div>
      <label class="toggle"><input type="checkbox" id="createEnvTemplates" checked /> Create env file templates</label>
      <label class="toggle"><input type="checkbox" id="createScripts" checked /> Create scripts/ wrappers</label>
      <label class="toggle"><input type="checkbox" id="scaffoldFeature" /> Scaffold a feature to start with</label>
      <div class="grid2 hidden" id="featureFields">
        <div class="field"><label for="featureName">Feature name</label><input id="featureName" placeholder="authentication" /></div>
        <div class="field"><label for="featureBasePath">Base path</label><input id="featureBasePath" value="lib/features" /></div>
      </div>
      <div class="nav">
        <button type="button" class="btn-ghost nav-back">Back</button>
        <button type="button" class="btn-primary nav-next">Review</button>
      </div>
    </section>

    <!-- Step 4: Review -->
    <section class="panel step-panel hidden" data-step="4">
      <h2>Review &amp; apply</h2>
      <div id="existingConfigWarn" class="alert warn hidden">release-toolkit.config.json already exists — enable <strong>Force overwrite</strong> to replace it.</div>
      <div id="compatibilityWarn" class="alert warn hidden"></div>
      <div class="preview-box" id="reviewPreview">Loading preview…</div>
      <label class="toggle" style="margin-top:1rem"><input type="checkbox" id="forceOverwrite" /> Force overwrite existing config/scripts</label>
      <label class="toggle"><input type="checkbox" id="dryRun" /> Dry run (preview only, no writes)</label>
      <div class="nav" style="align-items:center">
        <button type="button" class="btn-ghost nav-back">Back</button>
        <div style="display:flex;gap:0.75rem;align-items:center">
          <span class="status-pill" id="statusPill"><span class="dot"></span><span id="statusText">Ready</span></span>
          <button type="button" class="btn-teal" id="applyBtn">Apply setup</button>
        </div>
      </div>
      <div class="terminal hidden" id="terminal"></div>
      <ul class="result-list hidden" id="resultList"></ul>
    </section>
  </div>

  <script>
    const $ = (id) => document.getElementById(id);
    const stepLabels = ["Project", "Environments", "Versions", "Toolkit", "Review"];
    let currentStep = 0;
    let projectData = null;
    let logOffset = 0;
    let pollTimer = null;

    const state = {
      env_preset: "dev-prod",
      custom_env_names: "dev,prod",
      env_dir_style: "dotEnv",
      env_custom_prefix: "config/env",
      environments: {},
      toolkit_mode: "devDependency",
      local_toolkit_path: "../flutter-project-setup-toolkit",
      main_dart_rules: [],
    };

    function showAlert(msg, type) {
      const box = $("alertBox");
      box.textContent = msg;
      box.className = "alert" + (type ? " " + type : "");
      box.classList.remove("hidden");
    }
    function hideAlert() { $("alertBox").classList.add("hidden"); }

    function renderStepBar() {
      $("stepBar").innerHTML = stepLabels.map((label, i) =>
        `<div class="step-dot ${i === currentStep ? "active" : ""} ${i < currentStep ? "done" : ""}">${i + 1}. ${label}</div>`
      ).join("");
      document.querySelectorAll(".step-panel").forEach((el) => {
        el.classList.toggle("hidden", Number(el.dataset.step) !== currentStep);
      });
    }

    function goStep(n) {
      currentStep = Math.max(0, Math.min(stepLabels.length - 1, n));
      renderStepBar();
      hideAlert();
      if (currentStep === 4) refreshPreview();
    }

    async function api(path, opts) {
      const res = await fetch(path, opts);
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || res.statusText);
      return data;
    }

    function wireChoices(containerId, key, dataAttr) {
      document.querySelectorAll(`#${containerId} .choice`).forEach((el) => {
        el.addEventListener("click", () => {
          document.querySelectorAll(`#${containerId} .choice`).forEach((c) => c.classList.remove("selected"));
          el.classList.add("selected");
          state[key] = el.dataset[dataAttr];
          if (key === "env_preset") {
            $("customNamesField").classList.toggle("hidden", state.env_preset !== "custom");
          }
          if (key === "env_dir_style") {
            $("customPrefixField").classList.toggle("hidden", state.env_dir_style !== "custom");
          }
          if (key === "toolkit_mode") {
            $("localToolkitField").classList.toggle("hidden", state.toolkit_mode !== "localClone");
          }
          if (key === "env_preset" || key === "env_dir_style") refreshEnvPaths();
        });
      });
    }

    async function refreshEnvPaths() {
      const data = await api("/api/env-paths", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          env_preset: state.env_preset,
          custom_env_names: $("customEnvNames").value,
          env_dir_style: state.env_dir_style,
          env_custom_prefix: $("envCustomPrefix").value,
        }),
      });
      state.environments = data.environments;
      const tbody = $("envTable").querySelector("tbody");
      tbody.innerHTML = "";
      const defaultSelect = $("defaultEnv");
      defaultSelect.innerHTML = "";
      for (const [name, path] of Object.entries(data.environments)) {
        const tr = document.createElement("tr");
        tr.innerHTML = `<td>${name}</td><td><input data-env="${name}" value="${path}" /></td>`;
        tbody.appendChild(tr);
        const opt = document.createElement("option");
        opt.value = name;
        opt.textContent = name;
        if (name === "dev") opt.selected = true;
        defaultSelect.appendChild(opt);
      }
      tbody.querySelectorAll("input").forEach((input) => {
        input.addEventListener("change", () => {
          state.environments[input.dataset.env] = input.value;
        });
      });
    }

    function syncCustomTemplatePanel() {
      $("customTemplateFields").classList.toggle(
        "hidden",
        $("architecturePreset").value !== "custom",
      );
    }

    function syncExternalSdkPanel() {
      $("externalSdkFields").classList.toggle(
        "hidden",
        $("apiProtocol").value !== "external_sdk",
      );
    }

    function populateArchitectureApiOptions(data) {
      const archSelect = $("architecturePreset");
      archSelect.innerHTML = "";
      const groups = data.architecture_option_groups;
      if (groups?.length) {
        groups.forEach((group) => {
          const og = document.createElement("optgroup");
          og.label = group.label;
          (group.options || []).forEach((opt) => {
            const o = document.createElement("option");
            o.value = opt.id;
            o.textContent = opt.label || opt.id;
            og.appendChild(o);
          });
          archSelect.appendChild(og);
        });
      } else {
        (data.architecture_options || []).forEach((opt) => {
          const id = typeof opt === "string" ? opt : opt.id;
          const label = typeof opt === "string" ? opt : opt.label;
          const o = document.createElement("option");
          o.value = id;
          o.textContent = label || id;
          archSelect.appendChild(o);
        });
      }
      archSelect.value = data.architecture || data.default_architecture || "feature_first_clean";
      syncCustomTemplatePanel();

      const apiSelect = $("apiProtocol");
      apiSelect.innerHTML = "";
      (data.api_protocol_options || []).forEach((id) => {
        const o = document.createElement("option");
        o.value = id;
        o.textContent = id;
        apiSelect.appendChild(o);
      });
      apiSelect.value = data.api_protocol || data.default_api_protocol || "rest";
      syncExternalSdkPanel();

      if (data.external_sdk?.git?.url) {
        $("externalSdkPackage").value = data.external_sdk.package_name || "";
        $("externalSdkGitUrl").value = data.external_sdk.git.url || "";
        $("externalSdkGitRef").value = data.external_sdk.git.ref || "";
        $("externalSdkGitPath").value = data.external_sdk.git.path || "";
      }
      if (data.custom_template_path) {
        $("customTemplatePath").value = data.custom_template_path;
      }
      if (data.feature_base_path) $("featureBasePath").value = data.feature_base_path;
      if (data.state_management) $("stateManagement").value = data.state_management;
    }

    function collectPlanPayload() {
      const envs = {};
      $("envTable").querySelectorAll("input[data-env]").forEach((input) => {
        envs[input.dataset.env] = input.value;
      });
      const useDefaultKeys = $("useDefaultVersionKeys").checked;
      return {
        project: $("projectPath").value.trim(),
        env_preset: state.env_preset,
        custom_env_names: $("customEnvNames").value,
        env_dir_style: state.env_dir_style,
        env_custom_prefix: $("envCustomPrefix").value,
        environments: envs,
        default_environment: $("defaultEnv").value,
        use_default_version_keys: useDefaultKeys,
        version_keys: useDefaultKeys ? undefined : {
          android_name: $("vkAndroidName").value,
          android_code: $("vkAndroidCode").value,
          ios_marketing: $("vkIosMarketing").value,
          ios_build: $("vkIosBuild").value,
        },
        ios_flavor: $("iosFlavor").value,
        android_flavor: $("androidFlavor").value,
        include_main_dart_rules: $("includeMainDartRules").checked,
        main_dart_rules: state.main_dart_rules,
        toolkit_mode: state.toolkit_mode,
        local_toolkit_path: $("localToolkitPath").value,
        create_env_templates: $("createEnvTemplates").checked,
        create_scripts: $("createScripts").checked,
        state_management: $("stateManagement").value,
        feature_to_scaffold: $("scaffoldFeature").checked ? $("featureName").value : null,
        feature_base_path: $("featureBasePath").value,
        architecture_preset: $("architecturePreset").value,
        custom_template_path: $("architecturePreset").value === "custom"
          ? $("customTemplatePath").value
          : undefined,
        core_modules_errors: $("coreModulesErrors").checked,
        core_modules_logging: $("coreModulesLogging").checked,
        core_modules_theme: $("coreModulesTheme").checked,
        core_modules_connectivity: $("coreModulesConnectivity").checked,
        bootstrap_flavor_mains: $("bootstrapFlavorMains").checked,
        bootstrap_scaffold_test_mirror: $("bootstrapScaffoldTestMirror").checked,
        api_protocol: $("apiProtocol").value,
        external_sdk: $("apiProtocol").value === "external_sdk" ? {
          package_name: $("externalSdkPackage").value || "external_sdk",
          source: "git",
          git: {
            url: $("externalSdkGitUrl").value,
            ref: $("externalSdkGitRef").value || null,
            path: $("externalSdkGitPath").value || null,
          },
        } : undefined,
      };
    }

    async function loadProject() {
      const path = $("projectPath").value.trim();
      if (!path) return showAlert("Enter a project path");
      $("loadProjectBtn").disabled = true;
      try {
        projectData = await api("/api/detect?path=" + encodeURIComponent(path));
        populateArchitectureApiOptions(projectData);
        state.main_dart_rules = projectData.main_dart_rules || [];
        state.local_toolkit_path = projectData.suggested_local_toolkit_path;
        $("localToolkitPath").value = state.local_toolkit_path;
        if (projectData.has_existing_config) {
          showAlert("Existing release-toolkit.config.json found — you can force overwrite on the review step.", "warn");
        }
        if (state.main_dart_rules.length) {
          $("mainDartRulesBox").classList.remove("hidden");
          $("mainDartRulesPreview").textContent = state.main_dart_rules
            .map((r) => `"${r.match}" -> ${r.environment}`).join("\n");
        }
        await refreshEnvPaths();
        goStep(1);
      } catch (e) {
        showAlert(e.message);
      } finally {
        $("loadProjectBtn").disabled = false;
      }
    }

    async function refreshPreview() {
      try {
        const preview = await api("/api/preview", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(collectPlanPayload()),
        });
        $("reviewPreview").textContent = JSON.stringify(preview, null, 2);
        $("existingConfigWarn").classList.toggle("hidden", preview.config.action !== "skip_without_force");
        const compat = $("compatibilityWarn");
        if (preview.compatibility_warning) {
          compat.textContent = preview.compatibility_warning;
          compat.classList.remove("hidden");
        } else {
          compat.classList.add("hidden");
        }
      } catch (e) {
        $("reviewPreview").textContent = "Preview error: " + e.message;
      }
    }

    function setStatus(status, text) {
      const pill = $("statusPill");
      pill.className = "status-pill" + (status && status !== "idle" ? " " + status : "");
      $("statusText").textContent = text || status || "Ready";
    }

    function appendLogs(lines) {
      const term = $("terminal");
      term.classList.remove("hidden");
      if (!lines.length) return;
      term.textContent += lines.join("\n") + "\n";
      term.scrollTop = term.scrollHeight;
    }

    function startPolling() {
      if (pollTimer) clearInterval(pollTimer);
      pollTimer = setInterval(pollStatus, 700);
    }

    async function pollStatus() {
      try {
        const data = await api("/api/apply/status?offset=" + logOffset);
        if (data.logs?.length) {
          appendLogs(data.logs);
          logOffset = data.log_total;
        }
        if (data.status === "running") {
          setStatus("running", "Applying…");
          $("applyBtn").disabled = true;
        } else if (data.status === "succeeded") {
          setStatus("succeeded", "Done");
          clearInterval(pollTimer);
          $("applyBtn").disabled = false;
          if (data.result) {
            const list = $("resultList");
            list.classList.remove("hidden");
            list.innerHTML = (data.result.next_steps || []).map((s) => `<li>${s}</li>`).join("");
          }
        } else if (data.status === "failed") {
          setStatus("failed", "Failed");
          clearInterval(pollTimer);
          $("applyBtn").disabled = false;
          showAlert(data.error || "Setup failed");
        }
      } catch (_) {}
    }

    async function applySetup() {
      logOffset = 0;
      $("terminal").textContent = "";
      $("resultList").classList.add("hidden");
      hideAlert();
      setStatus("running", "Starting…");
      $("applyBtn").disabled = true;
      try {
        const payload = {
          ...collectPlanPayload(),
          force: $("forceOverwrite").checked,
          dry_run: $("dryRun").checked,
        };
        await api("/api/apply", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });
        startPolling();
      } catch (e) {
        setStatus("failed", "Error");
        showAlert(e.message);
        $("applyBtn").disabled = false;
      }
    }

    document.querySelectorAll(".nav-back").forEach((btn) => btn.addEventListener("click", () => goStep(currentStep - 1)));
    document.querySelectorAll(".nav-next").forEach((btn) => btn.addEventListener("click", () => goStep(currentStep + 1)));
    $("loadProjectBtn").addEventListener("click", loadProject);
    $("projectPath").addEventListener("keydown", (e) => { if (e.key === "Enter") loadProject(); });
    $("applyBtn").addEventListener("click", applySetup);
    $("useDefaultVersionKeys").addEventListener("change", (e) => {
      $("versionKeysGrid").classList.toggle("hidden", e.target.checked);
    });
    $("scaffoldFeature").addEventListener("change", (e) => {
      $("featureFields").classList.toggle("hidden", !e.target.checked);
    });
    $("apiProtocol").addEventListener("change", syncExternalSdkPanel);
    $("architecturePreset").addEventListener("change", syncCustomTemplatePanel);
    $("customEnvNames").addEventListener("change", refreshEnvPaths);
    $("envCustomPrefix").addEventListener("change", refreshEnvPaths);

    wireChoices("envPresetChoices", "env_preset", "preset");
    wireChoices("envDirChoices", "env_dir_style", "style");
    wireChoices("toolkitChoices", "toolkit_mode", "mode");
    renderStepBar();

    (async () => {
      try {
        const boot = await api("/api/bootstrap");
        if (boot.project_path) {
          $("projectPath").value = boot.project_path;
        }
      } catch (_) {}
    })();
  </script>
</body>
</html>
''';
