import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/studio_client.dart';
import '../studio_branding.dart';
import '../studio_log.dart';
import 'studio_webview_screen.dart';

const _prefsProjectKey = 'rtk_last_project_path';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.client,
    required this.initialView,
  });

  final StudioClient client;
  final String initialView;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  StudioEnvironment? _environment;
  String? _error;
  String? _selectedPath;
  ProjectAnalysis? _analysis;
  bool _loading = true;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    studioLog('Onboarding: bootstrap started');
    setState(() {
      _loading = true;
      _error = null;
      _analysis = null;
    });
    try {
      await widget.client.waitForServer();
      final env = await widget.client.fetchEnvironment();
      if (!mounted) return;
      setState(() {
        _environment = env;
        _loading = false;
      });
      studioLog('Onboarding: bootstrap complete');
      if (widget.initialView == 'quick-test') {
        await _openQuickTest();
      }
    } on Object catch (e, st) {
      studioLogError('Onboarding: bootstrap failed', e, st);
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _pickProjectFolder() async {
    studioLog('Onboarding: opening folder picker');
    final path = await getDirectoryPath(confirmButtonText: 'Select project folder');
    if (path == null || path.isEmpty) {
      studioLog('Onboarding: folder picker cancelled');
      return;
    }
    studioLog('Onboarding: selected folder $path');
    setState(() {
      _selectedPath = path;
      _analysis = null;
    });
    await _analyzeSelected();
  }

  Future<void> _analyzeSelected() async {
    final path = _selectedPath?.trim();
    if (path == null || path.isEmpty) return;
    setState(() => _working = true);
    try {
      final analysis = await widget.client.analyzeProject(path);
      if (!mounted) return;
      setState(() => _analysis = analysis);
    } on Object catch (e, st) {
      studioLogError('Onboarding: analyze failed', e, st);
      _showMessage('$e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _openQuickTest() async {
    if (_environment == null || !_environment!.canUseStudio) {
      _showMessage('Dart SDK is required. Install Dart before continuing.');
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => StudioWebViewScreen(
          client: widget.client,
          projectPath: '',
          initialView: 'quick-test',
          onChangeProject: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => OnboardingScreen(
                  client: widget.client,
                  initialView: widget.initialView,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openStudio(String projectPath, {String? view}) async {
    studioLog('Onboarding: opening studio for $projectPath view=${view ?? widget.initialView}');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsProjectKey, projectPath);
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => StudioWebViewScreen(
          client: widget.client,
          projectPath: projectPath,
          initialView: view ?? widget.initialView,
          onChangeProject: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => OnboardingScreen(
                  client: widget.client,
                  initialView: widget.initialView,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _continueToStudio() async {
    final path = _selectedPath?.trim();
    if (path == null || path.isEmpty) {
      _showMessage('Select or create a Flutter project first.');
      return;
    }
    if (_environment == null || !_environment!.canUseStudio) {
      _showMessage('Dart SDK is required. Install Dart before continuing.');
      return;
    }

    setState(() => _working = true);
    try {
      studioLog('Onboarding: continue with path=$path');
      var analysis = _analysis ?? await widget.client.analyzeProject(path);

      if (analysis.compatible) {
        studioLog('Onboarding: project compatible, registering…');
        final registered = await widget.client.registerProject(path);
        await _openStudio(registered);
        return;
      }

      studioLog('Onboarding: project not compatible (canRepair=${analysis.canRepair})');

      if (analysis.canRepair && _environment!.flutterInstalled) {
        final repair = await _confirmRepair(analysis);
        if (repair == true) {
          studioLog('Onboarding: repairing project structure…');
          final registered = await widget.client.registerProject(path, repair: true);
          await _openStudio(registered);
          return;
        }
        if (repair == null) return;
      }

      if (_environment!.flutterInstalled) {
        final create = await _confirmCreateInstead(analysis);
        if (create == true) {
          await _showCreateProjectDialog();
        }
      } else {
        _showMessage(
          'This folder is not a Flutter project. Install Flutter to repair structure '
          'or create a new project.',
        );
      }
    } on Object catch (e, st) {
      studioLogError('Onboarding: continue failed', e, st);
      _showMessage('$e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<bool?> _confirmRepair(ProjectAnalysis analysis) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repair Flutter structure?'),
        content: Text(
          'This folder is missing standard Flutter files:\n\n'
          '${analysis.issues.map((i) => '• $i').join('\n')}\n\n'
          '$studioProductName can run flutter create to add missing folders '
          'and files without removing your existing code.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Pick another')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Repair')),
        ],
      ),
    );
  }

  Future<bool?> _confirmCreateInstead(ProjectAnalysis analysis) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Not a Flutter project'),
        content: Text(
          analysis.issues.isEmpty
              ? 'This folder cannot be used as a Flutter project.'
              : 'Issues:\n${analysis.issues.map((i) => '• $i').join('\n')}\n\n'
                  'Create a new Flutter project instead?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create new')),
        ],
      ),
    );
  }

  Future<void> _showCreateProjectDialog() async {
    if (_environment == null || !_environment!.flutterInstalled) {
      _showMessage(
        'Flutter is not installed on this device. Install Flutter before creating a project.',
      );
      return;
    }

    final projectPath = await showDialog<String>(
      context: context,
      builder: (context) => _CreateProjectDialog(
        client: widget.client,
        initialParent: _selectedPath,
      ),
    );
    if (projectPath == null || projectPath.isEmpty) return;

    setState(() => _working = true);
    try {
      setState(() {
        _selectedPath = projectPath;
        _analysis = null;
      });
      await _openStudio(projectPath, view: 'setup');
    } on Object catch (e, st) {
      studioLogError('Onboarding: open studio after create failed', e, st);
      _showMessage('$e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(studioProductName),
        actions: [
          IconButton(
            tooltip: 'Refresh environment',
            onPressed: _loading || _working ? null : _bootstrap,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBody(message: _error!, onRetry: _bootstrap)
              : _OnboardingBody(
                  environment: _environment!,
                  selectedPath: _selectedPath,
                  analysis: _analysis,
                  working: _working,
                  onPickFolder: _pickProjectFolder,
                  onCreateProject: _showCreateProjectDialog,
                  onContinue: _continueToStudio,
                ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _OnboardingBody extends StatelessWidget {
  const _OnboardingBody({
    required this.environment,
    required this.selectedPath,
    required this.analysis,
    required this.working,
    required this.onPickFolder,
    required this.onCreateProject,
    required this.onContinue,
  });

  final StudioEnvironment environment;
  final String? selectedPath;
  final ProjectAnalysis? analysis;
  final bool working;
  final VoidCallback onPickFolder;
  final VoidCallback onCreateProject;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Choose your Flutter project', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Studio opens without a project. Pick an existing app folder, repair an '
          'incomplete structure, or create a new Flutter project.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        _EnvironmentPanel(environment: environment),
        const SizedBox(height: 24),
        Text('Project folder', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(
              selectedPath ?? 'No folder selected',
              style: TextStyle(color: selectedPath == null ? theme.hintColor : null),
            ),
            subtitle: analysis == null
                ? null
                : Text(
                    analysis!.compatible
                        ? 'Compatible Flutter project'
                        : analysis!.canRepair
                            ? 'Can be repaired to Flutter structure'
                            : 'Not a Flutter project',
                    style: TextStyle(
                      color: analysis!.compatible
                          ? Colors.green
                          : analysis!.canRepair
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.error,
                    ),
                  ),
            trailing: OutlinedButton.icon(
              onPressed: working ? null : onPickFolder,
              icon: const Icon(Icons.folder_open),
              label: const Text('Browse…'),
            ),
          ),
        ),
        if (analysis != null && !analysis!.compatible) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Structure issues', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ...analysis!.issues.map((issue) => Text('• $issue')),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: working || !environment.flutterInstalled ? null : onCreateProject,
                icon: const Icon(Icons.add),
                label: const Text('Create new project'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: working || !environment.canUseStudio ? null : onContinue,
                icon: working
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward),
                label: Text(working ? 'Working…' : 'Continue'),
              ),
            ),
          ],
        ),
        if (!environment.flutterInstalled) ...[
          const SizedBox(height: 16),
          Text(
            'Flutter is not installed. You can use Setup and Add feature on compatible projects. '
            'Install Flutter to repair structure, create projects, or build APK/IPA.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.tertiary),
          ),
        ],
      ],
    );
  }
}

