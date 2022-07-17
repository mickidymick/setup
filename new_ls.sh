#!/usr/bin/env bash

clear
unbuffer ls -Ahos --color=auto $@ | awk                              \
                'BEGIN {
                    first_len   = 0;
                    second_len  = 0;
                    third_len   = 0;
                    fourth_len  = 0;
                    fifth_len   = 0;
                    sixth_len   = 0;
                }

                function add_line(array, len, size) {
                    add_column(size, 0,  array, len, $1);
                    add_column(size, 1,  array, len, $2);
                    add_column(size, 2,  array, len, $3);
                    add_column(size, 3,  array, len, $4);
                    add_column(size, 4,  array, len, $5);
                    add_column(size, 5,  array, len, $6);
                    add_column(size, 6,  array, len, $7);
                    add_column(size, 7,  array, len, $8);
                    add_column(size, 8,  array, len, $9);
                    add_column(size, 9,  array, len, $10);
                    add_column(size, 10, array, len, $11);
                }

                function add_column(size, s_ind, array, ind, nvalue) {
                    array[ind][s_ind] = nvalue;
                    len = length(nvalue);
                    if (len > size[s_ind]) {
                        size[s_ind] = len;
                    }
                }

                function print_line(array, len, size) {
                    for (i = 0; i < len; i++) {
                        printf "%*s %*s %*s %*s %*s %*s %*s %*s %-*s %*s %*s\n",
                                size[0],  array[i][0], size[1], array[i][1],
                                size[2],  array[i][2], size[3], array[i][3],
                                size[4],  array[i][4], size[5], array[i][5],
                                size[6],  array[i][6], size[7], array[i][7],
                                size[8],  array[i][8], size[9], array[i][9],
                                size[10], array[i][10];
                    }
                }

                {
                    if (substr($2,1,1) == "d") {
                        if ((substr($9,5,1) == ";"  &&
                             substr($9,8,1) == "m"  &&
                             substr($9,9,1) == ".") ||
                             substr($9,1,1) == ".") {
                            add_line(first, first_len, size);
                            first_len++;
                        } else {
                            add_line(second, second_len, size);
                            second_len++;
                        }
                    }

                    if (substr($2,1,1) == "-") {
                        if (substr($9,1,1) == ".") {
                            add_line(third, third_len, size);
                            third_len++;
                        } else {
                            add_line(fourth, fourth_len, size);
                            fourth_len++;
                        }
                    }

                    if (substr($2,1,1) == "l") {
                        if (substr($9,1,1) == ".") {
                            add_line(fifth, fifth_len, size);
                            fifth_len++;
                        } else {
                            add_line(sixth, sixth_len, size);
                            sixth_len++;
                        }
                    }
                }

                END {
                    print_line(first, first_len, size);
                    print_line(second, second_len, size);
                    print_line(third, third_len, size);
                    print_line(fourth, fourth_len, size);
                    print_line(fifth, fifth_len, size);
                    print_line(sixth, sixth_len, size);
                }'
