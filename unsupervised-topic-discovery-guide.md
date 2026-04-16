# 不先设标签，怎么做“无监督主题分类”？

这份说明讲的是一种**真正不先给标签**的方法。

也就是说，一开始你**不先告诉模型**有哪些议题，比如不先写好：

- `standing mechanism`
- `appeal mechanism`
- `costs and fees`
- `transparency`

而是先让文本自己“长出”主题，再由你根据结果总结出正式议题体系。

这在更准确的学术语言里，通常不叫 `zero-shot classification`，而叫：

- `unsupervised topic modeling`
- `unsupervised clustering`
- `topic discovery`

通俗理解就是：

> 先不告诉机器答案，让机器先把“说得像一类的话”抱成团；  
> 然后你再看每一团到底在谈什么。

---

## 一、这套方法到底要做什么？

你的目标不是让模型一上来就说：

> “这段是上诉机制，那段是常设机制”

而是先让模型回答一个更基础的问题：

> “哪些发言彼此最像？它们能不能自然分成若干堆？”

如果很多发言总是被分到同一堆，而且它们都在讨论类似内容，那么这堆就可能是一个真实主题。

所以，这套方法的核心不是“先分类”，而是：

> **先发现主题，再给主题命名。**

---

## 二、最推荐的总体路线

最稳妥、最科学的流程是：

```text
会议发言文本
→ 切成一条一条发言
→ 最少限度清洗
→ 文本向量化（embeddings）
→ 无监督聚类
→ 提取每一簇的关键词
→ 看代表性发言
→ 让 LLM 帮忙给簇命名
→ 合并相近簇、删除套话簇
→ 最后形成正式议题体系
```

建议同时跑三种方法互相对照：

1. `BERTopic`
2. `Sentence-Transformers + HDBSCAN`
3. `LDA` 或 `NMF` 作为经典 baseline

这样更科学，因为你不是迷信某一个模型。

---

## 三、一步一步怎么做

下面是一个**完全不先设标签**的研究流程。

---

## 第 1 步：先把“分析单位”切好

你要先决定：

> 一条数据到底是什么？

对你这个题目，最合适的单位还是：

> **一个国家的一次发言**

不要用整场会议。  
也不要把一个国家一整年的发言揉成一团。

整理后，数据表大概长这样：

| speech_id | session_id | speaker | speech_text |
|---|---|---|---|
| 001 | 38 | Canada | ... |
| 002 | 38 | Brazil | ... |

这一步不是在“打标签”，只是把文本切成可分析的小单位。

通俗理解：

> 你要先把一大锅汤分成一小碗一小碗，后面才知道哪几碗味道像。

---

## 第 2 步：做最少限度的清洗

现在你要做的是“无监督发现主题”，所以**不要过度清洗**。

建议只做这些：

- 去掉页码、页眉、页脚
- 去掉乱码
- 保留完整句子
- 保留法律术语
- 不要把重要术语删掉

比如这些词千万不能误删：

- `appeal mechanism`
- `standing mechanism`
- `third-party funding`

为什么？

因为这些词本来就是主题线索。  
如果你先把线索擦掉，模型后面就更难发现真实主题。

通俗理解：

> 现在是让模型自己找规律，所以不要先把“提示词”抹掉。

---

## 第 3 步：去掉机械重复文本

谈判文本里经常有很多套话，比如：

- 感谢主席
- 感谢秘书处
- 欢迎工作文件
- 程序性客套话

这些内容如果太多，会污染聚类。

### 3.1 删除纯程序性句子

比如：

- `Thank you Chair.`
- `We thank the Secretariat.`
- `We appreciate the working paper.`

### 3.2 去重

如果完全重复的发言很多，可以去重，或者先标记重复文本。

为什么要这样做？

因为无监督模型会把“最常重复的东西”误当成主题。

如果你不先清理，最后可能聚出一个很大的主题，结果它只是“礼貌发言簇”。

---

## 第 4 步：先把文本变成 embeddings

这是关键一步。

你可以把 `embedding` 理解成：

> 把一段话变成一个数字坐标点

意思相近的话，在这个坐标空间里会更靠近。

这一步最好不要直接用聊天 LLM。  
更稳的是用 `sentence-transformers` 这类专门做语义向量的模型。

