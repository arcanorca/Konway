.pragma library

var paletteDefaults = ({
    "Calm Dark": { "alive": "#50C878", "dead": "#1A1A1A", "bg": "#1A1A1A" },
    "Paper Light": { "alive": "#537F67", "dead": "#DDD5C6", "bg": "#F3EFE6" },
    "Emerald": { "alive": "#4FBF8A", "dead": "#12221D", "bg": "#0D1714" },
    "Amber": { "alive": "#CFA15C", "dead": "#2A1D10", "bg": "#18120A" },
    "Monochrome": { "alive": "#AFAFAF", "dead": "#1D1D1D", "bg": "#101010" },
    "Catppuccin": { "alive": "#A6E3A1", "dead": "#313244", "bg": "#1E1E2E" },
    "Dracula": { "alive": "#50FA7B", "dead": "#44475A", "bg": "#282A36" },
    "Tokyo Night": { "alive": "#73DACA", "dead": "#292E42", "bg": "#1A1B26" },
    "Nord": { "alive": "#A3BE8C", "dead": "#3B4252", "bg": "#2E3440" },
    "Gruvbox": { "alive": "#FABD2F", "dead": "#3C3836", "bg": "#282828" },
    "Everforest": { "alive": "#A7C080", "dead": "#3D484D", "bg": "#2D353B" },
    "Rose Pine": { "alive": "#A890B6", "dead": "#1F1C21", "bg": "#1F1C21" },
    "Amiga": { "alive": "#FF8800", "dead": "#003C77", "bg": "#0055AA" },
    "Ayu Dark": { "alive": "#FFB454", "dead": "#1D242C", "bg": "#0F1419" },
    "Ayu Mirage": { "alive": "#FFCC66", "dead": "#333A46", "bg": "#212733" },
    "Braun": { "alive": "#FF5500", "dead": "#232323", "bg": "#161616" },
    "Casio Digital": { "alive": "#0088FF", "dead": "#19221C", "bg": "#121814" },
    "Classic Macintosh": { "alive": "#009DDC", "dead": "#1F1F1F", "bg": "#121212" },
    "Commodore 64": { "alive": "#FFFFFF", "dead": "#4945A2", "bg": "#3A3A9A" },
    "Cyberpunk": { "alive": "#FCEE0A", "dead": "#53042A", "bg": "#090622" },
    "Grayscale": { "alive": "#FFFFFF", "dead": "#2C2C2C", "bg": "#141414" },
    "Hacker Green": { "alive": "#00FF00", "dead": "#001E00", "bg": "#000000" },
    "Handheld": { "alive": "#9BBC0F", "dead": "#1A2417", "bg": "#141C12" },
    "Kanagawa": { "alive": "#7E9CD8", "dead": "#2F2F3D", "bg": "#1F1F28" },
    "macOS": { "alive": "#0A84FF", "dead": "#262627", "bg": "#1E1E1E" },
    "Material Ocean": { "alive": "#82AAFF", "dead": "#202530", "bg": "#0F111A" },
    "Monokai": { "alive": "#A6E22E", "dead": "#3E3E34", "bg": "#272822" },
    "Nintendo DS": { "alive": "#2F6FDB", "dead": "#DEE3E9", "bg": "#EEF1F5" },
    "Night Owl": { "alive": "#82AAFF", "dead": "#0E273F", "bg": "#011627" },
    "Nixie": { "alive": "#FF7A18", "dead": "#191614", "bg": "#0B0A09" },
    "Nothing": { "alive": "#D71921", "dead": "#111111", "bg": "#000000" },
    "One Dark": { "alive": "#61AFEF", "dead": "#3C414D", "bg": "#282C34" },
    "Oscilloscope": { "alive": "#39FF14", "dead": "#0A160C", "bg": "#050906" },
    "Phosphor Blue": { "alive": "#00FFFF", "dead": "#001E2D", "bg": "#000000" },
    "PlayStation 3": { "alive": "#3D9BFF", "dead": "#0F1B3A", "bg": "#050B1E" },
    "Solarized Dark": { "alive": "#268BD2", "dead": "#1A3F49", "bg": "#002B36" },
    "Synthwave 84": { "alive": "#FF7EDB", "dead": "#38304D", "bg": "#262335" },
    "Terminal": { "alive": "#8CFFAA", "dead": "#1E3024", "bg": "#1A1A1A" },
    "ThinkPad": { "alive": "#E42022", "dead": "#1F1F1F", "bg": "#121212" },
    "UNIX Workstation": { "alive": "#00F0FF", "dead": "#272E3C", "bg": "#181D26" },
    "VFD Hi-Fi": { "alive": "#66FFD4", "dead": "#0F1617", "bg": "#0B0E11" },
    "Nintendo Wii": { "alive": "#00A9E0", "dead": "#E8EDF1", "bg": "#F3F6F9" },
    "Windows XP": { "alive": "#245EDB", "dead": "#CBD2CF", "bg": "#ECE9D8" },
    "Zenburn": { "alive": "#8CD0D3", "dead": "#495249", "bg": "#3F3F3F" },
    "Midnight": { "alive": "#6C8CFF", "dead": "#141B30", "bg": "#0B1020" },
    "Sakura": { "alive": "#F4A7B9", "dead": "#2C2124", "bg": "#1E1618" },
    "Sand Dune": { "alive": "#E3C088", "dead": "#2D261C", "bg": "#1F1A14" },
    "Glacier": { "alive": "#8FE3F0", "dead": "#172A31", "bg": "#0E1A1F" }
})

