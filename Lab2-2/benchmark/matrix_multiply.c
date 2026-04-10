// matrix_multiply.c
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

// 矩阵大小（确保数据常驻L1/L2缓存）
#define MAT_SIZE 64
#define ITER 10

float matA[MAT_SIZE][MAT_SIZE];
float matB[MAT_SIZE][MAT_SIZE];
float matC[MAT_SIZE][MAT_SIZE];

// 初始化矩阵
void init_mat() {
    srand(12345); // 固定随机种子，保证可复现
    for (int i = 0; i < MAT_SIZE; i++) {
        for (int j = 0; j < MAT_SIZE; j++) {
            matA[i][j] = (float)rand() / RAND_MAX;
            matB[i][j] = (float)rand() / RAND_MAX;
            matC[i][j] = 0.0f;
        }
    }
}

// 矩阵乘法
void mat_mult() {
    for (int iter = 0; iter < ITER; iter++) {
        for (int i = 0; i < MAT_SIZE; i++) {
            for (int j = 0; j < MAT_SIZE; j++) {
                float sum = 0.0f;
                for (int k = 0; k < MAT_SIZE; k++) {
                    sum += matA[i][k] * matB[k][j];
                }
                matC[i][j] = sum;
            }
        }
    }
}

int main() {
    init_mat();
    mat_mult();
    printf("Matrix Mult Done! matC[0][0] = %f\n", matC[0][0]);
    return 0;
}