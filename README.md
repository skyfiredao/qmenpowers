**[中文版](README_zh.md)**

> Establish the heart of heaven and earth,
> Secure the livelihood of the people,
> Continue the lost teachings of past sages,
> Open an era of peace for all generations.
>
> — Zhang Zai, *Hengqu Four Maxims* (横渠四句)

# Qi Men Dun Jia — Eight Gates Huaqi Array
# 奇门遁甲 八门化气阵

A pure-Bash Qi Men Dun Jia plate-setting engine with zero external dependencies.

## What Is Qi Men Dun Jia?

Qi Men Dun Jia (奇门遁甲) is one of the "Three Styles" (三式) of classical Chinese cosmological forecasting, alongside Tai Yi (太乙) and Liu Ren (六壬). Dating back over two thousand years, it maps time and space onto a nine-palace grid derived from the Luoshu (洛书) magic square, then layers multiple symbol systems on top: heavenly stems, stars, gates, and deities. Each layer interacts through the five-phase (五行, wuxing) cycle of generation and overcoming, producing a rich symbolic picture of a given moment's energetic landscape.

The system was historically used for military strategy, site selection, and timing decisions. Today it remains a living tradition in Chinese metaphysics, studied for both its cultural depth and its internal structural elegance.

## Design Choices

**Zhi-Run intercalary method only.** Two major schools exist for handling the boundary between solar terms: Zhi-Run (置闰法) and Chai-Bu (拆补法). This project implements Zhi-Run exclusively. In Zhi-Run, when the current time falls between the Jieqi (节气) boundary and the start of a new Yuan (元), the previous Ju number is carried forward ("intercalated"). Chai-Bu instead splits and patches across both Ju numbers. Zhi-Run produces a single clean Ju per moment, which simplifies the computation pipeline and aligns with the dominant mainland Chinese tradition.

**Hourly Qi Men with rotating plate.** This is Shi Jia Qi Men (时家奇门), the hourly variant, not the daily or monthly variants. The plate uses the rotating-plate (转盘) method, where stars and gates physically rotate around the nine palaces. The alternative flying-star (飞盘) method assigns symbols by flight path rather than rotation. Rotating plate preserves the spatial relationship between symbols and palaces, making it more intuitive for reading directional significance.

**Tianqin palace assignment.** The star Tianqin (天禽, Heavenly Bird) sits in the center palace (5-palace), which has no gate and therefore needs a hosting palace. Three modes are available via `--tianqin=MODE`:

- **`follow-tiannei`** (default): Tianqin follows wherever Tiannei (天内) goes. When the heaven plate rotates, Tiannei and Tianqin share the same palace. This preserves Tianqin's yin-earth affinity with Tiannei's yin-earth nature.
- **`jikun`**: Tianqin lodges permanently in the Kun 2-palace (寄坤二宫), regardless of plate rotation. This is the most traditional convention.
- **`follow-zhifu`**: Tianqin follows the Zhifu (值符) duty star to its rotated palace.

In all modes, the hosting palace displays Tianqin with a `[寄]` (lodging) marker alongside the palace's own rotated star.

**Pure Bash, no external tools.** The entire engine runs in Bash 3.2+ with no calls to Python, bc, awk, or any other external program. All arithmetic uses Bash integer math. Calendar calculations (Gregorian to Julian Day Number, Ganzhi cycle indexing) are implemented from scratch in shell arithmetic. This makes the tool portable to any system with a POSIX-compatible Bash, including stock macOS.

**Script and data fully separated.** Every domain constant lives in `data/*.dat` files, using a simple `key=value` format. The scripts contain zero hardcoded domain knowledge. You could, in theory, swap the data files to model a different Qi Men variant without touching a line of code.

## Architecture

The engine is split into library files, CLI entry points, and a data directory.

