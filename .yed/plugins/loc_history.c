#include <yed/plugin.h>

#define inline static inline
#include <yed/tree.h>
typedef char *yedrc_path_t;
typedef struct loc_data{
    int row;
    int col;
    int can_update;
}loc_data_t;
use_tree(yedrc_path_t, loc_data_t);
#undef inline

void init_loc_history(yed_event *event);
void set_start_loc_from_history(yed_event *event);
void update_loc_history(yed_event *event);
void write_back_loc_history(yed_event *event);
void unload(yed_plugin *self);

tree(yedrc_path_t, loc_data_t) hist;
yed_event_handler h1;

int yed_plugin_boot(yed_plugin *self) {
    yed_event_handler h;

    YED_PLUG_VERSION_CHECK();

    yed_plugin_set_unload_fn(self, unload);
    hist = tree_make_c(yedrc_path_t, loc_data_t, strcmp);

    h1.kind = EVENT_BUFFER_PRE_LOAD;
    h1.fn   = init_loc_history;
    yed_plugin_add_event_handler(self, h1);

    h.kind = EVENT_BUFFER_POST_LOAD;
    h.fn   = set_start_loc_from_history;
    yed_plugin_add_event_handler(self, h);

    h.kind = EVENT_CURSOR_POST_MOVE;
    h.fn   = update_loc_history;
    yed_plugin_add_event_handler(self, h);

    h.kind = EVENT_PRE_QUIT;
    h.fn   = write_back_loc_history;
    yed_plugin_add_event_handler(self, h);

    return 0;
}

void init_loc_history(yed_event *event) {
    char line[512];
    char str[512];
    char app[512];

    strcpy(app, "/my_loc_history.txt");

    if (!ys->options.no_init) {
        if (ys->options.init) {
            abs_path(ys->options.init, str);
        } else {
            abs_path("~/.yed", str);
        }
        strcat(str, app);
    }

    FILE *fp;

    fp = fopen (str, "r");
    if (fp == NULL) {
        return;
    }

    const char s[2] = " ";
    char *tmp_path;
    char *tmp_row;
    char *tmp_col;
    while( fgets( line, 512, fp ) != NULL ) {
        tmp_path = strtok(line, s);
        tmp_row = strtok(NULL, s);
        tmp_col = strtok(NULL, s);

        loc_data_t tmp;
        tmp.row = atoi(tmp_row);
        tmp.col = atoi(tmp_col);
        tmp.can_update = 0;
        tree_insert(hist, strdup(tmp_path), tmp);
    }
    fclose(fp);
    yed_delete_event_handler(h1);
}

void set_start_loc_from_history(yed_event *event) {
    char file_name[512];
    loc_data_t tmp;
    yed_frame *frame;
    frame = event->frame;

    if (!frame
    ||  !event->buffer
    ||  event->buffer->kind != BUFF_KIND_FILE) {
        return;
    }

    tree_it(yedrc_path_t, loc_data_t) it;
    abs_path(event->path, file_name);

    it = tree_lookup(hist, file_name);
    if( tree_it_good(it) ) {
        tmp = tree_it_val(it);
        yed_set_cursor_within_frame(frame, tmp.row, tmp.col);
        tree_it_val(it).can_update = 1;
    }
}

void update_loc_history(yed_event *event) {
    char file_name[512];
    loc_data_t tmp;
    yed_frame *frame;
    frame = event->frame;


    if (!frame
    ||  !frame->buffer
    ||  frame->buffer->kind != BUFF_KIND_FILE) {
        return;
    }

    tree_it(yedrc_path_t, loc_data_t) it;
    abs_path(frame->buffer->path, file_name);

    it = tree_lookup(hist, file_name);
    if( tree_it_good(it) ) {
        if(!tree_it_val(it).can_update) {
            return;
        }
        tree_it_val(it).row = frame->cursor_line;
        tree_it_val(it).col = frame->cursor_col;
    }else{
        tmp.row = frame->cursor_line;
        tmp.col = frame->cursor_col;
        tmp.can_update = 1;
        tree_insert(hist, strdup(file_name), tmp);
    }
}

void write_back_loc_history(yed_event *event) {
    char str[512];
    char app[512];

    strcpy(app, "/my_loc_history.txt");

    if (!ys->options.no_init) {
        if (ys->options.init) {
            abs_path(ys->options.init, str);
        } else {
            abs_path("~/.yed", str);
        }
        strcat(str, app);
    }

    FILE *fp;

    fp = fopen (str, "w+");
    if (fp == NULL) {
        return;
    }

    tree_it(yedrc_path_t, loc_data_t) it;
    tree_traverse(hist, it) {
        fprintf(fp, "%s %d %d\n", tree_it_key(it), tree_it_val(it).row, tree_it_val(it).col);
    }
    fclose(fp);
}

void unload(yed_plugin *self) {
    tree_free(hist);
}
