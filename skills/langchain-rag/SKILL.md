---
name: langchain-rag
description: "在构建任何检索增强生成（RAG）系统时调用此技能。涵盖文档加载器、RecursiveCharacterTextSplitter、嵌入模型（OpenAI）以及向量存储（Chroma、FAISS、Pinecone）。"
---

<overview>
检索增强生成（RAG）通过从外部知识源获取相关上下文来增强大语言模型（LLM）的回答能力。

**处理流程：**
1. **索引（Index）**：加载 → 切分 → 嵌入向量化 → 存储
2. **检索（Retrieve）**：查询 → 嵌入向量化 → 检索 → 返回文档
3. **生成（Generate）**：文档 + 查询 → LLM → 回答

**核心组件：**
- **文档加载器（Document Loaders）**：从文件、网页、数据库中摄取数据
- **文本切分器（Text Splitters）**：将文档切分为块（chunks）
- **嵌入模型（Embeddings）**：将文本转换为向量
- **向量存储（Vector Stores）**：存储并检索向量
</overview>

<vectorstore-selection>

| 向量存储 | 适用场景 | 持久化方式 |
|--------------|----------|-------------|
| **InMemory** | 测试 | 仅内存 |
| **FAISS** | 本地、高性能 | 磁盘 |
| **Chroma** | 开发环境 | 磁盘 |
| **Pinecone** | 生产环境、全托管 | 云端 |

</vectorstore-selection>

---

## 完整的 RAG 流程

<ex-basic-rag-setup>
<python>
端到端 RAG 流程：加载文档、切分为块、嵌入向量化、存储、检索并生成回答。

```python
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_community.vectorstores import InMemoryVectorStore
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_core.documents import Document

# 1. 加载文档
docs = [
    Document(page_content="LangChain is a framework for LLM apps.", metadata={}),
    Document(page_content="RAG = Retrieval Augmented Generation.", metadata={}),
]

# 2. 切分文档
splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
splits = splitter.split_documents(docs)

# 3. 创建嵌入并存储
embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
vectorstore = InMemoryVectorStore.from_documents(splits, embeddings)

# 4. 创建检索器
retriever = vectorstore.as_retriever(search_kwargs={"k": 4})

# 5. 在 RAG 中使用
model = ChatOpenAI(model="gpt-4.1")
query = "What is RAG?"
relevant_docs = retriever.invoke(query)

context = "\n\n".join([doc.page_content for doc in relevant_docs])
response = model.invoke([
    {"role": "system", "content": f"Use this context:\n\n{context}"},
    {"role": "user", "content": query},
])
```
</python>
<typescript>
端到端 RAG 流程：加载文档、切分为块、嵌入向量化、存储、检索并生成回答。

```typescript
import { ChatOpenAI, OpenAIEmbeddings } from "@langchain/openai";
import { MemoryVectorStore } from "@langchain/classic/vectorstores/memory";
import { RecursiveCharacterTextSplitter } from "@langchain/textsplitters";
import { Document } from "@langchain/core/documents";

// 1. 加载文档
const docs = [
  new Document({ pageContent: "LangChain is a framework for LLM apps.", metadata: {} }),
  new Document({ pageContent: "RAG = Retrieval Augmented Generation.", metadata: {} }),
];

// 2. 切分文档
const splitter = new RecursiveCharacterTextSplitter({ chunkSize: 500, chunkOverlap: 50 });
const splits = await splitter.splitDocuments(docs);

// 3. 创建嵌入并存储
const embeddings = new OpenAIEmbeddings({ model: "text-embedding-3-small" });
const vectorstore = await MemoryVectorStore.fromDocuments(splits, embeddings);

// 4. 创建检索器
const retriever = vectorstore.asRetriever({ k: 4 });

// 5. 在 RAG 中使用
const model = new ChatOpenAI({ model: "gpt-4.1" });
const query = "What is RAG?";
const relevantDocs = await retriever.invoke(query);

const context = relevantDocs.map(doc => doc.pageContent).join("\n\n");
const response = await model.invoke([
  { role: "system", content: `Use this context:\n\n${context}` },
  { role: "user", content: query },
]);
```
</typescript>
</ex-basic-rag-setup>

