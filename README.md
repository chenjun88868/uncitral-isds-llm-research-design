# 基于 LLM 的 UNCITRAL ISDS 改革谈判“隐形联盟”研究设计

## 一、研究目标

### 1.1 核心研究问题

本文拟回答以下问题：

> 在 UNCITRAL ISDS 改革谈判中，各国是否形成了稳定的谈判联盟？这些联盟究竟是按发展水平、地区、法律传统形成，还是按具体议题临时形成？

更通俗地说，就是：

> 哪些国家在 ISDS 改革谈判中经常站在一起？它们为什么站在一起？

### 1.2 研究策略总览

本研究不把 LLM 当作“自动写论文机器”，而是把它当作“高速研究助理”。整个流程是：

```text
UNCITRAL 逐字稿 / 会议材料
→ 文本清洗
→ 按“国家的一次发言”切分
→ LLM 辅助识别议题
→ LLM 辅助判断立场
→ 人工黄金样本验证
→ 人工复核低置信度样本
→ 建立国家—议题立场数据库
→ 构建国家相似度网络
→ 进行社区发现与联盟解释
```

---

## 二、LLM 在研究中的角色

### 2.1 LLM 可以做什么

- 把逐字稿按“谁发言、说了什么”切开。
- 识别每段发言涉及哪个议题。
- 判断一个国家对某个议题的态度。
- 总结该国家为什么这样说。
- 抽取关键词、法律概念、政策理由。
- 帮助检查标注是否前后一致。
- 协助生成代码、表格和图表说明。
- 协助撰写方法部分初稿。

### 2.2 LLM 不应该单独做什么

- 不经人工检查就直接决定所有立场。
- 直接替研究者给出最终研究发现。
- 直接判断因果关系。
- 在没有证据时说“某国属于某联盟”。
- 把模糊发言强行分类成支持或反对。

### 2.3 最科学的原则

> LLM 可以做大规模“初判”，但必须用人工样本、统一规则和统计检验来证明它的判断可靠。

---

## 三、研究对象与分析单位

### 3.1 研究对象

研究材料主要包括：

- UNCITRAL Working Group III 会议报告
- session transcripts
- country statements
- working papers
- submitted proposals
- meeting summaries

### 3.2 分析单位

本研究的最小分析单位为：

> 一个国家的一次发言

而不是整场会议，也不是一个国家全部发言的总和。

建议整理后的基础数据表如下：

| speech_id | session_id | date | speaker | speaker_type | speech_text | source_file | page_or_paragraph |
|---|---|---|---|---|---|---|---|
| 0001 | Session 38 | 2020-01-20 | China | State | ... | A_CN9_970.pdf | p.12 |
| 0002 | Session 38 | 2020-01-20 | EU | Group | ... | A_CN9_970.pdf | p.13 |
| 0003 | Session 38 | 2020-01-20 | Canada | State | ... | A_CN9_970.pdf | p.14 |

---

## 四、议题范围选择

第一版研究不宜一次覆盖全部议题，建议先聚焦 6 个核心议题：

1. 常设机制 / `standing mechanism`
2. 上诉机制 / `appeal mechanism`
3. 仲裁员行为准则 / `code of conduct`
4. 第三方资助 / `third-party funding`
5. 费用控制 / `costs and fees`
6. 透明度与保密 / `transparency and confidentiality`

选择这些议题的理由是：

- 它们处于 ISDS 改革争论的核心位置。
- 各国立场差异可能较明显。
- LLM 相对容易从文本中识别这些主题。
- 它们能同时覆盖制度性议题和技术性议题。

---

## 五、数据整理方案

### 5.1 原始材料的文件组织

建议建立如下目录：

```text
data_raw/
  session_34/
  session_35/
  session_36/
  ...
```

每场会议至少记录以下元数据：

- `session_id`
- `date`
- `source_file`
- `source_url`
- `meeting_topic`
- `document_number`

### 5.2 文本清洗步骤

1. 将 PDF、Word、HTML 统一转换为纯文本。
2. 删除页眉、页脚、重复页码等无关内容。
3. 按“发言者：发言内容”切分。
4. 区分 Chair、Secretariat、国家代表、观察员、区域组织。
5. 为每条发言添加来源信息和段落定位。

### 5.3 该阶段的产出文件

建议产出：

- `data_processed/speeches_clean.csv`

该表至少包含：

