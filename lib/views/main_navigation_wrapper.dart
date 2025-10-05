import 'package:flutter/material.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'home_page.dart';
import 'coming_soon_page.dart';
import 'bible_quiz_page.dart';
import 'reader_page_modern.dart';
import 'spiritual_wall_page.dart';
import 'journal_page.dart';
import 'settings_page.dart';

class MainNavigationWrapper extends StatefulWidget {
  final int initialIndex;
  final String? initialRoute;
  
  const MainNavigationWrapper({
    super.key,
    this.initialIndex = 1,
    this.initialRoute,
  });

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  late int _currentIndex;
  Widget? _currentPage;

  final List<Widget> _pages = [
    const SettingsPage(), // Paramètres
    const HomePageWidget(), // Accueil
    const JournalPage(), // Journal
    const SpiritualWallPage(), // Mur Spirituel
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    
    // Si une route spécifique est demandée, afficher cette page
    if (widget.initialRoute != null) {
      _loadPageFromRoute(widget.initialRoute!);
    }
  }

  void _loadPageFromRoute(String route) {
    switch (route) {
      case '/reader':
        _currentPage = const ReaderPageModern();
        break;
      case '/spiritual_wall':
        setState(() {
          _currentIndex = 3; // Mur Spirituel
          _currentPage = null;
        });
        break;
      case '/journal':
        setState(() {
          _currentIndex = 2; // Journal
          _currentPage = null;
        });
        break;
      default:
        _currentPage = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPage ?? IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CircleNavBar(
        activeIcons: const [
          Icon(Icons.settings, color: Color(0xFF6B7280)),
          Icon(Icons.home, color: Color(0xFF6B7280)),
          Icon(Icons.book, color: Color(0xFF6B7280)),
          Icon(Icons.wallpaper, color: Color(0xFF6B7280)),
        ],
        inactiveIcons: const [
          Text("Paramètres", style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
          Text("Accueil", style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
          Text("Journal", style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
          Text("Spiritual Wall", style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
        ],
        color: Colors.white,
        height: 60,
        circleWidth: 60,
        initIndex: _currentIndex,
        onChanged: (v) {
          setState(() {
            _currentIndex = v;
            _currentPage = null; // Retour aux pages principales
          });
        },
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        cornerRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
        shadowColor: Colors.black12,
        elevation: 10,
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Colors.white, Colors.white],
        ),
      ),
    );
  }
}