```
skill_qmenpowers/
├── skills/
│   ├── qmen_dunjia/
│   │   └── SKILL.md                # Router skill: time-type triage + plate setting + sub-skill dispatch
│   ├── qmen_event/
│   │   └── SKILL.md                # AI interpretation skill
│   ├── qmen_caiguan/
│   │   └── SKILL.md                # Wealth & career diagnosis skill
│   ├── qmen_huaqizhen/
│   │   └── SKILL.md                # Huaqizhen array placement skill
│   ├── qmen_hunlian/
│   │   └── SKILL.md                # Hunlian (marriage/romance) analysis skill
│   ├── qmen_wanwu/
│   │   └── SKILL.md                # Wanwu imagery portrait skill
│   └── qmen_xingge/
│       └── SKILL.md                # Personality analysis skill
├── bin/
│   ├── qimen.sh                    # Plate setting CLI
│   ├── qimen_event.sh              # Event analysis CLI
│   ├── qimen_caiguan.sh            # Caiguan (wealth/career) diagnosis CLI
│   ├── qimen_huaqizhen.sh          # Huaqizhen (array placement) CLI
│   ├── qimen_hunlian.sh            # Hunlian (marriage/romance) analysis CLI
│   ├── qimen_wanwu.sh              # Wanwu imagery extraction CLI
│   └── qimen_xingge.sh             # Personality analysis CLI
├── install.sh                      # Installation script
├── lib/
│   ├── data_loader.sh              # Generic data file loader
│   ├── qimen_engine.sh             # Core computation engine
│   ├── qimen_output.sh             # Output formatting (text + JSON)
│   ├── qimen_json.sh               # Shared JSON parsing and utility library
│   ├── qimen_event.sh              # Event analysis library
│   ├── qimen_banmenhuaqizhen.sh    # Core huaqizhen library
│   ├── qimen_caiguan.sh            # Caiguan analysis library
│   ├── qimen_hunlian.sh            # Hunlian (marriage/romance) analysis library
│   └── qimen_xingge.sh             # Personality analysis library
└── data/
    ├── tiangan_dizhi.dat           # Engine: stems & branches
    ├── jieqi_table.dat             # Engine: solar term timestamps
    ├── meta_jieqi.dat              # Engine: solar term metadata
    ├── ju_map.dat                  # Engine: ju number mapping
    ├── nine_stars.dat              # Engine: nine stars basics
    ├── eight_gates.dat             # Engine: eight gates basics
    ├── eight_deities.dat           # Engine: eight deities ordering
    ├── sanqi_liuyi.dat             # Engine: three wonders & six yi
    ├── luoshu.dat                  # Engine: luoshu traversal order
    ├── meta_palace.dat             # Engine: palace metadata
    ├── twelve_states.dat           # Engine: twelve growth stages
    ├── wanwu_bagua.dat             # Reference: eight trigrams correspondences
    ├── wanwu_tiangan.dat           # Reference: heavenly stems correspondences
    ├── wanwu_dizhi.dat             # Reference: earthly branches correspondences
    ├── wanwu_wuxing.dat            # Reference: five phases correspondences
    ├── wanwu_nine_stars.dat        # Reference: nine stars correspondences
    ├── wanwu_eight_gates.dat       # Reference: eight gates correspondences
    ├── wanwu_eight_deities.dat     # Reference: eight deities correspondences
    ├── wanwu_geju.dat              # Reference: pattern definitions & diagnostics
    ├── rules_yongshen.dat          # Analysis: yongshen selection rules
    ├── wanwu_prefix_map.dat        # Analysis: symbol-to-prefix mapping
    ├── meta_huaqizhen.dat          # Huaqi: stem relationships, liuhai rules, yaohai definitions
    ├── hangye_quxiang.dat          # Huaqi: industry-to-symbol mapping
    ├── rules_buzhen.dat            # Buzhen: prohibition, suppression, miexiang rules
    ├── buzhen_xiangshu.dat         # Buzhen: stem/branch imagery (colors, materials, animals)
    ├── rules_hunlian.dat           # Hunlian: gan-he combinations, muyu positions, guchen/guasu groups, taohua deity/sanqi rules
    └── wanwu_huaqizhen.dat         # Huaqi: personality analysis correspondences
```

**`lib/data_loader.sh`** is a generic key=value file parser. It reads `.dat` files into shell variables and arrays. Comma-separated values become indexed arrays. Keys with CJK characters are stored via an internal key-value store (`dl_get`/`dl_set`) for Bash 3 compatibility, since older Bash lacks associative arrays with non-ASCII keys.

**`lib/qimen_engine.sh`** contains all computation logic: calendar math (Gregorian/JDN conversion, Ganzhi cycle calculation), solar term lookup, Yuan/Ju determination with intercalary handling, and the full plate-laying pipeline (earth plate, heaven plate rotation, gate rotation, deity placement, pattern detection).

**`lib/qimen_output.sh`** reads the global arrays populated by the engine and formats them for display. It supports two modes: human-readable text (palace-by-palace listing with a header block) and structured JSON.

**`lib/qimen_json.sh`** provides shared JSON parsing and utility functions: plate JSON parsing into the dl key-value store, day/hour stem palace location, stem extraction, and wanwu correspondence lookup. Used by all analysis CLI scripts.

**`lib/qimen_event.sh`** provides the event-specific analysis pipeline: yongshen (use god) selection by question type, yongshen palace marking, 81-combination lookups, pattern marker collection, and structured text/JSON output formatting. Used exclusively by `bin/qimen_event.sh`.

**`bin/qimen.sh`** is the plate-setting CLI wrapper. It parses options, sources the library files, calls the engine, and dispatches to the appropriate output formatter.

**`bin/qimen_event.sh`** is the event analysis CLI. It reads a plate JSON produced by `qimen.sh`, runs the analysis pipeline, and outputs a structured analysis JSON. Used exclusively for event plates (问事局).

