#include <string.h>

#ifndef IN_YMAKEFILE
#define NO_UNION_TYPE

/* Holomacs Surgical Shims */
#define NO_ARG_ARRAY
typedef unsigned char GLYPH;
#define BLOCK_INPUT
#define UNBLOCK_INPUT
extern char *echo_area_glyphs;
extern int last_known_column_point;
extern char syntax_code_spec[];
#define LISP_FLOAT_TYPE
#define PATH_EXEC "/usr/bin"
#define TOTALLY_UNBLOCK_INPUT
#undef LOAD_AVE_TYPE
#define DISP_TABLE_SIZE 256

/* The Shimmering 64-bit Truth: Top-Bit Tagging */
#define Lisp_Object long
#define INTBITS 64
#define VALBITS 55
#define GCTYPEBITS 8

#define XTYPE(a) ((enum Lisp_Type) ((((unsigned long)(a)) >> 55) & 0xFFUL))
#define XPNTR(a) ((long)(a) & 0x007FFFFFFFFFFFFFL)
#define XUINT(a) ((long)(a) & 0x007FFFFFFFFFFFFFL)
#define XSET(var, type, ptr) ((var) = (((unsigned long)(type)) << 55) | XPNTR(ptr))
#define XSETTYPE(var, type) ((var) = (((unsigned long)(type)) << 55) | XPNTR(var))
#define XINT(a) (((long)(a) << 9) >> 9)
#define XFASTINT(a) (a)
#define XSETINT(var, i) ((var) = (long)(i) & 0x007FFFFFFFFFFFFFL)
#define MARKBIT (1L << 63)
#define XMARKBIT(a) ((a) < 0)
#define XSETMARKBIT(a,b) ((a) = ((a) & ~MARKBIT) | ((b) ? MARKBIT : 0))
#define XUNMARKBIT(a) ((a) &= ~MARKBIT)

#undef DATA_SEG_BITS
#undef PURE_SEG_BITS

extern long Vstandard_display_table;
extern long selected_screen;
#define SCREEN_WIDTH(s) 80
#define XSCREEN(s) (&holomacs_screen)
extern int holomacs_cursX;
extern int holomacs_cursY;
#define SCREEN_CURSOR_X(s) holomacs_cursX
#define SCREEN_CURSOR_Y(s) holomacs_cursY
#undef update_screen
#ifndef IN_DISPNEW
#define update_screen(...) 0
#endif
extern char holomacs_msgbuf[1024];
#define SCREEN_MESSAGE_BUF(s) holomacs_msgbuf
struct holomacs_screen_struct {
  int width;
  int height;
  int root_window;
};
extern struct holomacs_screen_struct holomacs_screen;
#define SCREEN_ROOT_WINDOW(s) (XSCREEN(s)->root_window)
#define screens 0
#define SCREEN_PTR struct holomacs_screen_struct *
#define PENDING_OUTPUT_COUNT(f) 0
extern struct matrix *current_screen;
extern struct matrix *new_screen;
extern struct matrix *temp_screen;
extern long (*calculate_costs_hook)();
extern unsigned char downcase_table[];
extern unsigned char upcase_table[];
struct buffer;
extern struct buffer *current_buffer;
extern int cursor_vpos;
extern int cursor_hpos;
extern int quit_char;
#define PATH_LOADSEARCH "/usr/share/emacs/lisp"
extern void (*fix_screen_hook)();
#define I_PUSH 0
#define TIOCSIGNAL 0
#define bzero(a,b) memset(a,0,b)
#define bcopy(a,b,c) memmove(b,a,c)
#define bcmp(a,b,c) memcmp(a,b,c)
struct matrix {
  int height, width;
  char *highlight;
  char *enable;
  unsigned char **contents;
  int *used;
  unsigned char *total_contents;
};
#define INFINITY 999999
extern int sys_nerr;
extern char *sys_errlist[];
extern int must_write_spaces;
extern int memory_below_screen;
extern int char_ins_del_ok;
extern int *DC_ICcost;
extern int screen_width;
extern int screen_height;
extern char *minibuf_prompt;
extern int minibuf_prompt_width;
extern int last_command_char;
extern int unread_command_char;
extern int windows_or_buffers_changed;
extern int update_mode_lines;
extern int unchanged_modified;
extern int beg_unchanged;
extern int end_unchanged;
extern int no_redraw_on_reenter;
extern int scroll_region_ok;
extern int dont_calculate_costs;
#define per_line_cost(s) 0
#define string_cost(s) 0
extern int (*read_socket_hook)();
extern int line_ins_del_ok;
extern int my_edata;

#define WIFSIGNALED(s) 0
#define WIFEXITED(s) 1
#define WTERMSIG(s) 0
#define WIFSTOPPED(s) 0
#define WSTOPSIG(s) 0
#define WCOREDUMP(s) 0

#define FROM_KBD 1
#define egetenv getenv

#endif /* IN_YMAKEFILE */
#ifndef IN_YMAKEFILE
#define PURESIZE 120000
#endif
#ifndef IN_YMAKEFILE
extern long Vminibuffer_list;
extern long Vctl_x_map;
extern long Vesc_map;
extern long Vctl_x_4_map;
extern long Vhelp_map;
extern long Vglobal_map;
extern long Qinhibit_quit;
#endif
#ifndef USER_FULL_NAME
#define USER_FULL_NAME (pw->pw_gecos)
#endif
#ifndef SYSTEM_TYPE
#define SYSTEM_TYPE "linux"
#endif
#ifndef SHORTBITS
#define SHORTBITS 16
#endif

/* Final 6 Stubs */
extern void get_screen_size();
extern void unrequest_sigio();
extern void request_sigio();
extern void setpgrp_of_tty();
extern void wait_without_blocking();
extern char* get_system_name();