- `speech_id`
- `session_id`
- `date`
- `speaker`
- `speaker_type`
- `speech_text`
- `source_file`
- `page_or_paragraph`

---

## 六、建立标注规则书（Codebook）

Codebook 是本研究最关键的科学控制工具。它要同时约束人类标注者和 LLM。

### 6.1 立场标签设计

建议使用以下 6 类 `stance`：

| 中文标签 | 英文标签 | 含义 |
|---|---|---|
| 支持 | `support` | 明确赞成某议题或方案 |
| 反对 | `oppose` | 明确不同意某议题或方案 |
| 有条件支持 | `conditional_support` | 原则上支持，但附带条件 |
| 担忧 | `concern` | 未明确反对，但强调风险、成本或问题 |
| 提问/澄清 | `question` | 主要是要求解释或澄清 |
| 不明确 | `unclear` | 无法可靠判断 |

### 6.2 各标签的操作定义

#### `support`

满足以下任一情况即可标为 `support`：

- 明确欢迎某方案；
- 明确赞成推进某机制；
- 明确认为某改革必要；
- 明确支持某项提案。

例：

> We support the establishment of an appellate mechanism.

#### `oppose`

满足以下任一情况即可标为 `oppose`：

- 明确不同意某方案；
- 明确表示没有必要；
- 主张不应继续推进；
- 明确主张保留现有安排。

例：

> We do not see the need for a standing mechanism.

#### `conditional_support`

在原则上支持，但同时提出限制条件时使用。

例：

> We could support an appellate mechanism, provided that costs are controlled.

#### `concern`

不直接反对，但突出担心、风险或负担时使用。

例：

> We are concerned that a standing mechanism may create additional financial burdens.

#### `question`

仅要求解释、说明或澄清，而没有清楚表态时使用。

例：

> Could the Secretariat clarify how appointments would be made?

#### `unclear`

人和 LLM 都无法可靠判断时使用。

> 在科学研究中，承认“不知道”比错误自信更可靠。

### 6.3 其他标注字段

建议同时标注以下变量：

- `issue`
- `stance`
- `target_proposal`
- `reasoning_frame`
- `evidence_quote`
- `confidence`

其中 `reasoning_frame` 可选分类包括：

- cost
- legitimacy
- efficiency
- consistency
- sovereignty
- transparency
- flexibility
- institutional feasibility
- access to justice
- other

---

## 七、人工黄金样本设计

### 7.1 为什么必须先做人类样本

在正式使用 LLM 前，必须先建立人工“黄金样本”，它相当于标准答案。

建议流程：

1. 从全部发言中随机抽取 100–200 条。
2. 由研究者本人独立标注一遍。
3. 如有条件，再由第二位标注者独立标注。
4. 两人标完后比较差异。
5. 根据争议点修订 codebook。

建议文件名：

- `annotation/gold_sample.csv`

### 7.2 人工一致性检验

若有两位标注者，建议计算：

- Cohen’s Kappa
- Krippendorff’s Alpha
- Percent Agreement

粗略解释标准：

| 一致性水平 | 解释 |
|---|---|
| 0.80 以上 | 很好 |
| 0.60–0.80 | 可以接受 |
| 0.40–0.60 | 需要修改规则 |
| 0.40 以下 | 规则不可靠 |

如果一致性不足，应先修改 codebook，再进入 LLM 阶段。

---

## 八、LLM 标注方案

### 8.1 Prompt 设计原则

Prompt 必须明确规定：

1. 研究背景；
2. 可选议题列表；
3. `stance` 标签定义；
4. 输出格式；
5. 不确定时必须标 `unclear`；
6. 不允许编造文本中没有的信息；
7. 必须提供原文证据；
8. 只输出结构化 JSON。

### 8.2 建议 Prompt 模板

```text
You are assisting a political/legal research project on UNCITRAL Working Group III ISDS reform negotiations.

Your task is to classify one speech by one speaker.

Allowed issues:
1. standing mechanism
2. appeal mechanism
3. code of conduct
4. third-party funding
5. costs and fees
6. transparency and confidentiality
7. appointment of adjudicators
8. other
9. none

Allowed stances:
- support
- oppose
- conditional_support
- concern
- question
- unclear

Rules:
- Use only information explicitly present in the speech.
- Do not infer a country’s position from outside knowledge.
- If the speech is vague, choose unclear.
- A speech may involve more than one issue.
- For each issue, provide a short evidence quote from the speech.
- Return valid JSON only.

Speech:
{speech_text}

Return:
{
  "speaker": "",
  "issues": [
    {
      "issue": "",
      "stance": "",
      "target_proposal": "",
      "reasoning_frame": "",
      "evidence_quote": "",
      "confidence": 0.0
    }
  ]
}
```

