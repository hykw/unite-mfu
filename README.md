unite-mfu
=========

Vim script for Unite(unite source for Most Frequently Used File)

When you edit/open the file, it write the filename into a file.
This script count the file, and return the filenames in MFU order.

## Usage

    :Unite mfu:writeonly
    :Unite mfu:readwrite

":Unite mfu:writeonly" shows the files which are written recently, 
":Unite mfu:readwrite"(or just ":Unite mfu") are the all files.

I map the function like these(for me, it's more useful than any MRU plugin)

    nnoremap [Unite]m :Unite mfu:writeonly<CR>
    nnoremap [Unite]M :Unite mfu:readwrite<CR>
    map <Leader>m [Unite]m
    map <Leader>M [Unite]M


## Option

    " default: 0(1 = count also include just open)
    g:unite-mfu#count_only_edit=0

    " count file is written in this directory
    let g:unite_mfu#count_dir=expand('$HOME/.unite_mfu')

    " How many days the data is valid (in write only)
    let g:unite_mfu#read_writeFile_days = 2

    " How many days the data is valid (in read only)
    let g:unite_mfu#read_readFile_days = 1

    " How many files, it returns
    let g:unite_mfu#max_return_nums = 10

## TODO

    Truncate the old data from the file in the directory(~/.unite_mfu).
    Now, it just adds the record in the tail(it should be records, in VimLeavePre event?)
