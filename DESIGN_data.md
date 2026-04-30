# 数据结构设计文档

本文档描述各脚本 JSON 输出的完整数据结构。所有脚本默认读取 `./qmen_birth.json`（命盘），可通过 `--input` 指定事件盘。

---

## 目录

- [Event 问事局分析](#event-问事局分析)
- [Caiguan 财官诊断](#caiguan-财官诊断)
- [Huaqizhen 化气阵布阵](#huaqizhen-化气阵布阵)
- [Yishenhuanjiang 移神换将化解](#yishenhuanjiang-移神换将化解)
- [Hunlian 婚恋分析](#hunlian-婚恋分析)
- [Xingge 性格分析](#xingge-性格分析)
- [Yaoce 遥测分析](#yaoce-遥测分析)
- [Wanwu 万物类象提取](#wanwu-万物类象提取)

---

## Event 问事局分析

**输出文件**: `qmen_event_analysis.json`

```jsonc
{
  "source": "./qmen_event.json",              // 输入盘文件路径
  "question_type": "事业",                     // 问题类型（9种之一）
  "datetime": "2026-04-23 11:00",             // 起局时间
  "si_zhu": {                                  // 四柱
    "year": "丙午",
    "month": "壬辰",
    "day": "丁卯",
    "hour": "丙午"
  },
  "ju": {                                      // 局信息
    "type": "阳遁",
    "number": 5,
    "yuan": "上元"
  },

  "ri_gan": {"stem": "丁", "palace": 2},      // 日干及所在宫
  "shi_gan": {"stem": "丙", "palace": 3},     // 时干及所在宫

  "yongshen": [                                // 用神（按优先级排列）
    {"priority": 0, "type": "gate", "name": "开门", "palace": 1},
    {"priority": 1, "type": "star", "name": "天心", "palace": 2}
  ],

  "zhi_fu": {"star": "天英", "palace": 3},    // 值符
  "zhi_shi": {"gate": "景门", "palace": 2},   // 值使

  "kong_wang": [                               // 空亡（2项）
    {"branch": "寅", "palace": 8},
    {"branch": "卯", "palace": 3}
  ],
  "yi_ma": {"branch": "申", "palace": 2},     // 驿马

  "palaces": {                                 // 九宫详情（key 为宫号字符串）
    "1": {
      "name": "坎1宫",
      "wuxing": "水",
      "direction": "北",
      "star": "天冲",
      "gate": "开门",
      "deity": "九地",
      "tian_gan": "丙",                        // 天盘天干
      "di_gan": "癸",                          // 地盘天干
      "state": "胎",                           // 十二长生状态
      "markers": [],                           // 格局标记数组
      "is_yongshen": true,                     // 是否为用神宫
      "is_ri_gan": false,                      // 日干是否在此宫
      "is_shi_gan": false,                     // 时干是否在此宫
      "wanwu": {                               // 万物类象（星/门/神）
        "star": {
          "五行": "木",
          "吉凶": "小吉(勇武之星)",
          "核心描述": "勇武之星,航空,航天...",
          "颜色": "碧绿,青",
          "人物": "军人,武将,运动员...",
          "性格品质": "勇猛果敢,急躁冲动...",
          "场所环境": "军营,战场,操场...",
          "身体": "肝,胆,足,筋,神经",
          "疾病": "肝胆疾病,筋骨损伤...",
          "事业行为": "开拓创业,征伐,竞争...",
          "占断适宜": "出行,赴任,搬迁...",
          "占断不宜": "安静守成,养病"
        },
        "gate": {
          "五行": "金",
          "吉凶": "大吉(三吉门之一)",
          "核心描述": "西北方,乾金宫,开创事业...",
          "颜色": "白色,金色,银白",
          "人物": "领导,官员,老板...",
          "性格品质": "大方豁达,有魄力...",
          "场所环境": "政府机关,公司...",
          "身体": "头,肺,大肠,骨骼",
          "疾病": "头痛,肺病,骨骼疾病...",
          "事业行为": "开业,创办,上任...",
          "占断适宜": "开业,开工,上任...",
          "占断不宜": "隐藏,暗中行事..."
        },
        "deity": {
          "五行": "土(坤土)",
          "吉凶": "吉",
          "核心描述": "坤方之土神,主柔顺虚恭之事...",
          "颜色": "黄色,黑",
          "代表人物": "母亲,妻子,老妇人...",
          "性格品质": "厚道宽容,柔顺安静...",
          "场所环境": "田野,地下室,坟墓...",
          "身体疾病": "脾,胃,腹部...",
          "事件行为": "守旧不动,隐藏蓄积...",
          "占断含义": "宜守不宜攻,宜静不宜动..."
        }
      },
      "combination": {                         // 81组合（天盘干加地盘干）
        "tian_di": "丙加癸",
        "name": "月奇华盖",
        "jixi": "平",                          // 吉/凶/平
        "meaning": "阴阳相碍,光明被蒙蔽..."
      }
    }
    // ... 共 9 宫（1-9），中5宫 wanwu 为空对象
  },

  "key_combinations": [                        // 关键宫位的81组合汇总
    {
      "palace": 1,
      "role": "yongshen",                      // 角色: yongshen/ri_gan/shi_gan
      "tian_di": "丙加癸",
      "name": "月奇华盖",
      "jixi": "平",
      "meaning": "阴阳相碍,光明被蒙蔽..."
    }
    // ... 用神宫 + 日干宫 + 时干宫 的组合
  ]
}
```

### 字段说明

- `palaces` 的 key 为字符串 `"1"` 至 `"9"`，非整数
- `markers` 数组可能包含：`"庚"`, `"干墓"`, `"星墓"`, `"门墓"`, `"门迫"`, `"空亡"`, `"驿马"`, `"击刑"`, `"星反吟"`, `"门反吟"`, `"星伏吟"`, `"门伏吟"`
- `wanwu` 中具体包含哪些字段取决于对应 `wanwu_*.dat` 数据文件的定义
- `--verbose` 模式下 wanwu 包含所有字段；默认精简模式仅包含核心字段
- 中5宫的 star/gate/deity/tian_gan 均为空字符串，wanwu 为空对象 `{}`

---

## Caiguan 财官诊断

**输出文件**: `qmen_caiguan.json`

```jsonc
{
  "datetime": "2026-04-18 10:00",         // 起局时间
  "si_zhu": {                              // 四柱
    "year": "丙午",
    "month": "壬辰",
    "day": "壬戌",
    "hour": "乙巳"
  },
  "ju": {                                  // 局信息
    "type": "阳遁",                         // 阳遁/阴遁
    "number": 7,                           // 局数 1-9
    "yuan": "下元"                          // 上元/中元/下元
  },
  "birth_year_stem": "癸",                 // 出生年天干（从 qmen_birth.json 读取）

  "yuegling": {                            // 月令分析
    "branch": "辰",                         // 月支
    "wuxing": "土",                         // 月令五行
    "palaces": [                           // 月令对各宫的关系（8宫，不含中5宫）
      {
        "palace": 1,                       // 宫号
        "wuxing": "水",                     // 宫五行
        "relation": "ke_target",           // 月令与宫的五行关系
        "star": "天柱",                     // 该宫九星
        "gate": "杜门",                     // 该宫八门
        "deity": "螣蛇"                    // 该宫八神
      }
      // ... 共 8 项
    ]
  },

  "caifu_yaohai": [                        // 财富七要害
    {
      "name": "戊",                         // 要害名称
      "type": "stem",                      // 类型: stem/gate/deity/special
      "desc": "本钱",                       // 中文描述
      "palace": 7,                         // 所在宫号
      "palace_info": {                     // 宫位详情
        "name": "兑7宫",
        "wuxing": "金",
        "direction": "西",
        "star": "天英",
        "gate": "生门",
        "deity": "九天",
        "tian_gan": "庚",                  // 天盘天干
        "di_gan": "戊",                    // 地盘天干
        "state": "帝旺",                   // 十二长生状态
        "liuhai": "庚",                    // 六害标记（逗号分隔）
        "liuhai_count": 1                  // 六害数量
      },
      "liuhai": "庚",                      // 六害（同 palace_info 中的）
      "liuhai_count": 1,
      "yuegling_relation": "sheng_target", // 月令关系英文标识
      "yuegling_relation_cn": "损耗量小"   // 月令关系中文含义
    }
    // ... 共 7 项: 戊(本钱), 生门(利润), 六合(合作), 月令, 行业, 时干, 干财
  ],

  "shiye_yaohai": [                        // 事业七要害（结构同 caifu_yaohai）
    {
      "name": "开门",
      "type": "gate",
      "desc": "所在公司或单位",
      "palace": 9,
      "palace_info": { /* ... */ },
      "liuhai": "",
      "liuhai_count": 0,
      "yuegling_relation": "bei_ke",
      "yuegling_relation_cn": "努力可成"
    }
    // ... 共 7 项: 开门(公司), 景门(形象), 玄武(小人), 庚(压力), 行业, 符使, 诸天干
  ],

  "gan_cai": {                             // 干财分析
    "ri_gan": "壬",                         // 日干
    "ri_gan_cai": "丙,丁",                  // 日干所克（日干财）
    "nian_gan": "癸",                       // 生年干
    "nian_gan_cai": "丙,丁",                // 生年干所克（生年财）
    "stems": [                             // 干财天干在局中的状态
      {
        "stem": "丙",                       // 干财天干
        "is_ri_gan_cai": true,             // 是否为日干财
        "is_nian_gan_cai": true,           // 是否为生年财
        "palace": 5,                       // 所在宫号
        "palace_info": { /* ... */ },
        "liuhai": "",
        "liuhai_count": 0,
        "wuhe_alt": ""                     // 五合替代天干（找不到时用）
      }
      // ... 每个干财天干一项
    ]
  },

  "fushi": {                               // 符使分析
    "zhi_fu": {                            // 值符（话语权/上级）
      "star": "天芮",
      "palace": 6,
      "liuhai": "",
      "liuhai_count": 0
    },
    "zhi_shi": {                           // 值使（用武之地）
      "gate": "死门",
      "palace": 3,
      "liuhai": "空",
      "liuhai_count": 1
    }
  },

  "tiangan_roles": [                       // 天干角色（事业维度的人事关系）
    {
      "role": "年干",                       // 角色
      "desc": "大老板",                     // 中文描述
      "stem": "丙",                         // 天干
      "palace": 5,                         // 宫号
      "liuhai": "",
      "liuhai_count": 0
    }
    // ... 共 4 项: 年干(大老板), 月干(上级), 日干(自己), 时干(下属/客户)
  ],

  "hangye": {                              // 行业匹配（自动从盘面推算）
    "job": "西医",
    "symbols": ["天心"],                    // 匹配的奇门符号
    "palace": 8,
    "palace_info": { /* ... */ },
    "liuhai": "星墓,空",
    "liuhai_count": 2
  }
}
```

### 六害标记值

六害字段（`liuhai`）中可能出现以下标记，逗号分隔：

| 标记 | 含义 |
|------|------|
| `刑` | 六仪击刑 |
| `干墓` | 天干入墓 |
| `星墓` | 九星入墓 |
| `门墓` | 八门入墓 |
| `庚` | 天盘见庚 |
| `庚(对宫)` | 对宫有庚（间接影响） |
| `虎` | 白虎同宫 |
| `虎(对宫)` | 对宫有白虎（间接影响） |
| `玄武(对宫)` | 对宫有玄武（间接影响） |
| `迫` | 门迫 |
| `空` | 空亡 |

---

## Huaqizhen 化气阵布阵

**输出文件**: `qmen_huaqizhen.json`

```jsonc
{
  "datetime": "2026-04-18 10:00",
  "si_zhu": { /* 同 caiguan */ },
  "ju": { /* 同 caiguan */ },

  "protected_stems": [                     // 受保护的天干
    {
      "stem": "壬",                         // 天干
      "role": "日干",                       // 角色: 日干/时干/生年干/家人/意象/值符宫干/值使宫干
      "palace": 6,                         // 所在宫号
      "dangers": ""                        // 六害（逗号分隔，空=安全）
    },
    {
      "stem": "乙",
      "role": "时干",
      "palace": 8,
      "dangers": "入墓,空亡"
    }
    // ... 所有受保护天干
  ],

  "miexiang": [                            // 灭象清单
    {
      "palace": 2,                         // 宫号
      "name": "坤2宫",                      // 宫名
      "direction": "西南",                  // 方位
      "stem": "丁",                         // 需灭象的天干
      "reason": "入墓",                     // 灭象原因
      "method": "可移动,不可抛弃,不可赠送",  // 灭象方式
      "safe_to": "西(7宫),北(1宫)",         // 安全移动方位
      "xiang": {                           // 物象描述
        "color": "暗红",                    // 颜色
        "material": "尖锐",                // 材质
        "desc": "烛火刀剑"                  // 具体物品
      }
    }
    // ... 每个需灭象的宫位一项
  ],

  "buzhen": [                              // 布阵方案
    {
      "palace": 2,                         // 宫号
      "name": "坤2宫",
      "direction": "西南",
      "liuhai": "星墓",                    // 该宫六害
      "actions": [                         // 布阵动作
        {
          "type": "压入墓",                 // 压制类型: 压击刑/压入墓/压门迫/压庚白虎/填空亡
          "tiangan": [                     // 天干象（放高处）
            {
              "stem": "甲",
              "position": "高处",
              "xiang": {
                "color": "亮绿",
                "material": "硬木",
                "desc": "木雕硬木家具"
              }
            }
          ],
          "dizhi": [                       // 地支象（放低处）
            {
              "branch": "丑",
              "position": "低处",
              "xiang": {
                "color": "暗棕",
                "zodiac": "牛",
                "alt": "暗棕色陶罐"        // 替代物
              }
            }
          ],
          "move_away": []                  // 需移走的天干（灭象）
        }
      ],
      "jinji_conflicts": []               // 禁忌冲突（某干不能放此宫）
    }
    // ... 每个需要布阵的宫位一项
  ],

  "global_notes": {                        // 全局注意事项
    "position_tiangan": "高处",
    "position_dizhi": "低处",
    "position_note": "以人胸为界",
    "caution": "普通人不要选凶险的形象如龙虎蛇"
  }
}
```

---

## Yishenhuanjiang 移神换将化解

**输出文件**: `qmen_yishenhuanjiang.json`

移神换将化解脚本检测命盘中所有六害问题（击刑/干墓/门迫/空亡/庚金/白虎），为每个问题计算多条化解路径（灭象/暗合/地支合/泄化/冲墓/合出/补象/六合安抚），并映射出具体物象。击刑/干墓/庚金三类必须灭象先行。

```jsonc
{
  "type": "yishenhuanjiang",
  "datetime": "1973-04-24 19:30",             // 起局时间
  "sizhu": "癸丑 丙辰 庚寅 丙戌",             // 四柱
  "day_stem": "庚",                            // 日干
  "hour_stem": "丙",                           // 时干
  "year_stem": "癸",                           // 生年干
  "problem_count": 9,                          // 检测到的问题总数

  "problems": [                                // 问题列表（按宫分组排列）
    {
      "palace": 2,                             // 宫位编号
      "palace_name": "坤2宫",                  // 宫位名称
      "direction": "西南",                     // 方位
      "wuxing": "土",                          // 宫位五行
      "degree_start": 202.5,                   // 方位起始角度
      "degree_end": 247.5,                     // 方位结束角度
      "problem_type": "rumu",                  // 问题类型（见下方枚举）
      "problem_label": "干墓",                 // 问题中文标签
      "problem_detail": "乙",                  // 问题主体（天干/门/神名）
      "paths": [                               // 化解路径（有序，灭象在前）
        {
          "method": "灭象",                    // 化解方法名
          "target": "移走乙象",                // 操作目标
          "action": "从西南移至正西或正北",    // 具体动作
          "objects": "竹编,雕梁画柱,...",       // 对应物象（逗号分隔）
          "viable": true,                      // 是否可行
          "source": "bmhq L221"                // 来源标注
        },
        {
          "method": "冲墓",
          "target": "丑冲未",                  // 冲墓：用什么冲什么
          "objects": "帽子,腰带,...",
          "viable": true,
          "source": "参考文档"
        },
        {
          "method": "合出",
          "target": "午合未",                  // 合出：用什么合什么
          "objects": "电视机,音响,...",
          "viable": true,
          "source": "参考文档"
        },
        {
          "method": "避让",
          "target": "避开西南",
          "objects": "",                        // 避让无物象
          "viable": true,
          "source": "（推导）"
        }
      ]
    }
    // ... 同宫多个问题连续排列
  ],

  "jinji": [                                   // 禁忌列表（固定6条）
    "不可用克法直接对抗凶象",
    "不可同时激活多个凶象方位",
    "空亡方位不可放化解物（无气承载）",
    "入墓之物不可用合法（已被困合不动）",
    "只灭能灭的象，不能移动的不动",
    "移动后不要再碰"
  ],

  "yindong": [                                 // 引动方式（固定3种）
    {"name": "语言引动", "desc": "对化解物品说出意图，明确告知其用途"},
    {"name": "行为引动", "desc": "每日固定时间与化解物互动（擦拭/点燃/浇水）"},
    {"name": "择时引动", "desc": "选择天干有利时辰放置或激活"}
  ]
}
```

### problem_type 枚举

| 值 | 标签 | 含义 | 灭象 |
|---|---|---|---|
| `jixing` | 击刑 | 六仪击刑 | ✅ 必须 |
| `rumu` | 干墓 | 天干入墓 | ✅ 必须 |
| `geng` | 庚金 | 天盘见庚 | ✅ 必须 |
| `menpo` | 门迫 | 门克宫 | ❌ |
| `kongwang` | 空亡 | 天干落空亡 | ❌ |
| `baihu` | 白虎 | 八神白虎 | ❌ |

### paths 字段（按问题类型）

**击刑 (jixing)**:
- `灭象` → `暗合` → `地支合` → `泄化` → `避让`
- 暗合/地支合/泄化 含 `note` 和 `placement` 字段

**干墓 (rumu)**:
- `灭象` → `冲墓` → `合出` → `避让`

**庚金 (geng)**:
- `灭象` → `乙合庚` → `巳合申` → `泄化`
- 乙合庚/巳合申含 `desc`、`placement` 字段（high/low）
- 乙合庚/巳合申的 `objects` 前缀 `[优先]` 标记笔记推荐物品

**门迫 (menpo)**:
- `补生` → `泄克`

**空亡 (kongwang)**:
- `补象`（单一路径）

**白虎 (baihu)**:
- `六合安抚` → `泄化`

### path 对象字段说明

| 字段 | 类型 | 必有 | 说明 |
|------|------|------|------|
| `method` | string | ✅ | 化解方法名 |
| `target` | string | ✅ | 操作目标描述 |
| `action` | string | 灭象/击刑/庚 | 具体执行动作 |
| `desc` | string | 庚 | 方法补充描述 |
| `objects` | string | ✅ | 物象逗号分隔列表 |
| `viable` | boolean | ✅ | 是否可行（通常 true） |
| `source` | string | ✅ | 数据来源标注 |
| `note` | string | 击刑 | 推导说明 |
| `placement` | string | 庚/击刑 | 放置位置（high/low/空） |

---

## Hunlian 婚恋分析

**输出文件**: `qmen_hunlian.json`

```jsonc
{
  "datetime": "2026-04-18 10:00",
  "si_zhu": { /* 同 caiguan */ },

  "ri_gan": {                              // 日干（代表自己）
    "stem": "庚",
    "palace": 7,
    "name": "兑7宫",
    "direction": "西",
    "palace_info": {
      "tian_gan": "庚",
      "di_gan": "戊",
      "star": "天英",
      "gate": "生门",
      "deity": "九天",
      "state": "帝旺"
    },
    "wanwu": {                             // 万物类象（星/门/神/天干/地干）
      "star": { "吉凶": "", "颜色": "", "人物": "", "性格品质": "" },
      "gate": { "吉凶": "", "颜色": "", "人物": "", "性格品质": "" },
      "deity": { "吉凶": "", "颜色": "", "代表人物": "", "性格品质": "", "事件行为": "" },
      "tian_gan": { "方位": "", "颜色": "", "性格品质": "", "人物": "", "形态": "", "动物": "", "植物": "", "器物": "" },
      "di_gan": { "方位": "", "颜色": "", "性格品质": "", "人物": "", "形态": "", "动物": "", "植物": "", "器物": "" }
    }
  },

  "gan_he": {                              // 干合（代表伴侣，结构同 ri_gan）
    "stem": "乙",
    "palace": 8,
    "name": "艮8宫",
    "direction": "东北",
    "palace_info": { /* ... */ },
    "wanwu": { /* ... */ }
  },

  "liuhe": {                               // 六合（月老/人缘，结构同 ri_gan 但无 wanwu）
    "palace": 3,
    "name": "震3宫",
    "direction": "东",
    "palace_info": { /* ... */ },
    "wanwu": { /* ... */ }
  },

  "muyu": {                                // 沐浴位（桃花位）
    "dizhi": "午",                          // 沐浴地支
    "palace": 9,                           // 沐浴所在宫
    "name": "离9宫",
    "direction": "南",
    "palace_info": { /* ... */ }
  },

  "sanqi": {                               // 三奇位置
    "乙": {
      "palace": 8,
      "name": "艮8宫",
      "direction": "东北",
      "palace_info": { /* ... */ },
      "with_ri_gan": false,                // 是否与日干同宫
      "with_gan_he": true                  // 是否与干合同宫
    },
    "丙": { /* 同上结构 */ },
    "丁": { /* 同上结构 */ }
  },

  "taohua": {                              // 桃花检测
    "ri_gan_sanqi": [],                    // 与日干同宫的三奇
    "gan_he_sanqi": ["乙"],                // 与干合同宫的三奇
    "xuanwu_with_ri_gan": false,           // 玄武是否与日干同宫
    "xuanwu_with_gan_he": false,           // 玄武是否与干合同宫
    "taiyin_with_ri_gan": false,           // 太阴是否与日干同宫
    "taiyin_with_gan_he": true,            // 太阴是否与干合同宫
    "ri_gan_at_muyu": false,               // 日干是否在沐浴位
    "gan_he_at_muyu": false,               // 干合是否在沐浴位
    "rengui_with_ri_gan": false,           // 壬癸是否与日干同宫
    "rengui_with_gan_he": false            // 壬癸是否与干合同宫
  },

  "fuyin_fanyin": {                        // 伏吟反吟
    "fuyin_palaces": "",                   // 伏吟宫号（逗号分隔）
    "fanyin_palaces": "",                  // 反吟宫号（逗号分隔）
    "is_fuyin_ju": false,                  // 是否伏吟局
    "is_fanyin_ju": false                  // 是否反吟局
  },

  "kongwang": {                            // 空亡
    "palace_1": 8,                         // 空亡宫1
    "palace_2": 3,                         // 空亡宫2
    "ri_gan_kw": false,                    // 日干是否空亡
    "gan_he_kw": true,                     // 干合是否空亡
    "liuhe_kw": true                       // 六合是否空亡
  },

  "gen_kun": {                             // 艮坤（家庭根基）
    "gen8": {                              // 艮8宫（东北）
      "liuhai": "星墓,空",                 // 六害
      "liuhai_array": ["星墓", "空"],
      "liuhai_count": 2,
      "has_geng": false,                   // 是否有庚
      "has_baihu": false                   // 是否有白虎
    },
    "kun2": {                              // 坤2宫（西南）
      "liuhai": "星墓",
      "liuhai_array": ["星墓"],
      "liuhai_count": 1,
      "has_geng": false,
      "has_baihu": false
    }
  },

  "guchen_guasu": {                        // 孤辰寡宿
    "group": "亥子丑",                      // 所属地支组
    "guchen": "寅",                         // 孤辰地支
    "guasu": "戌",                          // 寡宿地支
    "jiehua": {                            // 化解方案
      "dizhi_1": "亥",                     // 化解地支1
      "dizhi_2": "卯",                     // 化解地支2
      "shengxiao_1": "猪",                 // 化解生肖1
      "shengxiao_2": "兔"                  // 化解生肖2
    }
  },

  "special_positions": {                   // 特殊位置（情趣模块）
    "tianpeng": {                          // 天蓬（性魅力）
      "palace": 3,
      "name": "震3宫",
      "direction": "东",
      "palace_info": { /* ... */ }
    },
    "shangmen": {                          // 伤门（短期刺激）
      "palace": 6,
      "name": "乾6宫",
      "direction": "西北",
      "palace_info": { /* ... */ }
    },
    "ding": {                              // 丁奇（男性情趣）
      "palace": 2,
      "name": "坤2宫",
      "direction": "西南",
      "palace_info": { /* ... */ }
    },
    "gui": {                               // 癸水（女性情趣）
      "palace": 9,
      "name": "离9宫",
      "direction": "南",
      "palace_info": { /* ... */ }
    }
  }
}
```

---

## Xingge 性格分析

**输出文件**: `qmen_xingge.json`

```jsonc
{
  "type": "xingge",                        // 类型标识

  "birth_info": {                          // 出生信息
    "datetime": "1955-02-24 19:15",
    "sizhu": "乙未 戊寅 丙辰 戊戌"
  },

  "inner": {                               // 内在性格（日干）
    "stem": "丙",                           // 日干
    "stem_wuxing": "火",                    // 日干五行
    "wuxing_color": "红",                   // 五行颜色
    "palace": 7,                           // 日干所在宫号
    "palace_name": "兑",                    // 宫名
    "palace_wuxing": "金",                  // 宫五行
    "star": "天辅",                         // 该宫九星
    "gate": "开门",                         // 该宫八门
    "deity": "九天",                        // 该宫八神
    "stem_xingge": "放射，表现，热烈...",   // 天干性格描述
    "star_xingge": "师相，辅佐，指导...",   // 九星性格描述
    "gate_xingge": "开阔，开拓，开创...",   // 八门性格描述
    "deity_xingge": "高远，远，飞，变..."   // 八神性格描述
  },

  "outer": {                               // 外在性格（时干，结构同 inner）
    "stem": "戊",
    "stem_wuxing": "土",
    "wuxing_color": "棕",
    "palace": 3,
    "palace_name": "震",
    "palace_wuxing": "木",
    "star": "天心",
    "gate": "杜门",
    "deity": "六合",
    "stem_xingge": "收容，积聚，钱...",
    "star_xingge": "君王，中心，领导...",
    "gate_xingge": "阻塞，阻隔，限制...",
    "deity_xingge": "人缘，合，媒，多..."
  }
}
```

---

## Yaoce 遥测分析

**输出文件**: `qmen_yaoce.json`

```jsonc
{
  "type": "yaoce",                             // 类型标识
  "birth_datetime": "1973-04-24 19:30",        // 生日局时间
  "event_datetime": "2026-04-18 10:00",        // 问事局时间
  "birth_day_stem": "庚",                      // 生日日干
  "birth_hour_stem": "丙",                     // 生日时干
  "birth_year_stem": "癸",                     // 生年干
  "zhifu_stem": "庚",                          // 生日局值符宫天盘天干
  "zhishi_stem": "癸",                         // 生日局值使宫天盘天干

  "stems": [                                   // 各保护天干在问事局中的落宫分析
    {
      "stem": "庚",                             // 天干
      "role": "日干",                           // 角色: 日干/时干/生年干/值符宫干/值使宫干/意象干
      "tian_palace": 7,                        // 该干在问事局天盘所在宫（0=未找到）
      "di_palace": 9,                          // 该干在问事局地盘所在宫（0=未找到）
      "analysis_palace": 7,                    // 实际分析宫（天盘优先，无则用地盘）
      "palace_name": "兑7宫",                   // 分析宫名
      "palace_wuxing": "金",                    // 分析宫五行
      "direction": "西",                        // 分析宫方位
      "tian_gan": "庚",                         // 该宫天盘天干
      "di_gan": "戊",                           // 该宫地盘天干
      "star": "天英",                           // 该宫九星
      "gate": "生门",                           // 该宫八门
      "deity": "九天",                          // 该宫八神
      "state": "帝旺",                          // 该宫十二长生状态
      "markers": "",                           // 格局标记（逗号分隔字符串）
      "liuhai": "庚",                           // 六害标记（逗号分隔）
      "liuhai_count": 1,                       // 六害数量
      "wanwu": {                               // 万物类象（扁平 key-value，前缀分组）
        "tian_gan_五行阴阳": "阳金",
        "tian_gan_方位": "西",
        "tian_gan_颜色": "亮白,亮黄,白,粉,银白",
        "tian_gan_概念": "暴力,阻碍...",
        "tian_gan_身体脏腑": "头骨,大骨骼...",
        "tian_gan_性格品质": "果决,义薄云天...",
        "tian_gan_人物": "军警,黑社会...",
        "tian_gan_形态": "棱角,硬,大",
        "tian_gan_地理": "道路,关卡...",
        "tian_gan_动物": "老虎,狼...",
        "tian_gan_植物": "橡树,核桃树...",
        "tian_gan_器物": "石头,刀枪...",
        "di_gan_五行阴阳": "阳土",
        "di_gan_方位": "中央（寄坤宫）...",
        "di_gan_颜色": "棕黄,黄...",
        "di_gan_概念": "财富,中正...",
        // ... di_gan_* 同上模式
        "star_五行": "火",
        "star_吉凶": "小凶(中平偏凶)",
        "star_核心描述": "中平小凶,冲动之人...",
        "star_颜色": "红,紫,橙",
        "star_人物": "文人,画家...",
        "star_性格品质": "外表华丽,好面子...",
        "star_场所环境": "窑炉,厨房...",
        "star_身体": "心,眼,小肠,血脉",
        "star_疾病": "心脏病,眼疾...",
        "star_事业行为": "文艺表演,绘画...",
        "star_占断适宜": "文化活动,庆典...",
        "star_占断不宜": "求财,出行...",
        "gate_五行": "土",
        "gate_吉凶": "大吉(三吉门之一)",
        "gate_核心描述": "东北方,艮土宫...",
        // ... gate_* 同上模式
        "deity_五行": "金(乾金)",
        "deity_吉凶": "吉",
        "deity_核心描述": "乾金之卦..."
        // ... deity_* 同上模式
      }
    }
    // ... 共 5 项（日干/时干/生年干/值符宫干/值使宫干）
    //     有 --yixiang 时增加第 6 项（意象干）
    //     注意：同一天干可能因不同 role 重复出现（如日干=值符宫干）
  ]
}
```

### 字段说明

- `tian_palace` / `di_palace`：天干在问事局天盘/地盘的位置，`0` 表示未找到
- `analysis_palace`：天盘优先；天盘找不到则用地盘；都找不到则为 `0`
- `markers`：逗号分隔字符串（非数组），对应排盘时的格局标记
- `wanwu`：扁平 key-value 结构，key 格式为 `{前缀}_{字段名}`
  - 前缀：`tian_gan`（天盘天干）, `di_gan`（地盘天干）, `star`（九星）, `gate`（八门）, `deity`（八神）
  - 具体字段取决于对应 `wanwu_*.dat` 文件中的定义
- 同一天干因不同角色可能重复出现（如庚同时是日干和值符宫干），宫位信息完全相同但 `role` 不同

---

## Wanwu 万物类象提取

**输出文件**: `qmen_wanwu.json`

支持两种模式：手动模式（指定符号）和宫位模式（从盘中读取）。

### 手动模式

```jsonc
{
  "mode": "manual",                            // 模式标识
  "symbols": {                                 // 输入的符号（仅包含实际指定的）
    "stem": "丙",                              // 天干（可选）
    "star": "天冲",                            // 九星（可选）
    "gate": "伤门",                            // 八门（可选）
    "deity": "九天",                           // 八神（可选）
    "state": "帝旺"                            // 十二长生（可选）
  },
  "wanwu": {                                   // 万物类象（每个符号一个对象）
    "stem": {                                  // 天干万物类象
      "symbol": "丙",                          // 符号名
      "五行阴阳": "阳火",
      "方位": "南",
      "季节": "夏",
      "时段": "中午",
      "颜色": "大红,亮红,紫,红,赤",
      "数字": "3,7",
      "形态": "大,圆,片状",
      "概念": "表现,希望,光明...",
      "身体脏腑": "心脏,小肠...",
      "性格品质": "光明磊落,慷慨...",
      "体形": "体型丰满,圆脸...",
      "得令失令": "得令时成绩辉煌...",
      "天象": "太阳,晴朗...",
      "地理": "厨房,高岭...",
      "人物": "情人,当权者...",
      "动物": "马,牛,猪...",
      "植物": "带柄果实,梨子...",
      "器物": "光亮之物,灯,灶...",
      "食物": "烧烤,热食...",
      "感觉": "热,烫,痒",
      "味道": "苦辣,苦"
    },
    "gate": {                                  // 八门万物类象
      "symbol": "伤门",
      "五行": "木",
      "吉凶": "凶(可为用)",
      "默认宫位": "三宫震",
      "核心描述": "东方,震木宫...",
      "类象": "地面交通工具,刑警...",
      "旺衰": "旺于春木,相于冬水...",
      "概念": "受伤,伤心...",
      "颜色": "青色,绿色,碧绿",
      "身体": "肝,胆,手足,筋骨",
      "疾病": "跌打外伤,骨折...",
      "人物": "伤者,猎人,军警...",
      "工作": "公安,军警...",
      "形态": "威严,恐惧...",
      "性格品质": "急躁,好动...",
      "场所环境": "道路,车站...",
      "事业行为": "追债讨账,竞争...",
      "占断适宜": "追债,讨账...",
      "占断不宜": "嫁娶,安葬...",
      "方位": "东方",
      "天时": "春天,早晨...",
      "常见组合": "伤门+天冲快速行动..."
    }
    // star, deity, state 同理（如果指定了）
  }
}
```

### 宫位模式

```jsonc
{
  "mode": "palace",                            // 模式标识
  "palace": 3,                                 // 宫号
  "palace_name": "震3宫",                       // 宫名
  "input": "./qmen_birth.json",                // 输入盘路径
  "symbols": {                                 // 从盘中读取的符号
    "stem": "癸",                              // 天盘天干
    "star": "天辅",                            // 九星
    "gate": "休门",                            // 八门
    "deity": "六合",                           // 八神
    "state": "长生"                            // 十二长生
  },
  "wanwu": {                                   // 结构同手动模式
    "stem": { /* ... */ },
    "star": { /* ... */ },
    "gate": { /* ... */ },
    "deity": { /* ... */ },
    "state": { /* ... */ }
  }
}
```

### 字段说明

- 每个 wanwu 子对象的具体字段完全取决于对应 `wanwu_*.dat` 数据文件
- 天干字段来自 `wanwu_tiangan.dat`，九星来自 `wanwu_nine_stars.dat`，八门来自 `wanwu_eight_gates.dat`，八神来自 `wanwu_eight_deities.dat`
- `state`（十二长生）来自 `twelve_states.dat`，字段较少（仅含基本描述）
- 手动模式 `symbols` 对象只包含实际传入的参数（未指定的不出现）
- 宫位模式 `symbols` 总是包含 5 个字段（stem/star/gate/deity/state）

---

## 通用子结构

### palace_info

宫位详情对象，在多个输出中复用：

```jsonc
{
  "tian_gan": "庚",      // 天盘天干
  "di_gan": "戊",        // 地盘天干
  "star": "天英",        // 九星
  "gate": "生门",        // 八门
  "deity": "九天",       // 八神
  "state": "帝旺"        // 十二长生状态
}
```

caiguan 的 palace_info 额外包含：
```jsonc
{
  "name": "兑7宫",       // 宫名
  "wuxing": "金",        // 宫五行
  "direction": "西",     // 方位
  "liuhai": "庚",        // 六害标记
  "liuhai_count": 1      // 六害数量
}
```

### wanwu (万物类象)

hunlian 输出中各位置的万物类象对象：

```jsonc
{
  "star": { "吉凶": "", "颜色": "", "人物": "", "性格品质": "" },
  "gate": { "吉凶": "", "颜色": "", "人物": "", "性格品质": "" },
  "deity": { "吉凶": "", "颜色": "", "代表人物": "", "性格品质": "", "事件行为": "" },
  "tian_gan": { "方位": "", "颜色": "", "性格品质": "", "人物": "", "形态": "", "动物": "", "植物": "", "器物": "" },
  "di_gan": { "方位": "", "颜色": "", "性格品质": "", "人物": "", "形态": "", "动物": "", "植物": "", "器物": "" }
}
```

注意：具体包含哪些字段取决于数据文件中的定义，上述为常见字段。