class _EnvironmentPanel extends StatelessWidget {
  const _EnvironmentPanel({required this.environment});

  final StudioEnvironment environment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Device environment', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _StatusRow(label: 'Dart SDK', ok: environment.dartInstalled, detail: environment.dartVersion),
            _StatusRow(label: 'Flutter', ok: environment.flutterInstalled, detail: environment.flutterVersion),
            if (environment.macos)
              _StatusRow(
                label: 'Xcode (iOS builds)',
                ok: environment.xcodeInstalled,
                detail: environment.xcodeInstalled ? 'Installed' : 'Not found',
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.ok, required this.detail});

  final String label;
  final bool ok;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.cancel, color: ok ? Colors.green : Colors.redAccent, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          if (detail != null) Text(detail!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _CreateProjectDialog extends StatefulWidget {
  const _CreateProjectDialog({
    required this.client,
    this.initialParent,
  });

  final StudioClient client;
  final String? initialParent;

  @override
  State<_CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<_CreateProjectDialog> {
  late final TextEditingController _nameController;
  String? _parentPath;
  bool _creating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'my_flutter_app');
    _parentPath = widget.initialParent?.trim().isNotEmpty == true
        ? widget.initialParent
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickParent() async {
    final picked = await getDirectoryPath(confirmButtonText: 'Select parent folder');
    if (picked != null) setState(() => _parentPath = picked);
  }

  Future<void> _create() async {
    final parent = _parentPath?.trim();
    final name = _nameController.text.trim();
    if (parent == null || parent.isEmpty) {
      setState(() => _error = 'Select a parent folder');
      return;
    }
    if (name.isEmpty) {
      setState(() => _error = 'Enter a project name');
      return;
    }
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final path = await widget.client.createProject(
        parentPath: parent,
        projectName: name,
      );
      if (!mounted) return;
      Navigator.pop(context, path);
    } on Object catch (e, st) {
      studioLogError('CreateProjectDialog: create failed', e, st);
      setState(() {
        _error = '$e';
        _creating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Flutter project'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            enabled: !_creating,
            decoration: const InputDecoration(
              labelText: 'Project name',
              hintText: 'my_flutter_app',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _parentPath ?? 'No parent folder selected',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _creating ? null : _pickParent,
            icon: const Icon(Icons.folder_open),
            label: const Text('Choose parent folder'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: _creating ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _creating ? null : _create,
          child: Text(_creating ? 'Creating…' : 'Create'),
        ),
      ],
    );
  }
}