通俗理解：

> 你是在把每段话放进一张“语义地图”里。  
> 说得像的话，会在地图上挨得近。

---

## 第 5 步：先跑 BERTopic

这是最推荐的第一轮主方法。

最基础的做法就是：

```python
from bertopic import BERTopic

docs = speeches["speech_text"].tolist()

topic_model = BERTopic()
topics, probs = topic_model.fit_transform(docs)
```

跑完之后你可以看：

```python
topic_model.get_topic_info()
topic_model.get_document_info(docs)
```

你会得到：

- 每条发言属于哪个 topic
- 每个 topic 有多少条文本
- 每个 topic 最代表性的关键词
- 哪些文本被判成离群点 `-1`

BERTopic 的一个好处是：

> 它通常不需要你先指定主题数量

这很适合你现在“我不想先加标签”的需求。

---

## 第 6 步：再跑 embedding + HDBSCAN

这一步是为了验证 BERTopic 的结果，不是为了重复劳动。

思路是：

1. 自己生成 embeddings
2. 用 `HDBSCAN` 聚类
3. 看聚类结构是否大体类似 BERTopic

示意代码：

```python
from sentence_transformers import SentenceTransformer
import hdbscan

model = SentenceTransformer("all-MiniLM-L6-v2")
embeddings = model.encode(docs, show_progress_bar=True)

clusterer = hdbscan.HDBSCAN(min_cluster_size=15, min_samples=5)
labels = clusterer.fit_predict(embeddings)
probs = clusterer.probabilities_
```

这里要注意：

- `labels` 是每条文本属于哪个簇
- `-1` 表示噪音点
- `probs` 表示这条文本属于该簇的把握程度

这一步的意义是：

> 如果 BERTopic 和 HDBSCAN 单跑出来的簇结构很像，说明你的主题结构更可信。

---

## 第 7 步：再跑一个经典 baseline：LDA 或 NMF

为什么还要跑老方法？

因为这叫**对照**。

如果只有 BERTopic 跑出了某个主题，而 `LDA/NMF` 完全没有类似东西，你就要谨慎。  
如果几种方法都反复出现类似主题，说明这个主题更稳。

注意：

- `LDA/NMF` 通常需要你先选 `n_topics`
- 所以你可以试几组，比如 `5`、`8`、`10`、`12`
- 然后比较哪组更合理

通俗理解：

> 同一个地方，如果三台不同牌子的相机都拍到了差不多的轮廓，那这轮廓就更可信。

---

## 四、怎么判断“这个无监督结果科学不科学”？

这是最关键的部分。

你不能说：

> 模型分出来了 8 类，所以就一定有 8 个真实议题

这不科学。

你要做验证。

---

## 第 8 步：做“内部质量检查”

### 8.1 看每个簇的关键词是否像话

比如一个簇的前几个词是：

- `appeal`
- `review`
- `appellate`
- `consistency`
- `errors`

那它大概率是在谈“上诉机制”。

如果一个簇关键词是：

- `thank`
- `chair`
- `appreciate`
- `secretariat`

那说明你聚出了“客套话簇”，这不是你真正关心的 substantive topic。

### 8.2 看代表性文本

不要只看词。  
每个 topic 至少抽 `5–10` 条代表性发言。

你要问自己：

- 这些文本真的在谈同一件事吗？
- 还是只是碰巧用了几个相似词？

### 8.3 看离群点比例

如果很多文本都被打成 `-1` 或噪音，可能说明：

- 文本太短
- 清洗不好
- 参数不合适
- 主题本来就很碎

---

## 第 9 步：做量化检验

最常见的两个指标是：

### 9.1 coherence

看一个 topic 的高频词是否“彼此搭配得自然”。

通俗解释：

> 这堆词放在一起，像不像在说同一个话题？

### 9.2 silhouette score

看同簇文本是不是更近、不同簇文本是不是更远。

通俗解释：

> 这一堆文本抱团紧不紧？  
> 不同堆之间分得开不开？

但要注意：

> `coherence` 和 `silhouette` 都重要，  
> 但都不能单独决定“真不真实”。

因为主题模型里最重要的还是：

- 可解释性
- 稳定性
- 和原文是否吻合

---

## 第 10 步：做“稳定性检查”

