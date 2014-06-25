/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */
char *untmnt_msg = "Unterminated string constant";
int comment_loop = 0; 
%}

/*
 * Define names for regular expressions here.
 */

%x COMMENT
%x COMMENT_TYPEB
%x STRING
%x INVALID_STRING

DARROW          =>

%%
"--"			{ BEGIN COMMENT_TYPEB;}
<COMMENT_TYPEB>.	{			}
<COMMENT_TYPEB>\n	{ curr_lineno++;
			  BEGIN INITIAL;}
"(*"			{ BEGIN COMMENT; comment_loop++;  }
<COMMENT>"(*"		{ comment_loop++; }
<COMMENT>"*)"		{ comment_loop--;
			  if (comment_loop == 0)
			  {
				BEGIN INITIAL;
			  }  
			}

 /*<COMMENT>[^*\n]+	{ 		  }*/

<COMMENT><<EOF>>	{ BEGIN INITIAL;
			  cool_yylval.error_msg = "EOF in comment";
			  return ERROR;}
<COMMNET>\n		{ curr_lineno++;  }
<COMMENT>\.		{ 		  }
<COMMENT>.		{ 		  }


\"			{ string_buf_ptr = string_buf;  BEGIN (STRING); }
<STRING>\"		{ BEGIN (INITIAL);
			  *string_buf_ptr++ = '\0';
			  cool_yylval.symbol = stringtable.add_string(string_buf);
			  return STR_CONST;
			}

<STRING><<EOF>>		{ BEGIN (INITIAL);
			  cool_yylval.error_msg = "EOF in string constant";
			  return ERROR;
			  }
<STRING>"\0"		{
			  BEGIN (INVALID_STRING);
			  cool_yylval.error_msg = "String contains null character.";
			  *string_buf_ptr++ = '\0';
			  return ERROR;
			 }

<STRING>\\n		{ *string_buf_ptr++ = '\n'; curr_lineno++;  }
<STRING>\\t		{ *string_buf_ptr++ = '\t'; }
<STRING>\\b		{ *string_buf_ptr++ = '\b'; }
<STRING>\\f		{ *string_buf_ptr++ = '\f'; }
 /* comment line */

<STRING>\\		{ *string_buf_ptr++ = '\\'; }
<STRING>\\\n		{ *string_buf_ptr++ = '\n'; curr_lineno++;
			    }

<STRING>\n		{ 
			  BEGIN (INITIAL);
			  curr_lineno++;
			  cool_yylval.error_msg = "Unterminated string constant.";
			  return ERROR; }

<STRING>\\\0	  	{ 
			  BEGIN (INVALID_STRING);
			  cool_yylval.error_msg = "String contains escaped null character.";
			  return ERROR;
			}

<STRING>\\.		{ *string_buf_ptr++ = yytext[1];
			}


<STRING>[^\\\n\"|^\0]+	{ char *yptr = yytext;
			  while( *yptr ){
   			  	*string_buf_ptr++ = *yptr++;
    				}
  			} 

<INVALID_STRING>{

\"	{	BEGIN(INITIAL);	}

\n	{	curr_lineno++;	}

.	{			}

} 


 /*
  *  Nested comments
  */


 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

(?i:class)		{ return CLASS; }

(?i:else)		{ return ELSE; }

(?i:fi)			{ return FI; }
(?i:if)			{ return IF; }
(?i:in)			{ return IN; }
(?i:inherits)		{ return INHERITS; }
(?i:let)		{ return LET; }
(?i:loop)		{ return LOOP; }
(?i:pool)		{ return POOL; }
(?i:then)		{ return THEN; }
(?i:while)		{ return WHILE; }
(?i:case)		{ return CASE; }
(?i:esac)		{ return ESAC; }
(?i:of)			{ return OF; }
(?i:darrow)		{ return DARROW; }
(?i:new)		{ return NEW; }
(?i:isvoid)		{ return ISVOID; }
(?i:not)		{ return NOT; }
(?i:str_const)		{ return STR_CONST; }
(?i:int_const)		{ return INT_CONST; }
[0-9]+			{ cool_yylval.symbol = inttable.add_string(yytext);
			  return INT_CONST;}

