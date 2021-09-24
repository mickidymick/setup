#include <yed/plugin.h>

void kammerdienerb_special_buffer_prepare_focus(int n_args, char **args);
void kammerdienerb_special_buffer_prepare_jump_focus(int n_args, char **args);
void kammerdienerb_special_buffer_prepare_unfocus(int n_args, char **args);
void kammerdienerb_quit(int n_args, char **args);
void kammerdienerb_write_quit(int n_args, char **args);
void kammerdienerb_go_menu(int n_args, char **args);
void kammerdienerb_go_menu_key_handler(yed_event *event);
void kammerdienerb_find_cursor_word(int n_args, char **args);

int go_menu_stay;

#define ARGS_SCRATCH_BUFF "*scratch", (BUFF_SPECIAL)
#define ARGS_GO_MENU_BUFF "*go-menu", (BUFF_SPECIAL | BUFF_RD_ONLY)

yed_buffer *get_or_make_buffer(char *name, int flags) {
    yed_buffer *buff;
LOG_FN_ENTER();

    if ((buff = yed_get_buffer(name)) == NULL) {
        buff = yed_create_buffer(name);
        yed_log("\ninit.c: created %s buffer", name);
    }
    buff->flags |= flags;

LOG_EXIT();
    return buff;
}

int yed_plugin_boot(yed_plugin *self) {
    yed_event_handler  go_menu_key;
    char              *term;
    char              *env_style;

    YED_PLUG_VERSION_CHECK();

    LOG_FN_ENTER();

    yed_log("init.c");
    yed_log("\n# ********************************************************");
    yed_log("\n# **  This is Zach McMichael's yed configuration  **");
    yed_log("\n# ********************************************************");

    yed_plugin_set_command(self, "special-buffer-prepare-focus",      kammerdienerb_special_buffer_prepare_focus);
    yed_plugin_set_command(self, "special-buffer-prepare-jump-focus", kammerdienerb_special_buffer_prepare_jump_focus);
    yed_plugin_set_command(self, "special-buffer-prepare-unfocus",    kammerdienerb_special_buffer_prepare_unfocus);
    yed_plugin_set_command(self, "qa",                                yed_default_command_quit);
    yed_log("\ninit.c: added overrides for 'special-buffer-prepare-*' commands");

    get_or_make_buffer(ARGS_SCRATCH_BUFF);
    get_or_make_buffer(ARGS_GO_MENU_BUFF);

    go_menu_key.kind = EVENT_KEY_PRESSED;
    go_menu_key.fn   = kammerdienerb_go_menu_key_handler;
    yed_plugin_add_event_handler(self, go_menu_key);

    yed_plugin_set_command(self, "go-menu", kammerdienerb_go_menu);
    yed_plugin_set_command(self, "kammerdienerb-find-cursor-word", kammerdienerb_find_cursor_word);

    YEXE("plugin-load", "yedrc");

    /*
     * Set things that need to be dynamic,
     * but allow yedrc to override.
     */
    if (!yed_term_says_it_supports_truecolor()) {
        yed_cerr("init.c: WARNING: terminal does not report that it supports truecolor\n"
                 "using truecolor anyways");
    }

    YEXE("set", "truecolor", "yes");

    if (file_exists_in_PATH("rg")) {
        yed_log("init.c: found an rg executable");
        YEXE("set", "grep-prg",      "rg --vimgrep '%' | sort");
        YEXE("set", "find-file-prg", "rg --files | rg '(^[^/]*%)|(/[^/]*%[^/]*$)' | sort");
    } else if (file_exists_in_PATH("fzf")) {
        yed_log("init.c: found a fzf executable");
        YEXE("set", "find-file-prg", "fzf --filter='%'");
    }

    if (getenv("DISPLAY") && file_exists_in_PATH("notify-send")) {
        yed_log("init.c: using desktop notifications for builder");
        YEXE("set", "builder-notify-command", "notify-send -i utilities-terminal yed %");
    }

    /* Load my yedrc file. */
    char *path;
    path = get_config_item_path("yedrc");
    YEXE("yedrc-load", path);
    free(path);

    /* Load style via environment var if set. */
    if ((term = getenv("TERM"))
    &&  strcmp(term, "linux") == 0) {
        yed_log("init.c: TERM = linux -- activating vt style\n");
        YEXE("style", "vt");
    } else if ((env_style = getenv("YED_STYLE"))) {
        yed_log("init.c: envirnoment variable YED_STYLE = %s -- activating\n", env_style);
        YEXE("style", env_style);
    }

    yed_plugin_set_command(self, "q",  kammerdienerb_quit);
    yed_plugin_set_command(self, "Q",  kammerdienerb_quit);
    yed_plugin_set_command(self, "wq", kammerdienerb_write_quit);
    yed_plugin_set_command(self, "Wq", kammerdienerb_write_quit);
    yed_log("\ninit.c: added overrides for 'q'/'Q' and 'wq'/'Wq' commands");

    LOG_EXIT();
    return 0;
}


