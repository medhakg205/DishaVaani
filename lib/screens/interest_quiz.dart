import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/settings/app_settings.dart';
import '../models/interest_profile.dart';
import '../services/profile_store.dart';
import '../widgets/theme_mode_toggle.dart';
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
final List<Set<String>> selectedAnswers =
    List.generate(5, (_) => <String>{});

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
    if (selectedAnswers[currentQuestion].contains(category)) {
      selectedAnswers[currentQuestion].remove(category);
    } else {
      selectedAnswers[currentQuestion].add(category);
    }
  });
}

void nextQuestion() {
  if (selectedAnswers[currentQuestion].isEmpty) {
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

for (final questionAnswers in selectedAnswers) {
  for (final category in questionAnswers) {
    if (scores.containsKey(category)) {
      scores[category] = scores[category]! + 1.0;
    }
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
    await ProfileStore().saveInitialProfile(InterestProfile(scores)); //new

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

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeModeNotifier,
      builder: (context, _, child) {
        final isDark = AppSettings.isDarkMode;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        AppColors.darkBgTop,
                        AppColors.darkBgMid,
                        AppColors.darkBgBottom,
                      ]
                    : [
                        AppColors.lightBgTop,
                        AppColors.lightBgMid,
                        AppColors.lightBgBottom,
                      ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // -------------------------------------------------
                  // TOP BAR
                  // -------------------------------------------------
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: previousQuestion,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF22161E).withValues(alpha: 0.85)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFFF5A623).withValues(alpha: 0.3)
                                    : AppColors.lightBorder,
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: isDark ? const Color(0xFFFFD54F) : AppColors.maroon,
                              size: 17,
                            ),
                          ),
                        ),

                        const Spacer(),

                        const ThemeModeToggle(),
                        const SizedBox(width: 12),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF22161E).withValues(alpha: 0.8)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFFF5A623).withValues(alpha: 0.25)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            '${currentQuestion + 1} / ${questions.length}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFFFE082) : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // -------------------------------------------------
                  // PROGRESS BAR
                  // -------------------------------------------------
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: progress,
                        backgroundColor: isDark ? Colors.white12 : Colors.black12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? const Color(0xFFF5A623) : terracotta,
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
                        24,
                        20,
                        20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFFF5A623).withValues(alpha: 0.16)
                                  : terracotta.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFFFFD54F).withValues(alpha: 0.35)
                                    : terracotta.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 13,
                                  color: isDark ? const Color(0xFFFFD54F) : terracotta,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'TAILORING YOUR AUDIO EXPERIENCE',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 10.5,
                                    letterSpacing: 1.4,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFFFFE082) : terracotta,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            question['question'],
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 27,
                              height: 1.18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Pick what speaks to you. DishaVaani will emphasize stories around these themes.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // -------------------------------------------------
                          // ANSWER GRID
                          // -------------------------------------------------
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: answers.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.82,
                            ),
                            itemBuilder: (context, index) {
                              final answer = answers[index];
                              final String category = answer['category'];
                              final bool isSelected =
                                  selectedAnswers[currentQuestion].contains(category);

                              return GestureDetector(
                                onTap: () => selectAnswer(category),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: isSelected
                                          ? (isDark ? const Color(0xFFF5A623) : terracotta)
                                          : (isDark
                                              ? Colors.white.withValues(alpha: 0.12)
                                              : Colors.black.withValues(alpha: 0.08)),
                                      width: isSelected ? 3 : 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? (isDark
                                                ? const Color(0xFFF5A623).withValues(alpha: 0.4)
                                                : terracotta.withValues(alpha: 0.28))
                                            : Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                                        blurRadius: isSelected ? 18 : 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(19),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // IMAGE
                                        CachedNetworkImage(
                                          imageUrl: answer['image'],
                                          fit: BoxFit.cover,
                                          fadeInDuration: const Duration(milliseconds: 300),
                                          fadeOutDuration: const Duration(milliseconds: 100),
                                          placeholder: (context, url) => Container(
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF1E141B)
                                                  : const Color(0xFFF5EFE6),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: maroon,
                                            child: Icon(
                                              answer['icon'],
                                              color: Colors.white,
                                              size: 50,
                                            ),
                                          ),
                                        ),

                                        // DARK GRADIENT
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withValues(alpha: 0.25),
                                                Colors.black.withValues(alpha: 0.88),
                                              ],
                                              stops: const [0.35, 0.65, 1.0],
                                            ),
                                          ),
                                        ),

                                        // ICON / CHECK BADGE
                                        Positioned(
                                          top: 10,
                                          right: 10,
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? (isDark ? const Color(0xFFF5A623) : terracotta)
                                                  : (isDark
                                                      ? const Color(0xFF1E1016).withValues(alpha: 0.75)
                                                      : Colors.white.withValues(alpha: 0.9)),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isSelected
                                                    ? Colors.white
                                                    : (isDark
                                                        ? const Color(0xFFFFD54F).withValues(alpha: 0.3)
                                                        : Colors.transparent),
                                                width: 1.2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.25),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: isSelected
                                                ? Icon(
                                                    Icons.check_rounded,
                                                    color: isDark ? const Color(0xFF1B1017) : Colors.white,
                                                    size: 24,
                                                  )
                                                : Icon(
                                                    answer['icon'],
                                                    color: isDark ? const Color(0xFFFFD54F) : maroon,
                                                    size: 20,
                                                  ),
                                          ),
                                        ),

                                        // TITLE
                                        Positioned(
                                          left: 14,
                                          right: 12,
                                          bottom: 14,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                answer['text'],
                                                style: const TextStyle(
                                                  fontFamily: 'Manrope',
                                                  fontSize: 16,
                                                  height: 1.12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              if (isSelected) ...[
                                                const SizedBox(height: 5),
                                                Container(
                                                  height: 3,
                                                  width: 24,
                                                  decoration: BoxDecoration(
                                                    color: isDark ? const Color(0xFFF5A623) : terracotta,
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 18),

                          Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Text(
                                selectedAnswers[currentQuestion].isNotEmpty
                                    ? '✨ ${selectedAnswers[currentQuestion].length} selected — great picks for your tour!'
                                    : 'Tap on what sparks your interest',
                                key: ValueKey(selectedAnswers[currentQuestion].length),
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFFFD54F) : AppColors.maroon,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // -------------------------------------------------
                  // NEXT / FINISH BUTTON
                  // -------------------------------------------------
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: selectedAnswers[currentQuestion].isEmpty
                            ? null
                            : nextQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFFF5A623) : maroon,
                          disabledBackgroundColor: isDark ? Colors.white12 : Colors.black12,
                          foregroundColor: isDark ? const Color(0xFF1E1016) : Colors.white,
                          elevation: isDark && selectedAnswers[currentQuestion].isNotEmpty ? 6 : 0,
                          shadowColor: const Color(0xFFF5A623).withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currentQuestion == questions.length - 1
                                  ? 'FINISH & START TOUR'
                                  : 'CONTINUE',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 15.5,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.bold,
                                color: selectedAnswers[currentQuestion].isEmpty
                                    ? (isDark ? Colors.white38 : Colors.black26)
                                    : (isDark ? const Color(0xFF1E1016) : Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              currentQuestion == questions.length - 1
                                  ? Icons.check_circle_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 19,
                              color: selectedAnswers[currentQuestion].isEmpty
                                  ? (isDark ? Colors.white38 : Colors.black26)
                                  : (isDark ? const Color(0xFF1E1016) : Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}