(?i:bool_const)		{ return BOOL_CONST; }
(t(?i:rue)){1}		{ cool_yylval.boolean = 1 ; return BOOL_CONST; }
(f(?i:alse))		{ cool_yylval.boolean = 0 ; return BOOL_CONST; }

(?i:typeid)		  	{ return TYPEID; }
(T(?i:rue))			{ cool_yylval.symbol = idtable.add_string(yytext);
			 	  return TYPEID; 
			 	  }
(F(?i:alse))			{ cool_yylval.symbol = idtable.add_string(yytext);
			  	  return TYPEID;
			  	  }
(?-i:[A-Z])(?i:[a-z_]|[0-9])*	{ cool_yylval.symbol = idtable.add_string(yytext);
				  return TYPEID;
				  }


(?i:objectid)			{ return OBJECTID; }
(?-i:[a-z])(?i:[a-z_|0-9])*	{ cool_yylval.symbol = idtable.add_string(yytext);
			  	  return OBJECTID;
			  	  }




(?i:assign)		{ return ASSIGN; }
(?i:not)		{ return NOT; }
(?i:le)			{ return LE; }
(?i:error)		{ return ERROR; }
(?i:let_stmt)		{ return LET_STMT; }
"{"			{ return '{'; }
"}"			{ return '}'; }
"("			{ return '('; }
")"			{ return ')'; }
";"			{ return ';'; }
","			{ return ','; }
":"			{ return ':'; }
"@"			{ return '@'; }
"."			{ return '.'; }
"+"			{ return '+'; }
"*"			{ return '*'; }
"/"			{ return '/'; }
"-"			{ return '-'; }
"~"			{ return '~'; }
"<"			{ return '<'; }
"="			{ return '='; }
"<-"			{ return ASSIGN; }
"<="			{ return LE; }

"!" 			{ cool_yylval.error_msg = "!"; return ERROR; }
"#"			{ cool_yylval.error_msg = "#"; return ERROR; }
"$"			{ cool_yylval.error_msg = "$"; return ERROR; }
"%"			{ cool_yylval.error_msg = "%"; return ERROR; }
"^"			{ cool_yylval.error_msg = "^"; return ERROR; }
"&"			{ cool_yylval.error_msg = "&"; return ERROR; }
"_"			{ cool_yylval.error_msg = "_"; return ERROR; }
">"			{ cool_yylval.error_msg = ">"; return ERROR; }
"?"			{ cool_yylval.error_msg = "?"; return ERROR; }
"`"			{ cool_yylval.error_msg = "`"; return ERROR; }
"["			{ cool_yylval.error_msg = "["; return ERROR; }
"]"			{ cool_yylval.error_msg = "]"; return ERROR; }
\\			{ cool_yylval.error_msg = "\\" ; return ERROR; } 
"|"			{ cool_yylval.error_msg = "|"; return ERROR; }
[^\x20-x7E]		{ 
			   string_buf_ptr = string_buf;
			   char *yptr = yytext;
			   char test = 'a';
			   char len = 'a';
			   int i = 0;
			   int size;
			   char *error = NULL;
			   char *contains = "00";			

			   while( *yptr ){
   			  	*string_buf_ptr++ = *yptr++;
				len = strlen(string_buf);
				for(i = 0; i < len ; i++)
				{
					test = string_buf[i];
					printf("INVALID is %d\n", test);
					printf("Char is %c",'0'+test);
					len = '0'+test;

				}
				
				
    				}
			
			 }

"*)"			{ cool_yylval.error_msg = "Unmatched *)";
			  return ERROR; }




 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

\n		{ curr_lineno++;	}
[ \t]		{			}

%%

