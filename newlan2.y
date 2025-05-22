%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "array2.h"

void yyerror(const char *s);
int yylex();
extern int yylineno;

// Symbol table
#define MAX_SYMBOLS 100
typedef struct {
    char *name;
    Array *array;
} Symbol;
Symbol symbol_table[MAX_SYMBOLS];
int symbol_count = 0;

// AST root
ASTNode *ast_root = NULL;

// Token Table
extern TokenTable token_table;

// Function to create AST nodes
ASTNode *new_ast_node(NodeType type) {
    ASTNode *node = malloc(sizeof(ASTNode));
    node->type = type;
    return node;
}

// Function to print AST
void print_ast(ASTNode *node, int indent) {
    if (!node) return;
    for (int i = 0; i < indent; i++) printf("  ");
    switch (node->type) {
        case NODE_PROGRAM:
            printf("Program (%d statements)\n", node->data.program.statement_count);
            for (int i = 0; i < node->data.program.statement_count; i++) {
                print_ast(node->data.program.statements[i], indent + 1);
            }
            break;
        case NODE_C_STATEMENT:
            printf("C_Statement: int %s =\n", node->data.c_statement.identifier);
            print_ast(node->data.c_statement.expr, indent + 1);
            break;
        case NODE_JS_STATEMENT:
            printf("JS_Statement: ");
            switch (node->data.js_statement.js_type) {
                case JS_ARRAY_CREATE:
                    printf("array %s = []\n", node->data.js_statement.identifier);
                    break;
                case JS_PUSH:
                    printf("push(%s, \n", node->data.js_statement.identifier);
                    print_ast(node->data.js_statement.expr, indent + 1);
                    for (int i = 0; i < indent; i++) printf("  ");
                    printf(")\n");
                    break;
                case JS_POP:
                    printf("pop(%s)\n", node->data.js_statement.identifier);
                    break;
                case JS_PRINT:
                    printf("print(%s)\n", node->data.js_statement.identifier);
                    break;
            }
            break;
        case NODE_EXPR_NUMBER:
            printf("Number: %d\n", node->data.expr_number.value);
            break;
        case NODE_EXPR_BINARY:
            printf("Binary: %c\n", node->data.expr_binary.op);
            print_ast(node->data.expr_binary.left, indent + 1);
            print_ast(node->data.expr_binary.right, indent + 1);
            break;
        case NODE_EXPR_PAREN:
            printf("Parenthesized:\n");
            print_ast(node->data.expr_paren.expr, indent + 1);
            break;
    }
}

// Function to free AST
void free_ast(ASTNode *node) {
    if (!node) return;
    switch (node->type) {
        case NODE_PROGRAM:
            for (int i = 0; i < node->data.program.statement_count; i++) {
                free_ast(node->data.program.statements[i]);
            }
            free(node->data.program.statements);
            break;
        case NODE_C_STATEMENT:
            free(node->data.c_statement.identifier);
            free_ast(node->data.c_statement.expr);
            break;
        case NODE_JS_STATEMENT:
            free(node->data.js_statement.identifier);
            free_ast(node->data.js_statement.expr);
            break;
        case NODE_EXPR_BINARY:
            free_ast(node->data.expr_binary.left);
            free_ast(node->data.expr_binary.right);
            break;
        case NODE_EXPR_PAREN:
            free_ast(node->data.expr_paren.expr);
            break;
        default:
            break;
    }
    free(node);
}

// Function to print Token Table
void print_token_table() {
    printf("\nToken Table\n");
    printf("%-20s %-20s %-10s\n", "Type", "Value", "Line");
    printf("----------------------------------------\n");
    for (int i = 0; i < token_table.count; i++) {
        printf("%-20s %-20s %-10d\n",
               token_table.entries[i].type,
               token_table.entries[i].value,
               token_table.entries[i].line);
    }
}

// Symbol table functions
Array *find_or_create_array(const char *name) {
    for (int i = 0; i < symbol_count; i++) {
        if (strcmp(symbol_table[i].name, name) == 0) {
            return symbol_table[i].array;
        }
    }
    if (symbol_count < MAX_SYMBOLS) {
        symbol_table[symbol_count].name = strdup(name);
        symbol_table[symbol_count].array = new_array();
        return symbol_table[symbol_count++].array;
    } else {
        yyerror("Symbol table full");
        return NULL;
    }
}

Array *find_array(const char *name) {
    for (int i = 0; i < symbol_count; i++) {
        if (strcmp(symbol_table[i].name, name) == 0) {
            return symbol_table[i].array;
        }
    }
    yyerror("Array not found");
    return NULL;
}
%}

%code requires {
    #include "array2.h"
}

%union {
    int num;
    char *str;
    Array *arr;
    ASTNode *node;
}

%token INT ARRAY PUSH POP PRINT PLUS MINUS MULT DIV ASSIGN SEMICOLON
%token LBRACKET RBRACKET LPAREN RPAREN LBRACE RBRACE NEWLINE COMMA
%token <num> NUMBER
%token <str> IDENTIFIER

%type <node> program statements statement c_statement js_statement expr

%left PLUS MINUS
%left MULT DIV

%%
program:
    statements {
        $$ = new_ast_node(NODE_PROGRAM);
        $$->data.program.statements = $1->data.program.statements;
        $$->data.program.statement_count = $1->data.program.statement_count;
        ast_root = $$;
    }
    ;

