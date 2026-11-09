
import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int questionIndex = 0;
  int score = 0;
  int? selectedAnswer;
  bool finished = false;

  static const Color green = Color(0xFF103D30);

  final List<Map<String, dynamic>> questions = [
    {
      'question': 'What is the capital of India?',
      'answers': ['Mumbai', 'New Delhi', 'Kolkata', 'Chennai'],
      'correct': 1,
    },
    {
      'question': 'Which planet is known as the Red Planet?',
      'answers': ['Earth', 'Venus', 'Mars', 'Jupiter'],
      'correct': 2,
    },
    {
      'question': 'How many days are there in a week?',
      'answers': ['5', '6', '7', '8'],
      'correct': 2,
    },
    {
      'question': 'Which is the largest ocean?',
      'answers': ['Atlantic', 'Indian', 'Arctic', 'Pacific'],
      'correct': 3,
    },
    {
      'question': 'What is the national animal of India?',
      'answers': ['Lion', 'Tiger', 'Elephant', 'Leopard'],
      'correct': 1,
    },
  ];

  void nextQuestion() {
    if (selectedAnswer == null) return;

    if (selectedAnswer == questions[questionIndex]['correct']) {
      score++;
    }

    if (questionIndex < questions.length - 1) {
      setState(() {
        questionIndex++;
        selectedAnswer = null;
      });
    } else {
      setState(() {
        finished = true;
      });
    }
  }

  void restartQuiz() {
    setState(() {
      questionIndex = 0;
      score = 0;
      selectedAnswer = null;
      finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        title: const Text('Daily Quiz'),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: finished ? resultScreen() : quizContent(),
      ),
    );
  }

  Widget quizContent() {
    final question = questions[questionIndex];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 15),
          Text(
            'Question ${questionIndex + 1} of ${questions.length}',
            style: const TextStyle(
              color: green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (questionIndex + 1) / questions.length,
            color: const Color(0xFF16845C),
            backgroundColor: Colors.black12,
          ),
          const SizedBox(height: 35),
          Text(
            question['question'],
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: green,
            ),
          ),
          const SizedBox(height: 25),
          ...List.generate(
            (question['answers'] as List).length,
            (index) {
              final isSelected = selectedAnswer == index;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      selectedAnswer = index;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isSelected
                        ? const Color(0xFFD7EFE3)
                        : Colors.white,
                    foregroundColor: green,
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF16845C)
                          : Colors.black12,
                      width: isSelected ? 2 : 1,
                    ),
                    padding: const EdgeInsets.all(17),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(
                    question['answers'][index],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              );
            },
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: selectedAnswer == null ? null : nextQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
            child: Text(
              questionIndex == questions.length - 1
                  ? 'Finish Quiz'
                  : 'Next Question',
            ),
          ),
        ],
      ),
    );
  }

  Widget resultScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 75,
              color: Color(0xFF16845C),
            ),
            const SizedBox(height: 20),
            const Text(
              'Quiz Completed!',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: green,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Your Score: $score / ${questions.length}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: restartQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 35,
                  vertical: 15,
                ),
              ),
              child: const Text('Play Again'),
            ),
          ],
        ),
      ),
    );
  }
}
