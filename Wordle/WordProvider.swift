//
//  WordProvider.swift
//  Wordle
//
//  Created by Fikir on 11/9/26.
//

import UIKit

struct WordProvider {
    /// Curated list of 320+ high-frequency, well-known 5-letter English words for targets
    static let curatedTargetWords: [String] = [
        "ABOUT", "ABOVE", "ACTOR", "ACUTE", "ADMIT", "ADOPT", "ADULT", "AFTER", "AGAIN", "AGENT",
        "AGREE", "AHEAD", "ALARM", "ALBUM", "ALERT", "ALIKE", "ALIVE", "ALLOW", "ALONE", "ALONG",
        "ALTER", "AMONG", "ANGER", "ANGLE", "ANGRY", "APART", "APPLE", "APPLY", "ARENA", "ARGUE",
        "ARISE", "ARMOR", "ARROW", "ASIDE", "ASSET", "AUDIO", "AUDIT", "AVOID", "AWAIT", "AWAKE",
        "AWARD", "AWARE", "BADGE", "BAKER", "BASIC", "BASIS", "BEACH", "BEAST", "BEGIN", "BEING",
        "BELOW", "BENCH", "BIRTH", "BLACK", "BLADE", "BLAME", "BLAND", "BLANK", "BLAST", "BLAZE",
        "BLEND", "BLESS", "BLIND", "BLOCK", "BLOOD", "BLOOM", "BLOWN", "BOARD", "BOAST", "BONUS",
        "BOOST", "BOOTH", "BOUND", "BRAIN", "BRAND", "BRAVE", "BREAD", "BREAK", "BREED", "BRIEF",
        "BRICK", "BRING", "BRISK", "BROAD", "BROWN", "BRUSH", "BUILD", "BUILT", "BUNCH", "BURST",
        "CABIN", "CABLE", "CAMEL", "CANAL", "CANDY", "CANOE", "CARGO", "CARRY", "CATCH", "CAUSE",
        "CEDAR", "CHAIN", "CHAIR", "CHALK", "CHAMP", "CHANT", "CHAOS", "CHARM", "CHART", "CHASE",
        "CHEAP", "CHECK", "CHEEK", "CHEER", "CHEST", "CHIEF", "CHILD", "CHILL", "CHORD", "CIDER",
        "CIVIL", "CLAIM", "CLAMP", "CLASH", "CLASP", "CLASS", "CLEAN", "CLEAR", "CLERK", "CLICK",
        "CLIFF", "CLIMB", "CLOAK", "CLOCK", "CLONE", "CLOSE", "CLOTH", "CLOUD", "CLOVE", "CLOWN",
        "COAST", "COLOR", "COMET", "CORAL", "COUNT", "COURT", "COVER", "CRACK", "CRAFT", "CRANE",
        "CRASH", "CRATE", "CRAVE", "CRAWL", "CRAZY", "CREAM", "CREEK", "CRIME", "CRISP", "CROSS",
        "CROWD", "CROWN", "CRUSH", "CURVE", "CYCLE", "DAILY", "DANCE", "DREAM", "DRIFT", "DRINK",
        "DRIVE", "EARLY", "EARTH", "EAGLE", "ELITE", "EMPTY", "ENEMY", "ENJOY", "ENTER", "EQUAL",
        "ERROR", "EVENT", "EVERY", "EXACT", "EXIST", "FAITH", "FALSE", "FANCY", "FAULT", "FAVOR",
        "FEAST", "FIBER", "FIELD", "FIGHT", "FINAL", "FIRST", "FLAME", "FLASH", "FLEET", "FLOAT",
        "FLOOD", "FLOOR", "FLOUR", "FLOCK", "FLUID", "FLUTE", "FOCUS", "FORCE", "FORTH", "FORTY",
        "FORUM", "FOUND", "FRAME", "FRESH", "FRONT", "FROST", "FRUIT", "GIANT", "GIVEN", "GLEAM",
        "GLASS", "GLOBE", "GLORY", "GLOVE", "GRACE", "GRADE", "GRAIN", "GRAND", "GRANT", "GRAPE",
        "GRAPH", "GRASP", "GRASS", "GRAVE", "GREAT", "GREEN", "GREET", "GRIEF", "GRILL", "GROVE",
        "GUARD", "GUESS", "GUIDE", "HABIT", "HAPPY", "HARSH", "HAVEN", "HEART", "HEAVY", "HONOR",
        "HORSE", "HOTEL", "HOUSE", "HUMAN", "HUMOR", "IDEAL", "IMAGE", "INDEX", "INNER", "INPUT",
        "IRONY", "ISSUE", "JEWEL", "JOINT", "JUDGE", "JUICE", "KNIFE", "KNOCK", "LABEL", "LABOR",
        "LARGE", "LASER", "LATCH", "LATER", "LAUGH", "LAYER", "LEARN", "LEASE", "LEAST", "LEMON",
        "LEVEL", "LEVER", "LIGHT", "LIMIT", "LIVER", "LOCAL", "LOGIC", "LOOSE", "LOVER", "LOWER",
        "LUCKY", "LUNAR", "LUNCH", "MAGIC", "MAJOR", "MAKER", "MANGO", "MANOR", "MAPLE", "MARCH",
        "MATCH", "MAYOR", "MEDAL", "MEDIA", "MELON", "MERCY", "MERIT", "METAL", "METER", "MICRO",
        "MIGHT", "MINOR", "MIXER", "MODEL", "MODEM", "MONEY", "MONTH", "MORAL", "MOTOR", "MOUNT",
        "MOUSE", "MOUTH", "MOVIE", "MUSIC", "NAVAL", "NERVE", "NIGHT", "NOBLE", "NOISE", "NORTH",
        "NOVEL", "NURSE", "OCEAN", "OFFER", "OFTEN", "OLIVE", "ONION", "OPERA", "ORBIT", "ORDER",
        "ORGAN", "OTHER", "OUTER", "OZONE", "PAINT", "PANEL", "PANIC", "PAPER", "PARTY", "PASTA",
        "PATCH", "PAUSE", "PEACE", "PEACH", "PEARL", "PEDAL", "PHASE", "PHONE", "PHOTO", "PIANO",
        "PILOT", "PINCH", "PITCH", "PIVOT", "PIZZA", "PLACE", "PLAIN", "PLANE", "PLANT", "PLATE",
        "PLAZA", "POINT", "POLAR", "POWER", "PRICE", "PRIDE", "PRIME", "PRINT", "PRIZE", "PROBE",
        "PROUD", "PULSE", "PUPIL", "QUEEN", "QUEST", "QUICK", "QUIET", "QUITE", "RADAR", "RADIO",
        "RAISE", "RANCH", "RANGE", "RAPID", "RATIO", "REACH", "REACT", "READY", "REALM", "REBEL",
        "REFER", "RELAX", "RELAY", "RESET", "RIDER", "RIDGE", "RIGHT", "RIVAL", "RIVER", "ROBOT",
        "ROCKY", "ROUND", "ROUTE", "ROYAL", "RULER", "RURAL", "SALAD", "SAUCE", "SCALE", "SCENE",
        "SCENT", "SCOPE", "SCORE", "SCOUT", "SEDAN", "SENSE", "SERVE", "SEVEN", "SHADE", "SHAFT",
        "SHAKE", "SHARE", "SHARP", "SHEEP", "SHEET", "SHELF", "SHELL", "SHIFT", "SHINE", "SHIRT",
        "SHOCK", "SHORE", "SHORT", "SIGHT", "SINCE", "SIREN", "SKILL", "SKIRT", "SLATE", "SLEEP",
        "SLICE", "SLIDE", "SMART", "SMILE", "SMOKE", "SOLAR", "SOLID", "SOLVE", "SOUND", "SOUTH",
        "SPACE", "SPARK", "SPEAR", "SPEED", "SPELL", "SPEND", "SPICE", "SPILL", "SPINE", "SPITE",
        "SPLIT", "SPORT", "SQUAD", "STAFF", "STAGE", "STAIN", "STAIR", "STAKE", "STAND", "START",
        "STATE", "STEAM", "STEEL", "STEEP", "STEER", "STICK", "STILL", "STOCK", "STONE", "STORE",
        "STORM", "STORY", "STRIP", "STUDY", "SUGAR", "SUITE", "SUPER", "SWEET", "SWIFT", "SWORD",
        "TABLE", "TASTE", "TEACH", "THEME", "TIGER", "TITLE", "TODAY", "TONIC", "TOPIC", "TOTAL",
        "TOUCH", "TOWER", "TRACK", "TRADE", "TRAIL", "TRAIN", "TREAT", "TREND", "TRIAL", "TRIBE",
        "TRICK", "TROOP", "TRUCK", "TRULY", "TRUTH", "TULIP", "TWICE", "UNCLE", "UNDER", "UNION",
        "UNITY", "UPPER", "UPSET", "URBAN", "USAGE", "VALID", "VALUE", "VAPOR", "VAULT", "VENUE",
        "VERVE", "VIDEO", "VIGOR", "VIRAL", "VISIT", "VITAL", "VOICE", "VOTER", "WASTE", "WATCH",
        "WATER", "WHEAT", "WHEEL", "WHERE", "WHILE", "WHITE", "WHOLE", "WIDOW", "WIDTH", "WOMAN",
        "WORLD", "WORRY", "WORTH", "WOULD", "WOUND", "WRITE", "WRONG", "YACHT", "YEARN", "YIELD",
        "YOUNG", "YOUTH", "ZEBRA"
    ]

