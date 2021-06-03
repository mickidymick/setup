#include <yed/plugin.h>

void completer_auto_match_buff_post_insert_handler(yed_event *event);
void remover_auto_match_buff_pre_delete_back_handler(yed_event *event);
void remover_auto_match_buff_post_delete_back_handler(yed_event *event);

int do_delete_match;

int yed_plugin_boot(yed_plugin *self) {
    yed_event_handler h;

    YED_PLUG_VERSION_CHECK();

    h.kind = EVENT_BUFFER_POST_INSERT;
    h.fn   = completer_auto_match_buff_post_insert_handler;
    yed_plugin_add_event_handler(self, h);

    h.kind = EVENT_BUFFER_PRE_DELETE_BACK;
    h.fn   = remover_auto_match_buff_pre_delete_back_handler;
    yed_plugin_add_event_handler(self, h);

    h.kind = EVENT_BUFFER_POST_DELETE_BACK;
    h.fn   = remover_auto_match_buff_post_delete_back_handler;
    yed_plugin_add_event_handler(self, h);

    return 0;
}

void completer_auto_match_buff_post_insert_handler(yed_event *event) {
    yed_frame *frame;
    int save_col;
    int save_row;
    char match = 0;

    if ( event->key == '(' ) {
        if ( !yed_var_is_truthy("disable-auto-paren") ) {
            match = ')';
        }
    } else if ( event->key == '[' ) {
        if ( !yed_var_is_truthy("disable-auto-bracket") ) {
            match = ']';
        }
    } else if ( event->key == '"' ) {
        if ( !yed_var_is_truthy("disable-auto-dquote") ) {
            match = '"';
        }
    } else if ( event->key == '\'' ) {
        if ( !yed_var_is_truthy("disable-auto-quote") ) {
            match = '\'';
        }
    } else if ( event->key == '{' ) {
        if ( !yed_var_is_truthy("disable-auto-brace") ) {
            match = '}';
        }
    }

    if ( match == 0 ) return;

    if ( !event->frame ) {
        return;
    }

    if ( !event->frame->buffer ) {
        return;
    }

    frame = event->frame;

    save_col = frame->cursor_col;
    save_row = frame->cursor_line;

    if (match == '}') {
        yed_line *line;
        int       i, j, brace_col, tabw;

        tabw = yed_get_tab_width();

        if (tabw <= 0) {
            return;
        }

        line = yed_buff_get_line(frame->buffer, frame->cursor_line);
        if (!line)    { return; }

        brace_col = frame->cursor_col - 1;

        i = 0;

        while (i < brace_col
        &&     yed_line_col_to_glyph(line, i + 1)->c == ' ') {
            i += 1;
        }

        yed_buff_insert_line(frame->buffer, save_row+1);
        yed_buff_insert_line(frame->buffer, save_row+2);

        for (j=0; j<i; j++){
            yed_append_to_line(frame->buffer, save_row+2, G(' '));
        }
        yed_append_to_line(frame->buffer, save_row+2, G('}'));

        for (j=0; j<i+tabw; j++){
            yed_append_to_line(frame->buffer, save_row+1, G(' '));
        }

        yed_set_cursor_within_frame(frame, save_row+1, j+1);

        return;
    }

    yed_insert_into_line(frame->buffer, save_row, save_col, G(match));
}

void remover_auto_match_buff_pre_delete_back_handler(yed_event *event) {
    yed_frame *frame;
    int save_col;
    int save_row;
    char match = 0;
    char key_first = 0;
    char key_second = 0;

    if ( !event->frame ) {
        return;
    }

    if ( !event->frame->buffer ) {
        return;
    }

    if ( event->frame->buffer->has_selection ) {
        return;
    }

    frame = event->frame;
    save_col = frame->cursor_col;
    save_row = frame->cursor_line;

    if ( save_col == 1 ) {
        return;
    }

    key_first = yed_buff_get_glyph(event->frame->buffer, save_row, save_col-1)->c;
    key_second = yed_buff_get_glyph(event->frame->buffer, save_row, save_col)->c;

    if ( key_first == '(' ) {
        if ( !yed_var_is_truthy("disable-auto-paren") ) {
            match = ')';
        }
    } else if ( key_first == '[' ) {
        if ( !yed_var_is_truthy("disable-auto-bracket") ) {
            match = ']';
        }
    } else if ( key_first == '"' ) {
        if ( !yed_var_is_truthy("disable-auto-dquote") ) {
            match = '"';
        }
    } else if ( key_first == '\'' ) {
        if ( !yed_var_is_truthy("disable-auto-quote") ) {
            match = '\'';
        }
    }

    if ( match != key_second ) {
        return;
    }

    if ( match == 0 ) return;

    do_delete_match = 1;
}

void remover_auto_match_buff_post_delete_back_handler(yed_event *event){
    if ( !do_delete_match ) {
        return;
    }

    YEXE("delete-forward");

    do_delete_match = 0;
}
