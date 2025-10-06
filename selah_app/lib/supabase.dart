// lib/supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://rvwwgvzuwlxnnzumsqvg.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ2d3dndnp1d2x4bm56dW1zcXZnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0MDY3NTIsImV4cCI6MjA3NDk4Mjc1Mn0.FK28ps82t97Yo9vz9CB7FbKpo-__YnXYo8GHIw-8GmQ';

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
}
