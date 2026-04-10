// cache_test.c
#include <stdio.h>
#include <stdlib.h>

#define FIB_N 1000000
#define ARR_SIZE 10240

long long fib[FIB_N];
int arr[ARR_SIZE];  // 10K * 4B = 40KB

// 迭代斐波那契(CPU)
long long fib_iter() {
    fib[0] = 0;
    fib[1] = 1;
    for (int i = 2; i < FIB_N; i++) {
        fib[i] = fib[i-1] + fib[i-2];
    }
    return fib[FIB_N-1];
}

// 数组遍历累加(Mem)
int arr_sum() {
    int sum = 0;
    for (int i = 0; i < ARR_SIZE; i++) {
        arr[i] = i * 2;
        sum += arr[i];
    }
    return sum;
}

int main() {
    long long fib_res = fib_iter();
    int arr_res = arr_sum();
    printf("Fib(%d) = %lld, ArrSum = %d\n", FIB_N, fib_res, arr_res);
    return 0;
}