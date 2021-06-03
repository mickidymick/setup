#include <yed/plugin.h>

#include <stdio.h>
#include <ctype.h>
#include <unistd.h>

void mk_src_pair(int n_args, char **args) {
    char  hpath[256];
    char  cpath[256];
    FILE *fh;
    FILE *fc;
    char  upper[128];
    char *upper_p;
    int   i;

    if (n_args != 1) {
        yed_cerr("expected 1 argument, but got %d", n_args);
        return;
    }

    sprintf(hpath, "src/%s.h", args[0]);
    sprintf(cpath, "src/%s.c", args[0]);

    if (access("src", F_OK) != 0) {
        yed_cerr("no src directory -- cancelling", hpath);
        return;
    }
    if (access(hpath, F_OK) == 0) {
        yed_cerr("file '%s' already exists -- cancelling", hpath);
        return;
    }
    if (access(cpath, F_OK) == 0) {
        yed_cerr("file '%s' already exists -- cancelling", cpath);
        return;
    }


    upper_p = upper;
    for (i = 0; i < strlen(args[0]); i += 1) {
        *(upper_p++) = toupper(args[0][i]);
    }
    *upper_p = 0;


    if (!(fh = fopen(hpath, "w"))) {
        yed_cerr("could not fopen() file '%s'", hpath);
        return;
    }
    fprintf(fh,
"#ifndef __%s_H__\n"
"#define __%s_H__\n"
"\n"
"#endif", upper, upper);

    fclose(fh);

    if (!(fc = fopen(cpath, "w"))) {
        yed_cerr("could not fopen() file '%s'", cpath);
        return;
    }
    fprintf(fc, "#include \"%s.h\"\n", args[0]);

    fclose(fc);

    yed_cprint("created '%s' and '%s'\n", hpath, cpath);
}

int yed_plugin_boot(yed_plugin *self) {
    YED_PLUG_VERSION_CHECK();

    yed_plugin_set_command(self, "mk-src-pair", mk_src_pair);

    return 0;
}
