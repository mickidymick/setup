""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""" Basic Settings """"""""""""""""""""""""""""""""
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


" Don't try to be vi compatible
set nocompatible

" Recursively consider files
set path=.,,**

" Turn on syntax highlighting
syntax on

" Show line numbers
set number relativenumber

" Highlight the current line differently
set cursorline

" Show last command
set showcmd

" Splits go to the right or down
set splitright
set splitbelow

" Blink cursor on error instead of beeping
set visualbell

" Encoding
set encoding=utf-8

" Whitespace and indentation
fu! Strip_trailing_whitespace()
    " Don't strip on these filetypes
    if &ft =~ 'vim\|perl'
        return
    endif

    let l = line(".")
    let c = col(".")
    %s/\s\+$//e
    call cursor(l, c)
endfun

fu! ReTab()
    if &ft =~ 'make'
        return
    endif
    retab
endfu

aug Strip_trailing_whitespace_gr
    au!
    autocmd BufWritePre * call Strip_trailing_whitespace() " remove trailing whitespace on write
    autocmd BufWritePre * call ReTab() " fix tabs
aug END

set wrap linebreak nolist
set breakindent
let &showbreak="  ↳"
set formatoptions=tcqrn1
set tabstop=4
set shiftwidth=4
set softtabstop=0
set expandtab
set smarttab
" If the filetype is Makefile then we need to use tabs
" So do not expand tabs into space.
aug Make_why_gr
    au!
    autocmd FileType make setlocal noexpandtab
aug END
set noshiftround
set autoindent
set smartindent
filetype indent on

" Cursor motion
set scrolloff=3
set backspace=indent,eol,start

" Don't use the mouse
set mouse=

" Wildmenu
set wildmenu

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""" Key mappings and commands """""""""""""""""""""""""""
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let mapleader = " "
nnoremap <silent> <space> <nop>
inoremap <silent> jj <esc>
cnoremap <silent> jj <c-f>
command W w
command Q q
cnoremap Q! q!
command Wq wq


" reload this file
nnoremap <leader>rc :so $MYVIMRC<cr>


" Because I forget sometimes..
nnoremap <c-b>n :echo "You're not in TMUX, dummy!"<cr>
nnoremap <c-b>p :echo "You're not in TMUX, dummy!"<cr>

" Move up/down editor lines
nnoremap <silent> j gj
nnoremap <silent> k gk

" system clipboard
map <c-y> "+y
map <c-p> "+p

" Remote editing
nnoremap <leader>er :edit scp://
nnoremap <leader>vr :vsp  scp://

" Word count
xnoremap <silent> <leader>wc g<C-g>:<C-U>echo v:statusmsg<CR>
nnoremap <silent> <leader>wc <nop>


""" Compile error checking
function Make_Check()
    let output = system("make check 2>&1")
    if v:shell_error == 0
        echo "No Errors"
    else
        let nocolor = system("echo " . shellescape(output) . " | perl -pe 's/\x1b\[[0-9;]*m//g'")
        echo nocolor
    endif
endfunction

nnoremap <silent> <leader>mc :call Make_Check()<CR>

""" Spell check toggle
function! Toggle_sc()
    if exists('b:use_spell_check')
        if b:use_spell_check == 1
            setlocal nospell
            let b:use_spell_check = 0
            echo("Spell check off")
        else
            setlocal spell spelllang=en_us
            let b:use_spell_check = 1
            echo("Spell check on")
        endif
    else
        setlocal spell spelllang=en_us
        let b:use_spell_check = 1
        echo("Spell check on")
    endif
endfunction

noremap <silent> <leader>sc :call Toggle_sc()<cr>


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""" Navigation """"""""""""""""""""""""""""""""""
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""" Buffers
nnoremap <silent> <c-l> :bn<cr>
nnoremap <silent> <c-h> :bp<cr>
set wildcharm=<c-l>
cnoremap <c-h> <s-tab>

fu! Buff_menu()
    if len(getbufinfo({'buflisted':1})) > 1
        call feedkeys(":buffer [Z")
    else
        echo "No other buffers"
    endif
endfu

nnoremap <leader>b :call Buff_menu()<cr>

""" Files
nnoremap <leader>f :find <c-l><s-tab>

""" Content
if executable("rg")
    set grepprg=rg\ --vimgrep
    set grepformat=%f:%l:%c:%m
else
    set grepprg=grep\ -Irn\ .
endif

fu! Ggrepper(pattern)
    return system(join([&grepprg, shellescape(a:pattern), ''], ' '))
endfu

command! -nargs=1 Grep cgetexpr Ggrepper(<q-args>) | copen

nnoremap <leader>g :Grep 

" Close the quickfix window after selection.
aug QF_close_gr
    au!
    autocmd FileType qf nnoremap <buffer> <CR> <CR>:cclose<CR>
aug END

nnoremap <leader>qf :copen<cr>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""""""""""""""""""""""""""""""""""" Searching """"""""""""""""""""""""""""""""""
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set incsearch
set smartcase
set showmatch
set hlsearch
nohl

