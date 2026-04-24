# 数据结构设计文档

本文档描述各脚本 JSON 输出的完整数据结构。所有脚本默认读取 `./qmen_birth.json`（命盘），可通过 `--input` 指定事件盘。

---

## 目录

- [Caiguan 财官诊断](#caiguan-财官诊断)
- [Huaqizhen 化气阵布阵](#huaqizhen-化气阵布阵)
- [Hunlian 婚恋分析](#hunlian-婚恋分析)
- [Xingge 性格分析](#xingge-性格分析)

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
      "jinbi_conflicts": []               // 禁忌冲突（某干不能放此宫）
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
