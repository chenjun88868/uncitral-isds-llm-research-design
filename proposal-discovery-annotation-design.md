# Proposal Discovery Annotation Design

这份说明记录如何设计 proposal discovery 人工标注任务。我的目标不是让模型直接替我发现所有 proposal，而是先做一批质量可控的人工标注数据，再用 supervised machine learning。

## 1. 分析单位

我把 `42-48` 届 UNCITRAL Working Group III 逐字稿切成 speaker turn。一个样本就是一个 speaker 的一次连续发言；如果同一次发言里有好几段，也仍然算同一个样本。

最终用于抽样的基础表是：

```text
ACIIL_42_48_all_speaker_turns.xlsx
```

这个表共有 `8270` 条 speaker-turn 样本。每条样本保留了 `record_id`、`source_doc`、`source_markdown`、`session_id`、`date`、`speaker`、`speaker_type`、`turn_index`、`word_count`、`char_count` 和 `text`。

## 2. 我没有按单行随机抽样

proposal 往往不是孤立出现的。一个代表提出文本修改，后面几个代表可能马上支持、反对、补充或要求澄清。如果随机抽单行，标注员很容易看不到上下文。

所以我按连续区块抽样。区块内部的 speaker turn 保持原始顺序，不跨原始文档。这样标注员看到的是一小段完整讨论，而不是散落的句子。

## 3. 200 条校准样本

我先抽了一个 `200` 条的校准集，用来训练标注员、讨论边界案例、形成 codebook。

这批样本不是随机抽的。我参考了已有的 proposal repository：

```text
proposal_repository_opus47.csv
```

然后给全部 `8270` 条 speaker turn 打了一个 proposal probability score。分数主要来自几类信号：

- 是否出现 `we propose`、`we suggest`、`should be`、`we support`、`we oppose` 这类 proposal 或 stance 表达；
- 是否出现 `add`、`delete`、`replace`、`retain`、`revise`、`clarify` 这类文本动作；
- 是否涉及 `article`、`paragraph`、`draft`、`option`、`code of conduct`、`advisory centre`、`mediation`、`adjudicators`、`permanent mechanism` 等改革对象；
- 是否命中 proposal repository 里的 representative evidence；
- 该样本所在文件是否是 proposal 证据比较密集的文件。

最后我抽了 `8` 个连续区块，每块 `25` 条，一共 `200` 条。区块如下：

| Block | Source | Record ID Range | Turn Range |
|---|---|---:|---:|
| B01 | `42-3.md` | `423005-423029` | `5-29` |
| B02 | `42-5.md` | `425061-425085` | `61-85` |
| B03 | `43-1.md` | `431030-431054` | `30-54` |
| B04 | `43-11.md` | `4311068-4311092` | `68-92` |
| B05 | `43-17.md` | `4317075-4317099` | `75-99` |
| B06 | `44-7.md` | `447042-447066` | `42-66` |
| B07 | `45-1.md` | `451007-451031` | `7-31` |
| B08 | `46-2.md` | `462070-462094` | `70-94` |

核验结果是：`200` 条样本的 `record_id` 全部唯一。其中 proposal score `>=18` 的样本有 `115` 条，score `>=28` 的样本有 `83` 条。

这批数据放在：

```text
CalibrationSet200/
```

对应脚本是：

```text
SplittingCode/01_CalibrationSet200_high_probability_proposal_blocks.py
```

## 4. 900 条正式监督样本

校准集之外，我又抽了 `900` 条正式监督样本。这里我按 Session 分层，因为不同 Session 的原始样本数不同。样本多的 Session 分到更多区块，样本少的 Session 分到更少区块。

原始样本量是：

| Session | 原始样本数 |
|---|---:|
| 42 | 837 |
| 43 | 2197 |
| 44 | 989 |
| 45 | 1000 |
| 46 | 1023 |
| 47 | 1204 |
| 48 | 1020 |
| **合计** | **8270** |

我最后抽了 `36` 个连续区块，共 `900` 条。实际分布如下：

| Session | 区块数 | 样本数 |
|---|---:|---:|
| 42 | 4 | 92 |
| 43 | 10 | 240 |
| 44 | 4 | 108 |
| 45 | 4 | 108 |
| 46 | 5 | 110 |
| 47 | 5 | 130 |
| 48 | 4 | 112 |
| **合计** | **36** | **900** |

每个区块都在同一个 `source_doc` 内，所有区块内部的 `turn_index` 都连续。这 `900` 条没有和前面 `200` 条校准样本的已知区间重叠。

