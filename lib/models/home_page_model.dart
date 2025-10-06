import 'package:flutter/material.dart';

class HomePageModel extends ChangeNotifier {
  /// Calendar
  DateTimeRange? calendarSelectedDay;

  /// Carousel
  final PageController pageController = PageController();
  int carouselCurrentIndex = 1;

  void initState(BuildContext context) {
    final now = DateTime.now();
    calendarSelectedDay = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  void updateCarouselIndex(int index) {
    carouselCurrentIndex = index;
    notifyListeners();
  }

  void updateSelectedDay(DateTimeRange? selectedDay) {
    calendarSelectedDay = selectedDay;
    notifyListeners();
  }

  @override
  void dispose() {
    // rien à disposer pour CarouselController
    super.dispose();
  }
}
