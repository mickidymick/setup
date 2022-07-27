#include <yed/plugin.h>

static array_t extra_extensions;

void unload(yed_plugin *self);
void maybe_change_ft(yed_buffer *buff);
void maybe_change_ft_event(yed_event *event);

static void _add_extra_extensions(void);

int yed_plugin_boot(yed_plugin *self) {
    tree_it(yed_buffer_name_t, yed_buffer_ptr_t) bit;
    yed_event_handler                            buff_post_load_handler;
    yed_event_handler                            buff_pre_write_handler;

    YED_PLUG_VERSION_CHECK();

    if (yed_get_var("lang-bpftrace-extensions") == NULL) {
        yed_set_var("lang-bpftrace-extensions", "");
    }

LOG_FN_ENTER();
    yed_plugin_set_unload_fn(self, unload);

    if (yed_plugin_make_ft(self, "BPF") == FT_ERR_TAKEN) {
        yed_cerr("lang/s: unable to create file type name");
        LOG_EXIT();
        return 1;
    }

    buff_post_load_handler.kind = EVENT_BUFFER_POST_LOAD;
    buff_post_load_handler.fn   = maybe_change_ft_event;
    buff_pre_write_handler.kind = EVENT_BUFFER_PRE_WRITE;
    buff_pre_write_handler.fn   = maybe_change_ft_event;

    yed_plugin_add_event_handler(self, buff_post_load_handler);
    yed_plugin_add_event_handler(self, buff_pre_write_handler);

    tree_traverse(ys->buffers, bit) {
        maybe_change_ft(tree_it_val(bit));
    }

LOG_EXIT();
    return 0;
}

static void _add_extra_extensions(void) {
    char       *token;
    char       *tmp;
    const char  s[2] = " ";

    if (array_len(extra_extensions) > 0) {
        array_clear(extra_extensions);
    }
    extra_extensions = array_make(char *);
    token = strtok(yed_get_var("lang-bpftrace-extensions"), s);
    while(token != NULL) {
        tmp = strdup(token);
        array_push(extra_extensions, tmp);
        token = strtok(NULL, s);
    }
}

void unload(yed_plugin *self) {}

void maybe_change_ft(yed_buffer *buff) {
    const char *ext;
    char **extension;

    _add_extra_extensions();

    if (buff->ft != FT_UNKNOWN) {
        return;
    }
    if (buff->path == NULL) {
        return;
    }
    if ((ext = get_path_ext(buff->path)) == NULL) {
        return;
    }

    array_traverse(extra_extensions, extension) {
        if (strcmp(ext, (*extension)) == 0) {
            yed_buffer_set_ft(buff, yed_get_ft("BPF"));
            break;
        }
    }
}

void maybe_change_ft_event(yed_event *event) {
    if (event->buffer) {
        maybe_change_ft(event->buffer);
    }
}