**`lib/qimen_banmenhuaqizhen.sh`** provides the core huaqizhen library: common helpers, palace finders, six-harm (六害) detection per palace with opposite-palace influence (玄武/庚/白虎 affect both host and opposite palace), monthly decree (月令) wuxing relationship computation with Chinese meaning labels (扩张/稳健/努力/损耗/大亏), controlled-wealth (干财) stem tracing with five-combination (天干五合) fallback and special missing-甲-find-zhifu rule (缺甲找值符), symbol location utilities, palace summary generation, yuegling relations, and the full buzhen (布阵) pipeline: protected stem identification (day/hour, birth year, family, yixiang concept stems, zhifu/zhishi), eight-palace six-harm scanning, miexiang (灭象) list generation with safe relocation targets, buzhen plan per palace (suppress jixing via combination, suppress rumu via clash, suppress menpo via combination, suppress geng/baihu via yi-stem, fill kongwang), jinbi (禁忌) conflict detection, and physical object imagery mapping.

**`lib/qimen_caiguan.sh`** provides the caiguan-specific analysis pipeline: seven-hazard (七要害) yaohai analysis for both wealth and career dimensions with monthly decree Chinese meaning labels, gan_cai analysis with special missing-甲-find-zhifu rule (缺甲找值符宫干 instead of 己), industry symbol (hangye) lookup, fushi analysis, tiangan roles analysis, JSON output formatting, and the caiguan pipeline entry point.

**`lib/qimen_hunlian.sh`** provides the hunlian (marriage/romance) analysis pipeline: birth day stem palace location, gan-he (stem combination) partner, liuhe (six harmony), muyu (bathing position), sanqi (three wonders) proximity checks, taohua (peach blossom) detection across multiple indicators (xuanwu, taiyin, ren/gui, sanqi co-location), fuyin/fanyin palace scanning, kongwang impact on partner positions, gen/kun palace six-harm inspection, guchen/guasu (lonely star) computation with jiehua remedies, and special position tracking (tianpeng, shangmen, ding, gui).

**`lib/qimen_xingge.sh`** provides the personality analysis pipeline: birth day stem (inner personality) and hour stem (outer personality) palace location, personality correspondence extraction from huaqizhen-specific wanwu data (stem, star, gate, deity personality traits per palace), wuxing color mapping, and structured text/JSON output.

**`bin/qimen_caiguan.sh`** is the caiguan diagnosis CLI. It reads the birth plate (`./qmen_birth.json`) only. It auto-reads `./qmen_birth.json` for birth year stem, then outputs a structured caiguan analysis JSON with wealth and career hazard diagnostics.

**`bin/qimen_huaqizhen.sh`** is the huaqizhen buzhen CLI. It defaults to birth plate (`./qmen_birth.json`); use `--input` to specify an event plate for event-based analysis. It auto-reads `./qmen_birth.json` for birth year stem, takes optional family stems and yixiang concept stems, and outputs a structured buzhen JSON with miexiang list and per-palace placement plans.

**`bin/qimen_hunlian.sh`** is the hunlian (marriage/romance) analysis CLI. It reads the birth plate (`./qmen_birth.json`) only. It auto-reads `./qmen_birth.json` for birth day stem, then outputs a structured hunlian analysis JSON with partner detection, taohua indicators, guchen/guasu assessment, and palace-level relationship diagnostics.

**`bin/qimen_xingge.sh`** is the personality analysis CLI. It reads the birth plate (`./qmen_birth.json`) only. It reads the birth day stem and hour stem, locates them on the plate, extracts personality trait correspondences from the star, gate, and deity at each stem's palace, and outputs structured personality analysis JSON.

**`bin/qimen_wanwu.sh`** is the wanwu imagery extraction CLI. It supports two modes: palace mode (`--palace=N`) extracts all wanwu correspondences for a given palace from a plate JSON, and manual mode (`--stem/--star/--gate/--deity/--state`) accepts any combination of symbols directly. Each symbol is optional; at least one is required. Outputs structured text and JSON with full wanwu correspondences per symbol.

## Data Files

Data files fall into two categories: **engine data** (11 files consumed by the computation pipeline) and **reference data** (8 `wanwu_*` files providing comprehensive correspondence tables for interpretation). All live under `data/`, use `key=value` format with `#` comments.

### Engine Data

| File | Contents |
|------|----------|
| `tiangan_dizhi.dat` | Heavenly Stems (天干) and Earthly Branches (地支): the 10+12 cyclical characters forming the sexagenary system |
| `jieqi_table.dat` | Solar term timestamps from 1899 to 2100, stored as Unix-epoch seconds for each of the 24 Jieqi per year |
| `meta_jieqi.dat` | Solar term metadata: Jie (节) vs. Qi (气) classification, Yin/Yang Dun assignment, Yuan cycle info |
| `ju_map.dat` | Ju number mapping: for each solar term and Yuan (upper/middle/lower), the Ju number (1–9) |
| `nine_stars.dat` | Nine Stars (九星): name, wuxing, auspiciousness, default palace |
| `eight_gates.dat` | Eight Gates (八门): name, wuxing, auspiciousness, default palace |
| `eight_deities.dat` | Eight Deities (八神): Yang-sequence and Yin-sequence ordering |
| `sanqi_liuyi.dat` | Three Wonders and Six Yi (三奇六仪): the nine instruments and their stem assignments |
| `luoshu.dat` | Luoshu magic square (洛书) palace traversal order |
| `meta_palace.dat` | Palace metadata: name, wuxing, direction, Earthly Branches, tail numbers, Xiantian/Houtian numbers |
| `twelve_states.dat` | Twelve Growth Stages (十二长生): lifecycle states used in palace vitality assessment |

