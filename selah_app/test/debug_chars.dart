void main() {
  const text = 'Jésus dit: "Bonjour" et « salut ».';
  
  for (int i = 0; i < text.length; i++) {
    final ch = text[i];
    final code = ch.codeUnitAt(0);
    print('Char: $ch (code: $code)');
    
    if (ch == '"' || ch == '"') {
      print('  -> Détecté comme guillemet typographique');
    }
  }
}