statements:
    /* empty */ {
        $$ = new_ast_node(NODE_PROGRAM);
        $$->data.program.statements = NULL;
        $$->data.program.statement_count = 0;
    }
    | statements statement {
        $$ = new_ast_node(NODE_PROGRAM);
        int count = $1->data.program.statement_count;
        $$->data.program.statements = realloc($1->data.program.statements,
                                             sizeof(ASTNode*) * (count + 1));
        if ($2) {
            $$->data.program.statements[count] = $2;
            $$->data.program.statement_count = count + 1;
        } else {
            $$->data.program.statements = $1->data.program.statements;
            $$->data.program.statement_count = count;
        }
    }
    ;

statement: 
    c_statement SEMICOLON { $$ = $1; }
    | js_statement SEMICOLON { $$ = $1; }
    | c_statement NEWLINE { $$ = $1; }
    | js_statement NEWLINE { $$ = $1; }
    | c_statement { $$ = $1; }
    | js_statement { $$ = $1; }
    ;

c_statement:
    INT IDENTIFIER ASSIGN expr {
        $$ = new_ast_node(NODE_C_STATEMENT);
        $$->data.c_statement.identifier = $2;
        $$->data.c_statement.expr = $4;
        printf("C-like: %s = %d\n", $2, $4->data.expr_number.value);
    }
    ;

js_statement:
    ARRAY IDENTIFIER ASSIGN LBRACKET RBRACKET {
        $$ = new_ast_node(NODE_JS_STATEMENT);
        $$->data.js_statement.js_type = JS_ARRAY_CREATE;
        $$->data.js_statement.identifier = $2;
        $$->data.js_statement.expr = NULL;
        Array *arr = find_or_create_array($2);
        printf("JS-like: Array %s created\n", $2);
    }
    | PUSH LPAREN IDENTIFIER COMMA expr RPAREN {
        $$ = new_ast_node(NODE_JS_STATEMENT);
        $$->data.js_statement.js_type = JS_PUSH;
        $$->data.js_statement.identifier = $3;
        $$->data.js_statement.expr = $5;
        Array *arr = find_array($3);
        if (arr) {
            push_array(arr, $5->data.expr_number.value);
            printf("JS-like: Pushed %d to array %s\n", $5->data.expr_number.value, $3);
        }
    }
    | POP LPAREN IDENTIFIER RPAREN {
        $$ = new_ast_node(NODE_JS_STATEMENT);
        $$->data.js_statement.js_type = JS_POP;
        $$->data.js_statement.identifier = $3;
        $$->data.js_statement.expr = NULL;
        Array *arr = find_array($3);
        if (arr) {
            int value = pop_array(arr);
            printf("JS-like: Popped %d from array %s\n", value, $3);
        }
    }
    | PRINT LPAREN IDENTIFIER RPAREN {
        $$ = new_ast_node(NODE_JS_STATEMENT);
        $$->data.js_statement.js_type = JS_PRINT;
        $$->data.js_statement.identifier = $3;
        $$->data.js_statement.expr = NULL;
        Array *arr = find_array($3);
        if (arr) {
            printf("JS-like: Array %s = ", $3);
            print_array(arr);
        }
    }
    ;

expr:
    NUMBER {
        $$ = new_ast_node(NODE_EXPR_NUMBER);
        $$->data.expr_number.value = $1;
    }
    | expr PLUS expr {
        $$ = new_ast_node(NODE_EXPR_BINARY);
        $$->data.expr_binary.op = '+';
        $$->data.expr_binary.left = $1;
        $$->data.expr_binary.right = $3;
        $$->data.expr_number.value = $1->data.expr_number.value + $3->data.expr_number.value;
    }
    | expr MINUS expr {
        $$ = new_ast_node(NODE_EXPR_BINARY);
        $$->data.expr_binary.op = '-';
        $$->data.expr_binary.left = $1;
        $$->data.expr_binary.right = $3;
        $$->data.expr_number.value = $1->data.expr_number.value - $3->data.expr_number.value;
    }
    | expr MULT expr {
        $$ = new_ast_node(NODE_EXPR_BINARY);
        $$->data.expr_binary.op = '*';
        $$->data.expr_binary.left = $1;
        $$->data.expr_binary.right = $3;
        $$->data.expr_number.value = $1->data.expr_number.value * $3->data.expr_number.value;
    }
    | expr DIV expr {
        $$ = new_ast_node(NODE_EXPR_BINARY);
        $$->data.expr_binary.op = '/';
        $$->data.expr_binary.left = $1;
        $$->data.expr_binary.right = $3;
        if ($3->data.expr_number.value == 0) {
            yyerror("Division by zero");
            $$->data.expr_number.value = 0;
        } else {
            $$->data.expr_number.value = $1->data.expr_number.value / $3->data.expr_number.value;
        }
    }
    | LPAREN expr RPAREN {
        $$ = new_ast_node(NODE_EXPR_PAREN);
        $$->data.expr_paren.expr = $2;
        $$->data.expr_number.value = $2->data.expr_number.value;
    }
    ;

%%
int main() {
    printf("CJFusion Parser\n");
    yyparse();
    printf("\nAbstract Syntax Tree:\n");
    print_ast(ast_root, 0);
    print_token_table();
    free_ast(ast_root);
    for (int i = 0; i < token_table.count; i++) {
        free(token_table.entries[i].type);
        free(token_table.entries[i].value);
    }
    free(token_table.entries);
    for (int i = 0; i < symbol_count; i++) {
        free(symbol_table[i].name);
        free(symbol_table[i].array->data);
        free(symbol_table[i].array);
    }
    return 0;
}

void yyerror(const char *s) {
    fprintf(stderr, "Error at line %d: %s\n", yylineno, s);
}