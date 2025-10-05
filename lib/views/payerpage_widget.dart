import '/components/card42_product_details_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:carousel_slider/carousel_slider.dart' as carousel;
import 'package:flip_card/flip_card.dart';
import 'package:ff_theme/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import '../utils/prayer_subjects_mapper.dart';
import 'package:go_router/go_router.dart';

import 'payerpage_model.dart';
export 'payerpage_model.dart';

class PayerpageWidget extends StatefulWidget {
  const PayerpageWidget({super.key});

  static String routeName = 'Payerpage';
  static String routePath = '/payerpage';

  @override
  State<PayerpageWidget> createState() => _PayerpageWidgetState();
}

class _PayerpageWidgetState extends State<PayerpageWidget> {
  late PayerpageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Données dynamiques
  List<PrayerItem> _items = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PayerpageModel());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      safeSetState(() {});
      _loadPrayerItems();
    });
  }
  
  void _loadPrayerItems() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Map? args;
      try {
        final extra = GoRouterState.of(context).extra;
        if (extra is Map) args = extra;
      } catch (_) {
        // Navigator classique
        args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
      }
      final raw = (args?['items'] as List?) ?? [];
      setState(() {
        _items = raw.cast<PrayerItem>();
      });
    });
  }
  
  void _toggleValidate(int index) {
    setState(() {
      _items[index].validated = !_items[index].validated;
      // déplacer l'item validé à la fin
      final item = _items.removeAt(index);
      if (item.validated) {
        _items.add(item);
      } else {
        final firstValidated = _items.indexWhere((e) => e.validated);
        final insertAt = (firstValidated == -1) ? _items.length : firstValidated;
        _items.insert(insertAt, item);
      }
    });
  }
  
  List<Widget> _buildDynamicCards() {
    return _items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return _buildDynamicPrayerCard(item, index);
    }).toList();
  }
  
  List<Widget> _buildDefaultCards() {
    // Cartes par défaut si pas de données
    return [
      _buildDefaultCard(FlutterFlowTheme.of(context).tertiary, FlutterFlowTheme.of(context).error, 'Louange', 'Adorer Dieu pour sa bonté'),
      _buildDefaultCard(FlutterFlowTheme.of(context).success, FlutterFlowTheme.of(context).accent2, 'Action de grâce', 'Remercier pour les bénédictions'),
      _buildDefaultCard(FlutterFlowTheme.of(context).success, FlutterFlowTheme.of(context).success, 'Repentance', 'Demander pardon et purification'),
      _buildDefaultCard(FlutterFlowTheme.of(context).info, FlutterFlowTheme.of(context).info, 'Obéissance', 'Mettre en pratique la Parole'),
      _buildDefaultCard(FlutterFlowTheme.of(context).error, FlutterFlowTheme.of(context).error, 'Intercession', 'Prier pour les autres'),
    ];
  }
  
  Widget _buildDynamicPrayerCard(PrayerItem item, int index) {
    final isValidated = item.validated;
    
    return Stack(
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(3, 0, 0, 0),
          child: Container(
            width: 386.8,
            height: 100,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              boxShadow: [
                BoxShadow(
                  blurRadius: 8,
                  color: Color(0x33000000),
                  offset: Offset(0, 2),
                )
              ],
              borderRadius: BorderRadius.circular(22),
            ),
            child: FlipCard(
              fill: Fill.fillBack,
              direction: FlipDirection.HORIZONTAL,
              speed: 400,
              front: Container(
                width: 365.07,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isValidated 
                      ? [Colors.grey[300]!, Colors.grey[400]!]
                      : [item.color, item.color.withOpacity(0.8)],
                    stops: [0, 1],
                    begin: AlignmentDirectional(0, -1),
                    end: AlignmentDirectional(0, 1),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: AlignmentDirectional(0, 0),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(0, 10, 55, 0),
                        child: GradientText(
                          'THÈME DE PRIÈRE',
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).lightMutedColor,
                            fontSize: 26,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                            shadows: [
                              Shadow(
                                color: FlutterFlowTheme.of(context).secondaryText,
                                offset: Offset(2.0, 2.0),
                                blurRadius: 8.0,
                              )
                            ],
                          ),
                          colors: [
                            FlutterFlowTheme.of(context).primaryBackground,
                            FlutterFlowTheme.of(context).lightMutedColor
                          ],
                          gradientDirection: GradientDirection.ltr,
                          gradientType: GradientType.linear,
                        ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional(0, 0.4),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(0, 20, 0, 0),
                        child: Text(
                          item.theme.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).lightMutedColor,
                            fontSize: 18,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional(1, -1),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(0, 6, 10, 0),
                        child: Icon(
                          isValidated ? Icons.check_circle : Icons.swipe_left,
                          color: FlutterFlowTheme.of(context).lightMutedColor,
                          size: 33,
                        ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional(0, -1),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(220, 16, 0, 0),
                        child: Text(
                          isValidated ? 'TERMINÉ' : 'Tourne pour voir le sujet de prière',
                          textAlign: TextAlign.end,
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.poppins(
                              fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                              fontStyle: FontStyle.italic,
                            ),
                            color: FlutterFlowTheme.of(context).lightMutedColor,
                            fontSize: 8,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                            fontStyle: FontStyle.italic,
                            lineHeight: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              back: InkWell(
                onTap: () => _toggleValidate(index),
                child: Container(
                  width: 380.4,
                  height: 100,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).lightMutedColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: AlignmentDirectional(0, -0.4),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(0, 1, 55, 0),
                          child: Text(
                            'Sujet de Prière',
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).darkMutedColor,
                              fontSize: 22,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional(0, 0.3),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(16, 0, 55, 0),
                          child: Text(
                            item.subject,
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                              ),
                              color: isValidated 
                                ? FlutterFlowTheme.of(context).darkMutedColor.withOpacity(0.6)
                                : FlutterFlowTheme.of(context).darkMutedColor,
                              fontSize: 16,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w500,
                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                              decoration: isValidated ? TextDecoration.lineThrough : TextDecoration.none,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional(1, -1),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(0, 6, 10, 0),
                          child: Icon(
                            isValidated ? Icons.check_circle : Icons.touch_app,
                            color: FlutterFlowTheme.of(context).darkMutedColor,
                            size: 33,
                          ),
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional(0, -1),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(220, 16, 8, 0),
                          child: Text(
                            isValidated ? 'VALIDÉ' : 'Tapez pour Valider le sujet de prière',
                            textAlign: TextAlign.end,
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.poppins(
                                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                fontStyle: FontStyle.italic,
                              ),
                              color: FlutterFlowTheme.of(context).darkMutedColor,
                              fontSize: 8,
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                              fontStyle: FontStyle.italic,
                              lineHeight: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDefaultCard(Color color1, Color color2, String theme, String subject) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(3, 0, 0, 0),
          child: Container(
            width: 386.8,
            height: 100,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              boxShadow: [
                BoxShadow(
                  blurRadius: 8,
                  color: Color(0x33000000),
                  offset: Offset(0, 2),
                )
              ],
              borderRadius: BorderRadius.circular(22),
            ),
            child: FlipCard(
              fill: Fill.fillBack,
              direction: FlipDirection.HORIZONTAL,
              speed: 400,
              front: Container(
                width: 365.07,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color1, color2],
                    stops: [0, 1],
                    begin: AlignmentDirectional(0, -1),
                    end: AlignmentDirectional(0, 1),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: AlignmentDirectional(0, 0),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(0, 10, 55, 0),
                        child: GradientText(
                          'THÈME DE PRIÈRE',
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).lightMutedColor,
                            fontSize: 26,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                            shadows: [
                              Shadow(
                                color: FlutterFlowTheme.of(context).secondaryText,
                                offset: Offset(2.0, 2.0),
                                blurRadius: 8.0,
                              )
                            ],
                          ),
                          colors: [
                            FlutterFlowTheme.of(context).primaryBackground,
                            FlutterFlowTheme.of(context).lightMutedColor
                          ],
                          gradientDirection: GradientDirection.ltr,
                          gradientType: GradientType.linear,
                        ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional(0, 0.4),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(0, 20, 0, 0),
                        child: Text(
                          theme.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).lightMutedColor,
                            fontSize: 18,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional(1, -1),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(0, 6, 10, 0),
                        child: Icon(
                          Icons.swipe_left,
                          color: FlutterFlowTheme.of(context).lightMutedColor,
                          size: 33,
                        ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional(0, -1),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(220, 16, 0, 0),
                        child: Text(
                          'Tourne pour voir le sujet de prière',
                          textAlign: TextAlign.end,
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.poppins(
                              fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                              fontStyle: FontStyle.italic,
                            ),
                            color: FlutterFlowTheme.of(context).lightMutedColor,
                            fontSize: 8,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                            fontStyle: FontStyle.italic,
                            lineHeight: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              back: Container(
                width: 380.4,
                height: 100,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).lightMutedColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: AlignmentDirectional(0, -0.4),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(0, 1, 55, 0),
                        child: Text(
                          'Sujet de Prière',
                          textAlign: TextAlign.center,
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).darkMutedColor,
                            fontSize: 22,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional(0, 0.3),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(16, 0, 55, 0),
                        child: Text(
                          subject,
                          textAlign: TextAlign.center,
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).darkMutedColor,
                            fontSize: 16,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w500,
                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional(1, -1),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(0, 6, 10, 0),
                        child: Icon(
                          Icons.touch_app,
                          color: FlutterFlowTheme.of(context).darkMutedColor,
                          size: 33,
                        ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional(0, -1),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(220, 16, 8, 0),
                        child: Text(
                          'Tapez pour Valider le sujet de prière',
                          textAlign: TextAlign.end,
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.poppins(
                              fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                              fontStyle: FontStyle.italic,
                            ),
                            color: FlutterFlowTheme.of(context).darkMutedColor,
                            fontSize: 8,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                            fontStyle: FontStyle.italic,
                            lineHeight: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).accent3,
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Stack(
                children: [
                  Align(
                    alignment: AlignmentDirectional(0, 0),
                    child: wrapWithModel(
                      model: _model.card42ProductDetailsModel,
                      updateCallback: () => safeSetState(() {}),
                      updateOnChange: true,
                      child: Card42ProductDetailsWidget(),
                    ),
                  ),
                ],
              ),
              Stack(
                children: [
                  Align(
                    alignment: AlignmentDirectional(0, 0),
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(8, 55, 8, 0),
                      child: Container(
                        width: double.infinity,
                        height: 420.81,
                        child: carousel.CarouselSlider(
                          items: _items.isEmpty ? _buildDefaultCards() : _buildDynamicCards(),
                          carouselController: _model.carouselController ??= carousel.CarouselController(),
                          options: carousel.CarouselOptions(
                            initialPage: 1,
                            viewportFraction: 0.24,
                            disableCenter: true,
                            enlargeCenterPage: true,
                            enlargeFactor: 0.15,
                            enableInfiniteScroll: true,
                            scrollDirection: Axis.vertical,
                            autoPlay: false,
                            onPageChanged: (index, _) => _model.carouselCurrentIndex = index,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}