    /// Target pool sanitized to exactly-5-letter A–Z words, so a malformed
    /// entry can never become an unwinnable (or crashing) secret word.
    static let targetWords: [String] = {
        var seen = Set<String>()
        return curatedTargetWords
            .map { $0.uppercased() }
            .filter { $0.count == 5 && $0.allSatisfy { ("A"..."Z").contains($0) } && seen.insert($0).inserted }
    }()

    private static let targetWordSet: Set<String> = Set(targetWords)

    private static let textChecker = UITextChecker()

    /// Deterministically retrieves a 5-letter word for a given date
    static func dailyWord(for date: Date = Date()) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        
        // Deterministic hash based on year and day of year
        let seed = abs((year * 365 + dayOfYear * 31) ^ 0x5DEECE66D)
        let index = seed % targetWords.count
        return targetWords[index]
    }

    /// Random target word for Classic Endless mode
    static func randomTargetWord() -> String {
        targetWords.randomElement() ?? "SWIFT"
    }

    /// Validates if a 5-letter string is a legitimate English word
    static func isValidWord(_ candidate: String) -> Bool {
        let upper = candidate.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard upper.count == 5 else { return false }

        // Fast check against curated list
        if targetWordSet.contains(upper) {
            return true
        }

        // Full English language dictionary validation via iOS UITextChecker
        let range = NSRange(location: 0, length: upper.utf16.count)
        let misspelledRange = textChecker.rangeOfMisspelledWord(
            in: upper.lowercased(),
            range: range,
            startingAt: 0,
            wrap: false,
            language: "en_US"
        )
        return misspelledRange.location == NSNotFound
    }
}
