**[English](README.md)**

> 为天地立心，
> 为生民立命，
> 为往圣继绝学，
> 为万世开太平。
>
> — 张载《横渠四句》

# 奇门遁甲 八门化气阵

纯 Bash 实现的奇门遁甲起局引擎，零外部依赖。

## 奇门遁甲简介

奇门遁甲与太乙、六壬并称"三式"，是中国古代最精密的时空预测体系之一。它以洛书九宫为空间框架，将天干、九星、八门、八神等多层符号体系叠加于九宫之上，通过五行生克关系呈现特定时刻的能量格局。

奇门遁甲历史上用于军事决策、择地、择时。今天它作为中国术数的核心分支，因其内部结构的严谨与精妙而持续受到研究。

## 设计取向

**只用置闰法，不用拆补法。** 处理节气交界有两大流派：置闰法在超神接气时沿用前局局数，保持每个时刻只对应一个局；拆补法则将时间拆分到前后两个局中。本项目选择置闰法，计算链路更干净。

**时家奇门，转盘。** 本项目实现的是时家奇门（按时辰起局），非日家、月家。盘式采用转盘法（星、门绕九宫旋转），非飞盘法（按飞行轨迹布符号）。转盘保留了符号与宫位的空间对应关系，读盘时方位意义更直观。

**天禽寄宫。** 天禽星居中五宫，中宫无门，需要寄宫。通过 `--tianqin=MODE` 选择三种模式：

- **`follow-tiannei`**（默认）：天禽随天内走。天盘转动后，天内落在哪宫，天禽就寄在该宫。天禽属阴土，与天内同气，故随之最合理。
- **`jikun`**：天禽固定寄坤二宫，不随转盘变动。这是最传统的做法。
- **`follow-zhifu`**：天禽随值符星走，值符转到哪宫天禽就寄在该宫。

无论哪种模式，天禽所寄宫位会在该宫原有星旁额外显示 `天禽(中) [寄]`。

**纯 Bash，无外部工具。** 整个引擎运行在 Bash 3.2+ 上，不调用 Python、bc、awk 或任何外部程序。所有运算使用 Bash 整数算术。历法计算（公历/儒略日转换、干支循环推算）全部以 shell 算术从头实现。macOS 自带的 Bash 3.2 即可运行。

**脚本与数据完全分离。** 全部领域常量存放在 `data/*.dat` 文件中，采用 `key=value` 格式。脚本内不含任何硬编码的领域知识。理论上，替换数据文件就能建模不同的奇门变体，无需改动任何代码。

## 架构

引擎由库文件、CLI 入口和数据目录组成。

