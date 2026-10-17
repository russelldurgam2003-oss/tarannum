class Verse {
  final int id;
  final String sadr;
  final String ajz;

  Verse({
    required this.id,
    required this.sadr,
    required this.ajz,
  });

  // دالة لتحويل بيانات JSON إلى كائن Verse
  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      id: json['id'],
      sadr: json['sadr'],
      ajz: json['ajz'],
    );
  }
}