let g:check_search_hl = 0

fu! Disable_search_hl()
    if g:check_search_hl == 1
        let g:check_search_hl = 0
        set nohlsearch
        redraw
    endif
endfu

fu! Restore_Disable_search_hl()
    augroup HLSearch_gr
        au!
        au CursorMoved * :call Disable_search_hl()
        au InsertEnter * :call Disable_search_hl()
    augroup end
endfu

call Restore_Disable_search_hl()

fu! Skip_once_Disable_search_hl()
    augroup HLSearch_gr
        au!
        au CursorMoved * :call Restore_Disable_search_hl()
        au InsertEnter * :call Restore_Disable_search_hl()
    augroup end
endfu

fu! Enable_search_hl()
    let g:check_search_hl = 1
    set hlsearch
    redraw
endfu

fu! Keys_with_hl(key)
    call feedkeys(a:key, 'n')
    call Enable_search_hl()
    call Skip_once_Disable_search_hl()
endfu

fu! Search_with_hl()
    let @/ = ""
    call Keys_with_hl("/")
endfu

nnoremap <silent> /  :call Search_with_hl()<cr>
nnoremap <silent> n  :call Keys_with_hl("n")<cr>
nnoremap <silent> N  :call Keys_with_hl("N")<cr>
nnoremap <silent> *  :call Keys_with_hl("*")<cr>
nnoremap <silent> #  :call Keys_with_hl("#")<cr>
nnoremap <silent> g* :call Keys_with_hl("g*")<cr>
nnoremap <silent> g# :call Keys_with_hl("g#")<cr>


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""" Utility """""""""""""""""""""""""""""""""""
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""" Commenting out stuff
fu! Comment_vim()
    if getline('.') =~ '^\" '
        execute 'normal! 0dldl'
    elseif getline('.') =~ '^\"$'
        execute 'normal! 0dl'
    else
        execute 'normal! 0i" '
    endif
endfu

fu! Comment_hash()
    if getline('.') =~ '^#\s\+'
        execute 'normal! 0dldl'
    elseif getline('.') =~ '^#$'
        execute 'normal! 0dl'
    else
        execute 'normal! 0i# '
    endif
endfu

fu! Comment_C()
    if getline('.') =~ '^/\* '
        execute 'normal! 0dldldl$dldldl'
    else
        execute 'normal! 0i/* A */'
    endif
endfu

fu! Do_Comment()
    let l:ft = &ft

    let l:pos = getpos('.')

    if l:ft == 'vim'
        call Comment_vim()
    elseif l:ft == 'bjou' || l:ft == 'bash' || l:ft == 'sh' || l:ft == 'python' || l:ft == 'perl' || l:ft == 'make'
        call Comment_hash()
    elseif l:ft == 'c' || l:ft == 'cpp'
        call Comment_C()
    else
        echo "No comment support for filetype " . l:ft
    endif

    call setpos('.', l:pos)
endfu

nnoremap <silent> <leader>co :call Do_Comment()<cr>
xnoremap <silent> <leader>co :call Do_Comment()<cr>


""" Return to last edit position when opening files
aug Restor_gr
    au!
    autocmd BufReadPost *
         \ if line("'\"") > 0 && line("'\"") <= line("$") |
         \   exe "normal! g`\"" |
         \ endif
aug END


""" Text alignment
function! Align_selection(regex) range
  let extra = 1
  let sep = empty(a:regex) ? '=' : a:regex
  let maxpos = 0
  let section = getline(a:firstline, a:lastline)
  for line in section
    let pos = match(line, ' *'.sep)
    if maxpos < pos
      let maxpos = pos
    endif
  endfor
  call map(section, 'Align_line(v:val, sep, maxpos, extra)')
  call setline(a:firstline, section)
endfunction

function! Align_line(line, sep, maxpos, extra)
  let m = matchlist(a:line, '\(.\{-}\) \{-}\('.a:sep.'.*\)')
  if empty(m)
    return a:line
  endif
  let spaces = repeat(' ', a:maxpos - strlen(m[1]) + a:extra)
  return m[1] . spaces . m[2]
endfunction

command! -range -nargs=? Align <line1>,<line2>call Align_selection('<args>')

nnoremap <leader>al :Align 
xnoremap <leader>al :Align 



""" Completion
set completeopt=longest,menuone

function! Tab_or_complete()
  if col('.')>1 && strpart( getline('.'), col('.')-2, 3 ) =~ '^\w'
    return "\<c-n>"
  else
    return "\<tab>"
  endif
endfunction

" Determine whether to open the completion menu, or insert a tab.
inoremap <expr> <tab>   pumvisible() ? "\<c-n>" : "\<c-r>=Tab_or_complete()\<cr>"
" Complete file names with ctrl-f.
inoremap <c-f>          <c-x><c-f><c-n>
" Use shift-tab to go backwards through the completion list.
inoremap <expr> <s-tab> pumvisible() ? "\<c-p>" : "\<s-tab>"
" If the completion menu is open, enter selects the competion word.
inoremap <expr> <cr>    pumvisible() ? "\<c-y>" : "\<c-g>u\<cr>"


