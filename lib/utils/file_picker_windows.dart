import 'dart:io';

/// Abre el diálogo de Windows para seleccionar un archivo.
/// Retorna la ruta seleccionada o null.
Future<String?> pickFileWindows() async {
  final script = '''
  Add-Type -AssemblyName System.Windows.Forms
  \$f = New-Object System.Windows.Forms.OpenFileDialog
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