这是很多人会漏掉，但其实非常科学。

做法：

- 换几个随机种子重新跑
- 换几组参数重新跑
- 看大主题是否反复出现

例如：

### BERTopic

试几组参数：

- 默认
- 更大的 `min_topic_size`
- 更小的 `min_topic_size`

### HDBSCAN

试几组：

- `min_cluster_size=10`
- `min_cluster_size=15`
- `min_cluster_size=20`

如果一个主题在很多版本里都出现，说明它比较稳。  
如果一个主题只在某个参数下出现一次，说明它可能不稳。

通俗理解：

> 真正重要的主题，不应该只在某一次“碰巧”的设置里出现。

---

## 五、LLM 在“无标签主题发现”里应该怎么用？

这里很重要。

如果你要保持前面阶段尽量无监督，LLM 最好放在后面。

也就是说：

> **先让算法把文本分堆，再让 LLM 帮你解释这些堆。**

而不是反过来。

---

## 第 11 步：先聚类，再让 LLM 给簇起名字

这是最推荐的用法。

做法：

你先从某个簇中取：

- 前 `15` 个关键词
- `5` 条代表性发言

然后问 LLM：

```text
Please propose a short, neutral topic label for this cluster based only on the keywords and representative texts. Do not infer beyond the provided materials.
```

LLM 这时做的是：

- 给簇命名
- 总结这个簇在谈什么
- 给出一句人能看懂的解释

这很有用，而且不太污染前面的无监督发现。

---

## 第 12 步：让 LLM 帮你识别“簇之间是否应合并”

有时候模型会分出两个很像的簇。

例如：

- 一个簇偏 `appeal mechanism`
- 一个簇偏 `review mechanism`

你可以把两个簇的关键词和代表文本给 LLM，看它是否建议：

- 合并
- 保持分开
- 认为一个是子主题

但这一步要记住：

> LLM 是辅助解释，不是最后裁判。

最后决定还得看文本证据。

---

## 六、如果你完全不想先加标签，最好的实践顺序是什么？

我给你一个最稳的顺序。

### 第一轮：纯无监督主题发现

方法组合：

- `BERTopic`
- `Embedding + HDBSCAN`
- `LDA/NMF baseline`

目的：

- 先看主题自然长成什么样
- 看是否反复出现一些稳定大主题
- 看你原来设想的 6 个议题是否真的存在

### 第二轮：后验命名

对每个 topic：

1. 看关键词
2. 看代表文本
3. 用 LLM 帮你起一个中性名字
4. 记录“这个名字是后验解释，不是预设标签”

### 第三轮：主题合并与清理

你会发现：

- 有些 topic 是 substantive topics
- 有些 topic 是礼貌套话
- 有些 topic 是程序性发言
- 有些 topic 太碎

这时你做：

- 合并相近 topic
- 删除程序性簇
- 保留 substantive topics

### 第四轮：再进入“正式标签化”

只有到这一步，你才开始说：

> 好，现在我根据无监督结果，整理出正式议题标签体系

这时候再回头形成：

- `standing mechanism`
- `appeal mechanism`
- `costs and fees`
- `transparency`

就会更科学，因为这些标签不是你一开始拍脑袋定的，而是：

> 先让文本自己说话，再由研究者总结出标签体系。

---

## 七、最简操作清单

如果你现在就要开始，可以直接按这个顺序做：

1. 整理出 `speech_id + speech_text`
2. 做最少清洗
3. 删除礼貌套话和重复文本
4. 跑一版 `BERTopic`
5. 跑一版 `SentenceTransformer + HDBSCAN`
6. 跑一版 `LDA` 或 `NMF`
7. 比较三种方法共同出现的大主题
8. 抽每个 topic 的代表文本人工看
9. 用 LLM 给 topic 命名
10. 合并相近 topic，删掉程序性簇
11. 最后形成正式议题体系

---

## 八、最后一句话

如果你真的想做到：

> **一开始不设标签，让模型自己发现议题**

那么最科学的方法不是“直接让聊天 LLM 给你分组”，而是：

> **embedding + clustering + topic extraction + LLM 后验命名**

这条路线既保留了“先让文本自己说话”的原则，又比直接让 LLM 一步到位更稳定、更容易复查，也更适合写进正式研究设计。
