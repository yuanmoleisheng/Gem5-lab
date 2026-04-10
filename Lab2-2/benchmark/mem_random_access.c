// mem_random_access.c
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

// 数组大小（远大于CPU缓存，强制走主存）
#define ARR_SIZE (1024 * 64)  // 64K * 4B = 256KB
#define ITER 100000

int *arr;
int *rand_idx;

// 初始化数组和随机索引
void init() {
    arr = (int *)malloc(ARR_SIZE * sizeof(int));
    rand_idx = (int *)malloc(ITER * sizeof(int));
    if (!arr || !rand_idx) { perror("Malloc failed"); exit(1); }
    
    srand(12345); // 固定随机种子
    for (int i = 0; i < ARR_SIZE; i++) arr[i] = rand();
    for (int i = 0; i < ITER; i++) rand_idx[i] = rand() % ARR_SIZE;
}

// 随机访问数组
void random_access() {
    int sum = 0;
    for (int i = 0; i < ITER; i++) {
        sum += arr[rand_idx[i]]; // 随机访存
    }
    printf("Random Access Done! Sum = %d\n", sum);
}

int main() {
    init();
    random_access();
    free(arr);
    free(rand_idx);
    return 0;
}