var coreCuratedIds = [
    "gosperglidergun",
    "glider",
    "rpentomino",
    "lwss",
    "block",
    "acorn",
    "diehard"
]

var builtinGosperRle = "x = 36, y = 9, rule = B3/S23\n24bo11b$22bobo11b$12bo10bobo12b$11bo11bob2o9b$2o8bo12bo11b$2o8bo11bobo11b$10bo10bobo11b$11bo10bo12b$12b12o!"

var clockGlyphs = ({
    "0": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
    "1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
    "2": ["01110", "10001", "00001", "00010", "00100", "01000", "11111"],
    "3": ["11110", "00001", "00001", "01110", "00001", "00001", "11110"],
    "4": ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
    "5": ["11111", "10000", "11110", "00001", "00001", "10001", "01110"],
    "6": ["00110", "01000", "10000", "11110", "10001", "10001", "01110"],
    "7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
    "8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
    "9": ["01110", "10001", "10001", "01111", "00001", "00010", "11100"],
    ":": ["0", "1", "0", "0", "1", "0", "0"]
})

var miniClockGlyphs = ({
    "0": ["111", "101", "101", "101", "111"],
    "1": ["010", "110", "010", "010", "111"],
    "2": ["111", "001", "111", "100", "111"],
    "3": ["111", "001", "111", "001", "111"],
    "4": ["101", "101", "111", "001", "001"],
    "5": ["111", "100", "111", "001", "111"],
    "6": ["111", "100", "111", "101", "111"],
    "7": ["111", "001", "001", "001", "001"],
    "8": ["111", "101", "111", "101", "111"],
    "9": ["111", "101", "111", "001", "111"],
    ":": ["0", "1", "0", "1", "0"]
})

var defaultCategoryWeights = ({
    "gliders": 1.1,
    "spaceships": 1.0,
    "methuselahs": 0.8,
    "oscillators": 0.6,
    "guns": 0.12,
    "still_lifes": 0.25
})

// Small 5-row letters for the AM/PM suffix next to the clock digits.
var ampmGlyphs = ({
    "A": ["010", "101", "111", "101", "101"],
    "P": ["111", "101", "111", "100", "100"],
    "M": ["10001", "11011", "10101", "10001", "10001"]
})