```
skill_qmenpowers/
├── skills/
│   ├── qmen_event/
│   │   └── SKILL.md                # 问事局解盘技能
│   ├── qmen_caiguan/
│   │   └── SKILL.md                # 财官诊断技能
│   ├── qmen_huaqizhen/
│   │   └── SKILL.md                # 化气阵布阵技能
│   ├── qmen_hunlian/
│   │   └── SKILL.md                # 婚恋分析技能
│   ├── qmen_wanwu/
│   │   └── SKILL.md                # 万物类象画像技能
│   └── qmen_xingge/
│       └── SKILL.md                # 性格分析技能
├── bin/
│   ├── qimen.sh                    # 起局 CLI
│   ├── qimen_event.sh              # 问事局分析 CLI
│   ├── qimen_caiguan.sh            # 财官分析 CLI
│   ├── qimen_huaqizhen.sh          # 化气阵布阵 CLI
│   ├── qimen_hunlian.sh            # 婚恋分析 CLI
│   ├── qimen_wanwu.sh              # 万物类象提取 CLI
│   └── qimen_xingge.sh             # 性格分析 CLI
├── install.sh                      # 安装脚本
├── lib/
│   ├── data_loader.sh              # 通用数据文件加载器
│   ├── qimen_engine.sh             # 核心计算引擎
│   ├── qimen_output.sh             # 输出格式化（文本 + JSON）
│   ├── qimen_json.sh               # 共享 JSON 解析与工具库
│   ├── qimen_event.sh              # 问事局分析库
│   ├── qimen_banmenhuaqizhen.sh    # 化气阵核心库
│   ├── qimen_caiguan.sh            # 财官分析库
│   ├── qimen_hunlian.sh            # 婚恋分析库
│   └── qimen_xingge.sh             # 性格分析库
└── data/
    ├── tiangan_dizhi.dat           # 引擎：天干地支
    ├── jieqi_table.dat             # 引擎：节气时间表
    ├── meta_jieqi.dat              # 引擎：节气元数据
    ├── ju_map.dat                  # 引擎：局数映射
    ├── nine_stars.dat              # 引擎：九星基础
    ├── eight_gates.dat             # 引擎：八门基础
    ├── eight_deities.dat           # 引擎：八神排列
    ├── sanqi_liuyi.dat             # 引擎：三奇六仪
    ├── luoshu.dat                  # 引擎：洛书遍历
    ├── meta_palace.dat             # 引擎：宫位元数据
    ├── twelve_states.dat           # 引擎：十二长生
    ├── wanwu_bagua.dat             # 参考：八卦万物类象
    ├── wanwu_tiangan.dat           # 参考：天干万物类象
    ├── wanwu_dizhi.dat             # 参考：地支万物类象
    ├── wanwu_wuxing.dat            # 参考：五行万物类象
    ├── wanwu_nine_stars.dat        # 参考：九星万物类象
    ├── wanwu_eight_gates.dat       # 参考：八门万物类象
    ├── wanwu_eight_deities.dat     # 参考：八神万物类象
    ├── wanwu_geju.dat              # 参考：格局定义与诊断表
    ├── rules_yongshen.dat          # 分析：用神选取规则
    ├── wanwu_prefix_map.dat        # 分析：符号名称到前缀映射
    ├── meta_huaqizhen.dat          # 化气：天干关系、六害规则、七要害定义
    ├── hangye_quxiang.dat          # 化气：行业取象映射
    ├── rules_buzhen.dat            # 布阵：禁忌、压制、灭象规则
    ├── buzhen_xiangshu.dat         # 布阵：天干地支形象（颜色、材质、生肖）
    ├── rules_hunlian.dat           # 婚恋：干合组合、沐浴位、孤辰寡宿分组、桃花神煞/三奇规则
    └── wanwu_huaqizhen.dat         # 化气：性格分析类象对应表
```

**`lib/data_loader.sh`** 是通用的 key=value 文件解析器。它将 `.dat` 文件读入 shell 变量和数组。逗号分隔的值自动展开为索引数组。含有 CJK 字符的键通过内部键值存储（`dl_get`/`dl_set`）处理，兼容 Bash 3（旧版 Bash 不支持非 ASCII 键的关联数组）。

**`lib/qimen_engine.sh`** 包含全部计算逻辑：历法运算（公历/儒略日转换、干支推算）、节气查表、元/局判定（含置闰处理），以及完整的起局流水线（地盘布局、天盘转星、人盘转门、神盘布神、格局检测）。

**`lib/qimen_output.sh`** 读取引擎填充的全局数组，格式化后输出。支持两种模式：人类可读的文本模式（逐宫列表 + 头部信息）和结构化 JSON。

**`lib/qimen_json.sh`** 提供共享 JSON 解析与工具函数：盘面 JSON 解析、日干/时干宫位查找、天干提取、万物类象查表。被所有分析 CLI 脚本使用。

**`lib/qimen_event.sh`** 提供问事局专用分析流水线：按问题类型选取用神、标记用神宫位、81 组天干克应查表、格局标记汇总、文本/JSON 输出格式化。仅被 `bin/qimen_event.sh` 使用。

**`bin/qimen.sh`** 是起局 CLI 封装。解析命令行参数，依次 source 库文件，调用引擎，再分发到对应的输出格式化函数。

**`bin/qimen_event.sh`** 是问事局分析 CLI。读取 `qimen.sh` 生成的起局 JSON，执行分析流水线，输出结构化分析 JSON。仅用于问事局。