### Reference Data (万物类象)

Comprehensive correspondence tables for Qi Men interpretation. These files are not consumed by the engine but serve as a structured knowledge base for reading and analysis.

| File | Contents |
|------|----------|
| `wanwu_bagua.dat` | Eight Trigrams (八卦): imagery, body, family, animal, direction, season, organ, emotion, and more per trigram |
| `wanwu_tiangan.dat` | Heavenly Stems (天干): wuxing, color, direction, body part, personality, season, number per stem |
| `wanwu_dizhi.dat` | Earthly Branches (地支): wuxing, direction, season, body, personality per branch; plus San-He, Liu-He, Liu-Chong, and punishment relationship tables |
| `wanwu_wuxing.dat` | Five Phases (五行): direction, season, organ, taste, color, emotion, number, sheng-ke cycles; includes Hetu numbers and seasonal vitality states |
| `wanwu_nine_stars.dat` | Nine Stars (九星): wuxing, auspiciousness, color, body/disease, personality, weather, objects, places, career, divination suitability per star |
| `wanwu_eight_gates.dat` | Eight Gates (八门): wuxing, auspiciousness, color, body/disease, personality, places, career, divination suitability; three-auspicious / three-inauspicious classification |
| `wanwu_eight_deities.dat` | Eight Deities (八神): wuxing, imagery, personality, body, events, objects per deity; Yang/Yin sequence notes |
| `wanwu_geju.dat` | Pattern Definitions (格局大全): Geng patterns, all 81 stem-on-stem combinations, auspicious/inauspicious pattern catalog, Men-Po conditions, Fan-Yin/Fu-Yin tables, tomb tables, Liu-Yi Ji-Xing, Kong-Wang, Yi-Ma rules |

### Analysis Data

| File | Contents |
|------|----------|
| `rules_yongshen.dat` | Yongshen (use god) selection rules: 9 question types, each with prioritized star/gate/deity/stem selections |
| `wanwu_prefix_map.dat` | Symbol name to wanwu file prefix mapping: maps Chinese names to data file key prefixes |

### Huaqi Data

| File | Contents |
|------|----------|
| `meta_huaqizhen.dat` | Tiangan five-combinations (天干五合), stem-conquers (天干所克) tables, wuxing relationships, dizhi wuxing, six-harm marker definitions, wealth seven-hazard and career seven-hazard element definitions, yixiang concept-to-stem mappings (财富→戊, 暴力→庚, etc.), opposite-palace (对宫) mappings |
| `hangye_quxiang.dat` | Industry-to-symbol mapping: maps job names to their corresponding Qi Men symbols (gates, stars, deities, stems) |
| `wanwu_huaqizhen.dat` | Huaqi-specific correspondences: ten stems (personality + imagery), eight gates (personality + imagery), nine stars (personality + industry + imagery), eight deities (personality + imagery) traits for character analysis; wuxing colors; palace name/wuxing mapping |

### Buzhen Data

| File | Contents |
|------|----------|
| `rules_buzhen.dat` | Prohibition rules (jinbi): which stems cannot be placed in which palaces (sanqi-rumu, liuyi-jixing); suppression methods (jixing→combination, rumu→clash, menpo→combination, geng/baihu→yi-stem, kongwang→fill); miexiang methods; safe palace definitions; protect priority |
| `buzhen_xiangshu.dat` | Physical imagery for array placement: each heavenly stem mapped to colors and materials; each earthly branch mapped to zodiac animals and substitute objects; position rules for object placement |

### Hunlian Data

| File | Contents |
|------|----------|
| `rules_hunlian.dat` | Hunlian: gan-he combinations, muyu positions, guchen/guasu groups, taohua deity/sanqi rules |

## Computation Pipeline

The engine function `qm_compute_plate` executes the following steps in order:

1. **Four Pillars (四柱干支).** Compute the year, month, day, and hour pillars. Each pillar is a Tiangan-Dizhi pair drawn from the sexagenary cycle, derived from calendar math.

2. **Ju Determination (局数).** Identify the current solar term, then determine which Yuan (上元/中元/下元, upper/middle/lower) the current day falls within. Look up the Ju number from the mapping table. If the date falls in an intercalary gap (between the Jie boundary and the next Yuan start), apply Zhi-Run: carry forward the previous Ju number.

