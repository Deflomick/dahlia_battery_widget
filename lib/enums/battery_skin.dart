/// Definisce gli stili visuali disponibili per l'icona della batteria.
enum BatterySkin {
  /// Stile rettangolare classico con polo positivo.
  classic,

  /// Cerchio luminoso con effetto neon.
  neon,

  /// Semplice arco di cerchio che rappresenta la percentuale.
  minimal,

  /// Tema floreale personalizzato con petali dinamici.
  theDahlia,

  /// Utilizza le icone standard del sistema Android.
  standardAsset;

  /// Restituisce un'etichetta leggibile per l'interfaccia utente.
  String get label {
    switch (this) {
      case BatterySkin.classic:
        return 'Classic';
      case BatterySkin.neon:
        return 'Neon';
      case BatterySkin.minimal:
        return 'Minimal';
      case BatterySkin.theDahlia:
        return 'The Dahlia';
      case BatterySkin.standardAsset:
        return 'Standard';
    }
  }
}

/// Restituisce il percorso dell'asset Dahlia corrispondente al livello della batteria.
///
/// Soglie:
/// - < 40%: dahlia_low (rosso/scarico)
/// - 40% - 79%: dahlia_mid (giallo/intermedio)
/// - >= 80%: dahlia_high (verde/pieno)
String getDahliaAssetPath(int level) {
  if (level < 40) {
    return 'assets/images/dahlia_low.png';
  } else if (level >= 80) {
    return 'assets/images/dahlia_high.png';
  } else {
    return 'assets/images/dahlia_mid.png';
  }
}
