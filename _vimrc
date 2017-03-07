if v:lang =~ "utf8$" || v:lang =~ "UTF-8$"
   set fileencodings=ucs-bom,utf-8,latin1
endif

set nocompatible	" Use Vim defaults (much better!)
set bs=indent,eol,start		" allow backspacing over everything in insert mode
"set ai			" always set autoindenting on
"set backup		" keep a backup file
set viminfo='20,\"50	" read/write a .viminfo file, don't store more
			" than 50 lines of registers
set ruler		" show the cursor position all the time

let mapleader=","

" Only do this part when compiled with support for autocommands
if has("autocmd")
  augroup redhat
  autocmd!
  " In text files, always limit the width of text to 78 characters
  autocmd BufRead *.txt set tw=78
  " When editing a file, always jump to the last cursor position
  autocmd BufReadPost *
  \ if line("'\"") > 0 && line ("'\"") <= line("$") |
  \   exe "normal! g'\"" |
  \ endif
  " don't write swapfile on most commonly used directories for NFS mounts or USB sticks
  autocmd BufNewFile,BufReadPre /media/*,/mnt/* set directory=~/tmp,/var/tmp,/tmp
  " start with spec file template
  autocmd BufNewFile *.spec 0r /usr/share/vim/vimfiles/template.spec
  augroup END
endif

if has("cscope") && filereadable("/usr/local/bin/cscope")
   set csprg=/usr/local/bin/cscope
   set csto=0
   set cst
   set nocsverb
   " add any database in current directory
   if filereadable("cscope.out")
      cs add cscope.out
   " else add database pointed to by environment
   elseif $CSCOPE_DB != ""
      cs add $CSCOPE_DB
   endif
   set csverb
endif

nmap <C-_>s :cs find s <C-R>=expand("<cword>")<CR><CR>
nmap <C-_>g :cs find g <C-R>=expand("<cword>")<CR><CR>
nmap <C-_>c :cs find c <C-R>=expand("<cword>")<CR><CR>
nmap <C-_>t :cs find t <C-R>=expand("<cword>")<CR><CR>
nmap <C-_>e :cs find e <C-R>=expand("<cword>")<CR><CR>
nmap <C-_>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
nmap <C-_>i :cs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
nmap <C-_>d :cs find d <C-R>=expand("<cword>")<CR><CR>

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  syntax on
  set hlsearch
endif

filetype plugin indent on

if &term=="xterm"
     set t_Co=8
     set t_Sb=[4%dm
     set t_Sf=[3%dm
endif

" Don't wake up system with blinking cursor:
" http://www.linuxpowertop.org/known.php
let &guicursor = &guicursor . ",a:blinkon0"
" ==========================================================
" " Pathogen - Allows us to organize our vim plugins
" " ==========================================================
" " Load pathogen with docs for all plugins
filetype off
"call pathogen#runtime_append_all_bundles()
"call pathogen#incubate()
"call pathogen#helptags()

filetype on
set tabstop=4
"set number
set showmatch
set incsearch
set hlsearch
set history=1000
set undolevels=1000
set title
set expandtab
set autoread
set autoindent smartindent " always set autoindenting on
set copyindent " copy the previous indentation on autoindenting
set hidden
set wildignore=*.swp,*.bak,*.pyc,*.class
set nobackup
set noswapfile
set list
set listchars=tab:>.,trail:.,extends:#,nbsp:.
set paste

" Toggle indentation during paste.
nnoremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>
set showmode
"
" " Set working directory
nnoremap <leader>. :lcd %:p:h<CR>

" Quit window on <leader>q
nnoremap <leader>q :q<CR>

" sudo write this
cmap W! w !sudo tee % >/dev/null
"map <silent> <leader>V :source ~/.vimrc<CR>:filetype detect<CR>:exe ":echo 'vimrc reloaded'"<CR>
nmap <silent> <leader>ev :e $MYVIMRC<CR>
nmap <silent> <leader>sv :so $MYVIMRC<CR>:filetype detect<CR>:exe ":echo 'vimrc reloaded'"<CR>

" Run command-t file search
map <leader>f :CommandT<CR>
" " Ack searching
nmap <leader>a <Esc>:Ack!
"
" " Load the Gundo window
map <leader>g :GundoToggle<CR>
"
" " Jump to the definition of whatever the cursor is on
map <leader>j :RopeGotoDefinition<CR>

nnoremap ; :
map <silent> <C-t> :NERDTreeToggle<CR>

"" Python
"au BufRead *.py compiler nose
au FileType python set omnifunc=pythoncomplete#Complete
au FileType python setlocal expandtab shiftwidth=4 tabstop=8 softtabstop=4 smartindent cinwords=if,elif,else,for,while,try,except,finally,def,class,with
au FileType coffee setlocal expandtab shiftwidth=4 tabstop=8 softtabstop=4 smartindent cinwords=if,elif,else,for,while,try,except,finally,def,class,with
au BufRead *.py set efm=%C\ %.%#,%A\ \ File\ \"%f\"\\,\ line\ %l%.%#,%Z%[%^\]%\\@=%m
"" Don't let pyflakes use the quickfix window
let g:pyflakes_use_quickfix = 0

"
"colorscheme Tomorrow-Night
"colorscheme Tomorrow-Night-Bright
"colorscheme 256-jungle
"colorscheme vividchalk
"colorscheme badwolf
"colorscheme molokai
"colorscheme railscat
"colorscheme ron
"

" Centralize backups, swapfiles and undo history
"set backupdir=~/.vim/backups
set directory=~/.vim/swaps
" Allow backspace in insert mode
set backspace=indent,eol,start
" Optimize for fast terminal connections
set ttyfast
" Show “invisible” characters
"set lcs=tab:▸\ ,trail:·,eol:¬,nbsp:_
set list

set laststatus=1
set statusline=%f\ \ %y\ \ %3.3m%4.4r%=%l\ /\ %L,\ %c\ \.

" Strip trailing whitespace (,ss)
function! StripWhitespace()
    let save_cursor = getpos(".")
    let old_query = getreg('/')
    :%s/\s\+$//e
    call setpos('.', save_cursor)
    call setreg('/', old_query)
endfunction
noremap <leader>ss :call StripWhitespace()<CR>
" Save a file as root (,W)
noremap <leader>W :w !sudo tee % > /dev/null<CR>

" Automatic commands
if has("autocmd")
    " Enable file type detection
    filetype on
    " Treat .json files as .js
    autocmd BufNewFile,BufRead *.json setfiletype json syntax=javascript
endif
