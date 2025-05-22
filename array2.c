#include <stdio.h>
#include <stdlib.h>
#include "array2.h"

Array *new_array() {
    Array *arr = malloc(sizeof(Array));
    arr->size = 0;
    arr->capacity = 10;
    arr->data = malloc(sizeof(int) * arr->capacity);
    return arr;
}

void push_array(Array *arr, int value) {
    if (arr->size >= arr->capacity) {
        arr->capacity *= 2;
        arr->data = realloc(arr->data, sizeof(int) * arr->capacity);
    }
    arr->data[arr->size++] = value;
}

int pop_array(Array *arr) {
    if (arr->size == 0) {
        printf("Error: Array is empty\n");
        return 0;
    }
    return arr->data[--arr->size];
}

void print_array(Array *arr) {
    printf("[");
    for (int i = 0; i < arr->size; i++) {
        printf("%d", arr->data[i]);
        if (i < arr->size - 1) {
            printf(", ");
        }
    }
    printf("]\n");
}