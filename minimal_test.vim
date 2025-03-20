" Minimal Tamarin Syntax Test (no custom syntax)

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

" Define minimal syntax file right in this script
let s:minimal_syntax = [
  \ '" Minimal syntax highlighting for Tamarin',
  \ 'syntax keyword spthyKeyword theory begin end rule lemma axiom builtins',
  \ 'syntax match spthyComment /\/\/.*$/ contains=@Spell',
  \ 'syntax region spthyComment start="/\*" end="\*/" contains=@Spell',
  \ 'syntax match spthyPublicVar /\$[A-Za-z0-9_]\+/',
  \ 'syntax match spthyFreshVar /\~[A-Za-z0-9_]\+/',
  \ 'syntax match spthyTemporalVar /#[A-Za-z0-9_]\+/',
  \ 'syntax match spthyPersistentFact /![A-Za-z0-9_]\+/',
  \ 'syntax match spthyNormalFact /\<[A-Z][A-Za-z0-9_]*\>/',
  \ 'syntax keyword spthyBuiltinFact Fr In Out K',
  \ 'syntax match spthyRuleArrow /--\[\|\]->/',
  \ 'syntax match spthyFunction /\<[a-z][A-Za-z0-9_]*\>(/he=e-1',
  \ 'syntax region spthyConstant start=/"/ end=/"/',
  \ 'syntax region spthyConstant start=/''/ end=/''/,'
  \ ]

" Define our own highlight groups without using external color definitions
let s:minimal_colors = [
  \ 'hi spthyKeyword guifg=#FF00FF gui=bold',
  \ 'hi spthyComment guifg=#777777 gui=italic',
  \ 'hi spthyPublicVar guifg=#006400',
  \ 'hi spthyFreshVar guifg=#FF69B4',
  \ 'hi spthyTemporalVar guifg=#00BFFF',
  \ 'hi spthyPersistentFact guifg=#FF3030 gui=bold',
  \ 'hi spthyNormalFact guifg=#1E90FF gui=bold',
  \ 'hi spthyBuiltinFact guifg=#1E90FF gui=bold,underline',
  \ 'hi spthyRuleArrow guifg=#708090 gui=bold',
  \ 'hi spthyFunction guifg=#FF6347 gui=italic',
  \ 'hi spthyConstant guifg=#FF1493 gui=bold'
  \ ]

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
  " Open test file
  execute 'edit ' . g:test_file
  
  " Set up minimal syntax
  let syntax_file = expand('~/minimal_spthy.vim')
  call writefile(s:minimal_syntax, syntax_file)
  execute 'source ' . syntax_file
  
  " Apply colors
  for color_def in s:minimal_colors
    execute color_def
  endfor
  
  " View the file
  redraw
  sleep 500m
  
  " Initialize report
  let report = ['# Minimal Tamarin Syntax Report', '', 
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