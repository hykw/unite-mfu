" unite-mfu
" version: 1.0.0
" Author: Hitoshi Hayakawa
" License: MIT
"
" URL: https://github.com/hykw/unite-mfu

if exists('g:loaded_unite_mfu')
  finish
endif
let g:loaded_unite_mfu= 1

let s:save_cpo = &cpo
set cpo&vim

""""""""""""""""""""""""""""""""""""""""""""""""""
if !exists('unite_mfu#count_dir')
  let g:unite_mfu#count_dir=expand('$HOME/.unite_mfu')
endif
if !exists('unite_mfu#read_writeFile_days')
  let g:unite_mfu#read_writeFile_days = 2
endif
if !exists('unite_mfu#read_readFile_days')
  let g:unite_mfu#read_readFile_days = 1
endif
if !exists('unite_mfu#max_return_nums')
  let g:unite_mfu#max_return_nums = 10
endif

let s:countFile_read = g:unite_mfu#count_dir . '/read.txt'
let s:countFile_write = g:unite_mfu#count_dir . '/write.txt'
""""""""""""""""""""""""""""""""""""""""""""""""""

augroup unite_mfu
  autocmd!
  autocmd BufRead * call unite_mfu#writeFileName(s:countFile_read)
  autocmd BufWrite * call unite_mfu#writeFileName(s:countFile_write)
augroup END

" check directory/files, and create if not exists
if filewritable(g:unite_mfu#count_dir) != 2
  call mkdir(g:unite_mfu#count_dir)
endif
if filereadable(s:countFile_read) == 0
  call writefile([], s:countFile_read)
endif
if filewritable(s:countFile_write) == 0
  call writefile([], s:countFile_write)
endif


""""""""""""""""""""""""""""""""""""""""""""""""""
function! unite_mfu#writeFileName(countFilename)
  let filename = expand('%:p')

  " ignore the count files
  if (filename == s:countFile_read) || (filename == s:countFile_write)
    return
  endif

ruby << EOL
  require 'date'

  File.open(VIM.evaluate('a:countFilename'), 'a') do |f|
    f.puts format('%s,%s', Time.now.strftime('%Y/%m/%d %H:%M:%S'), VIM.evaluate('filename'))
  end
EOL
endfunction


let s:unite_source = {
      \ 'name': 'mfu',
      \ 'description': 'candidate from most frequently used files'
      \}
call unite#define_source(s:unite_source)

function! s:unite_source.gather_candidates(args, context)
  if len(a:args) > 0
    if a:args[0] == 'writeonly'
      let countFile = s:countFile_write
      let read_days = g:unite_mfu#read_writeFile_days
    else
      let countFile = s:countFile_read
      let read_days = g:unite_mfu#read_readFile_days
    endif
  endif

ruby << EOL
keep_history_days = VIM.evaluate('read_days')
oldest_time = Time.now - (86400*keep_history_days)

def getTimeObject(datetime)
  date, time = datetime.split(' ')
  dates = date.split('/')
  times = time.split(':')
  return Time.local(dates[0], dates[1], dates[2], times[0], times[1], times[2])
end

files = []
File.open(VIM.evaluate('countFile')) do |f|
  while f.gets
    datetime, file = $_.chomp.split(',')
    file_time = getTimeObject(datetime)
    if oldest_time <= file_time
      files += [file]
    end
  end
end

# count
counts = {}
files.each do |file|
  counts[file] = (counts[file] == nil) ? 1 : counts[file]+1
end

ret = []
counts.sort {|(k1, v1), (k2, v2)| v2 <=> v1 }.each do |key, value|
  ret += [key]
end

maxLines = VIM.evaluate('g:unite_mfu#max_return_nums')
if ret.count > maxLines
  ret = ret[0..maxLines-1]
end

ret = ret.join(',')
VIM.command("let lines = '#{ret}'")
EOL

let lineLists = split(lines, ',')

return map(lineLists, '{
      \   "word": v:val,
      \   "source": "mfu",
      \   "kind": "file",
      \   "action__path": v:val,
      \ }')

endfunction

