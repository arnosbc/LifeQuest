import 'package:equatable/equatable.dart';

/// Archivo enviado temporalmente para revisar el avance de un paso.
class GuidedStepEvidence extends Equatable {
  const GuidedStepEvidence({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  static const maxBytes = 10 * 1024 * 1024;
  static const maxFiles = 5;
  static const maxTotalBytes = 10 * 1024 * 1024;

  final String name;
  final String mimeType;
  final List<int> bytes;

  @override
  List<Object?> get props => [name, mimeType, bytes];
}