这批样本中，proposal score `>=18` 的样本有 `459` 条，score `>=28` 的样本有 `233` 条。

这批数据放在：

```text
Supervision900/ACIIL_stratified900.xlsx
```

对应脚本是：

```text
SplittingCode/02_Supervision900_stratified_continuous_blocks.py
```

## 5. 三人标注任务分配

我们组有三名标注员。我把 `900` 条正式监督样本按区块分成两部分。

第一部分是三人共同标注的 reliability sample。这里我优先放入 proposal probability 更高的区块，因为这些区块更容易出现真正的 proposal，也更容易暴露 codebook 的边界问题。

第二部分是单人标注样本。我把剩下的区块完整分给三名标注员，尽量让每个人的工作量接近。

最后分配结果是：

| Sheet | 用途 | 样本数 | 区块数 |
|---|---|---:|---:|
| `shared_3coders` | 三人共同独立标注，用于一致性检验 | 313 | 13 |
| `Coder_A` | 单人标注 | 192 | 7 |
| `Coder_B` | 单人标注 | 195 | 8 |
| `Coder_C` | 单人标注 | 200 | 8 |
| **合计** |  | **900** | **36** |

我没有拆分任何区块。每个 `sample_block_id` 只进入一个任务 sheet。

分配后的文件是：

```text
Supervision900/CoderA:B:C.xlsx
```

对应脚本是：

```text
SplittingCode/03_Supervision900_CoderA:B:C_by_blocks.py
```

## 6. 标注流程

我把 `200` 条校准样本作为 training/calibration set。老师带三名标注员一起看这批样本，用它来统一什么算 proposal、什么不算 proposal，以及如何处理模糊情况。

校准之后，三名标注员独立标注 `shared_3coders` 里的 `313` 条样本。这个部分用来计算 intercoder reliability。计算一致性之前，三个人不讨论具体答案。

`Coder_A`、`Coder_B`、`Coder_C` 三个 sheet 是单人标注部分。每名标注员只标自己的 sheet。单人标注部分用于扩大训练数据；其中 `needs_review`、低置信度和明显有争议的样本后续进入人工裁决。

## 7. 我记录的标注字段

在样本表里，我保留了空白标注列：

| 字段 | 含义 |
|---|---|
| `has_proposal` | 这条 speaker turn 是否包含 proposal |
| `proposal_span` | 原文中对应 proposal 的片段 |
| `proposal_text_normalized` | 归一化后的 proposal 表述 |
| `proposal_label` | 简短 proposal 标签 |
| `proposal_type` | proposal 类型 |
| `target_object` | proposal 针对的对象 |
| `confidence` | 标注员对判断的信心 |
| `needs_review` | 是否需要复核 |
| `coder_notes` | 标注员备注 |

## 8. 一致性和最终标签

我用 `shared_3coders` 计算三人一致性。`has_proposal` 是最核心的二分类字段，可以报告 Fleiss' Kappa、Krippendorff's Alpha，并补充 pairwise Cohen's Kappa。

计算一致性以后，再讨论分歧样本。共同标注样本通过多数票或老师裁决形成最终标签。单人标注样本中被标为 `needs_review` 的部分也进入裁决。

## 9. 训练集、验证集和测试集

后续做机器学习时，我不按单行随机切分 train/dev/test，而是按 `sample_block_id` 切分。同一个连续区块只能进入同一个集合，不能一半在训练集、一半在测试集。

测试集优先从三人共同标注并经过裁决的样本里取。这样最终报告的模型表现建立在标签质量最高的样本上。单人标注样本主要进入训练集，用来扩大模型看到的语言形态。

我采用的比例是：

| Split | 用途 |
|---|---|
| Train | 训练 RoBERTa 或 open-source LLM |
| Dev | 调阈值、调 prompt、选模型 |
| Test | 最终评估，只在最后使用 |

实际切分时仍然按区块微调数量，而不是强行按单行凑精确比例。

## 10. 模型选择

这套人工标注数据后续用于 proposal discovery。我把 Qwen3-32B 作为优先尝试的开源大模型。

我这样选，是因为这个任务需要稳定的结构化输出、较好的长上下文处理能力、明确的微调路径和宽松许可。Qwen3-32B 是 Apache 2.0 许可，支持 LoRA、QLoRA 和 full fine-tuning；推理时可以关闭 thinking mode，让输出更接近一个稳定的标注器。

Llama 系列仍然可以作为对照模型，但我把 Qwen3-32B 放在主模型位置。

