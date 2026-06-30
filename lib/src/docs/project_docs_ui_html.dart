/// Project Docs Studio page HTML.
String projectDocsStudioHtml() => r'''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Project documentation</title>
  <style>
    :root {
      --bg: #0c1018; --surface: rgba(255,255,255,0.06); --border: rgba(255,255,255,0.1);
      --text: #f2f5ff; --muted: #8d98b3; --accent: #74b9ff; --teal: #4ecdc4;
      --danger: #ff6b6b; --warn: #fdcb6e; --success: #2ecc71;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: var(--bg); color: var(--text); min-height: 100vh;
      background-image: radial-gradient(ellipse 50% 40% at 10% 0%, rgba(116,185,255,0.15), transparent);
    }
    .wrap { max-width: 1000px; margin: 0 auto; padding: 1.5rem; }
    h1 { font-size: 1.75rem; margin-bottom: 0.35rem; }
    .subtitle { color: var(--muted); margin-bottom: 1.25rem; }
    .panel { background: var(--surface); border: 1px solid var(--border); border-radius: 14px; padding: 1.25rem; margin-bottom: 1rem; }
    label { display: block; font-size: 0.78rem; color: var(--muted); margin-bottom: 0.35rem; }
    input, select {
      width: 100%; background: rgba(0,0,0,0.35); border: 1px solid var(--border);
      color: var(--text); padding: 0.7rem; border-radius: 10px; margin-bottom: 0.85rem;
    }
    .grid2 { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
    @media (max-width: 720px) { .grid2 { grid-template-columns: 1fr; } }
    button {
      font-weight: 600; border: none; border-radius: 10px; padding: 0.75rem 1.25rem; cursor: pointer;
      background: linear-gradient(135deg, var(--accent), #0984e3); color: #fff;
    }
    button.secondary { background: transparent; border: 1px solid var(--border); color: var(--muted); }
    button:disabled { opacity: 0.45; cursor: not-allowed; }
    .actions { display: flex; gap: 0.75rem; flex-wrap: wrap; margin-bottom: 1rem; align-items: center; }
    .checks { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 0.5rem; margin-bottom: 1rem; }
    .check { display: flex; align-items: center; gap: 0.5rem; font-size: 0.85rem; }
    .check input { width: auto; margin: 0; }
    .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 0.75rem; margin-bottom: 1rem; }
    .card-mini { background: rgba(0,0,0,0.25); border: 1px solid var(--border); border-radius: 10px; padding: 0.75rem; }
    .card-mini .label { font-size: 0.72rem; color: var(--muted); }
    .card-mini .value { font-size: 1rem; font-weight: 700; margin-top: 0.25rem; }
    .preview { font-family: Menlo, monospace; font-size: 0.78rem; background: #050810; border: 1px solid var(--border);
      border-radius: 10px; padding: 1rem; min-height: 220px; white-space: pre-wrap; color: #b8c4e8; max-height: 480px; overflow: auto; }
    .alert { background: rgba(255,107,107,0.12); border: 1px solid rgba(255,107,107,0.35); color: #ffc9c9;
      padding: 0.75rem; border-radius: 10px; margin-bottom: 1rem; display: none; }
    .alert.visible { display: block; }
    .alert.warn { background: rgba(253,203,110,0.12); border-color: rgba(253,203,110,0.35); color: #ffeaa7; }
    .file-tabs { display: flex; gap: 0.35rem; flex-wrap: wrap; margin-bottom: 0.75rem; }
    .file-tab {
      font-size: 0.75rem; padding: 0.35rem 0.65rem; border-radius: 8px; cursor: pointer;
      border: 1px solid var(--border); background: transparent; color: var(--muted);
    }
    .file-tab.active { border-color: var(--accent); color: var(--text); background: rgba(116,185,255,0.12); }
    .status-ok { color: var(--success); }
    .status-miss { color: var(--warn); }
  </style>
</head>
<body>
  <div class="wrap">
    <h1>Project documentation</h1>
    <p class="subtitle">Generate README and doc/ guides from static project analysis — architecture, features, config, development, building, and testing.</p>
    <div id="alert" class="alert"></div>
    <div id="readmeWarn" class="alert warn"></div>

    <div class="panel">
      <label>Project path</label>
      <input id="projectPath" type="text" placeholder="/path/to/flutter/app" />
      <div class="grid2">
        <div>
          <label>Overwrite policy</label>
          <select id="overwritePolicy">
            <option value="skipExisting">Skip existing files (default)</option>
            <option value="refreshGenerated">Refresh toolkit-generated only</option>
            <option value="overwriteAll">Overwrite all selected files</option>
          </select>
        </div>
        <div>
          <label>Preview file</label>
          <select id="previewFile"></select>
        </div>
      </div>
      <label>Documents to generate</label>
      <div class="checks" id="docChecks"></div>
      <div class="actions">
        <button type="button" id="detectBtn" class="secondary">Scan project</button>
        <button type="button" id="previewBtn">Preview</button>
        <button type="button" id="writeBtn">Write documentation</button>
      </div>
    </div>

    <div class="cards" id="summaryCards" style="display:none"></div>

    <div class="panel">
      <label>Preview</label>
      <div class="file-tabs" id="fileTabs"></div>
      <div id="preview" class="preview">Select a project and click Preview.</div>
    </div>
  </div>
  <script>
    const DOC_FILES = [
      { id: "include_readme", path: "README.md", label: "README.md" },
      { id: "include_doc_index", path: "doc/README.md", label: "doc/README.md" },
      { id: "include_getting_started", path: "doc/getting-started.md", label: "Getting started" },
      { id: "include_architecture", path: "doc/architecture.md", label: "Architecture" },
      { id: "include_features", path: "doc/features.md", label: "Features" },
      { id: "include_configuration", path: "doc/configuration.md", label: "Configuration" },
      { id: "include_development", path: "doc/development.md", label: "Development" },
      { id: "include_building", path: "doc/building.md", label: "Building" },
      { id: "include_testing", path: "doc/testing.md", label: "Testing" },
    ];

    let previewData = null;
    let activeFile = "README.md";

    function showAlert(msg, warn) {
      const el = warn ? document.getElementById("readmeWarn") : document.getElementById("alert");
      el.textContent = msg;
      el.classList.add("visible");
      if (!warn) document.getElementById("readmeWarn").classList.remove("visible");
    }
    function hideAlerts() {
      document.getElementById("alert").classList.remove("visible");
      document.getElementById("readmeWarn").classList.remove("visible");
    }

    function buildChecks() {
      const box = document.getElementById("docChecks");
      box.innerHTML = DOC_FILES.map(f =>
        `<label class="check"><input type="checkbox" id="${f.id}" checked /> ${f.label}</label>`
      ).join("");
    }

    function specFromForm() {
      const spec = { overwrite_policy: document.getElementById("overwritePolicy").value };
      for (const f of DOC_FILES) {
        spec[f.id] = document.getElementById(f.id).checked;
      }
      return spec;
    }

    async function api(path, body) {
      const opts = body ? { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) } : {};
      const res = await fetch(path, opts);
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || res.statusText);
      return data;
    }

    function renderSummary(detect) {
      const ctx = detect.context || {};
      const cards = document.getElementById("summaryCards");
      cards.style.display = "grid";
      cards.innerHTML =
        `<div class="card-mini"><div class="label">Project</div><div class="value">${ctx.project_name || "—"}</div></div>` +
        `<div class="card-mini"><div class="label">Dart files</div><div class="value">${ctx.dart_file_count ?? "—"}</div></div>` +
        `<div class="card-mini"><div class="label">Missing docs</div><div class="value">${(detect.missing_docs || []).length}</div></div>` +
        `<div class="card-mini"><div class="label">Preset</div><div class="value">${ctx.configured_preset || ctx.detected_preset || "—"}</div></div>`;
    }

    function renderFileTabs(files) {
      const tabs = document.getElementById("fileTabs");
      const select = document.getElementById("previewFile");
      const paths = Object.keys(files || {}).sort();
      tabs.innerHTML = paths.map(p =>
        `<button type="button" class="file-tab ${p === activeFile ? "active" : ""}" data-path="${p}">${p}</button>`
      ).join("");
      select.innerHTML = paths.map(p => `<option value="${p}">${p}</option>`).join("");
      if (paths.length && !paths.includes(activeFile)) activeFile = paths[0];
      select.value = activeFile;
      tabs.querySelectorAll(".file-tab").forEach(btn => {
        btn.onclick = () => { activeFile = btn.dataset.path; renderPreview(); renderFileTabs(files); };
      });
    }

    function renderPreview() {
      const box = document.getElementById("preview");
      if (!previewData || !previewData.files) {
        box.textContent = "No preview yet.";
        return;
      }
      const path = document.getElementById("previewFile").value || activeFile;
      activeFile = path;
      const diff = previewData.diffs && previewData.diffs[path];
      const content = previewData.files[path] || "";
      const skip = previewData.skip_reasons && previewData.skip_reasons[path];
      let text = content;
      if (diff) text = "# Diff vs existing\n\n" + diff + "\n\n# Generated content\n\n" + content;
      if (skip) text = "[Will skip: " + skip + "]\n\n" + text;
      box.textContent = text;
    }

    async function detectProject() {
      hideAlerts();
      const path = (window.rtkRequireProject && rtkRequireProject()) || document.getElementById("projectPath").value.trim();
      if (!path) return;
      document.getElementById("projectPath").value = path;
      if (window.rtkSaveProject) rtkSaveProject(path);
      const data = await api("/api/docs/detect?path=" + encodeURIComponent(path));
      renderSummary(data);
      if (data.substantial_readme) {
        showAlert("Existing README has substantial custom content. It will be skipped unless you choose Overwrite all.", true);
      }
    }

    async function previewDocs() {
      hideAlerts();
      const path = (window.rtkRequireProject && rtkRequireProject()) || document.getElementById("projectPath").value.trim();
      if (!path) return;
      previewData = await api("/api/docs/preview", { path, spec: specFromForm() });
      renderFileTabs(previewData.files);
      if (previewData.substantial_readme) {
        showAlert("README has substantial custom content and will be skipped with the current policy. Proposed README is shown in preview.", true);
      }
      renderPreview();
    }

    async function writeDocs() {
      hideAlerts();
      const path = (window.rtkRequireProject && rtkRequireProject()) || document.getElementById("projectPath").value.trim();
      if (!path) return;
      if (!confirm("Write documentation files to " + path + "?")) return;
      const data = await api("/api/docs/write", { path, spec: specFromForm() });
      const written = (data.written || []).join(", ") || "(none)";
      const skipped = Object.keys(data.skipped || {}).length;
      showAlert("Written: " + written + (skipped ? " | Skipped: " + skipped + " file(s)" : ""));
      await detectProject();
    }

    document.getElementById("previewFile").onchange = renderPreview;
    document.getElementById("detectBtn").onclick = () => detectProject().catch(e => showAlert(e.message));
    document.getElementById("previewBtn").onclick = () => previewDocs().catch(e => showAlert(e.message));
    document.getElementById("writeBtn").onclick = () => writeDocs().catch(e => showAlert(e.message));

    buildChecks();
    if (window.rtkSyncProjectInput) {
      rtkSyncProjectInput().then(path => { if (path) detectProject().catch(() => {}); });
    }
  </script>
</body>
</html>
''';