/*
** Here's how I want this to behave (assuming a left/right split frame):
**
** If the left frame is currently active:
**    When the special buffer is focused, it appears in the right frame.
**    When jumping from the special buffer, it should go to the left frame.
**
** If the right frame is currently active:
**    If the special buffer is focused, it appears in the right frame.
**    When jumping from the special buffer _when it was focused from the right frame_,
**        it should go to the right frame.
**    Otherwise, jumps should go to the left frame.
*/

static int   stay_in_special_frame;
static char *reshow_buff_name;

void kammerdienerb_special_buffer_prepare_focus(int n_args, char **args) {
    yed_command     default_cmd;
    yed_frame      *frame;
    yed_frame_tree *tree;
    yed_frame_tree *root;
    yed_frame_tree *dest;

    stay_in_special_frame = 0;

    if (n_args != 1) {
        yed_cerr("expected 1 argument, but got %d", n_args);
        return;
    }

    if (ys->term_cols < (3 * ys->term_rows) && !yed_var_is_truthy("go-menu-force-split")) {
        default_cmd = yed_get_default_command("special-buffer-prepare-focus");
        if (default_cmd) {
            default_cmd(n_args, args);
            return;
        }
    }

    /* If there's no frames, make the two splits and focus the right one. */
    if (ys->active_frame == NULL) {
        YEXE("frame-new");
        YEXE("frame-vsplit");
        goto out;
    }

    frame = ys->active_frame;
    tree  = frame->tree;
    root  = yed_frame_tree_get_root(tree);

    /* Is this frame part of a tree that takes up the whole screen? */
    if (root->height == 1.0 && root->width == 1.0) {
        if (root == tree) {
            /* The frame takes up the whole screen. */
            YEXE("frame-vsplit");
        } else {
            /*
             * The frame we want to activate is always to the right
             * of the root, and all the way left until we find the leaf.
             */
            dest = root->child_trees[1];
            while (!dest->is_leaf) {
                dest = dest->child_trees[0];
            }

            yed_activate_frame(dest->frame);

            /*
             * If special-buffer focus was requested from the special frame,
             * then we want to stay here for any jumps.
             */
            stay_in_special_frame = dest->frame == frame;

            if (!stay_in_special_frame
            &&  dest->frame->buffer
            &&  dest->frame->buffer->name[0] != '*') {
                if (reshow_buff_name != NULL) {
                    free(reshow_buff_name);
                    reshow_buff_name = NULL;
                }
                reshow_buff_name = strdup(dest->frame->buffer->name);
            }
        }
    } else {
        /* Make a big one then. */
        YEXE("frame-new");
        YEXE("frame-vsplit");
    }

    /* In case I missed something. */
    if (ys->active_frame == NULL) {
        YEXE("frame-new");
    }

out:;
/*     yed_set_cursor_far_within_frame(ys->active_frame, 1, 1); */
}

void kammerdienerb_special_buffer_prepare_jump_focus(int n_args, char **args) {
    yed_command     default_cmd;
    yed_frame      *target;
    yed_frame      *frame;
    yed_frame_tree *tree;
    yed_frame_tree *root;
    yed_frame_tree *dest;

    if (n_args != 1) {
        yed_cerr("expected 1 argument, but got %d", n_args);
        return;
    }

    if (ys->term_cols < (3 * ys->term_rows) && !yed_var_is_truthy("go-menu-force-split")) {
        default_cmd = yed_get_default_command("special-buffer-prepare-jump-focus");
        if (default_cmd) {
            default_cmd(n_args, args);
            return;
        }
    }

    target = NULL;

    /*
     * If there aren't any frames, make the two splits and focus
     * the correct one.
     * This should never happen unless there's a bug somewhere.
     */
    if (ys->active_frame == NULL) {
        YEXE("frame-new");
        YEXE("frame-vsplit");
        if (!stay_in_special_frame) {
            YEXE("frame-prev");
        }
        goto out;
    }

    stay_in_special_frame = stay_in_special_frame ||
                            ((strcmp(args[0], "*go-menu") == 0)
                                && go_menu_stay);

    if (stay_in_special_frame) { goto out; }

    frame = ys->active_frame;
    tree  = frame->tree;
    root  = yed_frame_tree_get_root(tree);

    /*
     * The frame we want to activate is always to the left
     * of the root.
     */
    dest = root;
    while (!dest->is_leaf) {
        dest = dest->child_trees[0];
    }

    target = dest->frame;

    if (reshow_buff_name != NULL) {
        yed_frame_set_buff(frame, yed_get_buffer(reshow_buff_name));
    }

out:;
    if (reshow_buff_name != NULL) {
        free(reshow_buff_name);
        reshow_buff_name = NULL;
    }

    if (target == NULL) { target = ys->active_frame; }

    yed_frame_set_buff(target, NULL);
    yed_activate_frame(target);

    stay_in_special_frame = 0;
}

