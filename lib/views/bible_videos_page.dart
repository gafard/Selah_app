import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bible_video.dart';

class BibleVideosPage extends StatefulWidget {
  final List<String>? bibleReferences; // Références pour filtrer les vidéos pertinentes

  const BibleVideosPage({
    super.key,
    this.bibleReferences,
  });

  @override
  State<BibleVideosPage> createState() => _BibleVideosPageState();
}

class _BibleVideosPageState extends State<BibleVideosPage>
    with TickerProviderStateMixin {
  // Palette de couleurs de Selah
  static const Color _darkBackground = Color(0xFF1C1C1E);
  static const Color _goldAccent = Color(0xFF8B7355);
  static const Color _softWhite = Color(0xFFF5F5F5);
  static const Color _mediumGrey = Color(0xFF8E8E93);
  static const Color _cardBackground = Color(0xFF2C2C2E);

  late TabController _tabController;
  List<BibleVideo> _allVideos = [];
  List<BibleVideo> _relevantVideos = [];
  List<BibleVideo> _bookOverviews = [];
  List<BibleVideo> _themeVideos = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVideos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadVideos() {
    _allVideos = BibleProjectVideos.getDemoVideos();
    
    if (widget.bibleReferences != null) {
      _relevantVideos = BibleProjectVideos.getVideosForReading(widget.bibleReferences!);
    }
    
    _bookOverviews = BibleProjectVideos.getVideosByCategory('book_overview');
    _themeVideos = BibleProjectVideos.getVideosByCategory('theme');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                if (widget.bibleReferences != null)
                  _buildVideosList(_relevantVideos, 'Aucune vidéo trouvée pour cette lecture.')
                else
                  _buildVideosList(_allVideos, 'Aucune vidéo disponible.'),
                _buildVideosList(_bookOverviews, 'Aucun aperçu de livre disponible.'),
                _buildVideosList(_themeVideos, 'Aucune vidéo thématique disponible.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: _goldAccent),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: _goldAccent),
          onPressed: () {
            // TODO: Implémenter la recherche de vidéos
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Recherche à venir !')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _goldAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.play_circle_filled,
                  color: _goldAccent,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vidéos BibleProject',
                      style: GoogleFonts.playfairDisplay(
                        color: _softWhite,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Explorez les Écritures visuellement',
                      style: GoogleFonts.lato(
                        color: _mediumGrey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.bibleReferences != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _goldAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _goldAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_stories, color: _goldAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vidéos pour: ${widget.bibleReferences!.join(", ")}',
                      style: GoogleFonts.lato(
                        color: _goldAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _goldAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: _darkBackground,
        unselectedLabelColor: _mediumGrey,
        labelStyle: GoogleFonts.lato(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.lato(fontWeight: FontWeight.normal),
        tabs: [
          Tab(text: widget.bibleReferences != null ? 'Pertinentes' : 'Toutes'),
          const Tab(text: 'Livres'),
          const Tab(text: 'Thèmes'),
        ],
      ),
    );
  }

  Widget _buildVideosList(List<BibleVideo> videos, String emptyMessage) {
    if (videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.video_library_outlined,
              color: _mediumGrey,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: GoogleFonts.lato(
                color: _mediumGrey,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return _AnimatedVideoCard(
          video: video,
          delay: Duration(milliseconds: 100 * index),
          onTap: () => _playVideo(video),
        );
      },
    );
  }

  void _playVideo(BibleVideo video) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPlayerPage(video: video),
      ),
    );
  }
}

class _AnimatedVideoCard extends StatelessWidget {
  final BibleVideo video;
  final Duration delay;
  final VoidCallback onTap;

  // Palette de couleurs
  static const Color _darkBackground = Color(0xFF1C1C1E);
  static const Color _goldAccent = Color(0xFF8B7355);
  static const Color _softWhite = Color(0xFFF5F5F5);
  static const Color _mediumGrey = Color(0xFF8E8E93);
  static const Color _cardBackground = Color(0xFF2C2C2E);

  const _AnimatedVideoCard({
    required this.video,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail avec overlay de lecture
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _goldAccent.withOpacity(0.3),
                              _goldAccent.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_filled,
                            color: _goldAccent,
                            size: 64,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Badge de durée
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        video.formattedDuration,
                        style: GoogleFonts.lato(
                          color: _softWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  // Badge de catégorie
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _goldAccent.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        video.categoryDisplayName,
                        style: GoogleFonts.lato(
                          color: _darkBackground,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Contenu textuel
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: GoogleFonts.playfairDisplay(
                        color: _softWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      video.description,
                      style: GoogleFonts.lato(
                        color: _mediumGrey,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    // Tags des livres bibliques
                    if (video.relatedBooks.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: video.relatedBooks.map((book) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _goldAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              book,
                              style: GoogleFonts.lato(
                                color: _goldAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Page de lecture vidéo
class VideoPlayerPage extends StatefulWidget {
  final BibleVideo video;

  const VideoPlayerPage({super.key, required this.video});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  static const Color _darkBackground = Color(0xFF1C1C1E);
  static const Color _goldAccent = Color(0xFF8B7355);
  static const Color _softWhite = Color(0xFFF5F5F5);
  static const Color _cardBackground = Color(0xFF2C2C2E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _goldAccent),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player vidéo placeholder
            Container(
              height: 200,
              color: _cardBackground,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_circle_filled, color: _goldAccent, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Video Player',
                      style: GoogleFonts.lato(
                        color: _softWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Informations de la vidéo
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: GoogleFonts.playfairDisplay(
                      color: _softWhite,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _cardBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: GoogleFonts.lato(
                            color: _goldAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.video.description,
                          style: GoogleFonts.lato(
                            color: _softWhite,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.video.relatedBooks.isNotEmpty) ...[
                    Text(
                      'Livres bibliques associés',
                      style: GoogleFonts.lato(
                        color: _goldAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: widget.video.relatedBooks.map((book) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _goldAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _goldAccent.withOpacity(0.3)),
                          ),
                          child: Text(
                            book,
                            style: GoogleFonts.lato(
                              color: _goldAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