3. **Earth Plate (地盘).** Lay the nine instruments (三奇六仪) onto the nine palaces according to the Ju number and Yin/Yang Dun (阴遁/阳遁) direction.

4. **Zhifu and Zhishi (值符值使).** Identify the duty star (Zhifu, 值符) and duty gate (Zhishi, 值使) from the hour pillar's position on the earth plate.

5. **Heaven Plate Rotation (天盘).** Rotate the nine stars from their default palaces by an offset derived from the hour pillar, placing each star into its new palace position.

6. **Human Plate Rotation (人盘).** Rotate the eight gates using the Earthly Branch step method, shifting gates from their default palaces based on the hour branch offset.

7. **Deity Plate (神盘).** Place the eight deities starting from the Zhifu star's palace, following the Yang or Yin sequence depending on Dun direction.

8. **Twelve Growth Stages (十二长生).** Compute the lifecycle state (birth, growth, peak, decline, grave, etc.) for each palace based on the day stem's wuxing.

9. **Liuyi Jixing (六仪击刑).** Check whether any of the six Yi instruments land in a palace that carries a punishment (刑) relationship with their associated Earthly Branch.

10. **Kongwang (空亡).** Determine the two void/empty Branches from the hour pillar's position within its sexagenary decade, then map those Branches to palaces.

11. **Yima (驿马).** Derive the courier horse Branch from the hour Branch using the traditional formula, then map it to a palace.

12. **Pattern Markers (格局).** Scan each palace for significant configurations:

| Marker | Chinese | Meaning |
|--------|---------|---------|
| `[庚]` | 天盘庚 | Geng on the heaven plate (inauspicious metal energy) |
| `[干墓]` | 干入墓 | Heaven stem enters its grave palace |
| `[星墓]` | 星入墓 | Star enters its grave palace |
| `[门墓]` | 门入墓 | Gate enters its grave palace |
| `[门迫]` | 门迫 | Gate oppresses palace (gate's wuxing overcomes palace's wuxing) |
| `[星反吟]` | 星反吟 | Star sits in the palace opposite its home (reversal) |
| `[门反吟]` | 门反吟 | Gate sits in the palace opposite its home (reversal) |
| `[星伏吟]` | 星伏吟 | Star sits in its own home palace (stagnation) |
| `[门伏吟]` | 门伏吟 | Gate sits in its own home palace (stagnation) |
| `[击刑]` | 六仪击刑 | Six-instrument punishment |
| `[空亡]` | 空亡 | Void/empty |
| `[驿马]` | 驿马 | Courier horse (mobility indicator) |

## Output

Two output modes are available.

**Text mode** (default) prints a header block followed by a palace-by-palace listing:

```
奇门遁甲起局
时间: 1973-04-24 19:30
四柱: 癸丑 丙辰 庚寅 丙戌
局  : 阳遁8局 (下元)
值符: 天蓬
值使: 休门
空亡: 午(9宫) 未(2宫)
驿马: 申(2宫)

[ 巽4宫｜东南｜木 ]
  地支: 辰巳
  天盘: 己(土)
  地盘: 癸(水)
  神  : 白虎
  星  : 天英(凶)
  门  : 生门(吉)
  状态: 衰
  格局: [干墓] [门墓]
  先天数: 5  后天数: 4  尾数: 3,8

[ 震3宫｜东｜木 ]
  地支: 卯
  天盘: 癸(水)
  地盘: 壬(水)
  神  : 六合
  星  : 天辅(吉)
  门  : 休门(吉)
  状态: 长生
  先天数: 4  后天数: 3  尾数: 3,8

[ 艮8宫｜东北｜土 ]
  地支: 丑寅
  天盘: 壬(水)
  地盘: 戊(土)
  神  : 太阴
  星  : 天冲(吉)
  门  : 开门(吉)
  状态: 衰
  格局: [门墓]
  先天数: 7  后天数: 8  尾数: 5,0
```

**JSON mode** is always-on: every run writes a structured JSON file (based on `--type`) containing all header fields and an array of palace objects, each with every computed field. The text output is displayed on the terminal simultaneously.

## Analysis Script

The event analysis script `qimen_event.sh` reads a plate JSON (produced by `qimen.sh`), enriches it with wanwu correspondence data, marks yongshen (use god) palaces based on the question type, and outputs a structured analysis JSON.

### Pipeline

```bash
# Step 1: Generate birth plate
bin/qimen.sh --type=birth "1973-04-24 19:30"
# Creates ./qmen_birth.json

# Step 2: Generate event plate
bin/qimen.sh "2026-04-18 10:00"
# Creates ./qmen_event.json

# Step 3: Run analysis
bin/qimen_event.sh --question=事业
# Reads ./qmen_event.json, writes ./qmen_event_analysis.json
```

### Question Types