void kammerdienerb_special_buffer_prepare_unfocus(int n_args, char **args) {
    yed_command     default_cmd;
    yed_frame      *frame;
    yed_frame_tree *tree;
    yed_frame_tree *root;
    yed_frame_tree *dest;

    if (n_args != 1) {
        yed_cerr("expected 1 argument, but got %d", n_args);
        return;
    }

    if (ys->term_cols < (3 * ys->term_rows) && !yed_var_is_truthy("go-menu-force-split")) {
        default_cmd = yed_get_default_command("special-buffer-prepare-unfocus");
        if (default_cmd) {
            default_cmd(n_args, args);
            return;
        }
    }

    /*
     * If there aren't any frames, make the two splits and focus
     * the right one.
     * This should never happen unless there's a bug somewhere.
     */
    if (ys->active_frame == NULL) {
        YEXE("frame-new");
        YEXE("frame-vsplit");
        YEXE("frame-prev");
        goto out;
    }

    frame = ys->active_frame;
    tree  = frame->tree;
    root  = yed_frame_tree_get_root(tree);

    /*
     * The frame we want to activate is always to the left
     * of the root.
     */
    dest = root;
    while (dest && !dest->is_leaf) {
        dest = dest->child_trees[0];
    }

    yed_activate_frame(dest->frame);
out:;
    stay_in_special_frame = 0;
}

void kammerdienerb_quit(int n_args, char **args) {
    yed_frame      *frame;
    int             n_frames;
    yed_frame_tree *tree;

    /* 1 or 0 frames, just quit. */
    n_frames = array_len(ys->frames);
    if ((frame = ys->active_frame) == NULL
    ||  n_frames == 1) {
        YEXE("quit");
        return;
    }

    /* If we aren't in a 2-frame split situation, just delete the frame. */
    tree = frame->tree;
    if (n_frames != 2
    ||  tree->parent == NULL) {
        YEXE("frame-delete");
        return;
    }

    /*
     * Okay, it's a split.
     * If this frame is the left child, quit.
     * Otherwise, delete the frame.
     */
    if (tree == tree->parent->child_trees[0]) {
        YEXE("quit");
    } else {
        YEXE("frame-delete");
    }
}

void kammerdienerb_write_quit(int n_args, char **args) {
    YEXE("w");
    YEXE("q");
}

void kammerdienerb_go_menu(int n_args, char **args) {
    yed_buffer                                   *buff;
    tree_it(yed_buffer_name_t, yed_buffer_ptr_t)  bit;
    int                                           row;
    int                                           i;
    char                                         *bname;

    buff = get_or_make_buffer(ARGS_GO_MENU_BUFF);
    buff->flags &= ~BUFF_RD_ONLY;
    yed_buff_clear_no_undo(buff);

    row = 1;
    tree_traverse(ys->buffers, bit) {
        if (row > 1) {
            yed_buffer_add_line_no_undo(buff);
        }
        bname = tree_it_key(bit);
        for (i = 0; i < strlen(bname); i += 1) {
            yed_append_to_line_no_undo(buff, row, G(bname[i]));
        }
        row += 1;
    }

    /* add yedrc */
    if(yed_get_buffer_by_path("~/.config/yed/yedrc") == NULL) {
        if (row > 1) {
            yed_buffer_add_line_no_undo(buff);
        }
        bname = "~/.config/yed/yedrc";
        for (i = 0; i < strlen(bname); i += 1) {
            yed_append_to_line_no_undo(buff, row, G(bname[i]));
        }
    }
    row += 1;
    buff->flags |= BUFF_RD_ONLY;

    YEXE("special-buffer-prepare-focus", "*go-menu");
    if (ys->active_frame) {
        YEXE("buffer", "*go-menu");
    }
}

void kammerdienerb_go_menu_key_handler(yed_event *event) {
    yed_buffer *buff;
    yed_line   *line;
    char       *bname;

    buff = get_or_make_buffer(ARGS_GO_MENU_BUFF);

    if ((event->key != ENTER && event->key != CTRL_C)
    ||  ys->interactive_command
    ||  !ys->active_frame
    ||  ys->active_frame->buffer != buff) {
        return;
    }

    event->cancel = 1;

    if (event->key == ENTER) {
        line = yed_buff_get_line(buff, ys->active_frame->cursor_line);
        array_zero_term(line->chars);
        bname = array_data(line->chars);
        go_menu_stay = bname[0] == '*';
        YEXE("special-buffer-prepare-jump-focus", "*go-menu");
        YEXE("buffer", bname);
    } else {
        YEXE("special-buffer-prepare-unfocus", "*go-menu");

    }
}

void kammerdienerb_find_cursor_word(int n_args, char **args) {
    char *word;

    if (ys->current_search != NULL) {
        ys->current_search = NULL;
        ys->redraw = 1;
        return;
    }

    if (n_args != 0) {
        yed_cerr("expected 0 arguments, but got %d", n_args);
        return;
    }

    word = yed_word_under_cursor();

    if (word == NULL) {
        yed_cerr("cursor is not on a word");
        return;
    }

    YEXE("find-in-buffer", word);
    YEXE("find-prev-in-buffer");

    free(word);
}
