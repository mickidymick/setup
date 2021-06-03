#include <yed/plugin.h>

#define inline static inline
#include <yed/tree.h>
typedef char *yedrc_path_t;
typedef struct loc_data{
    int row;
    int col;
}loc_data_t;
use_tree(yedrc_path_t, loc_data_t);
#undef inline

void update_start_loc_from_history(yed_event *event);
void update_loc_history(yed_event *event);
void unload(yed_plugin *self);

tree(yedrc_path_t, loc_data_t) hist;

int yed_plugin_boot(yed_plugin *self) {
    yed_event_handler h;

    YED_PLUG_VERSION_CHECK();

    yed_plugin_set_unload_fn(self, unload);
    hist = tree_make_c(yedrc_path_t, loc_data, strcmp);

    h.kind = EVENT_BUFFER_PRE_LOAD;
    h.fn   = update_start_loc_from_history;
    yed_plugin_add_event_handler(self, h);

    h.kind = EVENT_CURSOR_MOVED;
    h.fn   = update_loc_history;
    yed_plugin_add_event_handler(self, h);

    return 0;
}

void update_start_loc_from_history(yed_event *event) {
    char str[512];
    char app[512];
    char file_name[512];

    if( ys->active_frame->buffer->flags & BUFF_SPECIAL ){
        LOG_EXIT();
        return;
    }

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
        LOG_EXIT();
        return;
    }

    char *buffer = 0;
    long length;

    fseek(fp, 0, SEEK_END);
    length = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    buffer = malloc(length);
    if (buffer)
    {
        fread(buffer, 1, length, fp);
    }
    fclose(fp);

    abs_path(ys->active_frame->buffer->path, file_name);

    //go through and add lines to tree


    /*
    char *substr;
    substr = strstr(buffer, file_name);
    if ( substr != NULL ) {

    }else{

    }
    */

}

void update_loc_history(yed_event *event) {
    tree_it(yedrc_path_t, loc_data_t);
}

void unload(yed_plugin *self) {
    tree_free(hist);
}
