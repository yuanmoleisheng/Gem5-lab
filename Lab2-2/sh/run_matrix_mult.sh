#!/bin/bash
# 脚本说明：一键执行matrix_multiply的7组配置测试，自动保存stats.txt
# gem5根目录和基准程序路径
GEM5_ROOT="./"
# 基准程序路径
BENCH_PATH="./lab2/lab2_2/matrix_multiply"
# 结果保存目录
RESULT_DIR="${GEM5_ROOT}/lab2_2_results/matrix_multiply"
mkdir -p ${RESULT_DIR}

# 函数：运行gem5测试并保存结果
run_test() {
    local config_num=$1
    local extra_params=$2 # 额外修改的参数
    echo "==================== 开始测试：${config_num} ===================="
    cd ${GEM5_ROOT}
    # 运行gem5（基础默认配置+额外参数）
    ./build/X86/gem5.opt ./configs/deprecated/example/se.py \
        --cmd=${BENCH_PATH} \
        --cpu-type=O3CPU \
        --caches \
        ${extra_params}
    # 保存stats.txt
    cp ./m5out/stats.txt ${RESULT_DIR}/matrix_multiply-stats_${config_num}.txt
    # 可选：保存config.ini，便于后续验证配置是否生效
    cp ./m5out/config.ini ${RESULT_DIR}/config_${config_num}.ini
    echo "==================== 测试完成：${config_num}，结果已保存 ===================="
    echo -e "\n"
}

# 执行7组测试（按测试组编号顺序）
run_test 1 "--cpu-clock=1GHz --l1d_size=64KiB --l2_size=128KiB --l2_assoc=8"    # 1. 减少L2
run_test 2 "--cpu-clock=4GHz --l1d_size=64KiB --l2_size=256KiB --l2_assoc=8"    # 2. 提高频率
run_test 3 "--cpu-clock=1GHz --l1d_size=32KiB --l2_size=256KiB --l2_assoc=8"    # 3. 减小L1-DCache
run_test 4 "--cpu-clock=1GHz --l1d_size=64KiB --l2_size=256KiB --l2_assoc=8"    # 4. 默认配置
run_test 5 "--cpu-clock=1GHz --l1d_size=64KiB --l2_size=256KiB --l2_assoc=2"    # 5. 降低L2关联度
run_test 6 "--cpu-clock=1GHz --l1d_size=64KiB --l2_size=2MiB --l2_assoc=8"      # 6. L2扩容
run_test 7 "--cpu-clock=1GHz --l1d_size=64KiB --l2_size=16MiB --l2_assoc=8"     # 7. L2进一步扩容

echo "==================== 所有配置测试完成！结果目录：${RESULT_DIR} ===================="