**`lib/qimen_banmenhuaqizhen.sh`** 提供化气阵核心库：通用辅助函数、宫位查找、逐宫六害（六害：刑、墓、庚、白虎、门迫、空亡）检测（含对宫影响：玄武/庚/白虎同时影响本宫和对宫）、月令五行生克关系计算（含中文含义标签：扩张/稳健/努力/损耗/大亏）、干财天干追踪（含天干五合回退及缺甲找值符宫干特殊规则）、符号定位工具、宫位摘要生成、月令关系，以及完整的布阵流水线：保护天干识别（日干/时干、生年干、家人干、意象干、值符/值使干）、八宫六害扫描、灭象清单生成（含安全方位推荐）、逐宫布阵方案（击刑用合、入墓用冲、门迫用合、庚/白虎用乙、空亡填象）、禁忌冲突检测、实物形象映射。

**`lib/qimen_caiguan.sh`** 提供财官分析专用流水线：财富和事业两个维度的七要害分析（含月令中文含义标签）、干财分析（含缺甲找值符宫干特殊规则）、行业取象查找、符使分析、天干角色分析、JSON 输出格式化，以及财官流水线入口。

**`lib/qimen_hunlian.sh`** 提供婚恋分析流水线：出生日干宫位定位、干合（天干合化）配偶、六合、沐浴位、三奇近距检测、桃花多维度检测（玄武、太阴、壬/癸、三奇同宫）、伏吟/反吟宫位扫描、空亡对配偶位影响评估、艮/坤宫六害检查、孤辰寡宿计算（含解化方案），以及特殊位置追踪（天蓬、伤门、丁、癸）。

**`lib/qimen_xingge.sh`** 提供性格分析流水线：出生日干（内在性格）和时干（外在性格）宫位定位、从化气阵专用万物类象数据中提取性格对应（每宫天干、星、门、神的性格特征）、五行颜色映射，以及结构化文本/JSON 输出。

**`bin/qimen_caiguan.sh`** 是财官诊断 CLI。只读取命盘（`./qmen_birth.json`）。自动从 `./qmen_birth.json` 读取出生年天干，输出结构化财官分析 JSON，包含财富和事业要害诊断。

**`bin/qimen_huaqizhen.sh`** 是化气阵布阵 CLI。默认读取命盘（`./qmen_birth.json`），可通过 `--input` 指定事件盘。自动从 `./qmen_birth.json` 读取出生年天干，接收可选的家人天干和意象概念天干，输出结构化布阵 JSON，包含灭象清单和逐宫摆放处方。

**`bin/qimen_hunlian.sh`** 是婚恋分析 CLI。只读取命盘（`./qmen_birth.json`）。自动从 `./qmen_birth.json` 读取出生日干，输出结构化婚恋分析 JSON，包含配偶检测、桃花指标、孤辰寡宿评估和宫位级感情诊断。

**`bin/qimen_xingge.sh`** 是性格分析 CLI。只读取命盘（`./qmen_birth.json`）。读取出生日干和时干，在盘面上定位二者，提取每个天干所在宫位的星、门、神性格特征对应，输出结构化性格分析 JSON。

**`bin/qimen_wanwu.sh`** 是万物类象提取 CLI。支持两种模式：盘面模式（`--palace=N`）从盘面 JSON 提取指定宫位的全部万物类象，手工模式（`--stem/--star/--gate/--deity/--state`）直接接受符号组合。每个参数可选，至少提供一个。输出结构化文本和 JSON。

## 数据文件

数据文件分为两类：**引擎数据**（11 个文件，起局计算直接使用）和**参考数据**（8 个 `wanwu_*` 文件，提供完整的万物类象对照表，供解盘参考）。均在 `data/` 目录下，`key=value` 格式，`#` 开头为注释。

### 引擎数据

| 文件 | 内容 |
|------|------|
| `tiangan_dizhi.dat` | 天干地支：十天干、十二地支，六十甲子循环的基础字符 |
| `jieqi_table.dat` | 节气时间表：1899 至 2100 年每年 24 节气的 Unix 时间戳 |
| `meta_jieqi.dat` | 节气元数据：节/气分类、阴遁/阳遁归属、元数周期信息 |
| `ju_map.dat` | 局数映射：每个节气在上元/中元/下元对应的局数（1~9） |
| `nine_stars.dat` | 九星：星名、五行、吉凶、默认宫位 |
| `eight_gates.dat` | 八门：门名、五行、吉凶、默认宫位 |
| `eight_deities.dat` | 八神：阳遁顺序与阴遁顺序 |
| `sanqi_liuyi.dat` | 三奇六仪：三奇（乙丙丁）和六仪（戊己庚辛壬癸）与天干的对应 |
| `luoshu.dat` | 洛书九宫：九宫环绕遍历顺序 |
| `meta_palace.dat` | 九宫元数据：宫名、五行、方位、地支、尾数、先天数/后天数 |
| `twelve_states.dat` | 十二长生：长生、沐浴、冠带、临官、帝旺、衰、病、死、墓、绝、胎、养 |

