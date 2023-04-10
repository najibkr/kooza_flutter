class KoozaError implements Exception {
  final String code;
  final String message;

  KoozaError copyWith({String? code, String? message}) {
    return KoozaError(
      code: code ?? this.code,
      message: message ?? this.message,
    );
  }

  const KoozaError({
    required this.code,
    required this.message,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'code': code,
      'message': message,
    };
  }

  factory KoozaError.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const KoozaError(code: 'UNKNOWN', message: 'UNKNOWN');
    }
    return KoozaError(
      code: (map['code'] as String?) ?? 'UNKNOWN',
      message: (map['message'] as String?) ?? 'UNKNOWN',
    );
  }

  @override
  String toString() {
    return '\nCode: $code\nMessage: $message';
  }
}
