#include <yed/plugin.h>
#include <yed/highlight.h>

void do_slide_run(yed_buffer *buff) {
    int  err;
    char cmd_buff[256];

    sprintf(cmd_buff, "$SHELL -c 'slide \"%s\" 2>&1 > /dev/null' 2>&1 > /dev/null &", buff->path);
    err = system(cmd_buff);
    if (err) {
        yed_cerr("failed to run '%s'", cmd_buff);
    }
}

void do_slide_run_if_not_running(yed_buffer *buff) {
    int running;

    running = !system("pgrep slide 2>&1 > /dev/null");

    if (running) {
        yed_cerr("slide is already running!");
        return;
    }

    do_slide_run(buff);
}

void do_slide_update(yed_buffer *buff) {
    int  err, running;

    running = !system("pgrep slide 2>&1 > /dev/null");

    if (!running) {
        yed_cerr("slide is not running!\n");
        yed_cprint("have you run the command 'slide-run'?");
        return;
    }

    err = system("pkill -HUP slide 2>&1 > /dev/null");
    if (err) {
        yed_cerr("failed to run 'pkill -HUP slide'");
    }
}

void slide_run(int n_args, char **args) {
    yed_frame  *frame;
    yed_buffer *buff;

    frame = ys->active_frame;

    if (!frame) {
        yed_cerr("no active frame");
        return;
    }

    buff = frame->buffer;

    if (!buff) {
        yed_cerr("active frame has no buffer");
        return;
    }

    if (buff->kind != BUFF_KIND_FILE
    ||  buff->flags & BUFF_SPECIAL
    ||  !buff->path
    ||  buff->ft != yed_get_ft("Slide")) {
        yed_cerr("buffer isn't a slide description file");
        return;
    }

    do_slide_run_if_not_running(buff);
}

void slide_update(int n_args, char **args) {
    yed_frame  *frame;
    yed_buffer *buff;

    frame = ys->active_frame;

    if (!frame) {
        yed_cerr("no active frame");
        return;
    }

    buff = frame->buffer;

    if (!buff) {
        yed_cerr("active frame has no buffer");
        return;
    }

    if (buff->kind != BUFF_KIND_FILE
    ||  buff->flags & BUFF_SPECIAL
    ||  !buff->path
    ||  buff->ft != yed_get_ft("Slide")) {
        yed_cerr("buffer isn't a slide description file");
        return;
    }

    do_slide_update(buff);
}

void slide_post_write_handler(yed_event *event);

int yed_plugin_boot(yed_plugin *self) {
    yed_event_handler post_write;

    post_write.kind = EVENT_BUFFER_POST_WRITE;
    post_write.fn   = slide_post_write_handler;
    yed_plugin_add_event_handler(self, post_write);

    yed_plugin_set_command(self, "slide-run",    slide_run);
    yed_plugin_set_command(self, "slide-update", slide_update);

    return 0;
}

void slide_post_write_handler(yed_event *event) {
    yed_buffer *buff;

    LOG_FN_ENTER();

    buff = event->buffer;

    if (buff->kind != BUFF_KIND_FILE
    ||  buff->flags & BUFF_SPECIAL
    ||  !buff->path
    ||  buff->ft != yed_get_ft("Slide")) {
        goto out;
    }

    do_slide_update(buff);

out:
    LOG_EXIT();
}
