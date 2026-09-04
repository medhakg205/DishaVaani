import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
const Color maroon = Color(0xFF6B2737);
const Color terracotta = Color(0xFFC1652F);
const Color gold = Color(0xFFD4A24E);
const Color sandstone = Color(0xFFF5EFE6);

class InterestQuizScreen extends StatefulWidget {
  const InterestQuizScreen({super.key});

  @override
  State<InterestQuizScreen> createState() => _InterestQuizScreenState();
}

class _InterestQuizScreenState extends State<InterestQuizScreen> {
  int currentQuestion = 0;

  // Stores the selected category for each question.
  final List<String?> selectedAnswers = List.filled(5, null);

  // DishaVaani interest scores.
  final Map<String, double> scores = {
    'history': 0.0,
    'architecture': 0.0,
    'military': 0.0,
    'religion': 0.0,
    'politics': 0.0,
    'food': 0.0,
    'shopping': 0.0,
    'relaxation': 0.0,
    'art': 0.0,
    'culture': 0.0,
    'nature': 0.0,
    'crafts': 0.0,
  };

  final List<Map<String, dynamic>> questions = [
    {
      'question':
          'What interests you most when exploring a new place?',
      'answers': [
        {
          'text': 'Architecture & monuments',
          'category': 'architecture',
          'icon': Icons.account_balance,
          'image':
              'https://images.unsplash.com/photo-1548013146-72479768bada',
        },
        {
          'text': 'Historical stories',
          'category': 'history',
          'icon': Icons.menu_book,
          'image':
              'https://images.unsplash.com/photo-1564399579883-451a5d44ec08',
        },
        {
          'text': 'Local food & traditions',
          'category': 'food',
          'icon': Icons.restaurant,
          'image':
              'https://images.unsplash.com/photo-1601050690597-df0568f70950',
        },
        {
          'text': 'Markets & local crafts',
          'category': 'shopping',
          'icon': Icons.storefront,
          'image':
              'https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a',
        },
        {
          'text': 'Art & culture',
          'category': 'art',
          'icon': Icons.palette,
          'image':
              'https://images.unsplash.com/photo-1561214115-f2f134cc4912',
        },
      ],
    },

    {
      'question':
          'What kind of history would you love to discover?',
      'answers': [
        {
          'text': 'Battles & warriors',
          'category': 'military',
          'icon': Icons.shield,
          'image':
              'https://images.unsplash.com/photo-1590050752117-238cb0fb1c1b',
        },
        {
          'text': 'Rulers & kingdoms',
          'category': 'politics',
          'icon': Icons.castle,
          'image':
              'https://images.unsplash.com/photo-1599661046289-e31897846e41',
        },
        {
          'text': 'Religious traditions',
          'category': 'religion',
          'icon': Icons.temple_hindu,
          'image':
              'https://images.unsplash.com/photo-1514222134-b57cbb8ce073',
        },
        {
          'text': 'Everyday life',
          'category': 'culture',
          'icon': Icons.people,
          'image':
              'https://images.unsplash.com/photo-1516321318423-f06f85e504b3',
        },
        {
          'text': 'Ancient art & crafts',
          'category': 'crafts',
          'icon': Icons.brush,
          'image':
              'https://images.unsplash.com/photo-1577083552431-6e5fd01aa342',
        },
      ],
    },

    {
      'question':
          'What would you notice first at a monument?',
      'answers': [
        {
          'text': 'Design & construction',
          'category': 'architecture',
          'icon': Icons.architecture,
          'image':
              'https://images.unsplash.com/photo-1511818966892-d7d671e672a2',
        },
        {
          'text': 'Defensive features',
          'category': 'military',
          'icon': Icons.shield,
          'image':
              'https://images.unsplash.com/photo-1599661046827-dacde6976549',
        },
        {
          'text': 'Religious significance',
          'category': 'religion',
          'icon': Icons.temple_hindu,
          'image':
              'https://images.unsplash.com/photo-1609766857041-ed402ea8069a',
        },
        {
          'text': 'Its historical story',
          'category': 'history',
          'icon': Icons.menu_book,
          'image':
              'https://images.unsplash.com/photo-1564507592333-c60657eea523',
        },
        {
          'text': 'Art & decoration',
          'category': 'art',
          'icon': Icons.palette,
          'image':
              'https://images.unsplash.com/photo-1549490349-8643362247b5',
        },
      ],
    },

    {
      'question':
          'What would you rather experience during a trip?',
      'answers': [
        {
          'text': 'Local cuisine',
          'category': 'food',
          'icon': Icons.restaurant,
          'image':
              'https://images.unsplash.com/photo-1585937421612-70a008356fbe',
        },
        {
          'text': 'Local markets',
          'category': 'shopping',
          'icon': Icons.shopping_bag,
          'image':
              'https://images.unsplash.com/photo-1531058020387-3be344556be6',
        },
        {
          'text': 'Peaceful places',
          'category': 'relaxation',
          'icon': Icons.self_improvement,
          'image':
              'https://images.unsplash.com/photo-1500534623283-312aade485b7',
        },
        {
          'text': 'Historic buildings',
          'category': 'architecture',
          'icon': Icons.account_balance,
          'image':
              'https://images.unsplash.com/photo-1524492412937-b28074a5d7da',
        },
        {
          'text': 'Traditional crafts',
          'category': 'crafts',
          'icon': Icons.handyman,
          'image':
              'https://images.unsplash.com/photo-1452860606245-08befc0ff44b',
        },
      ],
    },

    {
      'question':
          'Which story would you most likely listen to?',
      'answers': [
        {
          'text': 'A famous battle',
          'category': 'military',
          'icon': Icons.shield,
          'image':
              'https://images.unsplash.com/photo-1564399579883-451a5d44ec08',
        },
        {
          'text': 'A powerful kingdom',
          'category': 'politics',
          'icon': Icons.castle,
          'image':
              'https://images.unsplash.com/photo-1599661046289-e31897846e41',
        },
        {
          'text': 'Beliefs behind a monument',
          'category': 'religion',
          'icon': Icons.temple_hindu,
          'image':
              'https://images.unsplash.com/photo-1514222134-b57cbb8ce073',
        },
        {
          'text': 'How ordinary people lived',
          'category': 'culture',
          'icon': Icons.people,
          'image':
              'https://images.unsplash.com/photo-1529156069898-49953e39b3ac',
        },
        {
          'text': 'How the monument was built',
          'category': 'architecture',
          'icon': Icons.architecture,
          'image':
              'https://images.unsplash.com/photo-1511818966892-d7d671e672a2',
        },
      ],
    },
  ];