""" LaTeX
let g:latex_compile_prg="pdflatex -halt-on-error --interaction=nonstopmode"
let g:latex_view_prg="open -a Skim"

fu! LaTeX_compile()
    let l:cmd_str=g:latex_compile_prg . " " . expand('%:t')
    let l:output = system(l:cmd_str)
    let l:status = v:shell_error
    if l:status != 0
        echo l:output
        echo "There were errors compiling the LaTeX document."
    else
        echo "The LaTeX document was successfully compiled."
    endif
endfu

fu! LaTeX_view()
    let l:cmd_str=g:latex_view_prg . " " . expand('%:t:r') . ".pdf"
    let l:output = system(l:cmd_str)
    let l:status = v:shell_error
    if l:status != 0
        echo l:output
        echo "There was an error viewing the LaTeX document."
    endif
endfu

nnoremap <silent> <leader>lc :call LaTeX_compile()<cr>
nnoremap <silent> <leader>lv :call LaTeX_view()<cr>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""" Appearance """"""""""""""""""""""""""""""""""
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" needed for colors in TMUX
let &t_8f = "[38;2;%lu;%lu;%lum"
let &t_8b = "[48;2;%lu;%lu;%lum"

color hybrid_material

if has('termguicolors')
    set termguicolors
endif

""" Statusline
set noshowmode
set noruler
set laststatus=2

fu! Visual_mode_kind()
    let l:m = mode()
    if l:m == 'v'
        return 'v'
    elseif l:m == 'V'
        return 'l'
    elseif l:m == ""
        return 'b'
    endif

    return ''
endfu

set statusline=
set statusline+=%#SpellCap#%{(mode()=='n')?'\ \ NORMAL\ ':''}
set statusline+=%#SpellLocal#%{(mode()=='i')?'\ \ INSERT\ ':''}
set statusline+=%#SpellBad#%{(mode()=='R')?'\ \ RPLACE\ ':''}
set statusline+=%#SpellRare#%{(Visual_mode_kind()=='v')?'\ \ VISUAL\ ':''}
set statusline+=%#SpellRare#%{(Visual_mode_kind()=='l')?'\ \ V-LINE\ ':''}
set statusline+=%#SpellRare#%{(Visual_mode_kind()=='b')?'\ \ V-BLCK\ ':''}
set statusline+=%#CursorLine# " colour
set statusline+=\ %t\         " short file name
set statusline+=%=            " right align
set statusline+=%#CursorLine# " colour
set statusline+=\ %Y\         " file type
set statusline+=\ %3l::%-3c\  " line + column
set statusline+=%#CursorLine# " colour
set statusline+=\ %3p%%\      " percentage

""" A color scheme picker
let g:Color_scheme_picker_open     = 0
let g:Color_scheme_picker_selected = ''

fu! Color_scheme_picker()
    if g:Color_scheme_picker_open == 1
        echo 'Color_scheme_picker is alread open!'
        return
    endif

    let g:Color_scheme_picker_open     = 1
    let g:Color_scheme_picker_selected = g:colors_name

    let l:colors = getcompletion('', 'color')
    silent 12 new color_scheme_picker
    setlocal nobuflisted buftype=nofile bufhidden=wipe noswapfile
    put =l:colors
    norm ggdd
endfu

fu! Close_Color_scheme_picker()
    let g:Color_scheme_picker_open = 0
    execute 'color ' . g:Color_scheme_picker_selected
    redraw!
    echo 'Selected color scheme "' . g:Color_scheme_picker_selected . '".'
endfu

fu! Maybe_update_color()
    let l:current_color = g:colors_name
    let l:selected      = getline('.')

    if l:selected != l:current_color
        let l:changed = 0

        try
            execute 'color ' . l:selected
            let l:changed = 1
        catch /.*/
            execute 'color ' . g:Color_scheme_picker_selected
        finally
            redraw!
            if l:changed == 1
                echo 'Color scheme "' . l:selected . '"'
            else
                echom 'No such color scheme "' . l:selected . '" -- showing "' . g:Color_scheme_picker_selected . '"'
            endif
        endtry
    endif
endfu

fu! Select_Color_scheme()
    let g:Color_scheme_picker_selected = g:colors_name
    exe 'q'
endfu

aug Color_scheme_picker_gr
    au!
    au BufWipeout  color_scheme_picker call Close_Color_scheme_picker()
    au CursorMoved color_scheme_picker call Maybe_update_color()
    au BufEnter    color_scheme_picker nnoremap <buffer> <silent> <cr> :call Select_Color_scheme()<cr>
aug END
command! ColorSchemePicker call Color_scheme_picker()

nnoremap <leader>csp :ColorSchemePicker<cr>
