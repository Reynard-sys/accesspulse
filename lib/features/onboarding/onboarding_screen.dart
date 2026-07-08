import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.onCompleted, super.key});

  final VoidCallback onCompleted;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8faf9),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: [
                        _buildPageContent(
                          context,
                          titleWidget: Text(
                            'Places have living accessibility states.',
                            style: GoogleFonts.afacad(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              height: 1.11,
                              color: const Color(0xff17201c),
                              letterSpacing: -0.59,
                            ),
                          ),
                          description:
                              'Accessibility changes when ramps are blocked, elevators break, entrances degrade, or fixes are made. A place is not accessible forever because it was once declared accessible.',
                          imagePath: 'assets/images/man_in_wheelchair.png',
                        ),
                        _buildPageContent(
                          context,
                          titleWidget: Text(
                            'Your visit can update what others know.',
                            style: GoogleFonts.afacad(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              height: 1.11,
                              color: const Color(0xff17201c),
                              letterSpacing: -0.59,
                            ),
                          ),
                          description:
                              'Answer a few simple questions after visiting a place. Your confirmation helps the next person decide before they go.',
                          imagePath: 'assets/images/female_in_wheelchair.png',
                        ),
                        _buildPageContent(
                          context,
                          titleWidget: Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'Access'),
                                TextSpan(
                                  text: 'Pulse ',
                                  style: TextStyle(
                                    color: const Color(0xff2e7d5b),
                                  ),
                                ),
                                const TextSpan(
                                  text: 'turns experience into action.',
                                ),
                              ],
                            ),
                            style: GoogleFonts.afacad(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              height: 1.11,
                              color: const Color(0xff17201c),
                              letterSpacing: -0.59,
                            ),
                          ),
                          description:
                              'AI helps strengthen evidence, and institutions receive structured accessibility intelligence.',
                          imagePath: 'assets/images/teacher_and_girl.png',
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: _buildBottomControls(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(
    BuildContext context, {
    required Widget titleWidget,
    required String description,
    required String imagePath,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: titleWidget,
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            description,
            style: GoogleFonts.afacad(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: const Color(0xff5d6b63),
              height: 1.20,
              letterSpacing: -0.32,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: imagePath == 'assets/images/female_in_wheelchair.png'
                ? Transform.translate(
                    offset: const Offset(0.0, 30.0),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.fitWidth,
                      width: double.infinity,
                    ),
                  )
                : imagePath == 'assets/images/teacher_and_girl.png'
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.fitWidth,
                      width: double.infinity,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: Image.asset(imagePath, fit: BoxFit.contain),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    if (_currentPage < 2) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Semantics(
            label: 'Next onboarding page',
            button: true,
            child: InkWell(
              key: const ValueKey('onboarding-next-button'),
              onTap: _nextPage,
              borderRadius: BorderRadius.circular(26),
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xff17201c),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: Semantics(
          label: 'Check a Place',
          button: true,
          child: ElevatedButton(
            onPressed: widget.onCompleted,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff2e7d5b),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.6),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Check a Place',
                  style: GoogleFonts.afacad(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.15,
                    height: 1.37,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