### 8.3 正式标注前的验证

在全量标注前，应先用 LLM 标注黄金样本，再与人工结果对比，评估：

- 议题识别准确率；
- 立场判断准确率；
- 各标签的 precision、recall、F1；
- 是否存在系统性偏误。

---

## 九、LLM 误差分析与迭代

建议重点检查以下常见错误：

- 把外交辞令误判为 `support`；
- 把 `concern` 误判为 `oppose`；
- 把 `question` 误判为 `concern`；
- 没识别出一段发言中的多个议题；
- 把主席或秘书处发言误当成国家立场；
- 把区域组织发言误当成成员国立场；
- 利用外部常识推断，而不是根据文本判断。

建议在 Prompt 中加入限制性说明，例如：

> Expressions such as "further work is needed", "we seek clarification", or "we have concerns" should not be coded as oppose unless the speaker explicitly rejects the proposal.

Prompt 优化一般进行 2–3 轮即可，避免对黄金样本过拟合。

---

## 十、全量标注与人工复核

### 10.1 全量标注结果表

建议生成：

- `annotation/llm_annotations_raw.csv`

字段建议如下：

| speech_id | session_id | date | speaker | issue | stance | target_proposal | reasoning_frame | evidence_quote | confidence |
|---|---|---|---|---|---|---|---|---|---|

由于一条发言可能涉及多个议题，因此一个 `speech_id` 可以对应多行。

### 10.2 人工复核规则

建议采用如下复核阈值：

- `confidence ≥ 0.80`：暂时接受；
- `0.60–0.80`：抽样检查；
- `< 0.60`：人工逐条复查；
- `stance = unclear`：抽查并记录原因；
- 涉及核心国家的样本：重点复查。

核心国家可优先包括：

- China
- United States
- European Union
- India
- Brazil
- South Africa

复核后的正式数据集可命名为：

- `annotation/llm_annotations_reviewed.csv`

---

## 十一、从发言级数据到国家—议题数据库

### 11.1 汇总逻辑

网络分析最终需要的是：

> 国家 A 与国家 B 在某议题上的立场是否相似

因此必须把发言级数据汇总为国家—议题级数据。

建议形成：

- `data_final/country_issue_stance.csv`

示意如下：

| country | issue | support_count | oppose_count | conditional_support_count | concern_count | question_count | unclear_count | dominant_stance |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| Canada | appeal mechanism | 8 | 0 | 1 | 2 | 0 | 0 | support |
| Brazil | appeal mechanism | 2 | 1 | 0 | 5 | 0 | 1 | concern |
| India | standing mechanism | 0 | 5 | 0 | 3 | 0 | 0 | oppose |

### 11.2 `dominant_stance` 规则

建议提前固定判定规则，例如：

- 如果某国在某议题上超过 60% 的相关发言属于同一标签，则记为该议题的 `dominant_stance`；
- 若无任何标签超过 60%，则记为 `mixed`；
- 若存在明显前后变化，可额外标记为 `shifted`。

---

## 十二、构建国家联盟网络

### 12.1 国家相似度定义

最简单也最透明的定义为：

> 如果两个国家在同一议题上的 `dominant_stance` 相同，则记为一次立场相似。

边权重可定义为：

> 两国在所有核心议题中立场相同的次数

### 12.2 两类网络构造

#### 严格网络

只有完全相同标签才算相似：

- `support = support`
- `oppose = oppose`
- `concern = concern`
- `conditional_support = conditional_support`

#### 宽松网络

允许相近标签视为接近：

- `support` 与 `conditional_support` 视为接近；
- `oppose` 与 `concern` 视为接近；
- `question` 与 `unclear` 不计入相似度。

两套结果若大致相似，说明结论更稳健。

### 12.3 网络输出

建议生成：

- `network/country_edges_strict.csv`
- `network/country_edges_relaxed.csv`
- `network/network_metrics.csv`

---

## 十三、联盟识别与解释

### 13.1 社区发现

建议使用以下算法之一：

- Louvain
- Leiden

