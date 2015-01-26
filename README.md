unite-mfu
=========

Vim script for Unite(unite source for Most Frequently Used File)

When you edit/open the file, it write the filename into a file.
This script count the file, and return the filenames in MFU order.
Also, at VimLeavePre, it purge the old records from the count files.

## Usage

```vim
:Unite mfu:writeonly
:Unite mfu:readwrite
```

":Unite mfu:writeonly" shows the files which are written recently, 
":Unite mfu:readwrite"(or just ":Unite mfu") are the all files.

I map the function like these(for me, it's more useful than any MRU plugin)

```vim
nnoremap [Unite] <Nop>
nmap     <Leader>u [Unite]

nnoremap [Unite]m :Unite mfu:writeonly<CR>
nnoremap [Unite]M :Unite mfu:readwrite<CR>
map <Leader>m [Unite]m
map <Leader>M [Unite]M
```


## Option

```vim
" default: 0(1 = count also include just open)
let g:unite-mfu#count_only_edit=0

" count file is written in this directory
let g:unite_mfu#count_dir=expand('$HOME/.unite_mfu')

" How many hours the data is valid (in write only)
let g:unite_mfu#read_writeFile_hours = 12

" How many days the data is valid (in read only)
let g:unite_mfu#read_readFile_hours = 6

" How many files, it returns
let g:unite_mfu#max_return_nums = 10
```
