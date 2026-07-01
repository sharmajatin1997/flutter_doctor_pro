class ProjectDoctorException implements Exception {
  final String message;
  ProjectDoctorException(this.message);

  @override
  String toString() => 'ProjectDoctorException: $message';
}

class ScannerException extends ProjectDoctorException {
  ScannerException(super.message);
}

class BackupException extends ProjectDoctorException {
  BackupException(super.message);
}

class RestoreException extends ProjectDoctorException {
  RestoreException(super.message);
}