---

## 文档加载器

<ex-loading-pdf>
<python>
加载 PDF 文件并将每一页提取为独立的文档。

```python
from langchain_community.document_loaders import PyPDFLoader

loader = PyPDFLoader("./document.pdf")
docs = loader.load()
print(f"Loaded {len(docs)} pages")
```
</python>
<typescript>
加载 PDF 文件并将每一页提取为独立的文档。

```typescript
import { PDFLoader } from "@langchain/community/document_loaders/fs/pdf";

const loader = new PDFLoader("./document.pdf");
const docs = await loader.load();
console.log(`Loaded ${docs.length} pages`);
```
</typescript>
</ex-loading-pdf>

<ex-loading-web-pages>
<python>
获取并解析指定 Web URL 的内容为文档。

```python
from langchain_community.document_loaders import WebBaseLoader

loader = WebBaseLoader("https://docs.langchain.com")
docs = loader.load()
```
</python>
<typescript>
使用 Cheerio 获取并解析指定 Web URL 的内容为文档。

```typescript
import { CheerioWebBaseLoader } from "@langchain/community/document_loaders/web/cheerio";

const loader = new CheerioWebBaseLoader("https://docs.langchain.com");
const docs = await loader.load();
```
</typescript>
</ex-loading-web-pages>

<ex-loading-directory>
<python>
使用 glob 模式从目录中加载所有文本文件。

```python
from langchain_community.document_loaders import DirectoryLoader, TextLoader

# 从目录中加载所有文本文件
loader = DirectoryLoader(
    "path/to/documents",
    glob="**/*.txt",  # 要加载的文件模式
    loader_cls=TextLoader
)
docs = loader.load()
```
</python>
</ex-loading-directory>

---

## 文本切分

<ex-text-splitting>
<python>
使用 RecursiveCharacterTextSplitter 切分文档为块，支持配置块大小和重叠长度。

```python
from langchain_text_splitters import RecursiveCharacterTextSplitter

splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,        # 每个块的字符数
    chunk_overlap=200,      # 用于保持上下文连贯性的重叠字符数
    separators=["\n\n", "\n", " ", ""],  # 切分层级优先级
)

splits = splitter.split_documents(docs)
```
</python>
</ex-text-splitting>

---

## 向量存储

<ex-chroma-vectorstore>
<python>
创建持久化的 Chroma 向量存储并从磁盘重新加载。

```python
from langchain_chroma import Chroma
from langchain_openai import OpenAIEmbeddings

vectorstore = Chroma.from_documents(
    documents=splits,
    embedding=OpenAIEmbeddings(),
    persist_directory="./chroma_db",
    collection_name="my-collection",
)

# 加载已有存储
vectorstore = Chroma(
    persist_directory="./chroma_db",
    embedding_function=OpenAIEmbeddings(),
    collection_name="my-collection",
)
```
</python>
<typescript>
创建连接到运行中 Chroma 服务器的 Chroma 向量存储。

```typescript
import { Chroma } from "@langchain/community/vectorstores/chroma";
import { OpenAIEmbeddings } from "@langchain/openai";

const vectorstore = await Chroma.fromDocuments(
  splits,
  new OpenAIEmbeddings(),
  { collectionName: "my-collection", url: "http://localhost:8000" }
);
```
</typescript>
</ex-chroma-vectorstore>

<ex-faiss-vectorstore>
<python>
创建 FAISS 向量存储，保存至磁盘并重新加载。

```python
from langchain_community.vectorstores import FAISS

vectorstore = FAISS.from_documents(splits, embeddings)
vectorstore.save_local("./faiss_index")

# 仅加载由您创建且完全受控的 FAISS 索引。
# Python FAISS 加载器使用 pickle 存储元数据，因此切勿加载
# 下载的、共享的或其他不受信任的索引目录。
loaded = FAISS.load_local(
    "./faiss_index",
    embeddings,
    allow_dangerous_deserialization=True,
)
```
</python>
<typescript>
创建 FAISS 向量存储，保存至磁盘并重新加载。

