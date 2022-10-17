" # Learning Vimscript the Hard Way

" ## Chapter 1
" # https://learnvimscriptthehardway.stevelosh.com/chapters/01.html

:echo "Hello, world!"
:echom "Hello, world!"
:messages


/"arn:.*:lambda.*:function:\([^:]*\)"\(,\?\)\(\_.*"arn:.*:lambda:.*:function:\1:.*"\)\@!

/\v^(\s*)("arn:.*:lambda.*:function:[^:]*)"(,?)(\_.*\2:.*")@!/

" Add qualifier to InvokeFunction calls
:%s/\v^(\s*)("arn:.*:lambda.*:function:[^:]*)"(,?)(\_.*\2:.*")@!/\1\2",\r\1\2:*"\3/gc

rg --engine pcre2 -U '^(\s*)("arn:.+:lambda.+:function:[^:\n]+)"(,?)'
rg --engine pcre2 -g '*.tf' -U '^(\s*)("arn:.+:lambda.+:function:[^:\n]+)"(,?)$(?!\s*\2:.+")'

rg -g '!yarn.lock' 'node(.*)?12'
