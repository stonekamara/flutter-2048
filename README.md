# 🎮 2048 Flutter

A polished [2048](https://play2048.co/) puzzle game built with **Flutter**. Join the tiles, reach the 2048 tile and beat your best score!

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)

## ✨ Features

- 🧩 Classic 4×4 gameplay swipe to slide and merge tiles
- 🎬 Smooth animations: tiles glide, new tiles pop in, merges bounce
- 🏆 Score tracking with **best score saved** between sessions
- 🎉 Win overlay when you reach 2048 (keep playing if you dare!)
- 💀 Game-over detection with instant restart
- ⌨️ Keyboard support (arrow keys or WASD) on desktop & web
- 📱 Responsive layout plays great on phones, tablets and desktop
- 🖥️ Runs on Android, iOS and the web

## 📸 Screenshots

| Gameplay | Merging | Game over |
|----------|---------|-----------|
| *(add your screenshots here)* | | |

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or later)

### Run it

```bash
git clone https://github.com/stonekamara/flutter-2048.git
cd flutter-2048
flutter pub get
flutter run
```

Pick your target device (Android emulator, iOS simulator, Chrome or desktop).

### Play on the web

```bash
flutter run -d chrome
```

### Run the tests

```bash
flutter test
```

## 🎯 How to play

1. **Swipe** (or use the **arrow keys** / **WASD**) to move all tiles in one direction
2. Tiles with the same number **merge** when they collide, doubling their value
3. Each merge adds the new tile's value to your **score**
4. A new random tile (**2** or **4**) appears after every move
5. Reach **2048** to win keep going for a higher score!

## 🏗️ Architecture

```
lib/
├── main.dart        # UI, animations and game screen
└── game_2048.dart   # Pure game logic (board, moves, merges, scoring)
```

The game logic is kept **independent from Flutter** (`game_2048.dart` has zero UI dependencies), which keeps it easy to test and reuse.

## 🧪 Testing

- Widget tests verify the board renders and responds to swipes
- Unit tests cover the merge logic and scoring

## 📄 License

This project is licensed under the MIT License see the [LICENSE](LICENSE) file for details.

---

Made with ❤️ and Flutter.