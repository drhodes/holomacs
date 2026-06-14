#include "config.h"
#include <sys/types.h>
#include <sys/time.h>
#include <unistd.h>

/* Use the Lisp_Object type defined in config.h/lisp.h */
#define Lisp_Object long

/* Globals */
int holomacs_cursX = 0;
int holomacs_cursY = 0;
char holomacs_msgbuf[1024];
int holomacs_root_window = 0;
Lisp_Object Vstandard_display_table = 0;
Lisp_Object selected_screen = 0;
int last_known_column_point = 0;
char *echo_area_glyphs = 0;
int cursor_vpos = 0;
int cursor_hpos = 0;
int quit_char = 0;
Lisp_Object Qinhibit_quit = 0;
void (*fix_screen_hook)() = 0;
long (*calculate_costs_hook)() = 0;
struct holomacs_screen_struct holomacs_screen = {80, 24, 0};
int screen_width = 80;
int screen_height = 24;
Lisp_Object Vglobal_map = 0;
Lisp_Object Vminibuffer_list = 0;
Lisp_Object Vctl_x_map = 0;
Lisp_Object Vesc_map = 0;
Lisp_Object Vctl_x_4_map = 0;
Lisp_Object Vhelp_map = 0;
char *minibuf_prompt = 0;
int minibuf_prompt_width = 0;
Lisp_Object Vhelp_form = 0;
Lisp_Object Vcurrent_prefix_arg = 0;
int last_command_char = 0;
int unread_command_char = 0;
int windows_or_buffers_changed = 0;
int update_mode_lines = 0;
int unchanged_modified = 0;
int beg_unchanged = 0;
int end_unchanged = 0;
int no_redraw_on_reenter = 0;
int scroll_region_ok = 0;
int dont_calculate_costs = 0;
int (*read_socket_hook)() = 0;
int line_ins_del_ok = 0;
int my_edata = 0;
struct matrix *current_screen = 0;
struct matrix *new_screen = 0;
struct matrix *temp_screen = 0;
struct buffer *current_buffer = 0;
int sys_nerr = 0;
char *sys_errlist[1] = {0};
int must_write_spaces = 0;
int memory_below_screen = 0;
int char_ins_del_ok = 0;
int *DC_ICcost = 0;

/* Terminal Functions */
void update_begin() {}
void update_end() {}
void set_terminal_window() {}
void ins_del_lines() {}
void calculate_costs() {}
void ring_bell() {}
void term_init() {}
void set_terminal_modes() {}
void reset_terminal_modes() {}
void move_cursor() {}
void clear_screen() {}
void clear_end_of_line() {}
void output_chars() {}
void insert_chars() {}
void delete_chars() {}
void cmputc() {}

/* File/Lock Functions */
void lock_file() {}
void unlock_file() {}
void unlock_all_files() {}
void unlock_buffer() {}
void Funlock_buffer() {}

/* Lisp Environment/Execution */
void reorder_modifiers() {}
void bitch_at_user() {}
void BufferSafeCeiling() {}
void BufferSafeFloor() {}
void filemodestring() {}
unsigned char * holomacs_egetenv() { return 0; }
void malloc_init() {}
void init_environ() {}
void syms_of_environ() {}
void syms_of_filelock() {}
void syms_of_mocklisp() {}
void fatal() {}
int size_of_current_environ() { return 0; }
void get_current_environ() {}
void ml_apply() {}
void read_char() {}
void unexec() {}
void reassert_line_highlight() {}
void change_line_highlight() {}

/* Sysdep Functions */
void discard_tty_input() {}
void init_baud_rate() {}
void init_sys_modes() {}
int tabs_safe_p() { return 1; }
void reset_sys_modes() {}
int holomacs_select(int nfds, fd_set *rfds, fd_set *wfds, fd_set *efds, struct timeval *timeout) { return 0; }
int old_gtty;

/* Missing Core Functions */
void get_screen_size() {}
void unrequest_sigio() {}
void request_sigio() {}
void setpgrp_of_tty() {}
void wait_without_blocking() {}
char* get_system_name() { return "linux"; }

/* Missing Wait Status for 64-bit */
int holomacs_wait_status;