目的不是预设谁和谁是一派，而是让算法根据“谁经常立场相同”自动分组。

### 13.2 可视化方案

网络图建议设置如下：

- 点：国家
- 点大小：发言次数或中心性
- 线粗细：立场相似次数
- 颜色：社区发现结果
- 形状：发达国家 / 发展中国家 / 区域组织

建议至少绘制以下图：

1. 全部议题联盟图
2. 上诉机制联盟图
3. 常设机制联盟图
4. 费用与透明度联盟图

### 13.3 解释变量

为解释联盟形成原因，可加入以下国家属性：

- 发展水平
- 地区
- 法律传统
- 是否资本输出国
- ISDS 被诉经验
- BIT 签署活跃程度
- 是否 EU 成员

由此可检验：

- 联盟是否按发展水平形成；
- 是否按地区形成；
- 是否按法律传统形成；
- 是否按 ISDS 经验形成；
- 还是按议题临时组合。

---

## 十四、方向二：议题外溢（升级版）

如果方向一顺利完成，可以进一步扩展为“议题外溢”研究。

### 14.1 多层网络思路

将每个议题视为一层网络：

- Layer 1：code of conduct
- Layer 2：third-party funding
- Layer 3：costs and fees
- Layer 4：appeal mechanism
- Layer 5：standing mechanism
- Layer 6：transparency and confidentiality

然后检验：

> 在议题 A 上结盟的国家，是否更可能在之后的议题 B 上继续结盟？

### 14.2 可检验的问题

- 哪些议题层的网络最相似？
- 技术性议题上的合作是否外溢到制度性议题？
- 早期联盟是否能预测后期联盟？

该部分可作为第二阶段研究，或写成后续论文。

---

## 十五、LLM 使用的可重复性要求

为了保证研究可复查、可复制，建议记录：

- `model_name`
- `prompt_version`
- `date`
- `temperature`
- `input_file`
- `output_file`
- `human_review_status`

并尽量固定：

- 同一模型；
- 低 `temperature`；
- 相同 Prompt；
- 相同 JSON 输出结构。

同时，每条标注结果都应保留 `evidence_quote`，用于后续追溯。

---

## 十六、建议的项目目录结构

```text
uncitral-isds-llm-research-design/
  README.md
  data_raw/
  data_processed/
  annotation/
  data_final/
  network/
  outputs/
  prompts/
    prompt_v1.txt
    prompt_v2.txt
    prompt_final.txt
  docs/
    codebook_v1.md
    codebook_v2.md
```

---

## 十七、可直接执行的操作清单

### A. 数据准备

1. 下载全部 UNCITRAL WG III 会议材料。
2. 按 session 整理文件夹。
3. 统一转换为纯文本。
4. 按发言者切分。
5. 建立 `speeches_clean.csv`。

### B. 标注规则

6. 确定 6 个核心议题。
7. 写出 `stance` 定义。
8. 完成 `codebook_v1.md`。

### C. 人工样本

9. 随机抽取 100–200 条发言。
10. 进行双人标注。
11. 计算一致性。
12. 修订 codebook。

### D. LLM 验证

13. 写出 `prompt_v1.txt`。
14. 让 LLM 标注黄金样本。
15. 计算 accuracy、precision、recall、F1。
16. 做错误分析并更新 Prompt。

### E. 全量标注

17. 用最终 Prompt 标注全部发言。
18. 对低置信度样本人工复核。
19. 形成正式标注数据集。

### F. 网络分析

20. 汇总为国家—议题数据库。
21. 构建国家相似度边表。
22. 运行社区发现算法。
23. 生成联盟网络图。
24. 解释联盟结构。

### G. 写作

25. 撰写数据与方法部分。
26. 撰写结果部分。
27. 做稳健性检验。
28. 完成结论与研究限制。

---

## 十八、结论：最适合本题的 LLM 使用方式

本研究最科学的设计，不是让 LLM 直接“替代研究者”，而是让它承担以下角色：

> 在统一规则约束下，对大规模会议文本进行结构化初判，并通过人工黄金样本、统计一致性检验和人工复核，将文本材料转换为可验证、可复查、可统计的研究数据库。

换句话说：

> 你不是用 LLM 直接写出答案，而是用 LLM 帮你把大量谈判文本变成可以做实证研究的数据。

这才是把 LLM 用到“最大程度且足够科学”的方式。
