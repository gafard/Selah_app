import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Note {
  final String id;
  final String passageId;
  final String text;
  final int startOffset;
  final int endOffset;
  final DateTime createdAt;
  final String? verseReference;

  Note({
    required this.id,
    required this.passageId,
    required this.text,
    required this.startOffset,
    required this.endOffset,
    required this.createdAt,
    this.verseReference,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'passageId': passageId,
    'text': text,
    'startOffset': startOffset,
    'endOffset': endOffset,
    'createdAt': createdAt.toIso8601String(),
    'verseReference': verseReference,
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'],
    passageId: json['passageId'],
    text: json['text'],
    startOffset: json['startOffset'],
    endOffset: json['endOffset'],
    createdAt: DateTime.parse(json['createdAt']),
    verseReference: json['verseReference'],
  );
}

class NotesService {
  static const String _notesKey = 'user_notes';
  
  Future<List<Note>> getNotesForPassage(String passageId) async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getStringList(_notesKey) ?? [];
    
    return notesJson
        .map((json) => Note.fromJson(jsonDecode(json)))
        .where((note) => note.passageId == passageId)
        .toList();
  }
  
  Future<void> saveNote(Note note) async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getStringList(_notesKey) ?? [];
    
    // Remove existing note with same ID if it exists
    notesJson.removeWhere((json) {
      final existingNote = Note.fromJson(jsonDecode(json));
      return existingNote.id == note.id;
    });
    
    // Add new note
    notesJson.add(jsonEncode(note.toJson()));
    
    await prefs.setStringList(_notesKey, notesJson);
  }
  
  Future<void> deleteNote(String noteId) async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getStringList(_notesKey) ?? [];
    
    notesJson.removeWhere((json) {
      final note = Note.fromJson(jsonDecode(json));
      return note.id == noteId;
    });
    
    await prefs.setStringList(_notesKey, notesJson);
  }
  
  Future<List<Note>> getAllNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getStringList(_notesKey) ?? [];
    
    return notesJson
        .map((json) => Note.fromJson(jsonDecode(json)))
        .toList();
  }
}
