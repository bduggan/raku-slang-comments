#!/usr/bin/env raku
use Slang::Comments;

say "starting program";

my @x = 1 .. 10;

for @x {  #= ### running ...
  sleep 1;
}

say "done with the program";

