#!/usr/bin/env raku

use Slang::Comments;

my @seen;
for <a b c d> -> $x { #= ### pointy
  @seen.push($x);
  sleep 2;
}


