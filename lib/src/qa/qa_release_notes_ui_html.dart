/// QA Release Notes Studio page HTML.
String qaReleaseNotesStudioHtml() => r'''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>QA Release Notes</title>
  <style>
    :root {
      --bg: #0c1018; --surface: rgba(255,255,255,0.06); --border: rgba(255,255,255,0.1);
      --text: #f2f5ff; --muted: #8d98b3; --accent: #a29bfe; --teal: #4ecdc4;
      --danger: #ff6b6b; --warn: #fdcb6e;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: var(--bg); color: var(--text); min-height: 100vh;
      background-image: radial-gradient(ellipse 50% 40% at 90% 0%, rgba(162,155,254,0.18), transparent);
    }
    .wrap { max-width: 960px; margin: 0 auto; padding: 1.5rem; }
    h1 { font-size: 1.75rem; margin-bottom: 0.35rem; }
    .subtitle { color: var(--muted); margin-bottom: 1.25rem; }
    .panel { background: var(--surface); border: 1px solid var(--border); border-radius: 14px; padding: 1.25rem; margin-bottom: 1rem; }
    label { display: block; font-size: 0.78rem; color: var(--muted); margin-bottom: 0.35rem; }
    input, select {
      width: 100%; background: rgba(0,0,0,0.35); border: 1px solid var(--border);
      color: var(--text); padding: 0.7rem; border-radius: 10px; margin-bottom: 0.85rem;
    }
    .grid3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1rem; }
    @media (max-width: 720px) { .grid3 { grid-template-columns: 1fr; } }
    button, .btn {
      font-weight: 600; border: none; border-radius: 10px; padding: 0.75rem 1.25rem; cursor: pointer;
      background: linear-gradient(135deg, var(--accent), #6c5ce7); color: #fff;
    }
    button.secondary, .btn.secondary { background: transparent; border: 1px solid var(--border); color: var(--muted); }
    button:disabled { opacity: 0.45; cursor: not-allowed; }
    .actions { display: flex; gap: 0.75rem; flex-wrap: wrap; margin-bottom: 1rem; align-items: center; }
    .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 0.75rem; margin-bottom: 1rem; }
    .card-mini { background: rgba(0,0,0,0.25); border: 1px solid var(--border); border-radius: 10px; padding: 0.75rem; }
    .card-mini .label { font-size: 0.72rem; color: var(--muted); }
    .card-mini .value { font-size: 1rem; font-weight: 700; margin-top: 0.25rem; }
    .badge { display: inline-block; padding: 0.2rem 0.55rem; border-radius: 999px; font-size: 0.72rem; font-weight: 700; }
    .badge.low { background: rgba(78,205,196,0.2); color: var(--teal); }
    .badge.medium { background: rgba(253,203,110,0.2); color: var(--warn); }
    .badge.high { background: rgba(255,107,107,0.2); color: var(--danger); }
    .preview { font-family: Menlo, monospace; font-size: 0.78rem; background: #050810; border: 1px solid var(--border);
      border-radius: 10px; padding: 1rem; min-height: 220px; white-space: pre-wrap; color: #b8c4e8; max-height: 480px; overflow: auto; }
    .alert { background: rgba(255,107,107,0.12); border: 1px solid rgba(255,107,107,0.35); color: #ffc9c9;
      padding: 0.75rem; border-radius: 10px; margin-bottom: 1rem; display: none; }
    .alert.visible { display: block; }
    table { width: 100%; border-collapse: collapse; font-size: 0.82rem; margin-top: 0.5rem; }
    th, td { border: 1px solid var(--border); padding: 0.45rem; text-align: left; }
    th { color: var(--muted); font-weight: 600; }
    .link-row { margin-top: 0.75rem; font-size: 0.85rem; }
    .link-row a { color: var(--teal); }
  </style>
</head>
<body>
  <div class="wrap">
    <h1>QA release notes</h1>
    <p class="subtitle">Compare commits when git history exists, or scan the codebase to infer QA focus when it does not.</p>
    <div id="alert" class="alert"></div>
    <div class="panel">
      <label>Project path</label>
      <input id="projectPath" type="text" placeholder="/path/to/flutter/app" />
      <div class="grid3">
        <div>
          <label>Compare range</label>
          <select id="baseMode"><option value="codebase">Codebase scan</option></select>
        </div>
        <div>
          <label>Audience</label>
          <select id="audience">
            <option value="qa">QA (full)</option>
            <option value="pm">PM summary</option>
            <option value="executive">Executive</option>
          </select>
        </div>
        <div>
          <label>Compare label</label>
          <input id="compareLabel" readonly value="Codebase scan" />
        </div>
      </div>
      <div class="actions">
        <button type="button" id="generateBtn">Generate</button>
        <button type="button" id="copyBtn" class="secondary" disabled>Copy Markdown</button>
        <select id="downloadFormat" class="btn secondary" style="width:auto;padding:0.65rem 1rem">
          <option value="md">Download Markdown</option>
          <option value="csv">Download CSV (Excel)</option>
          <option value="json">Download JSON</option>
          <option value="html">Download HTML</option>
          <option value="xlsx">Download XLSX</option>
          <option value="confluence">Download Confluence wiki</option>
          <option value="jira">Download Jira comment</option>
          <option value="testrail">Download TestRail CSV</option>
          <option value="tuskr">Download Tuskr CSV</option>
          <option value="regression">Download regression matrix</option>
          <option value="eml">Download email (.eml)</option>
        </select>
        <button type="button" id="downloadBtn" class="secondary" disabled>Download</button>
      </div>
      <div id="summaryCards" class="cards" style="display:none"></div>
      <div id="linkRow" class="link-row" style="display:none"></div>
      <label>Preview</label>
      <div class="preview" id="preview">Select a project and click Generate…</div>
      <div id="checklistTable" style="margin-top:1rem"></div>
    </div>
  </div>
  <script>
    const $ = (id) => document.getElementById(id);
    let lastData = null;

    async function api(path, opts) {
      const res = await fetch(path, opts);
      const ct = res.headers.get("content-type") || "";
      if (!ct.includes("application/json")) {
        if (!res.ok) throw new Error(res.statusText);
        return res;
      }
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || res.statusText);
      return data;
    }

    function showAlert(msg) {
      $("alert").textContent = msg;
      $("alert").classList.add("visible");
    }

    function riskClass(level) {
      return (level || "low").toLowerCase();
    }

    function renderSummary(data) {
      $("summaryCards").style.display = "grid";
      $("summaryCards").innerHTML =
        '<div class="card-mini"><div class="label">Source</div><div class="value">' + (data.source || "git") + '</div></div>' +
        '<div class="card-mini"><div class="label">Time estimate</div><div class="value">~' + data.estimated_minutes + ' min</div></div>' +
        '<div class="card-mini"><div class="label">Risk</div><div class="value"><span class="badge ' + riskClass(data.risk_level) + '">' + data.risk_level + '</span></div></div>' +
        '<div class="card-mini"><div class="label">Impact</div><div class="value">' + data.impact + '</div></div>' +
        '<div class="card-mini"><div class="label">Platforms</div><div class="value">' + (data.platforms_affected || []).join(", ") + '</div></div>' +
        '<div class="card-mini"><div class="label">Go/No-Go</div><div class="value" style="font-size:0.85rem;font-weight:600">' + data.go_no_go_hint + '</div></div>';

      const links = [];
      if (data.compare && data.compare.compare_url) links.push('<a href="' + data.compare.compare_url + '" target="_blank">GitHub compare</a>');
      if (data.compare && data.compare.pr_url) links.push('<a href="' + data.compare.pr_url + '" target="_blank">Pull request</a>');
      if (data.quick_test_url) links.push('<a href="' + data.quick_test_url + '">Quick Test this commit</a>');
      if (links.length) {
        $("linkRow").style.display = "block";
        $("linkRow").innerHTML = links.join(" · ");
      } else {
        $("linkRow").style.display = "none";
      }

      const rows = (data.checklist || []).map((item, i) =>
        "<tr><td>" + (i+1) + "</td><td>" + item.area + "</td><td>" + item.item + "</td><td>" + item.priority + "</td><td>" + item.platform + "</td></tr>"
      ).join("");
      $("checklistTable").innerHTML = rows ? '<label>Checklist</label><table><thead><tr><th>#</th><th>Area</th><th>Item</th><th>Priority</th><th>Platform</th></tr></thead><tbody>' + rows + '</tbody></table>' : "";
    }

    async function loadCompareOptions() {
      const path = $("projectPath").value.trim();
      if (!path) return;
      const data = await api("/api/qa/compare-options?project=" + encodeURIComponent(path));
      const select = $("baseMode");
      select.innerHTML = "";
      (data.options || []).forEach((opt) => {
        const el = document.createElement("option");
        el.value = opt.id;
        el.textContent = opt.label;
        select.appendChild(el);
      });
      if (select.options.length) {
        $("compareLabel").value = select.options[select.selectedIndex].textContent;
      }
    }

    async function generate() {
      const path = $("projectPath").value.trim();
      if (!path) return showAlert("Enter project path");
      $("alert").classList.remove("visible");
      $("generateBtn").disabled = true;
      try {
        const data = await api("/api/qa/preview", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            project: path,
            base_mode: $("baseMode").value,
            audience: $("audience").value,
          }),
        });
        lastData = data;
        $("preview").textContent = data.markdown || "";
        renderSummary(data);
        $("copyBtn").disabled = false;
        $("downloadBtn").disabled = false;
      } catch (e) {
        showAlert(e.message || String(e));
      } finally {
        $("generateBtn").disabled = false;
      }
    }

    function download() {
      const path = $("projectPath").value.trim();
      if (!path) return showAlert("Enter project path");
      const format = $("downloadFormat").value;
      const url = "/api/qa/download?project=" + encodeURIComponent(path) +
        "&format=" + encodeURIComponent(format) +
        "&base_mode=" + encodeURIComponent($("baseMode").value) +
        "&audience=" + encodeURIComponent($("audience").value);
      window.location.href = url;
    }

    $("generateBtn").addEventListener("click", () => generate().catch((e) => showAlert(e.message)));
    $("downloadBtn").addEventListener("click", download);
    $("copyBtn").addEventListener("click", () => {
      if (!lastData || !lastData.markdown) return;
      navigator.clipboard.writeText(lastData.markdown).catch((e) => showAlert(e.message));
    });
    $("projectPath").addEventListener("change", () => {
      rtkSaveProject($("projectPath").value.trim());
      loadCompareOptions().catch(() => {});
    });
    $("baseMode").addEventListener("change", () => {
      $("compareLabel").value = $("baseMode").options[$("baseMode").selectedIndex].textContent;
    });

    (async () => {
      await rtkSyncProjectInput();
      await loadCompareOptions();
    })().catch(() => {});
  </script>
</body>
</html>
''';