### 参考数据（万物类象）

完整的奇门类象对照表，不参与引擎计算，作为解盘分析的结构化知识库。

| 文件 | 内容 |
|------|------|
| `wanwu_bagua.dat` | 八卦类象：取象、身体、家庭、动物、方位、季节、脏腑、情志等 |
| `wanwu_tiangan.dat` | 天干类象：五行、颜色、方位、身体部位、性格、季节、数字等 |
| `wanwu_dizhi.dat` | 地支类象：五行、方位、季节、身体、性格等；含三合、六合、六冲、刑害关系表 |
| `wanwu_wuxing.dat` | 五行类象：方位、季节、脏腑、味、色、情志、数字、生克关系；含河图数、旺相休囚死 |
| `wanwu_nine_stars.dat` | 九星类象：五行、吉凶、颜色、身体/疾病、性格、天象、器物、场所、事业、占断宜忌 |
| `wanwu_eight_gates.dat` | 八门类象：五行、吉凶、颜色、身体/疾病、性格、场所、事业、占断宜忌；三吉门/三凶门分类 |
| `wanwu_eight_deities.dat` | 八神类象：五行、取象、性格、身体、事件、器物；含阳遁/阴遁排列说明 |
| `wanwu_geju.dat` | 格局大全：庚格、81 组天干克应、吉格/凶格汇编、门迫条件、反吟伏吟表、入墓表、六仪击刑、空亡、驿马规则 |

### 分析数据

| 文件 | 内容 |
|------|------|
| `rules_yongshen.dat` | 用神选取规则：9 种问题类型，每种含优先级排序的星、门、神、干选取方案 |
| `wanwu_prefix_map.dat` | 符号名称到万物类象文件前缀的映射：将中文名称映射到数据文件的键前缀 |

### 化气数据

| 文件 | 内容 |
|------|------|
| `meta_huaqizhen.dat` | 天干五合、天干所克表、五行生克关系、地支五行、六害标记定义、财富七要害和事业七要害元素定义、意象概念→天干映射（财富→戊、暴力→庚等）、对宫映射 |
| `hangye_quxiang.dat` | 行业取象映射：将职业名称映射到对应的奇门符号（门、星、神、干） |
| `wanwu_huaqizhen.dat` | 化气阵类象对应表：十天干（性格+物象）、八门（性格+物象）、九星（性格+行业+物象）、八神（性格+物象）特征对应；五行颜色；宫位名称/五行映射 |

### 布阵数据

| 文件 | 内容 |
|------|------|
| `rules_buzhen.dat` | 禁忌规则（jinbi）：哪些天干不能放哪些宫（三奇入墓、六仪击刑）；压制方式（击刑用合、入墓用冲、门迫用合、庚/白虎用乙、空亡填象）；灭象方式；安全方位定义；保护优先级 |
| `buzhen_xiangshu.dat` | 布阵实物形象：每个天干对应的颜色和材质；每个地支对应的生肖动物和替代物品；物品摆放位置规则 |

### 婚恋数据

| 文件 | 内容 |
|------|------|
| `rules_hunlian.dat` | 婚恋规则：干合组合、沐浴位、孤辰寡宿分组、桃花神煞/三奇规则 |

## 计算流水线

引擎核心函数 `qm_compute_plate` 按以下顺序执行：

1. **四柱干支。** 计算年柱、月柱、日柱、时柱。每柱由一个天干和一个地支组成，从六十甲子循环中推算得出。

