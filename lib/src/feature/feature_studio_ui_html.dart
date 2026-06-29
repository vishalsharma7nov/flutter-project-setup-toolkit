/// Feature Studio page HTML.
String featureStudioHtml() => r'''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Feature Studio</title>
  <style>
    :root {
      --bg: #0a0e17; --surface: rgba(255,255,255,0.06); --border: rgba(255,255,255,0.1);
      --text: #f4f7ff; --muted: #8d98b3; --accent: #a29bfe; --teal: #4ecdc4;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: var(--bg); color: var(--text); min-height: 100vh;
      background-image: radial-gradient(ellipse 60% 40% at 80% 0%, rgba(162,155,254,0.2), transparent);
    }
    .wrap { max-width: 900px; margin: 0 auto; padding: 1.5rem; }
    h1 { font-size: 1.75rem; margin-bottom: 0.35rem; }
    .subtitle { color: var(--muted); margin-bottom: 1.25rem; }
    .panel { background: var(--surface); border: 1px solid var(--border); border-radius: 14px; padding: 1.25rem; margin-bottom: 1rem; }
    label { display: block; font-size: 0.78rem; color: var(--muted); margin-bottom: 0.35rem; }
    input, select {
      width: 100%; background: rgba(0,0,0,0.35); border: 1px solid var(--border);
      color: var(--text); padding: 0.7rem; border-radius: 10px; margin-bottom: 0.85rem;
    }
    .grid2 { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
    button {
      font-weight: 600; border: none; border-radius: 10px; padding: 0.75rem 1.25rem; cursor: pointer;
      background: linear-gradient(135deg, var(--accent), #6c5ce7); color: #fff;
    }
    button:disabled { opacity: 0.45; cursor: not-allowed; }
    .preview { font-family: Menlo, monospace; font-size: 0.78rem; background: #050810; border: 1px solid var(--border);
      border-radius: 10px; padding: 1rem; max-height: 220px; overflow: auto; white-space: pre-wrap; color: #b8c4e8; }
    .terminal { font-family: Menlo, monospace; font-size: 0.76rem; background: #050810; border: 1px solid var(--border);
      border-radius: 10px; padding: 1rem; min-height: 160px; max-height: 280px; overflow: auto; white-space: pre-wrap; }
    .alert { background: rgba(255,107,107,0.12); border: 1px solid rgba(255,107,107,0.35); color: #ffc9c9;
      padding: 0.75rem; border-radius: 10px; margin-bottom: 1rem; display: none; }
    .alert.visible { display: block; }
    .toggle { display: flex; align-items: center; gap: 0.5rem; margin-bottom: 1rem; font-size: 0.9rem; }
    .toggle input { width: auto; margin: 0; }
    .hidden { display: none !important; }
    button.secondary { background: transparent; border: 1px solid var(--border); color: var(--muted); }
  </style>
</head>
<body>
  <div class="wrap">
    <h1>Feature Studio</h1>
    <p class="subtitle">Scaffold feature folders using your project architecture preset and API protocol.</p>
    <div id="alert" class="alert"></div>
    <div class="panel">
      <label>Project path</label>
      <input id="projectPath" type="text" placeholder="/path/to/flutter/app" />
      <div class="grid2">
        <div>
          <label>Feature name</label>
          <input id="featureName" placeholder="authentication" />
        </div>
        <div>
          <label>Base path</label>
          <input id="basePath" value="lib/features" />
        </div>
      </div>
      <div class="grid2">
        <div>
          <label>Architecture preset</label>
          <select id="architecturePreset"></select>
        </div>
        <div>
          <label>API protocol</label>
          <select id="apiProtocol"></select>
        </div>
      </div>
      <div class="hidden" id="externalSdkFields">
        <div class="field"><label for="externalSdkPackage">External SDK package name</label><input id="externalSdkPackage" placeholder="vendor_sdk" /></div>
        <div class="field"><label for="externalSdkGitUrl">Git repository URL</label><input id="externalSdkGitUrl" placeholder="https://github.com/org/sdk.git" /></div>
        <div class="grid2">
          <div><label for="externalSdkGitRef">Git ref (optional)</label><input id="externalSdkGitRef" placeholder="main" /></div>
          <div><label for="externalSdkGitPath">Package path in repo (optional)</label><input id="externalSdkGitPath" placeholder="lib" /></div>
        </div>
      </div>
      <div class="hidden" id="customTemplateFields">
        <label for="customTemplatePath">Custom template JSON path</label>
        <input id="customTemplatePath" placeholder="templates/architecture/custom_feature.example.json" />
      </div>
      <label>State management</label>
      <select id="stateManagement">
        <option value="none">none</option>
        <option value="bloc">bloc</option>
        <option value="riverpod">riverpod</option>
        <option value="provider">provider</option>
        <option value="getx">getx</option>
      </select>
      <label class="toggle"><input type="checkbox" id="dryRun" /> Dry run (preview only)</label>
      <div class="preview" id="preview">Enter a feature name to preview files…</div>
      <div style="margin-top:1rem;display:flex;gap:0.75rem;align-items:center;flex-wrap:wrap">
        <button type="button" id="scaffoldBtn">Scaffold feature</button>
        <button type="button" id="saveDefaultsBtn" class="secondary">Save as project default</button>
        <span id="statusText" style="color:var(--muted);font-size:0.85rem">Ready</span>
      </div>
    </div>
    <div class="panel">
      <label>Output</label>
      <div class="terminal" id="terminal"></div>
    </div>
  </div>
  <script>
    const $ = (id) => document.getElementById(id);
    let logOffset = 0, pollTimer = null, projectData = null;

    async function api(path, opts) {
      const res = await fetch(path, opts);
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || res.statusText);
      return data;
    }

    function showAlert(msg) {
      $("alert").textContent = msg;
      $("alert").classList.add("visible");
    }

    function populateSelect(selectId, options, selected, groups) {
      const sel = $(selectId);
      sel.innerHTML = "";
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
          sel.appendChild(og);
        });
      } else {
        (options || []).forEach((opt) => {
          const id = typeof opt === "string" ? opt : opt.id;
          const label = typeof opt === "string" ? opt : (opt.label || opt.id);
          const o = document.createElement("option");
          o.value = id;
          o.textContent = label;
          sel.appendChild(o);
        });
      }
      if (selected) sel.value = selected;
    }

    function syncCustomTemplatePanel() {
      $("customTemplateFields").classList.toggle(
        "hidden",
        $("architecturePreset").value !== "custom",
      );
    }

    function scaffoldPayload() {
      const payload = {
        project: $("projectPath").value.trim(),
        feature: $("featureName").value.trim(),
        base_path: $("basePath").value,
        state_management: $("stateManagement").value,
        architecture_preset: $("architecturePreset").value,
        api_protocol: $("apiProtocol").value,
      };
      if ($("architecturePreset").value === "custom") {
        payload.custom_template_path = $("customTemplatePath").value.trim();
      }
      if ($("apiProtocol").value === "external_sdk") {
        payload.external_sdk = {
          package_name: $("externalSdkPackage").value || "external_sdk",
          source: "git",
          git: {
            url: $("externalSdkGitUrl").value,
            ref: $("externalSdkGitRef").value || null,
            path: $("externalSdkGitPath").value || null,
          },
        };
      }
      return payload;
    }

    function syncExternalSdkPanel() {
      $("externalSdkFields").classList.toggle(
        "hidden",
        $("apiProtocol").value !== "external_sdk",
      );
    }

    async function loadProject() {
      const path = $("projectPath").value.trim();
      if (!path) return;
      projectData = await api("/api/feature/detect?path=" + encodeURIComponent(path));
      $("stateManagement").value = projectData.state_management || "none";
      populateSelect(
        "architecturePreset",
        projectData.architecture_options || [],
        projectData.architecture,
        projectData.architecture_option_groups,
      );
      populateSelect(
        "apiProtocol",
        (projectData.api_protocol_options || []).map((id) => ({ id, label: id })),
        projectData.api_protocol,
      );
      if (projectData.external_sdk?.git?.url) {
        $("externalSdkPackage").value = projectData.external_sdk.package_name || "";
        $("externalSdkGitUrl").value = projectData.external_sdk.git.url || "";
        $("externalSdkGitRef").value = projectData.external_sdk.git.ref || "";
        $("externalSdkGitPath").value = projectData.external_sdk.git.path || "";
      }
      syncExternalSdkPanel();
      syncCustomTemplatePanel();
      if (projectData.custom_template_path) {
        $("customTemplatePath").value = projectData.custom_template_path;
      }
      if (projectData.default_base_path) $("basePath").value = projectData.default_base_path;
      await refreshPreview();
    }

    async function refreshPreview() {
      const payload = scaffoldPayload();
      if (!payload.project || !payload.feature) return;
      try {
        const data = await api("/api/feature/preview", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });
        $("preview").textContent = data.files.join("\n");
        $("alert").classList.remove("visible");
        if (data.already_exists) showAlert("Feature folder already exists — scaffold will skip existing files.");
      } catch (e) {
        $("preview").textContent = "Preview error: " + e.message;
      }
    }

    function appendLogs(lines) {
      if (!lines.length) return;
      $("terminal").textContent += lines.join("\n") + "\n";
      $("terminal").scrollTop = $("terminal").scrollHeight;
    }

    async function pollStatus() {
      const data = await api("/api/feature/status?offset=" + logOffset);
      if (data.logs?.length) { appendLogs(data.logs); logOffset = data.log_total; }
      if (data.status === "running") {
        $("statusText").textContent = "Scaffolding…";
        $("scaffoldBtn").disabled = true;
      } else if (data.status === "succeeded" || data.status === "failed") {
        clearInterval(pollTimer);
        $("scaffoldBtn").disabled = false;
        $("statusText").textContent = data.status === "succeeded" ? "Done" : "Failed";
        if (data.error) showAlert(data.error);
      }
    }

    async function scaffold() {
      const payload = scaffoldPayload();
      if (!payload.project || !payload.feature) return showAlert("Project path and feature name required");
      logOffset = 0;
      $("terminal").textContent = "";
      $("alert").classList.remove("visible");
      $("scaffoldBtn").disabled = true;
      await api("/api/feature/apply", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ ...payload, dry_run: $("dryRun").checked }),
      });
      pollTimer = setInterval(pollStatus, 700);
    }

    async function saveDefaults() {
      const payload = scaffoldPayload();
      if (!payload.project) return showAlert("Project path required");
      await api("/api/feature/save-config", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      $("statusText").textContent = "Defaults saved to release-toolkit.config.json";
      $("alert").classList.remove("visible");
    }

    $("featureName").addEventListener("input", refreshPreview);
    $("basePath").addEventListener("change", refreshPreview);
    $("stateManagement").addEventListener("change", refreshPreview);
    $("architecturePreset").addEventListener("change", () => {
      syncCustomTemplatePanel();
      refreshPreview();
    });
    $("apiProtocol").addEventListener("change", () => { syncExternalSdkPanel(); refreshPreview(); });
    $("projectPath").addEventListener("change", loadProject);
    $("scaffoldBtn").addEventListener("click", scaffold);
    $("saveDefaultsBtn").addEventListener("click", () => saveDefaults().catch((e) => showAlert(e.message)));

    (async () => {
      const boot = await api("/api/bootstrap");
      if (boot.project_path) {
        $("projectPath").value = boot.project_path;
        await loadProject();
      }
    })().catch(() => {});
  </script>
</body>
</html>
''';
