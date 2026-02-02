class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctOptionIndex;
  final String concept;
  final String difficulty;
  final String section;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctOptionIndex,
    required this.concept,
    required this.difficulty,
    this.section = 'General',
  });
}

class Assessment {
  final String id;
  final String title;
  final int durationMinutes;
  final List<Question> questions;
  final String category;

  Assessment({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.questions,
    required this.category,
  });
}
