" Simple Tamarin Syntax Test (VimScript only)

" Create test file
let g:test_file = expand('~/tamarin_test.spthy')
let g:report_file = expand('~/tamarin_report.txt')

" Generate test file content
let s:content = [
  \ '// Comment line',
  \ '/* Block comment */',
  \ '',
  \ 'theory TestTheory',
  \ 'begin',
  \ '',
  \ 'builtins: diffie-hellman, signing, hashing',
  \ '',
  \ 'rule TestRule:',
  \ '  [ Fr(~k) ]',
  \ '  --[ Action($A, ~k, #i) ]->',
  \ '  [ !PersistentFact($A, ~k), LinearFact(~k) ]',
  \ '',
  \ 'end'
  \ ]

" Write test file
call writefile(s:content, g:test_file)

" Function to check syntax at position
function! SyntaxCheck(line, col)
  let synID = synID(a:line, a:col, 1)
  if synID == 0
    return "No syntax group"
  endif
  
  let synName = synIDattr(synID, "name")
  let transID = synIDtrans(synID)
  let transName = synIDattr(transID, "name")
  let fg = synIDattr(transID, "fg#")
  
  return printf("ID: %d, Name: %s, Trans: %s, Color: %s", 
    \ synID, synName, transName, empty(fg) ? "default" : fg)
endfunction

" Test points to check
let s:test_points = [
  \ {'line': 1, 'col': 3, 'desc': 'Comment (//)'},
  \ {'line': 2, 'col': 3, 'desc': 'Block comment (/*)'}, 
  \ {'line': 4, 'col': 1, 'desc': 'Keyword (theory)'},
  \ {'line': 5, 'col': 1, 'desc': 'Keyword (begin)'},
  \ {'line': 7, 'col': 10, 'desc': 'Builtin (builtins)'},
  \ {'line': 9, 'col': 1, 'desc': 'Keyword (rule)'},
  \ {'line': 10, 'col': 5, 'desc': 'Builtin fact (Fr)'},
  \ {'line': 10, 'col': 9, 'desc': 'Fresh variable (~k)'},
  \ {'line': 11, 'col': 4, 'desc': 'Action start (--[)'},
  \ {'line': 11, 'col': 12, 'desc': 'Linear fact (Action)'},
  \ {'line': 11, 'col': 19, 'desc': 'Public variable ($A)'},
  \ {'line': 11, 'col': 23, 'desc': 'Fresh variable in action (~k)'},
  \ {'line': 11, 'col': 27, 'desc': 'Temporal variable (#i)'},
  \ {'line': 11, 'col': 31, 'desc': 'Action end (]->)'},
  \ {'line': 12, 'col': 4, 'desc': 'Persistent fact (!PersistentFact)'},
  \ {'line': 12, 'col': 20, 'desc': 'Public variable in fact ($A)'},
  \ {'line': 12, 'col': 24, 'desc': 'Fresh variable in fact (~k)'},
  \ {'line': 12, 'col': 29, 'desc': 'Linear fact (LinearFact)'},
  \ {'line': 14, 'col': 1, 'desc': 'Keyword (end)'}
  \ ]

" Generate report
function! GenerateReport()
  " Open test file and enable syntax
  execute 'edit ' . g:test_file
  set filetype=spthy
  syntax on
  redraw
  sleep 500m
  
  " Initialize report
  let report = ['# Tamarin Syntax Report', '', 
    \ 'File: ' . g:test_file, 
    \ 'Date: ' . strftime('%Y-%m-%d %H:%M:%S'),
    \ '',
    \ '| Line | Col | Description | Syntax Information |',
    \ '|------|-----|-------------|-------------------|']
  
  " Check each test point
  for point in s:test_points
    let info = SyntaxCheck(point.line, point.col)
    call add(report, printf('| %d | %d | %s | %s |', 
      \ point.line, point.col, point.desc, info))
  endfor
  
  " Write report
  call writefile(report, g:report_file)
  echo "Report generated at: " . g:report_file
  execute 'edit ' . g:report_file
endfunction

" Run the report
call GenerateReport() 