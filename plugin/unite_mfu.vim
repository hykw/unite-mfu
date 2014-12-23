" unite-mfu
" version: 1.1.0
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
  let g:unite_mfu#read_writeFile_hours = 12
endif
if !exists('unite_mfu#read_readFile_days')
  let g:unite_mfu#read_readFile_hours = 6
endif
if !exists('unite_mfu#max_return_nums')
  let g:unite_mfu#max_return_nums = 10
endif

let s:countFile_read = g:unite_mfu#count_dir . '/read.txt'
let s:countFile_write = g:unite_mfu#count_dir . '/write.txt'
let s:countFile_lastPurged = g:unite_mfu#count_dir . '/lastpurge.txt'
""""""""""""""""""""""""""""""""""""""""""""""""""

augroup unite_mfu
  autocmd!
  autocmd BufRead * call unite_mfu#writeFileName(s:countFile_read)
  autocmd BufWrite * call unite_mfu#writeFileName(s:countFile_write)
  autocmd VimLeavePre * call unite_mfu#purgeCountFiles(s:countFile_read, s:countFile_write, g:unite_mfu#read_readFile_hours, g:unite_mfu#read_writeFile_hours, s:countFile_lastPurged)
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
  " disable on Mac, because it crashes call ruby (due to ruby.c?), even in MacVim 7.4.527
  if system('uname') == "Darwin\n"
    return
  endif

  let filename = expand('%:p')

  " ignore the count files
  if (filename == s:countFile_read) || (filename == s:countFile_write) || (filename == s:countFile_lastPurged)
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
      let read_hours = g:unite_mfu#read_writeFile_hours
    else
      let countFile = s:countFile_read
      let read_hours = g:unite_mfu#read_readFile_hours
    endif
  endif

ruby << EOL
require 'time'
keep_history_hours = VIM.evaluate('read_hours')
oldest_time = Time.now - (3600*keep_history_hours)

files = []
File.open(VIM.evaluate('countFile')) do |f|
  while f.gets
    datetime, file = $_.chomp.split(',')
    file_time = Time.parse(datetime)
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

function! unite_mfu#purgeCountFiles(countfile_read, countfile_write, readFile_hours, writeFile_hours, countFile_lastPurged)
  " file exists, and the last purged date is within 1 day, it does nothing
  let doneNothing = 0
  if filewritable(a:countFile_lastPurged) == 1
ruby << EOL
    require 'time'

    lastpurged = ''
    File.open(VIM.evaluate('a:countFile_lastPurged'), 'r') do |f|
      lastpurged = f.gets.chomp
    end
    if Time.now() < Time.parse(lastpurged) + 86400
      VIM.command('let doneNothing = 1')
    end
EOL
  endif

  if doneNothing == 1
    return
  endif

  " purge and write the purged file
ruby << EOL
  require 'time'

  def purgeCountFile(countFile, read_hours)
    isValidRecordExist = false
    now = Time.now()

    histories = File.open(countFile).read.split("\n")
    File.open(countFile, 'w') do |f|
      histories.each do |aLine|
        datetime, filename = aLine.split(',')

        if isValidRecordExist == false
          # just in case, records are kept with read_hours * 2
          if now <= (Time.parse(datetime) + 3600 * read_hours * 2)
            isValidRecordExist = true
          end
        end

        if isValidRecordExist == false
          next
        end

        f.puts format('%s,%s', datetime, filename)
      end
    end
  end

  purgeCountFile(VIM.evaluate('a:countfile_read'), VIM.evaluate('a:readFile_hours'))
  purgeCountFile(VIM.evaluate('a:countfile_write'), VIM.evaluate('a:writeFile_hours'))

  # write the current time(aka last purged datetime) into the file.
  File.open(VIM.evaluate('s:countFile_lastPurged'), 'w') do |f|
    f.puts(Time.now.strftime('%Y/%m/%d %H:%M:%S'))
  end
EOL

endfunction
