# 实验2-3

| 实验序号 | 学号            | 姓名   |
| :------: | --------------- | ------ |
|  Lab2-3  | 2025E8013282032 | 郭义珉 |


## 1：实现NMRU策略

我们在路径`/src/mem/cache/replacement_policies/`下新建了两个文件：`nmru_rp.cc`和`nmru_rp.hh`。

这两个文件拷贝自`lru_rp`的头文件和源文件，拷贝后首先是把文件中的`LRU`字段全部替换成`NMRU`

对于`nmru_rp.hh`，我添加了头文件 `<random>`，成员变量中添加了一行

`mutable std::mt19937 randGen;`

对于`nmru_rp.cc`，需要修改的只有构造函数和成员函数`getVictim`，注意修改、添加相应头文件，具体代码如下

```cpp
NMRU::NMRU(const Params &p)
  : Base(p), randGen(std::random_device{}())
{
}

ReplaceableEntry*
NMRU::getVictim(const ReplacementCandidates& candidates) const
{
    // There must be at least one replacement candidate
    assert(candidates.size() > 0);

    // Visit all candidates to find mru_entry
    ReplaceableEntry* mru_entry = candidates[0];
    for (const auto& candidate : candidates) {
        auto& candidate_tick = std::static_pointer_cast<NMRUReplData>(candidate->replacementData)->lastTouchTick;
        auto& mru_tick = std::static_pointer_cast<NMRUReplData>(mru_entry->replacementData)->lastTouchTick;
        if(candidate_tick > mru_tick) {
            mru_entry = candidate;
        }
    }
    if(candidates.size() == 1) {
        return mru_entry;
    }
    std::vector<ReplaceableEntry*> nmru_candidates;
    for(const auto& candidate : candidates) {
        if(candidate != mru_entry) {
            nmru_candidates.push_back(candidate);
        }
    }
    assert(nmru_candidates.size() > 0);
    std::uniform_int_distribution<> dist(0, nmru_candidates.size() - 1);
    const int rand_idx = dist(randGen);
    ReplaceableEntry* victim = nmru_candidates[rand_idx];

    return victim;
}
```


### 2：配置NMRU策略

我们使用`se.py`配置脚本，它可以通过命令行参数来配置模拟环境，我们需要将`NMRU`策略添加进命令行参数中，并使其可以执行。

* 在`/src/mem/cache/replacement_policies/ReplacementPolicies.py`文件中，我们在其中加入了一个新类

```python
class NMRURP(BaseReplacementPolicy):    # 声明一个新类 NMRU
    type = "NMRURP"
    cxx_class = "gem5::replacement_policy::NMRU"
    cxx_header = "mem/cache/replacement_policies/nmru_rp.hh"
```

* 在`/src/mem/cache/replacement_policies/SConscript`文件中修改如下

```python
# 在SimObject数组最后添加NMRURP
SimObject('ReplacementPolicies.py', sim_objects=[
    'BaseReplacementPolicy', 'DuelingRP', 'FIFORP', 'SecondChanceRP',
    'LFURP', 'LRURP', 'BIPRP', 'MRURP', 'RandomRP', 'BRRIPRP', 'SHiPRP',
    'SHiPMemRP', 'SHiPPCRP', 'TreePLRURP', 'WeightedLRURP', 'NMRURP'])

Source('nmru_rp.cc')    # 添加对nmru源文件的调用
```

* 终端中重新编译gem5：`scons ./build/X86/gem5.opt -j4`，这中间可能失败多次，且十分玄学-_-，我搞了大半天一直内存不足，尝试了各种办法都无济于事，最后到了半夜想着随便再试一次，过不过都去睡觉，就在参数里随手填了个 `-j4`（刚开始用4不行，后来来来回回换了1，2都不行），结果这次就过了，以上一点碎碎念。
* 我想把缓存替换策略作为一个可选参数，这样便于更改
* 在 `./configs/common/ObjectList.py`文件中的 `cpu_list`后添加一句

```python
repl_list = ObjectList(getattr(m5.objects, 'BaseReplacementPolicy', None))
```

* 在 `./configs/common/Options.py`文件中添加两句

  ```python
  # 添加可选l1d替换策略
  parser.add_argument("--l1d_repl", type=str, default="LRURP",
                      choices=ObjectList.repl_list.get_names(),
                      help="L1 Data Cache Replacement Policy")
  parser.add_argument("--l2_repl", type=str, default="LRURP",
                      choices=ObjectList.repl_list.get_names(),
                      help="L2 Cache Replacement Policy")
  ```
* 在 `./configs/common/CacheConfig.py`文件中把这些选项连接到cache

  ```python
  #把选项连接到dcache
  dcache = dcache_class(size = options.l1d_size,
                        assoc = options.l1d_assoc,
                        replacement_policy = 
                        ObjectList.repl_list.get(options.l1d_repl)()
                        )
  system.l2 = l2_cache_class(clk_domain = system.cpu_clk_domain,
                             size = options.l2_size,
                             assoc = options.l2_assoc,
                             replacement_policy = 
                             ObjectList.repl_list.get(options.l2_repl)()
                             )
  ```


## 3：设计负载

这里我们采用Lab2-2中的基准测试程序`hybrid_fib`作为`cache_test`，并选取了`LRU`、`FIFO`、`NMRU`、`Random`四种不同的缓存替换策略，通过执行脚本文件`run_Lab2_3.sh`进行测试

得到的结果如下

| 缓存替换策略 |   IPC   | simSeconds | pageHitRate |
| :----------: | :------: | :--------: | :---------: |
|     LRU     | 1.186448 |  0.017951  |    90.65    |
|     FIFO     | 1.251533 |  0.017018  |    92.12    |
|     NMRU     | 1.128129 |  0.018879  |    79.95    |
|    Random    | 1.167915 |  0.018236  |    78.75    |

## 4：分析

`hybrid_fib`属于**混合负载**，其内存访问有两个核心特征：

1. **斐波那契计算**：反复访问 `fib`数组的前 2 个元素（强**时间局部性**，这两个元素是“最近使用（MRU）”的高频条目）；
2. **数组存储**：顺序访问 `arr`数组的连续元素（强**空间局部性**，这些元素是“非MRU但近期会被连续访问”的条目）。

四种策略的逻辑与负载特性的匹配度，导致性能差异：

* **FIFO**：仅按“条目进入缓存的顺序”替换，不跟踪使用频率。该负载的访问模式是“一批数据（如 `arr`数组）进入后短时间内连续使用，之后不再访问”，FIFO 的顺序替换刚好避开了正在使用的批量数据，因此命中率最高。
* **LRU**：优先替换“最久未使用”的条目，能跟踪 `hybrid_fib`的时间/空间局部性（保留近期访问的 `fib`前2元素和 `arr`连续元素），因此命中率和性能较好。
* **Random**：完全随机选择替换条目，无法利用任何局部性，因此命中率最低（78.75%），性能较差（符合预期）。
* **NMRU**：排除“最近使用（MRU）”的条目后，从剩余条目里随机选择替换 。该逻辑与 `hybrid_fib`的局部性特征冲突，导致命中率大幅下降，是表现最差的策略。