2. **定局。** 查找当前所在节气，判断当前日期落在哪个元（上元/中元/下元），再从映射表中查出对应局数。若日期处于超神接气的闰奇区间（节气交界与新元起点之间），执行置闰：沿用前一局的局数。

3. **地盘。** 根据局数和阴遁/阳遁方向，将九个仪（三奇六仪）布入九宫。

4. **值符值使。** 由时柱在地盘上的落宫位置，确定当值的星（值符）和门（值使）。

5. **天盘转星。** 以时柱推算的偏移量为步长，将九星从默认宫位旋转到新的宫位。

6. **人盘转门。** 采用地支步法，根据时支偏移量将八门从默认宫位旋转到新的宫位。

7. **神盘。** 从值符星所在宫位起，按阳遁顺排或阴遁逆排的顺序布置八神。

8. **十二长生。** 根据日干五行，计算每宫的生命周期状态（长生、帝旺、墓、绝等）。

9. **六仪击刑。** 检查六仪是否落入与其所纳地支构成刑关系的宫位。

10. **空亡。** 由时柱在其所属旬中的位置，推算两个空亡地支，再映射到对应宫位。

11. **驿马。** 由时支按传统公式推算驿马地支，映射到宫位。

12. **格局标记。** 逐宫扫描，检测以下特殊格局：

| 标记 | 含义 |
|------|------|
| `[庚]` | 天盘见庚（金气凶象） |
| `[干墓]` | 天干入墓（天干五行之墓与当前宫位重合） |
| `[星墓]` | 星入墓（星五行之墓与当前宫位重合） |
| `[门墓]` | 门入墓（门五行之墓与当前宫位重合） |
| `[门迫]` | 门迫宫（门之五行克宫之五行） |
| `[星反吟]` | 星反吟（星落在与本宫相对的宫位） |
| `[门反吟]` | 门反吟（门落在与本宫相对的宫位） |
| `[星伏吟]` | 星伏吟（星落回本宫，主停滞） |
| `[门伏吟]` | 门伏吟（门落回本宫，主停滞） |
| `[击刑]` | 六仪击刑 |
| `[空亡]` | 空亡 |
| `[驿马]` | 驿马（主动、变迁） |

## 输出

支持两种输出模式。

**文本模式**（默认）输出头部信息和逐宫明细：

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

**JSON 模式**始终开启：每次运行都会根据 `--type` 写入结构化 JSON 文件，包含全部头部字段和一个宫位数组，每个宫位对象含所有已计算字段。文本输出同时显示在终端。

## 分析脚本

分析脚本 `qimen_event.sh` 读取 `qimen.sh` 生成的起局 JSON，补充万物类象数据，根据问题类型标记用神宫位，输出结构化分析 JSON。

### 流水线

```bash
# 第一步：生成命盘
bin/qimen.sh --type=birth "1973-04-24 19:30"
# 生成 ./qmen_birth.json

# 第二步：生成事件盘
bin/qimen.sh "2026-04-18 10:00"
# 生成 ./qmen_event.json

# 第三步：运行分析
bin/qimen_event.sh --question=事业
# 读取 ./qmen_event.json，写入 ./qmen_event_analysis.json
```

### 问题类型

| 类型 | 含义 | 主要用神 |
|------|------|---------|
| 事业 | 事业、仕途 | 开门、天心星 |
| 求财 | 财运、理财 | 生门、六合 |
| 婚姻感情 | 婚姻、恋爱 | 六合、景门、乙奇 |
| 疾病健康 | 健康、疾病 | 天内星、死门 |
| 出行 | 出行、行程 | 开门、九天 |
| 官司诉讼 | 官司、法律纠纷 | 伤门、天英星 |
| 寻人寻物 | 寻人、寻物 | 六合、杜门 |
| 天气 | 天气预测 | 景门、天英星 |
| 家宅风水 | 家居、风水 | 生门、天任星 |

### 分析输出

分析 JSON 包含：
- 日干、时干所在宫位
- 用神标记及宫位位置
- 每宫万物类象（星、门、神、天干）
- 关键宫位的 81 组天干克应查表
- 格局标记（空亡、驿马、庚格、入墓、门迫、反吟、伏吟、击刑）

### CLI 参考

