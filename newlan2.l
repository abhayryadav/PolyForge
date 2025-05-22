%{
#include "newlan2.tab.h"
#include <stdlib.h>
#include <string.h>
#include "array2.h"

// Global Token Table
TokenTable token_table = { NULL, 0, 0 };

void add_token(const char *type, const char *value, int line) {
    if (token_table.count >= token_table.capacity) {
        token_table.capacity = token_table.capacity ? token_table.capacity * 2 : 10;
        token_table.entries = realloc(token_table.entries, sizeof(TokenEntry) * token_table.capacity);
    }
    TokenEntry *entry = &token_table.entries[token_table.count++];
    entry->type = strdup(type);
    entry->value = value ? strdup(value) : strdup("");
    entry->line = line;
}
%}

%option noyywrap
%option yylineno

%%
[0-9]+          { yylval.num = atoi(yytext); add_token("NUMBER", yytext, yylineno); return NUMBER; }
"int"           { add_token("INT", NULL, yylineno); return INT; }
"array"         { add_token("ARRAY", NULL, yylineno); return ARRAY; }
"push"          { add_token("PUSH", NULL, yylineno); return PUSH; }
"pop"           { add_token("POP", NULL, yylineno); return POP; }
"print"         { add_token("PRINT", NULL, yylineno); return PRINT; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.str = strdup(yytext); add_token("IDENTIFIER", yytext, yylineno); return IDENTIFIER; }
"+"             { add_token("PLUS", NULL, yylineno); return PLUS; }
"-"             { add_token("MINUS", NULL, yylineno); return MINUS; }
"*"             { add_token("MULT", NULL, yylineno); return MULT; }
"/"             { add_token("DIV", NULL, yylineno); return DIV; }
"="             { add_token("ASSIGN", NULL, yylineno); return ASSIGN; }
";"             { add_token("SEMICOLON", NULL, yylineno); return SEMICOLON; }
"["             { add_token("LBRACKET", NULL, yylineno); return LBRACKET; }
"]"             { add_token("RBRACKET", NULL, yylineno); return RBRACKET; }
"("             { add_token("LPAREN", NULL, yylineno); return LPAREN; }
")"             { add_token("RPAREN", NULL, yylineno); return RPAREN; }
"{"             { add_token("LBRACE", NULL, yylineno); return LBRACE; }
"}"             { add_token("RBRACE", NULL, yylineno); return RBRACE; }
","             { add_token("COMMA", NULL, yylineno); return COMMA; }
\n              { add_token("NEWLINE", NULL, yylineno); return NEWLINE; }
[ \t]           { /* ignore whitespace */ }
.               { printf("Unknown character: %s\n", yytext); add_token("UNKNOWN", yytext, yylineno); }
%%