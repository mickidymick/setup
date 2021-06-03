#include <yed/plugin.h>
#include <yed/highlight.h>

#define ARRAY_LOOP(a) for (__typeof((a)[0]) *it = (a); it < (a) + (sizeof(a) / sizeof((a)[0])); ++it)

highlight_info hinfo1;
highlight_info hinfo2;

void unload(yed_plugin *self);
void syntax_slide_line_handler(yed_event *event);

int yed_plugin_boot(yed_plugin *self) {
    yed_event_handler line;
    char *commands[] = {
        "point",
        "speed",
        "resolution",
        "begin",
        "end",
        "use",
        "include",
        "font",
        "size",
        "bold",
        "italic",
        "underline",
        "bg",
        "bgx",
        "fg",
        "fgx",
        "margin",
        "lmargin",
        "rmargin",
        "ljust",
        "cjust",
        "rjust",
        "vspace",
        "vfill",
        "bullet",
        "image",
        "translate",
    };
    char *constants[] = {
        "inf",
        "infin",
        "infinity",
    };

    yed_plugin_set_unload_fn(self, unload);

    highlight_info_make(&hinfo1);

    /* Ew.. This is sooo goofy. */
    highlight_within(&hinfo1, "begin ", "foobarbaz", 0, -1, HL_CALL);
    highlight_within(&hinfo1, "use ", "foobarbaz", 0, -1, HL_CALL);


    highlight_info_make(&hinfo2);

    highlight_numbers(&hinfo2);
    highlight_to_eol_from(&hinfo2, "#", HL_COMMENT);
    highlight_within(&hinfo2, "\"", "\"", '\\', -1, HL_STR);
    highlight_within(&hinfo2, "'", "'", '\\', -1, HL_STR);

    ARRAY_LOOP(commands)
        highlight_add_kwd(&hinfo2, *it, HL_KEY);
    /* Ew.. This is sooo goofy. (part 2) */
    highlight_within(&hinfo2, "font-bold-itali", "c", 0, 0, HL_KEY);
    highlight_within(&hinfo2, "font-bol", "d",        0, 0, HL_KEY);
    highlight_within(&hinfo2, "font-itali", "c",      0, 0, HL_KEY);
    highlight_within(&hinfo2, "no-bol", "d",          0, 0, HL_KEY);
    highlight_within(&hinfo2, "no-itali", "c",        0, 0, HL_KEY);
    highlight_within(&hinfo2, "no-underlin", "e",     0, 0, HL_KEY);
    ARRAY_LOOP(constants)
        highlight_add_kwd(&hinfo2, *it, HL_CON);

    line.kind = EVENT_LINE_PRE_DRAW;
    line.fn   = syntax_slide_line_handler;
    yed_plugin_add_event_handler(self, line);

    ys->redraw = 1;

    return 0;
}

void unload(yed_plugin *self) {
    highlight_info_free(&hinfo2);
    highlight_info_free(&hinfo1);
    ys->redraw = 1;
}

void syntax_slide_line_handler(yed_event *event) {
    yed_frame *frame;
    yed_line  *line;

    frame = event->frame;

    if (!frame
    ||  !frame->buffer
    ||  frame->buffer->kind != BUFF_KIND_FILE
    ||  frame->buffer->ft != yed_get_ft("Slide")) {
        return;
    }

    line = yed_buff_get_line(frame->buffer, event->row);

    /* Only highlight lines that start with ':'. */
    if (line->visual_width == 0
    ||  yed_line_col_to_glyph(line, 1)->c != ':') {
        return;
    }

    highlight_line(&hinfo1, event);
    highlight_line(&hinfo2, event);
}
