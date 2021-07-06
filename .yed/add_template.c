#include <yed/plugin.h>

void set_template(int nargs, char** args);

int yed_plugin_boot(yed_plugin *self) {

    YED_PLUG_VERSION_CHECK();

    yed_plugin_set_command(self, "set-template", set_template);

    return 0;
}

void set_template(int nargs, char** args) {
    char line[512];
    char str[512];
    char app[512];
    yed_frame *frame;

    frame = ys->active_frame;

    if (!frame
    ||  !frame->buffer
    ||  frame->buffer->kind != BUFF_KIND_FILE) {
        return;
    }

    if(nargs != 1) {
        yed_log("Must have the template name as an argument you gave %d args\n", nargs);
        LOG_EXIT();
        return;
    }
    strcpy(app, "/");
    strcat(app, args[0]);
    strcat(app, ".txt");

    if (!ys->options.no_init) {
        if (ys->options.init) {
            abs_path(ys->options.init, str);
        } else {
            abs_path("~/.yed/templates/", str);
        }
        strcat(str, app);
    }

    yed_log("file: %s\n", str);

    FILE *fp;

    fp = fopen (str, "r");
    if (fp == NULL) {
        LOG_EXIT();
        return;
    }

    yed_log("  \n");
    const char s[2] = " ";
    char *tmp_path;
    char *tmp_row;
    char *tmp_col;

    int start_row = frame->buffer->last_cursor_row;
    while( fgets( line, 512, fp ) != NULL ) {
        yed_log("line:%s", line);
/*         yed_buff_insert_line_no_undo(frame->buffer, start_row); */
        yed_log("last row:%d\n", start_row);
        start_row++;
        yed_buff_insert_string_no_undo(frame->buffer, line, start_row, 1);
    }
    fclose(fp);

    LOG_EXIT();

}
