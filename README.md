# Wordle

A five-letter word puzzle for iPhone and iPad, built entirely in SwiftUI. Guess the hidden word in six tries: after each guess, the tiles show which letters are in the right spot, which are in the word but misplaced, and which aren't in it at all.

## Features

- **Daily puzzle.** Everyone gets the same word each day. The home screen previews your board and tracks which recent days you've played.
- **Classic Endless.** Play word after word and build your high score. Unfinished games resume where you left off.
- **Coins and power-ups.** Earn coins for solving and spend them on help:

  | Power-up | Cost | What it does |
  | --- | --- | --- |
  | Reveal Letter | 50 | Fills in one correct letter in the current row |
  | Eliminate 3 | 35 | Removes three letters that aren't in the word from the keyboard |
  | Skip Word | 25 | Passes on the current word (Classic only) |

- **Rewards.** Fewer guesses earn more coins (100 for a first-try solve, down to 10 for six). There are bonuses for solving without power-ups (+20), finishing the daily puzzle (+30) and every third win in a streak (+25). Losing still earns 5.
- **Stats.** Games played, win rate, streaks, guess distribution and your Classic high score.
- **Themes.** Four color palettes (Swiss Classic, Indigo Pop, Forest Matte, Obsidian Coral) with System, Light and Dark appearance.
- **Feel.** Haptic feedback, animated tile flips, confetti on a win, and soft sound effects that play only for a win, a loss or a word that isn't in the word list. Sounds follow the silent switch, and both haptics and sounds can be turned off in Settings.

All progress is stored on the device. There are no accounts, ads or network requests.

## Requirements

- Xcode 27 or later
- iOS / iPadOS 27 or later

## Getting started

```bash
git clone https://github.com/FikrSam/Wordle.git
```

```bash
open Wordle/Wordle.xcodeproj
```

Choose an iPhone simulator and press **Run** (⌘R). To run on your own device, select your team under **Signing & Capabilities** and change the bundle identifier if needed.

## Project structure

| File | Purpose |
| --- | --- |
| `WordleApp.swift`, `ContentView.swift` | App entry point and navigation between the home and game screens |
| `HomeView.swift` | Home screen: daily preview, Classic Endless entry, week strip |
| `GameView.swift` | Game board, keyboard, power-ups and the results card |
| `GameViewModel.swift` | Game state, guess checking, power-ups, coins, stats and saving |
| `WordProvider.swift` | Answer list, daily word selection and word validation |
| `TactileComponents.swift` | Reusable controls: keys, buttons, coin badge, confetti |
| `SoundManager.swift` | Sound effects, generated in code (no audio files) |
| `HapticsManager.swift` | Haptic feedback |
| `SettingsManager.swift`, `SettingsSheetView.swift` | Preferences and the Settings screen |
| `StatsSheetView.swift` | Statistics screen |
| `Models.swift` | Shared types: tiles, game modes, power-ups, themes |

Guesses are accepted if they're in the built-in answer list or recognized as English words by the iOS spell checker.
