
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  static const Color green = Color(0xFF103D30);
  static const Color accent = Color(0xFF16845C);
  static const Color background = Color(0xFFF3F7F4);

  Future<void> openTelegram(String link) async {
    final uri = Uri.parse(link);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Telegram')),
      );
    }
  }

  void openQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuizScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        title: const Text(
          'GROW CAPITAL',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [green, Color(0xFF176B50)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AVAILABLE REWARDS',
                        style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 10),
                    Text(
                      '₹0.00',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Learn • Complete Tasks • Grow',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 18),
                    Text(
                      '✓ FREE TO JOIN • NO DEPOSIT REQUIRED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1D6),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GROW CAPITAL PREMIUM',
                        style: TextStyle(
                          color: green,
                          fontWeight: FontWeight.bold,
                        )),
                    SizedBox(height: 6),
                    Text('Optional membership • ₹49/month'),
                    SizedBox(height: 5),
                    Text(
                      'Free access and withdrawal remain available.',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Explore Activities',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: green,
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: activityCard(
                      Icons.quiz_outlined,
                      'Daily Quiz',
                      'Learn & Practice',
                      openQuiz,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: activityCard(
                      Icons.task_alt,
                      'Tasks',
                      'Daily Activities',
                      () => showMessage('Tasks are coming soon'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: activityCard(
                      Icons.people_outline,
                      'Referral',
                      'Invite Friends',
                      () => showMessage('Referral is coming soon'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: activityCard(
                      Icons.account_balance_wallet_outlined,
                      'My Wallet',
                      'Reward History',
                      () => showMessage('Wallet is coming soon'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Telegram Community',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: green,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => openTelegram(
                    'https://t.me/growcapital_support2',
                  ),
                  icon: const Icon(Icons.campaign),
                  label: const Text('Official Updates'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => openTelegram(
                    'https://t.me/growcapital_support1',
                  ),
                  icon: const Icon(Icons.support_agent),
                  label: const Text('Personal Customer Support'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: green,
                    side: const BorderSide(color: green),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Video Advertisement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: green,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 125,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_outline,
                        size: 42, color: accent),
                    SizedBox(height: 7),
                    Text(
                      'Video Advertisement Area',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Advertisement will appear here',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: green,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Rewards are subject to verification, eligibility '
                      'and available funds. No reward is guaranteed. '
                      'No deposit is required.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'GROW CAPITAL • Learn • Engage • Grow',
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.wallet_outlined),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget activityCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 19,
            horizontal: 8,
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: accent),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: green,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

  final List<Map<String, dynamic>> questions = [
    {
      'question': 'What is the capital of India?',
      'options': ['Mumbai', 'New Delhi', 'Kolkata', 'Chennai'],
      'answer': 1,
    },
    {
      'question': 'Which planet is known as the Red Planet?',
      'options': ['Earth', 'Venus', 'Mars', 'Jupiter'],
      'answer': 2,
    },
    {
      'question': 'How many days are there in a week?',
      'options': ['5', '6', '7', '8'],
      'answer': 2,
    },
    {
      'question': 'Which is the largest ocean?',
      'options': ['Indian', 'Atlantic', 'Arctic', 'Pacific'],
      'answer': 3,
    },
    {
      'question': 'Which language is used for Flutter apps?',
      'options': ['Java', 'Dart', 'Python', 'PHP'],
      'answer': 1,
    },
  ];

  void submitAnswer() {
    if (selectedAnswer == null) return;

    if (selectedAnswer == questions[questionIndex]['answer']) {
      score++;
    }

    setState(() {
      if (questionIndex < questions.length - 1) {
        questionIndex++;
        selectedAnswer = null;
      } else {
        finished = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[questionIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF103D30),
        foregroundColor: Colors.white,
        title: const Text('Daily Quiz'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: finished
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 75,
                      color: Color(0xFF16845C),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Quiz Completed!',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your Score: $score / ${questions.length}',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          questionIndex = 0;
                          score = 0;
                          selectedAnswer = null;
                          finished = false;
                        });
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${questionIndex + 1} of ${questions.length}',
                    style: const TextStyle(
                      color: Color(0xFF16845C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: (questionIndex + 1) / questions.length,
                    color: const Color(0xFF16845C),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    question['question'],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ...List.generate(
                    (question['options'] as List).length,
                    (index) => Card(
                      child: RadioListTile<int>(
                        value: index,
                        groupValue: selectedAnswer,
                        title: Text(question['options'][index]),
                        onChanged: (value) {
                          setState(() => selectedAnswer = value);
                        },
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          selectedAnswer == null ? null : submitAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF103D30),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(15),
                      ),
                      child: Text(
                        questionIndex == questions.length - 1
                            ? 'Finish Quiz'
                            : 'Next Question',
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
