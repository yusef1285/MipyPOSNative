import 'dart:io';

Future<String?> saveFileWindows(String defaultName) async {
  final script = '''
  Add-Type -AssemblyName System.Windows.Forms
  \$f = New-Object System.Windows.Forms.SaveFileDialog
  \$f.FileName = "$defaultName"
  \$f.Filter = "CSV Files (*.csv)|*.csv|All Files (*.*)|*.*"
  if (\$f.ShowDialog() -eq "OK") { Write-Output \$f.FileName }
  ''';

  final result = await Process.run(
    'powershell',
    ['-NoProfile', '-Command', script],
  );

  if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
    return result.stdout.toString().trim();
  }
  return null;
}
