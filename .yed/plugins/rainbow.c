#include <yed/plugin.h>
#include <stdio.h>
#include <stdlib.h>

#define MAYBE_CONVERT(rgb) (tc ? (rgb) : rgb_to_256(rgb))


#define red        MAYBE_CONVERT(0x8B1E3F)
#define orange     MAYBE_CONVERT(0xDB4C40)
#define yellow     MAYBE_CONVERT(0xF0C987)
#define green      MAYBE_CONVERT(0x49C97C)
#define blue       MAYBE_CONVERT(0x38729a)
#define purple     MAYBE_CONVERT(0xB800B1)
#define dark_blue  MAYBE_CONVERT(0x0D1F2D)
#define light_sand MAYBE_CONVERT(0xE0C1B3)
#define cyan       MAYBE_CONVERT(0x3ABEFF)
#define pink       MAYBE_CONVERT(0xEF476F)
#define pure_red   MAYBE_CONVERT(0xFF0000)
#define grey       MAYBE_CONVERT(0x071424)

#define background      dark_blue
#define foreground      light_sand
#define srch            light_sand
#define srch_cursor     purple
#define attn            pure_red
#define assoc_bg        MAYBE_CONVERT(dark_blue + 0x111122)
#define status_bg       orange
#define sel_color       grey
#define comment         red
#define keyword         blue
#define pp_keyword      blue
#define call            green
#define constant        cyan
#define number          pink
#define string          yellow
#define character       yellow

void change_color(yed_event *event);

PACKABLE_STYLE(rainbow) {
    yed_style s;
    int       tc,
              attr_kind;

    YED_PLUG_VERSION_CHECK();

    yed_event_handler h;

    h.kind = EVENT_POST_PUMP;
    h.fn   = change_color;
    yed_plugin_add_event_handler(self, h);

    tc        = !!yed_get_var("truecolor");
    attr_kind = tc ? ATTR_RGB : ATTR_256;

    memset(&s, 0, sizeof(s));

    s.active.flags            = attr_kind;
    s.active.fg               = foreground;
    s.active.bg               = background;

    s.inactive.flags          = attr_kind;
    s.inactive.fg             = foreground;
    s.inactive.bg             = background;

    s.active_border           = s.active;
    s.active_border.fg        = status_bg;
    s.inactive_border         = s.inactive;

    s.cursor_line.flags       = attr_kind;
    s.cursor_line.fg          = foreground;
    s.cursor_line.bg          = sel_color;

    s.search.flags            = attr_kind | ATTR_INVERSE;
    s.search.fg               = srch;

    s.search_cursor.flags     = attr_kind | ATTR_INVERSE;
    s.search_cursor.fg        = srch_cursor;

    s.selection.flags         = attr_kind;
    s.selection.fg            = foreground;
    s.selection.bg            = sel_color;

    s.attention.flags         = attr_kind | ATTR_BOLD;
    s.attention.fg            = attn;

    s.associate.flags         = attr_kind | ATTR_BOLD;
    s.associate.bg            = assoc_bg;

    s.command_line            = s.active;

    s.status_line.flags       = attr_kind | ATTR_BOLD;
    s.status_line.fg          = foreground;
    s.status_line.bg          = status_bg;

    s.active_gutter           = s.active;
    s.inactive_gutter         = s.inactive;

    s.code_comment.flags      = attr_kind;
    s.code_comment.fg         = comment;

    s.code_keyword.flags      = attr_kind | ATTR_BOLD;
    s.code_keyword.fg         = keyword;

    s.code_control_flow       =
    s.code_typename           = s.code_keyword;

    s.code_preprocessor.flags = attr_kind | ATTR_BOLD;
    s.code_preprocessor.fg    = pp_keyword;

    s.code_fn_call.flags      = attr_kind;
    s.code_fn_call.fg         = call;

    s.code_number.flags       = attr_kind;
    s.code_number.fg          = number;

    s.code_constant.flags     = attr_kind;
    s.code_constant.fg        = constant;

    s.code_string.flags       = attr_kind;
    s.code_string.fg          = string;

    s.code_character.flags    = attr_kind;
    s.code_character.fg       = character;

    yed_plugin_set_style(self, "rainbow", &s);

    return 0;
}

void change_color(yed_event *event) {
    time_t t;
    srand((unsigned) time(&t));

    yed_style *s = yed_get_active_style();

    s->active.fg               = ((rand() % 255) | ((rand() % 255) << 8) | ((rand() % 255) << 16));
    s->active.bg               = ((rand() % 255) | ((rand() % 255) << 8) | ((rand() % 255) << 16));
    s->inactive.fg             = ((rand() % 255) | ((rand() % 255) << 8) | ((rand() % 255) << 16));
    s->inactive.bg             = ((rand() % 255) | ((rand() % 255) << 8) | ((rand() % 255) << 16));
    s->active_border.fg        = ((rand() % 255) | ((rand() % 255) << 8) | ((rand() % 255) << 16));
    s->cursor_line.fg          = ((rand() % 255) | ((rand() % 255) << 8) | ((rand() % 255) << 16));
    s->cursor_line.bg          = ((rand() % 255) | ((rand() % 255) << 8) | ((rand() % 255) << 16));
    s->search.fg               = ((rand() % 255) | ((rand() % 255) << 8) | ((rand() % 255) << 16));
    s->search_cursor.fg        = ((rand() % 255) | ((rand() % 255) << 8) | ((rand() % 255) << 16));
    s->selection.fg            = ((rand() % 255) | ((rand() % 255) << 8) | ((rand() % 255) << 16));
    s->selection.bg            = ((rand() % 255) | ((rand() % 255) << 8) | ((rand() % 255) << 16));
    s->attention.fg            = ((rand() % 255) | ((rand() % 255) << 8) | ((rand() % 255) << 16));
    s->associate.bg            = ((rand() % 255) | ((rand() % 255) << 8) | ((rand() % 255) << 16));
    s->status_line.fg          = ((rand() % 255) | ((rand() % 255) << 8) | ((rand() % 255) << 16));
    s->status_line.bg          = ((rand() % 255) | ((rand() % 255) << 8) | ((rand() % 255) << 16));
    s->code_comment.fg         = ((rand() % 255) | ((rand() % 255) << 8) | ((rand() % 255) << 16));
    s->code_keyword.fg         = ((rand() % 255) | ((rand() % 255) << 8) | ((rand() % 255) << 16));
    s->code_preprocessor.fg    = ((rand() % 255) | ((rand() % 255) << 8) | ((rand() % 255) << 16));
    s->code_fn_call.fg         = ((rand() % 255) | ((rand() % 255) << 8) | ((rand() % 255) << 16));
    s->code_number.fg          = ((rand() % 255) | ((rand() % 255) << 8) | ((rand() % 255) << 16));
    s->code_constant.fg        = ((rand() % 255) | ((rand() % 255) << 8) | ((rand() % 255) << 16));
    s->code_string.fg          = ((rand() % 255) | ((rand() % 255) << 8) | ((rand() % 255) << 16));
    s->code_character.fg       = ((rand() % 255) | ((rand() % 255) << 8) | ((rand() % 255) << 16));
}
