---
name: qmen_zhanduan
description: "古籍占断 divination judgment: evaluate DSL rules from《奇门旨归》against event plate, AI explains in plain language"
---

# 奇门遁甲古籍占断

> 基于《奇门旨归》卷六至卷十三，脚本机械化评估判断规则并输出结论，AI 用白话解释结论含义。

## Trigger

用户**明确**要求占断时激活：
- 占断、占卜、占事、断卦、占问
- 具体主题名：婚姻、官司、求财、行人归期、投军...
- "帮我断一下"、"看看这个事情"、"问事"

**不激活**：
- 只说"奇门遁甲"未明确方向 → `qmen_dunjia` 路由
- 财官诊断 → `qmen_caiguan`
- 婚恋分析 → `qmen_hunlian`
- 布阵化解 → `qmen_huaqizhen`
- 性格分析 → `qmen_xingge`
- 意图模糊 → `qmen_dunjia` 路由

---

## 前置条件

- 问事局 JSON 必须已存在（`./qmen_event.json`）
- 命盘 JSON（`./qmen_birth.json`）可选，存在则自动读取年命天干
- 如不存在问事局，引导用户先通过 `qmen_dunjia` 路由起局

---

## Step 1: 确定占断主题

**用户已指定主题** → 直接使用，跳到 Step 2

**用户未指定** → 执行 `bin/qimen_zhanduan.sh`（无参数显示主题列表），问用户要断什么事

---

## Step 2: 执行占断

```bash
bin/qimen_zhanduan.sh --topic=<主题>
```

将完整 stdout 放在代码块中呈现。

---

## Step 3: 白话解释

对脚本输出的每条结论，用现代白话解释：
- 说明判断依据（哪个角色在哪个位置，什么状态触发了这条结论）
- 把古文结论翻译成日常用语
- 综合多条结论给出整体判断方向

**规则：**
- 解释必须基于脚本实际输出，不凭空编造
- 解释不等于建议 — 说明"情况如何"，不说"你应该怎么做"
- 如用户追问"该怎么办"，可基于结论方向给出参考，但注明是 AI 理解非古籍原文

---

## Step 4: 后续

用户可以：
- 换个主题继续断（重复 Step 1-2-3）
- 追问某条结论的细节
- 结束

---

## 技术参考

- 理论依据：《奇门旨归》朱浩文星源述，卷六至卷十三
- JSON 输出：自动写入 `./qmen_zhanduan.json`