| Type | Meaning | Primary Yongshen |
|------|---------|-----------------|
| 事业 | Career / official prospects | 开门 (Open Gate), 天心 (Tianxin Star) |
| 求财 | Wealth / financial matters | 生门 (Life Gate), 六合 (Liuhe Deity) |
| 婚姻感情 | Marriage / relationships | 六合 (Liuhe), 景门 (View Gate), 乙 (Yi Stem) |
| 疾病健康 | Health / illness | 天内 (Tiannei Star), 死门 (Death Gate) |
| 出行 | Travel / movement | 开门 (Open Gate), 九天 (Jiutian Deity) |
| 官司诉讼 | Lawsuits / legal disputes | 伤门 (Harm Gate), 天英 (Tianying Star) |
| 寻人寻物 | Finding people / lost items | 六合 (Liuhe), 杜门 (Block Gate) |
| 天气 | Weather | 景门 (View Gate), 天英 (Tianying Star) |
| 家宅风水 | Home / feng shui | 生门 (Life Gate), 天任 (Tianren Star) |

### Analysis Output

The analysis JSON includes:
- Day stem and hour stem palace positions
- Yongshen (use god) markings with palace locations
- Wanwu correspondences for each palace (star, gate, deity, stems)
- 81-combination lookups for key palaces
- Pattern markers (kongwang, yima, geng, rumu, menpo, fanyin, fuyin, jixing)

### CLI Reference

```
Usage: qimen_event.sh [OPTIONS]

Options:
  --input=PATH        Input plate JSON (default: ./qmen_event.json)
  --question=TYPE     Question type (required)
  --verbose           Full wanwu extraction (default: concise)
  --wanwu             Show wanwu (万物类象) in text output (JSON always includes wanwu)
  -h, --help          Show this help
```

## Huaqi Analysis Script (八门化气阵)

The huaqi script `qimen_caiguan.sh` reads the birth plate (`./qmen_birth.json`) only. It performs wealth/career deep analysis. It locates seven hazard elements (七要害) for both wealth and career dimensions, detects six-harm (六害: punishment, tomb, Geng, White Tiger, gate oppression, void) at each palace, computes monthly decree wuxing relationships with Chinese meaning labels (扩张/稳健/努力/损耗/大亏), traces controlled-wealth stems (干财) with five-combination fallback (missing 甲 uses zhifu palace stem instead of 己), and auto-derives industry symbols from the plate. The birth year stem is auto-read from `./qmen_birth.json`.

### Pipeline

```bash
# Default usage (birth plate analysis)
bin/qimen.sh --type=birth "1973-04-24 19:30"
# Creates ./qmen_birth.json
bin/qimen_caiguan.sh
# Reads ./qmen_birth.json by default
```

### CLI Reference

```
Usage: qimen_caiguan.sh [OPTIONS]

Options:
  --wanwu                 Show wanwu (万物类象) in text output (JSON always includes wanwu)
  -h, --help              Show this help

Requires: ./qmen_birth.json (for birth year stem)
```

## Buzhen Script (布阵)

The buzhen script `qimen_huaqizhen.sh` defaults to birth plate (`./qmen_birth.json`); use `--input` to specify an event plate for event-based analysis. It reads a huaqi analysis JSON and generates array placement plans. It identifies protected stems (day/hour stem, birth year stem, family stems, yixiang concept stems, zhifu/zhishi stems), scans all eight palaces for six-harm threats against protected stems (including opposite-palace influence from 玄武/庚/白虎), generates miexiang (灭象) lists with safe relocation targets, and produces per-palace buzhen plans (suppress jixing via combination, suppress rumu via clash, suppress menpo via combination, neutralize geng/baihu via yi-stem, fill kongwang gaps) with physical object imagery mapping. The birth year stem is auto-read from `./qmen_birth.json`.

### Pipeline

```bash
# Default usage (birth plate analysis)
bin/qimen.sh --type=birth "1973-04-24 19:30"
# Creates ./qmen_birth.json
bin/qimen_huaqizhen.sh
# Reads ./qmen_birth.json by default

# With event plate (optional, only when targeting a specific event)
bin/qimen.sh --type=birth "1973-04-24 19:30"
bin/qimen.sh "2026-04-18 10:00"
bin/qimen_huaqizhen.sh --input=./qmen_event.json
```

### CLI Reference

```
Usage: qimen_huaqizhen.sh [OPTIONS]

Options:
  --input=PATH            Input plate JSON (default: ./qmen_birth.json)
  --family-stems=S1,S2    Family members' birth year stems (optional)
  --yixiang=C1,C2         Concepts to protect: 财富,暴力,权威,突破,表现,情欲 (optional)
  --wanwu                 Show wanwu (万物类象) in text output (JSON always includes wanwu)
  -h, --help              Show this help

Requires: ./qmen_birth.json (for birth year stem)
```

## Hunlian Script (婚恋分析)