```typescript
import { FaissStore } from "@langchain/community/vectorstores/faiss";

const vectorstore = await FaissStore.fromDocuments(splits, embeddings);
await vectorstore.save("./faiss_index");

const loaded = await FaissStore.load("./faiss_index", embeddings);
```
</typescript>
</ex-faiss-vectorstore>

---

## 检索

<ex-similarity-search>
<python>
执行相似度检索并获取带有相关性得分的结果。

```python
# 基础检索
results = vectorstore.similarity_search(query, k=5)

# 带有得分的检索
results_with_score = vectorstore.similarity_search_with_score(query, k=5)
for doc, score in results_with_score:
    print(f"Score: {score}, Content: {doc.page_content}")
```
</python>
<typescript>
执行相似度检索并获取带有相关性得分的结果。

```typescript
// 基础检索
const results = await vectorstore.similaritySearch(query, 5);

// 带有得分的检索
const resultsWithScore = await vectorstore.similaritySearchWithScore(query, 5);
for (const [doc, score] of resultsWithScore) {
  console.log(`Score: ${score}, Content: ${doc.pageContent}`);
}
```
</typescript>
</ex-similarity-search>

<ex-mmr-search>
<python>
使用 MMR（最大边际相关性）在检索结果中平衡相关性与多样性。

```python
# MMR 平衡相关性与多样性
retriever = vectorstore.as_retriever(
    search_type="mmr",
    search_kwargs={"fetch_k": 20, "lambda_mult": 0.5, "k": 5},
)
```
</python>
</ex-mmr-search>

<ex-metadata-filtering>
<python>
向文档添加元数据，并按元数据属性过滤检索结果。

```python
# 创建文档时添加元数据
docs = [
    Document(
        page_content="Python programming guide",
        metadata={"language": "python", "topic": "programming"}
    ),
]

# 带过滤条件的检索
results = vectorstore.similarity_search(
    "programming",
    k=5,
    filter={"language": "python"}  # 仅检索 Python 相关文档
)
```
</python>
</ex-metadata-filtering>

<ex-rag-with-agent>
<python>
创建一个使用 RAG 作为工具来回答问题的 Agent。

```python
from langchain.agents import create_agent
from langchain.tools import tool

@tool
def search_docs(query: str) -> str:
    """在文档中检索相关信息。"""
    docs = retriever.invoke(query)
    return "\n\n".join([d.page_content for d in docs])

agent = create_agent(
    model="gpt-4.1",
    tools=[search_docs],
)

result = agent.invoke({
    "messages": [{"role": "user", "content": "How do I create an agent?"}]
})
```
</python>
<typescript>
创建一个使用 RAG 作为工具来回答问题的 Agent。

```typescript
import { createAgent } from "langchain";
import { tool } from "@langchain/core/tools";
import { z } from "zod";

const searchDocs = tool(
  async (input) => {
    const docs = await retriever.invoke(input.query);
    return docs.map(d => d.pageContent).join("\n\n");
  },
  {
    name: "search_docs",
    description: "Search documentation for relevant information.",
    schema: z.object({ query: z.string() }),
  }
);

const agent = createAgent({
  model: "gpt-4.1",
  tools: [searchDocs],
});

const result = await agent.invoke({
  messages: [{ role: "user", content: "How do I create an agent?" }],
});
```
</typescript>
</ex-rag-with-agent>

<boundaries>
### 可以配置的内容

- 块大小 / 重叠长度（Chunk size/overlap）
- 嵌入模型
- 检索返回数量（k）
- 元数据过滤器
- 检索算法：Similarity、MMR

### 不能配置的内容

- 嵌入向量维度（由各模型决定）
- 在同一个向量存储中混用来自不同模型的嵌入向量
</boundaries>

<fix-chunk-size>
<python>
块大小（Chunk size）通常建议在 500-1500 之间。

```python
# 错误：太小（丢失上下文）或太大（超出限制）
splitter = RecursiveCharacterTextSplitter(chunk_size=50)
splitter = RecursiveCharacterTextSplitter(chunk_size=10000)

# 正确
splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
```
</python>
<typescript>
块大小（Chunk size）通常建议在 500-1500 之间。