```
Usage: qimen_event.sh [OPTIONS]

Options:
  --input=PATH        输入起局 JSON（默认：./qmen_event.json）
  --question=TYPE     问题类型（必填）
  --verbose           完整万物类象提取（默认：精简模式）
  --wanwu             文本输出中显示万物类象（JSON 始终包含万物类象）
  -h, --help          显示帮助
```

## 化气分析脚本（八门化气阵）

化气脚本 `qimen_caiguan.sh` 只读取命盘（`./qmen_birth.json`）。它自动从 `./qmen_birth.json` 读取出生年天干，执行财富事业深度分析。它定位财富和事业两个维度的七要害，检测每宫六害（六害：刑、墓、庚、白虎、门迫、空亡），计算月令五行生克关系（含中文含义标签：扩张/稳健/努力/损耗/大亏），追踪干财天干（含天干五合回退及缺甲找值符宫干特殊规则），自动从盘面推算行业取象。

### 流水线

```bash
# 默认用法（命盘分析）
bin/qimen.sh --type=birth "1973-04-24 19:30"
# 生成 ./qmen_birth.json
bin/qimen_caiguan.sh
# 默认读取 ./qmen_birth.json
```

### CLI 参考

```
Usage: qimen_caiguan.sh [OPTIONS]

Options:
  --wanwu                 文本输出中显示万物类象（JSON 始终包含万物类象）
  -h, --help              显示帮助

依赖：./qmen_birth.json（用于读取出生年天干）
```

## 布阵脚本

布阵脚本 `qimen_huaqizhen.sh` 默认读取命盘（`./qmen_birth.json`），可通过 `--input` 指定事件盘进行事件分析。它读取化气分析 JSON，自动从 `./qmen_birth.json` 读取出生年天干，接收可选的家人天干和意象概念天干，生成布阵方案。它识别保护天干（日干/时干、生年干、家人干、意象干、值符/值使干），扫描八宫中对保护天干的六害威胁（含对宫影响：玄武/庚/白虎同时影响本宫和对宫），生成灭象清单（含安全转移方位），并为每宫生成布阵方案（击刑用合、入墓用冲、门迫用合、庚/白虎用乙奇、空亡填象），附带禁忌冲突检测和实物形象映射。

### 流水线

```bash
# 默认用法（命盘分析）
bin/qimen.sh --type=birth "1973-04-24 19:30"
# 生成 ./qmen_birth.json
bin/qimen_caiguan.sh
bin/qimen_huaqizhen.sh
# 默认读取 ./qmen_birth.json

# 使用事件盘
bin/qimen.sh --type=birth "1973-04-24 19:30"
bin/qimen.sh "2026-04-18 10:00"
bin/qimen_caiguan.sh --input=./qmen_event.json
bin/qimen_huaqizhen.sh --input=./qmen_event.json
```

### CLI 参考

```
Usage: qimen_huaqizhen.sh [OPTIONS]

Options:
  --input=PATH            输入起局 JSON（默认：./qmen_birth.json）
  --family-stems=S1,S2    家人出生年天干（可选）
  --yixiang=C1,C2         保护的意象概念：财富,暴力,权威,突破,表现,情欲（可选）
  --wanwu                 文本输出中显示万物类象（JSON 始终包含万物类象）
  -h, --help              显示帮助

依赖：./qmen_birth.json（用于读取出生年天干）
```

## 婚恋分析脚本

婚恋脚本 `qimen_hunlian.sh` 只读取命盘（`./qmen_birth.json`）。它自动从 `./qmen_birth.json` 读取出生日干，执行婚恋分析。它定位出生日干宫位，识别干合配偶，检测六合与沐浴位，多维度检测桃花指标（玄武、太阴、壬/癸、三奇同宫），扫描伏吟/反吟宫位，评估空亡对配偶位的影响，检查艮/坤宫六害，计算孤辰寡宿（含解化方案），并追踪特殊位置（天蓬、伤门、丁、癸）。

### 流水线

```bash
# 默认用法（命盘分析）
bin/qimen.sh --type=birth "1973-04-24 19:30"
# 生成 ./qmen_birth.json
bin/qimen_hunlian.sh
# 默认读取 ./qmen_birth.json
```

### CLI 参考

