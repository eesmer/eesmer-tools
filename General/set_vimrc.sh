#!/bin/bash

# ---------------------------------------------------------------------------------
# - VIM Customization -
# Root permissions are required for package installations.
# When using the root user, be careful about the target user account.
# Usage: bash set_vimrc TARGET_USER
# ---------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------
# Required Packages
# ---------------------------------------------------------------------------------
apt-get -y vim
apt-get -y install vim-airline vim-airline-themes fonts-powerline

TARGET_USER=$1

# ---------------------------------------------------------------------------------
# VIMRC FILE
# ---------------------------------------------------------------------------------
cat > /home/$TARGET_USER/.vimrc << EOF
set nocompatible
set encoding=utf-8
set bg=dark
syntax on
set is
set ic
set smartcase
nnoremap / /\v
vnoremap / /\v
set hidden
set scrolloff=3

filetype plugin indent on

"===================
" GPG
"===================
if has('packages')
  packadd! gnupg
else
  packadd gnupg
endif
set nomodeline

let g:GPGPreferSymmetric = 1
let g:GPGUsePipes       = 1
let g:GPGDefaultRecipients = []

augroup secure_gpg_files
  autocmd!
  autocmd BufReadPre,FileReadPre *.gpg,*.pgp,*.asc setlocal noswapfile nobackup nowritebackup noundofile
  autocmd BufReadPost,FileReadPost *.gpg,*.pgp,*.asc setlocal filetype=gpg
augroup END

"===================
" AIRLINE
"===================
set laststatus=2
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline_theme='badwolf'
"let g:airline_theme='dark'
"let g:airline_theme='molokai'
"let g:airline_theme='distinguished'
EOF
chown $TARGET_USER:$TARGET_USER /home/$TARGET_USER/.vimrc
chmod 755 /home/$TARGET_USER/.vimrc

# ---------------------------------------------------------------------------------
# BASHRC FILE
# correct TTY usage on each terminal - for GPG
# ---------------------------------------------------------------------------------
cat >> /home/$TARGET_USER/.bashrc << EOF
if [ -n "$PS1" ]; then
    export GPG_TTY="$(tty)"
fi
EOF