```typescript
// 错误：过小或过大
const splitter = new RecursiveCharacterTextSplitter({ chunkSize: 50 });

// 正确
const splitter = new RecursiveCharacterTextSplitter({ chunkSize: 1000, chunkOverlap: 200 });
```
</typescript>
</fix-chunk-size>

<fix-chunk-overlap>
<python>
使用重叠（块大小的 10-20%）来保持切分边界处的上下文连贯。

```python
# 错误：无重叠 - 边界处的上下文会断裂
splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=0)

# 正确：10-20% 的重叠
splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
```
</python>
</fix-chunk-overlap>

<fix-persist-vectorstore>
<python>
使用持久化向量存储替代内存存储，以避免数据丢失。

```python
# 错误：InMemory - 重启后数据丢失
vectorstore = InMemoryVectorStore.from_documents(docs, embeddings)

# 正确
vectorstore = Chroma.from_documents(docs, embeddings, persist_directory="./chroma_db")
```
</python>
<typescript>
使用持久化向量存储替代内存存储，以避免数据丢失。

```typescript
// 错误：Memory - 重启后数据丢失
const vectorstore = await MemoryVectorStore.fromDocuments(docs, embeddings);

// 正确
const vectorstore = await Chroma.fromDocuments(docs, embeddings, { collectionName: "my-collection" });
```
</typescript>
</fix-persist-vectorstore>

<fix-consistent-embeddings>
<python>
在建立索引和执行查询时使用相同的嵌入模型。

```python
# 错误：索引与查询使用不同的嵌入模型 - 互不兼容！
vectorstore = Chroma.from_documents(docs, OpenAIEmbeddings(model="text-embedding-3-small"))
retriever = vectorstore.as_retriever(embeddings=OpenAIEmbeddings(model="text-embedding-3-large"))

# 正确：使用相同的模型
embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
vectorstore = Chroma.from_documents(docs, embeddings)
retriever = vectorstore.as_retriever()  # 使用相同的嵌入模型
```
</python>
<typescript>
在建立索引和执行查询时使用相同的嵌入模型。

```typescript
const embeddings = new OpenAIEmbeddings({ model: "text-embedding-3-small" });
const vectorstore = await Chroma.fromDocuments(docs, embeddings);
const retriever = vectorstore.asRetriever();  // 使用相同的嵌入模型
```
</typescript>
</fix-consistent-embeddings>

<fix-faiss-deserialization>
<python>
仅对受信任的本地索引启用 FAISS 反序列化。Python FAISS 索引包含基于 pickle 的元数据，不受信任的 pickle 文件在加载时可能会执行任意代码。

```python
# 错误：加载下载的、共享的、云端托管的或由第三方控制的
# 且启用了危险反序列化的 FAISS 索引。
loaded_store = FAISS.load_local(
    "./untrusted_faiss_index",
    embeddings,
    allow_dangerous_deserialization=True,
)

# 正确：仅在该索引目录由您创建且始终在您的控制之下时才启用。
loaded_store = FAISS.load_local(
    "./faiss_index",
    embeddings,
    allow_dangerous_deserialization=True,
)
```

如果无法保证持久化索引的来源安全性，请勿使用 `allow_dangerous_deserialization=True` 进行加载。请从受信任的源文档重新构建索引，或者对于不受信任的文件使用不需要 pickle 反序列化的向量存储/后端。
</python>
</fix-faiss-deserialization>

<fix-dimension-mismatch>
<python>
确保嵌入维度与向量存储索引维度相匹配。

```python
# 错误：索引为 1536 维，但使用了 512 维的嵌入
pc.create_index(name="idx", dimension=1536, metric="cosine")
vectorstore = PineconeVectorStore.from_documents(
    docs, OpenAIEmbeddings(model="text-embedding-3-small", dimensions=512), index=pc.Index("idx")
)  # 错误：维度不匹配！

# 正确：匹配维度
embeddings = OpenAIEmbeddings()  # 默认 1536 维
```
</python>
</fix-dimension-mismatch>