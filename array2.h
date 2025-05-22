#ifndef ARRAY2_H
#define ARRAY2_H

typedef struct {
    int *data;      
    int size;       
    int capacity;   
} Array;

Array *new_array();
void push_array(Array *arr, int value);
int pop_array(Array *arr);
void print_array(Array *arr);

// AST Node Types
typedef enum {
    NODE_PROGRAM,
    NODE_C_STATEMENT,
    NODE_JS_STATEMENT,
    NODE_EXPR_NUMBER,
    NODE_EXPR_BINARY,
    NODE_EXPR_PAREN
} NodeType;

// JS Statement Types
typedef enum {
    JS_ARRAY_CREATE,
    JS_PUSH,
    JS_POP,
    JS_PRINT
} JSStatementType;

typedef struct ASTNode {
    NodeType type;
    union {
        struct {
            struct ASTNode **statements;
            int statement_count;
        } program;
        struct {
            char *identifier;
            struct ASTNode *expr;
        } c_statement;
        struct {
            JSStatementType js_type;
            char *identifier;
            struct ASTNode *expr;
        } js_statement;
        struct {
            int value;
        } expr_number;
        struct {
            char op;
            struct ASTNode *left;
            struct ASTNode *right;
        } expr_binary;
        struct {
            struct ASTNode *expr;
        } expr_paren;
    } data;
} ASTNode;

// Token Table
typedef struct {
    char *type;
    char *value;
    int line;
} TokenEntry;

typedef struct {
    TokenEntry *entries;
    int count;
    int capacity;
} TokenTable;

extern TokenTable token_table;

#endif