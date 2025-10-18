# IELTS Flashcards - Color Palette (Allineato a Pathway)

## 🎨 Sistema di Colori Pathway Applicato

L'applicazione IELTS Flashcards è ora completamente allineata al sistema di design di **Pathway**. I colori sono stati selezionati dal progetto Pathway per garantire coerenza visiva.

### Colori Principali

| Nome | Codice Hex | RGB | Utilizzo |
|------|-----------|-----|----------|
| **Primary (Rosso)** | `#e23434` | 226, 52, 52 | Accenti, errori, elementi importanti |
| **Secondary (Blu Scuro)** | `#2b2b6c` | 43, 43, 108 | Colore principale, header, titoli |
| **Writing (Blu Chiaro)** | `#94a8ca` | 148, 168, 202 | Categoria Writing |
| **Speaking (Verde)** | `#9bb175` | 155, 177, 117 | Categoria Speaking, azioni positive |
| **Listening (Giallo)** | `#face84` | 250, 206, 132 | Categoria Listening |
| **Reading (Viola)** | `#ad87c2` | 173, 135, 194 | Categoria Reading |
| **AI (Oro)** | `#e5bb00` | 229, 187, 0 | Funzionalità AI |

### Colori Semantici per le Azioni

| Azione | Colore | Utilizzo |
|--------|--------|----------|
| **Ripeti (Again)** | Rosso `#fb0000` | Revisione immediata |
| **Buono (Good)** | Viola (Reading) | Intervallo medio |
| **Facile (Easy)** | Verde (Speaking) | Intervallo lungo |

## 📱 Applicazione nel Design

### Componenti Principali

1. **Navigation Bar**
   - Titolo: Blu scuro secondario (#2b2b6c)
   - Icone: Blu scuro secondario (#2b2b6c)

2. **Flashcard**
   - Sfondo: Bianco con gradiente leggero
   - Titolo parola: Blu scuro secondario (#2b2b6c)
   - Traduzione: Rosso primario (#e23434)
   - Etichette (Definizione, Esempio): Viola Reading (#ad87c2)

3. **Pulsanti Azione**
   - "Ripeti": Rosso (#fb0000)
   - "Buono": Viola Reading (#ad87c2)
   - "Facile": Verde Speaking (#9bb175)

4. **Swipe Badges**
   - "Ripeti": Rosso (#fb0000)
   - "Buono": Viola Reading (#ad87c2)
   - "Facile": Verde Speaking (#9bb175)

5. **Progress Bar**
   - Colore: Blu scuro secondario (#2b2b6c)

6. **Livello Badge**
   - Sfondo: Blu scuro secondario (#2b2b6c)
   - Testo: Bianco

## 🎯 Vantaggi del Design Allineato

✅ **Coerenza Visiva**: Allineamento con la palette di Pathway
✅ **Usabilità**: Colori semantici chiari per le azioni (rosso = ripeti, verde = facile)
✅ **Accessibilità**: Contrasti appropriati per leggibilità
✅ **Professionionalità**: Design moderno e curato

## 🔄 Composizione Colori nel Codice

I colori sono definiti nello struct `AppColors` in `ContentView.swift`:

```swift
struct AppColors {
    static let primary = Color(red: 226/255, green: 52/255, blue: 52/255) // #e23434
    static let secondary = Color(red: 43/255, green: 43/255, blue: 108/255) // #2b2b6c
    static let writing = Color(red: 148/255, green: 168/255, blue: 202/255)
    static let speaking = Color(red: 155/255, green: 177/255, blue: 117/255)
    static let listening = Color(red: 250/255, green: 206/255, blue: 132/255)
    static let reading = Color(red: 173/255, green: 135/255, blue: 194/255)
    static let ai = Color(red: 229/255, green: 187/255, blue: 0/255)
}
```

Questo consente di mantenere la coerenza e di aggiornare facilmente i colori in futuro.

---

**Ultimo aggiornamento**: 18 Ottobre 2025
**Versione Pathway Utilizzata**: 2025
**Compatibilità**: iOS 26.0+
