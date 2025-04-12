import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:videosdk/videosdk.dart';

class QuizWidget extends StatefulWidget {
  final Room meeting; // Room instance to retrieve meeting and participant IDs

  const QuizWidget({Key? key, required this.meeting}) : super(key: key);

  @override
  _QuizWidgetState createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget> {
  final PageController _pageController = PageController();
  int _currentQuestionIndex = 0;
  Timer? _timer;
  int _remainingTime = 15;
  bool _quizStarted = false;
  String? _selectedChoice;
  int _score = 0; // Quiz marks starts at 0

  // List of quiz questions with choices and the correct answer
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What is photography?',
      'choices': [
        'Drawing with light',
        'Painting with water',
        'Writing stories',
        'Printing documents'
      ],
      'answer': 'Drawing with light',
    },
    {
      'question': 'Which is NOT a type of photography?',
      'choices': ['Portrait', 'Landscape', 'Cooking', 'Wildlife'],
      'answer': 'Cooking',
    },
    {
      'question': 'What is used to capture the photos?',
      'choices': ['Phone', 'Camera', 'Microphone', 'Telescope'],
      'answer': 'Camera',
    },
    {
      'question': 'What controls the brightness of a photo?',
      'choices': ['ISO', 'Zoom', 'Shutter', 'Flash'],
      'answer': 'ISO',
    },
    {
      'question': 'What does a tripod do?',
      'choices': [
        'Hold the camera steady',
        'Change camera settings',
        'Clean the lens',
        'Store photos'
      ],
      'answer': 'Hold the camera steady',
    },
    {
      'question': 'Which light is best for outdoor photography?',
      'choices': ['Morning and evening', 'Noon', 'Night', 'Artificial Light'],
      'answer': 'Morning and evening',
    },
    {
      'question': 'What is a zoom lens used for?',
      'choices': [
        'Taking close-up shots from far away',
        'Adding filters',
        'Fixing blurry images',
        'Editing photos'
      ],
      'answer': 'Taking close-up shots from far away',
    },
    {
      'question': 'What is a common use of portrait photography?',
      'choices': [
        'Shooting buildings',
        'Capturing nature',
        'Photographing animals',
        'Taking selfies'
      ],
      'answer': 'Taking selfies',
    },
    {
      'question': 'What is essential for low-light photography?',
      'choices': ['Flash', 'Tripod', 'Zoom Lens', 'Filter'],
      'answer': 'Flash',
    },
    {
      'question': 'What does editing software do?',
      'choices': [
        'Improve photo quality',
        'Capture photos',
        'Print photos',
        'Store files'
      ],
      'answer': 'Improve photo quality',
    },
    {
      'question': 'What should you clean regularly in your camera?',
      'choices': ['Lens', 'Battery', 'Flash', 'Shutter'],
      'answer': 'Lens',
    },
    {
      'question': 'What is "composition" in photography?',
      'choices': [
        'How a photo is arranged',
        'The color of the photo',
        'The size of the photo',
        'The brightness of the photo'
      ],
      'answer': 'How a photo is arranged',
    },
    {
      'question': 'Which tool adjusts color tones?',
      'choices': ['Filters', 'Shutter', 'Lens Cap', 'Battery'],
      'answer': 'Filters',
    },
    {
      'question': 'What is the first step to learn photography?',
      'choices': [
        'Understanding the camera',
        'Buying a tripod',
        'Printing photos',
        'Learning to edit'
      ],
      'answer': 'Understanding the camera',
    },
    {
      'question': 'What does a "wide-angle lens" capture?',
      'choices': [
        'Large Areas',
        'Tiny Objects',
        'Close Up Shoots',
        'Distant Object'
      ],
      'answer': 'Large Areas',
    },
  ];

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Starts the quiz and the timer
  void _startQuiz() {
    setState(() {
      _quizStarted = true;
      _score = 0; // Reset score on each quiz start
    });
    _startTimer();
  }

  // Timer logic: 15 seconds per question. When time runs out, go to the next question.
  void _startTimer() {
    _remainingTime = 15;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _goToNextQuestion();
        }
      });
    });
  }

  // When the user moves to the next question, check the answer, increment score if correct, and restart timer.
  void _goToNextQuestion() {
    _timer?.cancel();

    // Check if the answer for the current question is correct.
    final currentQuestion = _questions[_currentQuestionIndex];
    if (_selectedChoice != null && _selectedChoice == currentQuestion['answer']) {
      // Increment score by 1, ensuring the score does not exceed 15 marks.
      setState(() {
        if (_score < 15) _score++;
      });
    }

    // If there are more questions, move to the next.
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedChoice = null;
      });
      _pageController.nextPage(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _startTimer();
    } else {
      // Quiz ends here: update the quiz marks in Firestore and show completion dialog.
      _timer?.cancel();
      _updateQuizMarks();
      _showQuizCompletionDialog();
    }
  }

  // Handler for when a choice is selected.
  void _onOptionSelected(String choice) {
    if (_selectedChoice == null) {
      setState(() {
        _selectedChoice = choice;
      });
      Future.delayed(Duration(seconds: 2), () {
        _goToNextQuestion();
      });
    }
  }

  // Update Firestore by altering the 'Q_marks' value for this participant.
  Future<void> _updateQuizMarks() async {
    // Retrieve the unique participant and meeting IDs.
    final String participantId = widget.meeting.localParticipant.id;
    final String meetingId = widget.meeting.id;
    try {
      final DocumentReference participantDoc = FirebaseFirestore.instance
          .collection('meeting_record')
          .doc(meetingId)
          .collection('Stats')
          .doc(participantId);

      // Use update() to set the Q_marks field to the current _score.
      await participantDoc.update({'Q_marks': _score});
      debugPrint('Quiz marks updated to $_score for participant $participantId');
    } catch (e) {
      debugPrint('Error updating quiz marks: $e');
    }
  }

  // Display a dialog when the quiz is completed.
  void _showQuizCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Quiz Completed',
          style: GoogleFonts.quicksand(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
        ),
        content: Text(
          'Your score is: $_score/15',
          style: GoogleFonts.quicksand(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Optionally, reset the quiz to allow another attempt.
              setState(() {
                _currentQuestionIndex = 0;
                _selectedChoice = null;
                _quizStarted = false;
              });
              _pageController.jumpToPage(0);
            },
            child: Text(
              'Restart',
              style: GoogleFonts.quicksand(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // Build method renders either the quiz start UI or the active quiz.
  @override
  Widget build(BuildContext context) {
    return _quizStarted
        ? SizedBox(
      height: 400,
      child: Column(
        children: [
          Text(
            'Time Remaining: $_remainingTime seconds',
            style: GoogleFonts.quicksand(
              fontSize: 16,
              color: Colors.redAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question['question'],
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 20),
                      Wrap(
                        spacing: 10.0,
                        runSpacing: 10.0,
                        children: (question['choices'] as List).map<Widget>((choice) {
                          bool isSelected = choice == _selectedChoice;
                          bool isCorrect = choice == question['answer'];
                          Color backgroundColor;
                          if (isSelected) {
                            backgroundColor = isCorrect ? Colors.green : Colors.red;
                          } else {
                            backgroundColor = Colors.white;
                          }
                          return GestureDetector(
                            onTap: _selectedChoice == null
                                ? () => _onOptionSelected(choice)
                                : null,
                            child: Container(
                              width: MediaQuery.of(context).size.width / 2 - 30,
                              padding: EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(color: Colors.grey),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                choice,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.quicksand(
                                  fontSize: 16,
                                  color: isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    )
        : Column(
      children: [
        Divider(),
        Center(
          child: Text(
            'Quiz is Based on Lecture #01',
            style: GoogleFonts.quicksand(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Divider(),
        Center(
          child: ElevatedButton(
            onPressed: _startQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: Text(
              'Start Quiz',
              style: GoogleFonts.quicksand(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