The hunlian script `qimen_hunlian.sh` reads the birth plate (`./qmen_birth.json`) only. It performs marriage/romance analysis. It locates the birth day stem palace, identifies the gan-he (stem combination) partner, checks liuhe (six harmony) and muyu (bathing position), detects taohua (peach blossom) indicators across multiple dimensions (xuanwu, taiyin, ren/gui, sanqi co-location), scans fuyin/fanyin palaces, evaluates kongwang impact on partner positions, inspects gen/kun palace six-harm, computes guchen/guasu (lonely star) with jiehua remedies, and tracks special positions (tianpeng, shangmen, ding, gui). The birth day stem is auto-read from `./qmen_birth.json`.

### Pipeline

```bash
# Default usage (birth plate analysis)
bin/qimen.sh --type=birth "1973-04-24 19:30"
# Creates ./qmen_birth.json
bin/qimen_hunlian.sh
# Reads ./qmen_birth.json by default
```

### CLI Reference

```
Usage: qimen_hunlian.sh [OPTIONS]

Options:
  --wanwu                 Show wanwu (万物类象) in text output (JSON always includes wanwu)
  -h, --help              Show this help

Requires: ./qmen_birth.json (for birth day stem)
```

## Xingge Script (性格分析)

The xingge script `qimen_xingge.sh` defaults to birth plate (`./qmen_birth.json`). It performs personality analysis. It reads the birth day stem (inner personality) and hour stem (outer personality), locates each on the plate, extracts personality trait correspondences from the star, gate, and deity at each stem's palace using huaqizhen-specific wanwu data, maps wuxing colors, and outputs structured personality analysis JSON.

### Pipeline

```bash
# Default usage (birth plate analysis)
bin/qimen.sh --type=birth "1973-04-24 19:30"
# Creates ./qmen_birth.json
bin/qimen_xingge.sh
# Reads ./qmen_birth.json by default
```

### CLI Reference

```
Usage: qimen_xingge.sh [OPTIONS]

Options:
  --wanwu                 Show wanwu (万物类象) in text output (JSON always includes wanwu)
  -h, --help              Show this help

Requires: ./qmen_birth.json (for birth day stem and hour stem)
```

## Wanwu Script (万物类象提取)

The wanwu script `qimen_wanwu.sh` extracts full wanwu (万物类象) correspondences for a set of Qi Men symbols. Two input modes: palace mode reads symbols from a plate JSON, manual mode accepts symbols directly. At least one symbol is required in manual mode. Outputs structured text and JSON with all correspondence fields per symbol.

### Pipeline

```bash
# Palace mode: extract from birth plate
bin/qimen.sh --type=birth "1973-04-24 19:30"
bin/qimen_wanwu.sh --palace=3

# Manual mode: specify symbols directly (any combination, at least one)
bin/qimen_wanwu.sh --stem=丙 --star=天冲 --gate=伤门 --deity=九天 --state=帝旺

# Manual mode: single symbol
bin/qimen_wanwu.sh --gate=开门
```

### CLI Reference

```
Usage: qimen_wanwu.sh [OPTIONS]

Palace mode:
  --input=PATH            Input plate JSON (default: ./qmen_birth.json)
  --palace=N              Palace number (1-9)

Manual mode:
  --stem=X                Heavenly stem (e.g. 丙)
  --star=X                Nine star (e.g. 天冲)
  --gate=X                Eight gate (e.g. 伤门)
  --deity=X               Eight deity (e.g. 九天)
  --state=X               Twelve growth state (e.g. 帝旺)

Common:
  --output=PATH           Output JSON (default: ./qmen_wanwu.json)
  -h, --help              Show this help
```

`SKILL.md` files in the `skills/` directory define OpenCode AI skills for conversational interpretation.

**`qmen_dunjia`** is the unified router skill. When the user says "Qi Men Dun Jia" without a clear analysis direction, this skill takes over to (1) force a triage between event time vs. birth time, (2) perform the entry blessing ritual, (3) call `qimen.sh` to generate the appropriate plate JSON, and (4) hand off to the right sub-skill. Sub-skills detect the existing plate JSON and skip their own plate-setting step. The router never performs analysis itself.

**`qmen_event`** drives event plate reading (问事局): ritual blessing → generate plate → run analysis → narrative reading → follow-up. Maps free-text questions to 9 standard question types. Used exclusively for event plates; birth plate analysis uses the huaqizhen skill family (caiguan, hunlian, xingge, huaqizhen).

**`qmen_caiguan`** (财官诊断) drives wealth/career diagnosis: ritual blessing → generate birth plate → run caiguan analysis → diagnose seven hazards for wealth and career → "step on one, lift the other" advice → closing ritual reminder. Birth year stem is auto-read from `qmen_birth.json`. Uses birth plate only.

**`qmen_huaqizhen`** (化气阵布阵) drives array placement: ritual blessing → generate birth plate (event plate optional, only when targeting a specific event) → generate buzhen → miexiang + physical object recommendations → closing ritual reminder.