```
Usage: qimen_hunlian.sh [OPTIONS]

Options:
  --wanwu                 文本输出中显示万物类象（JSON 始终包含万物类象）
  -h, --help              显示帮助

依赖：./qmen_birth.json（用于读取出生日干）
```

## 性格分析脚本

性格分析脚本 `qimen_xingge.sh` 默认读取命盘（`./qmen_birth.json`）。它读取出生日干（内在性格）和时干（外在性格），在盘面上定位二者，从化气阵专用万物类象数据中提取每个天干所在宫位的星、门、神性格特征对应，映射五行颜色，输出结构化性格分析 JSON。

### 流水线

```bash
# 默认用法（命盘分析）
bin/qimen.sh --type=birth "1973-04-24 19:30"
# 生成 ./qmen_birth.json
bin/qimen_xingge.sh
# 默认读取 ./qmen_birth.json
```

### CLI 参考

```
Usage: qimen_xingge.sh [OPTIONS]

Options:
  --wanwu                 文本输出中显示万物类象（JSON 始终包含万物类象）
  -h, --help              显示帮助

依赖：./qmen_birth.json（用于读取出生日干和时干）
```

## 万物类象提取脚本

万物类象提取脚本 `qimen_wanwu.sh` 提取指定符号组合的全部万物类象对应。支持两种模式：盘面模式从盘面 JSON 中读取指定宫位的符号，手工模式直接接受符号参数。每个参数可选，至少提供一个。输出结构化文本和 JSON。

### 流水线

```bash
# 盘面模式：从命盘提取
bin/qimen.sh --type=birth "1973-04-24 19:30"
bin/qimen_wanwu.sh --palace=3

# 手工模式：直接指定符号（任意组合，至少一个）
bin/qimen_wanwu.sh --stem=丙 --star=天冲 --gate=伤门 --deity=九天 --state=帝旺

# 手工模式：单个符号
bin/qimen_wanwu.sh --gate=开门
```

### CLI 参考

```
用法: qimen_wanwu.sh [选项]

盘面模式:
  --input=PATH            输入盘面 JSON（默认：./qmen_birth.json）
  --palace=N              宫位号（1-9）

手工模式:
  --stem=X                天干（如：丙）
  --star=X                九星（如：天冲）
  --gate=X                八门（如：伤门）
  --deity=X               八神（如：九天）
  --state=X               十二长生（如：帝旺）

通用:
  --output=PATH           输出 JSON（默认：./qmen_wanwu.json）
  -h, --help              显示帮助
```

`skills/` 目录下的 `SKILL.md` 文件定义了 OpenCode AI 技能，用于驱动对话式解盘。

**`qmen_event`** 驱动问事局解盘：入局祝福 → 起局 → 运行分析 → 叙述式解读 → 追问。将用户的自由文本问题映射到 9 种标准问题类型。仅用于问事局；生日局分析使用化气阵技能家族（caiguan、hunlian、xingge、huaqizhen）。

**`qmen_caiguan`**（财官诊断）驱动财富事业诊断：入局祝福 → 生成命盘 → 生成事件盘 → 运行财官分析 → 诊断财富和事业七要害 → "踩一捧一"建议 → 封局提醒。出生年天干自动从 `qmen_birth.json` 读取。

**`qmen_huaqizhen`**（化气阵布阵）驱动布阵：入局祝福 → 生成命盘 → 生成事件盘 → 运行财官分析 → 生成布阵方案 → 灭象+实物摆放推荐 → 封局提醒。

**`qmen_hunlian`**（婚恋分析）驱动婚恋解读：入局祝福 → 生成命盘 → 生成事件盘 → 运行婚恋分析 → 按 5 个模块（脱单、死守、催桃花、斩桃花、情趣）加 4 个通用模块解读 → 封局提醒。

**`qmen_xingge`**（性格分析）驱动性格解读：生成命盘 → 运行性格分析 → AI 综合日干（内在性格）和时干（外在性格）所在宫位的天干/星/门/神性格特征，给出完整性格画像。

