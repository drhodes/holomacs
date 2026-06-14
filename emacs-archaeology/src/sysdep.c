#include "config.h"
/* Empty sysdep for Holomacs Oracle */
void init_all_sys_modes() {}
void reset_all_sys_modes() {}
void sys_suspend() {}
void croak() {}
int stuff_char() { return 0; }
void setup_pty() {}
void set_exclusive_use() {}
void wait_for_termination() {}
void child_setup_tty() {}