**`qmen_hunlian`** (婚恋分析) drives marriage/romance interpretation: ritual blessing → generate birth plate → run hunlian analysis → interpret across 5 modules (tuodan, sishou, cui_taohua, zhan_taohua, qingqu) plus 4 common modules → closing ritual reminder. Uses birth plate only.

**`qmen_xingge`** (性格分析) drives personality interpretation: generate birth plate → run personality analysis → AI synthesizes inner (day stem) and outer (hour stem) personality profiles from the combined stem/star/gate/deity traits at each palace.

**`qmen_wanwu`** (万物类象画像) generates creative imagery portraits from Qi Men symbol combinations. Three modes: scene (environment/atmosphere), object (shape/color/material/function), and person (appearance/temperament/behavior). Symbols are flexibly mapped to dimensions (each symbol used once), with twelve growth stages as lowest-priority modifier. Supports iterative refinement (style, domain, era adjustments) within wanwu data bounds.

## Usage

```bash
# Current time
bin/qimen.sh

# Specific datetime (auto-detected as birth plate)
bin/qimen.sh "2026-04-18 10:00"

# Birth plate (explicit)
bin/qimen.sh --type=birth "1973-04-24 19:30"

# Tianqin lodges in Kun 2-palace (traditional, instead of default follow-tiannei)
bin/qimen.sh --tianqin=jikun "2024-02-04 11:00"

# Tianqin follows Zhifu star
bin/qimen.sh --tianqin=follow-zhifu "2024-02-04 11:00"

# Custom JSON output path
bin/qimen.sh --output=/tmp/plate.json "2026-04-18 10:00"

# Full pipeline: birth plate + event plate + analysis
bin/qimen.sh --type=birth "1973-04-24 19:30"
bin/qimen.sh "2026-04-18 10:00"
bin/qimen_event.sh --question=事业

# Run analysis with custom paths
bin/qimen_event.sh --input=/tmp/plate.json --question=求财

# Verbose analysis (all wanwu fields)
bin/qimen_event.sh --question=婚姻感情 --verbose

# Caiguan (auto-reads birth year from qmen_birth.json)
bin/qimen.sh --type=birth "1973-04-24 19:30"
bin/qimen_caiguan.sh

# Buzhen (array placement)
bin/qimen.sh --type=birth "1973-04-24 19:30"
bin/qimen_huaqizhen.sh

# Buzhen with event plate
bin/qimen.sh --type=birth "1973-04-24 19:30"
bin/qimen.sh "2026-04-18 10:00"
bin/qimen_huaqizhen.sh --input=./qmen_event.json

# Buzhen with family protection
bin/qimen_huaqizhen.sh --family-stems=甲,丙

# Buzhen with yixiang concept protection
bin/qimen_huaqizhen.sh --yixiang=财富,权威

# Hunlian (marriage/romance analysis)
bin/qimen.sh --type=birth "1973-04-24 19:30"
bin/qimen_hunlian.sh

# Xingge (personality analysis)
bin/qimen.sh --type=birth "1973-04-24 19:30"
bin/qimen_xingge.sh

# Wanwu (imagery extraction, palace mode)
bin/qimen.sh --type=birth "1973-04-24 19:30"
bin/qimen_wanwu.sh --palace=3

# Wanwu (imagery extraction, manual mode)
bin/qimen_wanwu.sh --stem=丙 --star=天冲 --gate=伤门
```

Full CLI reference:

```
Usage: qimen.sh [OPTIONS] [DATETIME]

奇门遁甲起局 (Qi Men Dun Jia Plate Setting)
时家奇门 · 置闰法

DATETIME format: "YYYY-MM-DD HH:MM" (default: current time)

Options:
  --type=TYPE         Plate type: "event" or "birth"
                      Auto-selects: specified time → birth, current time → event
                      event → ./qmen_event.json, birth → ./qmen_birth.json
  --output=PATH       JSON file output path (default: based on --type)
  --tianqin=MODE      天禽 handling: "follow-tiannei" (default, follows Tiannei), "jikun", or "follow-zhifu"
  -h, --help          Show this help
```

## Installation

Run `install.sh` to symlink the project into your OpenCode skills directory and make the CLI executable:

```bash
bash install.sh
```

This creates a symlink for each `qmen_*` sub-skill in `~/.config/opencode/skills/` (e.g. `qmen_dunjia`, `qmen_event`, `qmen_caiguan`, `qmen_huaqizhen`, `qmen_hunlian`, `qmen_xingge`, `qmen_wanwu`). Restart OpenCode to load the skills.

## Requirements

Bash 3.2 or later. Tested on macOS (which ships Bash 3.2) and Linux. No external dependencies: no Python, no bc, no awk, no GNU coreutils extensions.

## Acknowledgments

What is implemented here represents roughly thirty percent of the author's lifetime study. With gratitude to Master Xun Shuang (荀爽) for his teaching.

## License

GPL-3.0
