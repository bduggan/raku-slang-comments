
#!/usr/bin/env raku
use Slang::Comments;

say "starting!";

for 100 .. * {  #= ### running
  sleep 1;
  last if ++$ > 10;
}

say "we are done!";