**`qmen_wanwu`**（万物类象画像）基于奇门符号组合生成创意画像描述。三种模式：场景（环境/氛围）、物品（形状/颜色/材质/功能）、人物（外貌/气质/行为）。符号灵活分配到不同维度（每个符号只用一次），十二长生优先级最低。支持迭代修改（风格、领域、时代调整），始终在万物类象数据范围内。

## 用法

```bash
# 当前时间
bin/qimen.sh

# 指定时间（自动识别为命盘）
bin/qimen.sh "2026-04-18 10:00"

# 命盘（显式指定）
bin/qimen.sh --type=birth "1973-04-24 19:30"

# 天禽寄坤二宫（传统做法，而非默认的随天芮）
bin/qimen.sh --tianqin=jikun "2024-02-04 11:00"

# 天禽随值符走
bin/qimen.sh --tianqin=follow-zhifu "2024-02-04 11:00"

# 自定义 JSON 输出路径
bin/qimen.sh --output=/tmp/plate.json "2026-04-18 10:00"

# 完整流水线：命盘 + 事件盘 + 分析
bin/qimen.sh --type=birth "1973-04-24 19:30"
bin/qimen.sh "2026-04-18 10:00"
bin/qimen_event.sh --question=事业

# 自定义输入输出路径
bin/qimen_event.sh --input=/tmp/plate.json --question=求财

# 详细模式分析（完整万物类象）
bin/qimen_event.sh --question=婚姻感情 --verbose

# 财官分析（自动从 qmen_birth.json 读取生年天干）
bin/qimen.sh --type=birth "1973-04-24 19:30"
bin/qimen_caiguan.sh

# 布阵
bin/qimen.sh --type=birth "1973-04-24 19:30"
bin/qimen_caiguan.sh
bin/qimen_huaqizhen.sh

# 布阵（使用事件盘）
bin/qimen.sh --type=birth "1973-04-24 19:30"
bin/qimen.sh "2026-04-18 10:00"
bin/qimen_caiguan.sh
bin/qimen_huaqizhen.sh --input=./qmen_event.json

# 布阵（含家人保护）
bin/qimen_huaqizhen.sh --family-stems=甲,丙

# 布阵（含意象概念保护）
bin/qimen_huaqizhen.sh --yixiang=财富,权威

# 婚恋分析
bin/qimen.sh --type=birth "1973-04-24 19:30"
bin/qimen_hunlian.sh

# 性格分析
bin/qimen.sh --type=birth "1973-04-24 19:30"
bin/qimen_xingge.sh

# 万物类象提取（盘面模式）
bin/qimen.sh --type=birth "1973-04-24 19:30"
bin/qimen_wanwu.sh --palace=3

# 万物类象提取（手工模式）
bin/qimen_wanwu.sh --stem=丙 --star=天冲 --gate=伤门
```

完整命令行参考：

```
用法: qimen.sh [选项] [日期时间]

奇门遁甲起局
时家奇门 · 置闰法

日期时间格式: "YYYY-MM-DD HH:MM"（默认：当前时间）

选项:
  --type=TYPE         盘类型: "event" 或 "birth"
                      默认自动选择: 指定时间→birth, 当前时间→event
                      event → ./qmen_event.json，birth → ./qmen_birth.json
  --output=PATH       JSON 文件输出路径（默认：根据 --type 决定）
  --tianqin=MODE      天禽寄宫: "follow-tiannei"（默认，随天芮）, "jikun", 或 "follow-zhifu"
  -h, --help          显示帮助
```

## 安装

运行 `install.sh` 将项目符号链接到 OpenCode 技能目录，并赋予 CLI 可执行权限：

```bash
bash install.sh
```

这会为每个 `qmen_*` 子技能在 `~/.config/opencode/skills/` 下创建独立的符号链接（如 `qmen_event`、`qmen_caiguan`、`qmen_huaqizhen`、`qmen_hunlian`、`qmen_wanwu`、`qmen_xingge`）。重启 OpenCode 即可加载这些技能。

## 环境要求

Bash 3.2 及以上。在 macOS（自带 Bash 3.2）和 Linux 上测试通过。无外部依赖：不需要 Python、bc、awk，也不依赖 GNU coreutils 扩展。

## 致谢

本项目所实现的内容约为作者平生所学的三成。感谢荀爽老师授业。

## 许可证

GPL-3.0
