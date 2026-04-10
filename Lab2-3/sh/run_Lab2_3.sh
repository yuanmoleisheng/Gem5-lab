#!/bin/bash
# 脚本说明：一键执行cache_test的4组配置测试，自动保存stats.txt
# gem5根目录和基准程序路径
GEM5_ROOT="."
# 基准程序路径
BENCH_PATH="./lab2/lab2_3/cache_test"
# 结果保存目录
RESULT_DIR="${GEM5_ROOT}/lab2_3_results"
mkdir -p ${RESULT_DIR}

# 函数：运行gem5测试并保存结果
run_test() {
    local config_name=$1
    local extra_params=$2 # 额外修改的参数
    echo "==================== 开始测试：${config_name} ===================="
    cd ${GEM5_ROOT}
    # 运行gem5（基础默认配置+额外参数）
    ./build/X86/gem5.opt ./configs/deprecated/example/se.py \
        --cmd=${BENCH_PATH} \
        --cpu-type=O3CPU \
        --num-cpus=1 \
        --cpu-clock=1GHz \
        --caches \
        --l2cache \
        ${extra_params}
    # 保存stats.txt
    cp ./m5out/stats.txt ${RESULT_DIR}/${config_name}_stats.txt
    # 可选：保存config.ini，便于后续验证配置是否生效
    cp ./m5out/config.ini ${RESULT_DIR}/config_${config_name}.ini
    echo "==================== 测试完成：${config_name}，结果已保存 ===================="
    echo -e "\n"
}

# 执行4组测试（按测试组编号顺序）
run_test "LRURP" "--l1d_repl=LRURP --l2_repl=LRURP"             # 1. 默认LRU替换策略
run_test "FIFORP" "--l1d_repl=FIFORP --l2_repl=FIFORP"          # 2. FIFO替换策略
run_test "NMRURP" "--l1d_repl=NMRURP --l2_repl=NMRURP"          # 3. NMRU替换策略
run_test "RandomRP" "--l1d_repl=RandomRP --l2_repl=RandomRP"    # 4. Random替换策略

echo "==================== 所有配置测试完成！结果目录：${RESULT_DIR} ===================="