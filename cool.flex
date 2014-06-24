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



%}

/*
 * Define names for regular expressions here.
 */

%x COMMENT
%x STRING
%x INVALID_STRING

DARROW          =>

%%

"(*"			{ BEGIN COMMENT;  }
<COMMENT>"*)"		{ BEGIN INITIAL;  }
<COMMENT>[^*\n]+	{ 		  }
<COMMENT>"*"		{		  }
<COMMENT><<>>		{ BEGIN INITIAL;
			  cool_yylval.error_msg = "EOF in comment";
			  return ERROR;}
<COMMNET>\n		{ curr_lineno++;  }


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

<STRING>\\\		{ *string_buf_ptr++ = '\\'; }
<STRING>\\\n		{ *string_buf_ptr++ = '\n'; curr_lineno++;
			    }

<STRING>\n		{ 
			  BEGIN (INITIAL);
			  curr_lineno++;
			  cool_yylval.error_msg = "Unterminated string constant.";
			  return ERROR; }

<STRING>\0\"	  	{ 
			  BEGIN (INITIAL);
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

"class"		{ return CLASS; }

(?i:else)	{ return ELSE; }

"fi"		{ return FI; }
"if"		{ return IF; }
"in"		{ return IN; }
"inherits"	{ return INHERITS; }
"let"		{ return LET; }
"loop"		{ return LOOP; }
"pool"		{ return POOL; }
"then"		{ return THEN; }
"while"		{ return WHILE; }
"case"		{ return CASE; }
"esac"		{ return ESAC; }
"of"		{ return OF; }
"darrow"	{ return DARROW; }
"new"		{ return NEW; }
"isvoid"	{ return ISVOID; }
"str_const"	{ return STR_CONST; }
"int_const"	{ return INT_CONST; }

"bool_const"	{ return BOOL_CONST; }
(t(?i:rue))	{ cool_yylval.boolean = 1 ; return BOOL_CONST; }

"typeid"	{ return TYPEID; }
(T(?i:rue))	{ cool_yylval.symbol = idtable.add_string(yytext); return TYPEID; }

"objectid"	{ return OBJECTID; }
"assign"	{ return ASSIGN; }
"not"		{ return NOT; }
"le"		{ return LE; }
"error"		{ return ERROR; }
"let_stmt"	{ return LET_STMT; }
"{"		{ return '{'; }
"}"		{ return '}'; }
"("		{ return '('; }
")"		{ return ')'; }
";"		{ return ';'; }



 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

\n		{ curr_lineno++;	}
[ \t]		{			}

%%
