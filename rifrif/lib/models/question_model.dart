class Question {
  final String id;
  final String questionText;
  final String authorName;
  final String authorEmail;
  final String presentationTitle;
  final String presentationId;
  final DateTime timestamp;
  final bool isAnswered;
  final String? answer;
  final DateTime? answeredAt;

  Question({
    required this.id,
    required this.questionText,
    required this.authorName,
    required this.authorEmail,
    required this.presentationTitle,
    required this.presentationId,
    required this.timestamp,
    this.isAnswered = false,
    this.answer,
    this.answeredAt,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] ?? '',
      questionText: map['questionText'] ?? '',
      authorName: map['authorName'] ?? '',
      authorEmail: map['authorEmail'] ?? '',
      presentationTitle: map['presentationTitle'] ?? '',
      presentationId: map['presentationId'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      isAnswered: map['isAnswered'] ?? false,
      answer: map['answer'],
      answeredAt: map['answeredAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['answeredAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionText': questionText,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'presentationTitle': presentationTitle,
      'presentationId': presentationId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isAnswered': isAnswered,
      'answer': answer,
      'answeredAt': answeredAt?.millisecondsSinceEpoch,
    };
  }

  Question copyWith({
    String? id,
    String? questionText,
    String? authorName,
    String? authorEmail,
    String? presentationTitle,
    String? presentationId,
    DateTime? timestamp,
    bool? isAnswered,
    String? answer,
    DateTime? answeredAt,
  }) {
    return Question(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      authorName: authorName ?? this.authorName,
      authorEmail: authorEmail ?? this.authorEmail,
      presentationTitle: presentationTitle ?? this.presentationTitle,
      presentationId: presentationId ?? this.presentationId,
      timestamp: timestamp ?? this.timestamp,
      isAnswered: isAnswered ?? this.isAnswered,
      answer: answer ?? this.answer,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }
}