  void selectAnswer(String category) {
    setState(() {
      selectedAnswers[currentQuestion] = category;
    });
  }

  void nextQuestion() {
    if (selectedAnswers[currentQuestion] == null) {
      return;
    }

    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
      });
    } else {
      finishQuiz();
    }
  }

  void previousQuestion() {
    if (currentQuestion > 0) {
      setState(() {
        currentQuestion--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void calculateScores() {
    // Reset scores first.
    for (final key in scores.keys) {
      scores[key] = 0.0;
    }

    for (final category in selectedAnswers) {
      if (category != null && scores.containsKey(category)) {
        scores[category] = scores[category]! + 1.0;
      }
    }

    // Convert the raw score into a percentage-like value.
    for (final key in scores.keys) {
      scores[key] = scores[key]! / questions.length;
    }
  }

  String getTopInterest() {
    String bestCategory = 'history';
    double highestScore = -1;

    scores.forEach((category, score) {
      if (score > highestScore) {
        highestScore = score;
        bestCategory = category;
      }
    });

    return _prettyCategory(bestCategory);
  }

  String _prettyCategory(String category) {
    switch (category) {
      case 'architecture':
        return 'Architecture & Monuments';
      case 'history':
        return 'Historical Stories';
      case 'military':
        return 'Battles & Warriors';
      case 'religion':
        return 'Religious Traditions';
      case 'politics':
        return 'Rulers & Kingdoms';
      case 'food':
        return 'Local Food';
      case 'shopping':
        return 'Markets & Crafts';
      case 'relaxation':
        return 'Peaceful Places';
      case 'art':
        return 'Art & Culture';
      case 'culture':
        return 'People & Culture';
      case 'crafts':
        return 'Traditional Crafts';
      default:
        return category;
    }
  }

  Future<void> finishQuiz() async {
    calculateScores();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: sandstone,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: gold,
                    size: 36,
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  'Your feed is ready!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: maroon,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'We’ll personalize your DishaVaani experience around:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 22),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: sandstone,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.favorite,
                        color: terracotta,
                        size: 25,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          getTopInterest(),
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: maroon,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: maroon,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'LET’S EXPLORE',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[currentQuestion];
    final answers = question['answers'] as List;

    final progress =
        (currentQuestion + 1) / questions.length;

    return Scaffold(
      backgroundColor: sandstone,
      body: SafeArea(
        child: Column(
          children: [
            // -------------------------------------------------
            // TOP BAR
            // -------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: previousQuestion,
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black,
                        size: 22,
                      ),
                    ),
                  ),

                  const Spacer(),

                  Text(
                    '${currentQuestion + 1}/${questions.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // -------------------------------------------------
            // PROGRESS BAR
            // -------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  minHeight: 11,
                  value: progress,
                  backgroundColor: Colors.black12,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(
                    terracotta,
                  ),
                ),
              ),
            ),

            // -------------------------------------------------
            // CONTENT
            // -------------------------------------------------
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  55,
                  20,
                  20,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TUNING YOUR EXPERIENCE',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 14,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.bold,
                        color: terracotta,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      question['question'],
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 34,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // -------------------------------------------------
                    // ANSWER GRID
                    // -------------------------------------------------
                    GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount: answers.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.78,
                      ),
                      itemBuilder: (context, index) {
                        final answer = answers[index];

                        final String category =
                            answer['category'];

                        final bool isSelected =
                            selectedAnswers[currentQuestion] ==
                                category;

                        return GestureDetector(
                          onTap: () {
                            selectAnswer(category);
                          },
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(26),
                              border: Border.all(
                                color: isSelected
                                    ? terracotta
                                    : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    isSelected ? 0.18 : 0.08,
                                  ),
                                  blurRadius:
                                      isSelected ? 12 : 7,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(23),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // IMAGE
CachedNetworkImage(
  imageUrl: answer['image'],
  fit: BoxFit.cover,
  fadeInDuration: const Duration(milliseconds: 300),
  fadeOutDuration: const Duration(milliseconds: 100),

placeholder: (context, url) {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          sandstone,
          Color(0xFFDED8CF),
        ],
      ),
    ),
  );
},

  errorWidget: (context, url, error) {
    return Container(
      color: maroon,
      child: Icon(
        answer['icon'],
        color: Colors.white,
        size: 60,
      ),
    );
  },
),

                                  // DARK GRADIENT
                                  Container(
                                    decoration:
                                        const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin:
                                            Alignment.topCenter,
                                        end:
                                            Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black87,
                                        ],
                                        stops: [0.45, 1.0],
                                      ),
                                    ),
                                  ),

                                  // ICON / CHECK
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(
                                        milliseconds: 180,
                                      ),
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? terracotta
                                            : Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 28,
                                            )
                                          : Icon(
                                              answer['icon'],
                                              color: maroon,
                                              size: 24,
                                            ),
                                    ),
                                  ),

                                  // TITLE
                                  Positioned(
                                    left: 18,
                                    right: 12,
                                    bottom: 17,
                                    child: Text(
                                      answer['text'],
                                      style: const TextStyle(
                                        fontFamily: 'serif',
                                        fontSize: 18,
                                        height: 1.05,
                                        fontWeight:
                                            FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    const Center(
                      child: Text(
                        'Pick what feels most interesting to you',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 14,
                          color: Colors.black45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // -------------------------------------------------
            // NEXT BUTTON
            // -------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                20,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed:
                      selectedAnswers[currentQuestion] == null
                          ? null
                          : nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: maroon,
                    disabledBackgroundColor:
                        Colors.black12,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    currentQuestion ==
                            questions.length - 1
                        ? 'FINISH'
                        : 'NEXT',
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}