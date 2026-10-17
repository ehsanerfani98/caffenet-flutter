/// فایل آپلودشده — Formatter::uploadedFile بک‌اند.
class UploadedFile {
  const UploadedFile({
    required this.id,
    required this.name,
    this.size = 0,
    this.type = '',
    this.url = '',
    this.uploadedAt = '',
  });

  final String id;
  final String name;
  final int size;
  final String type;
  final String url;
  final String uploadedAt;

  factory UploadedFile.fromJson(dynamic raw) {
    if (raw is! Map) return const UploadedFile(id: '', name: '');
    final m = raw.cast<String, dynamic>();
    return UploadedFile(
      id: '${m['id'] ?? ''}',
      name: '${m['name'] ?? ''}',
      size: (m['size'] as num?)?.toInt() ?? 0,
      type: '${m['type'] ?? ''}',
      url: '${m['url'] ?? ''}',
      uploadedAt: '${m['uploadedAt'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'size': size,
        'type': type,
        'url': url,
        'uploadedAt': uploadedAt,
      };
}
