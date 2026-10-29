class Verse {
  final int id;
  final String sadr;
  final String ajz;
  final String poet;
  final String sea;

  Verse({
    required this.id,
    required this.sadr,
    required this.ajz,
    required this.poet,
    required this.sea,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      id: json['id'],
      sadr: json['sadr'],
      ajz: json['ajz'],
      poet: json['poet'] ?? 'غير معروف',
      sea: json['sea'] ?? '',
    );
  }
}