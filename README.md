[![Actions Status](https://github.com/bduggan/raku-slang-comments/actions/workflows/linux.yml/badge.svg)](https://github.com/bduggan/raku-slang-comments/actions/workflows/linux.yml)
[![Actions Status](https://github.com/bduggan/raku-slang-comments/actions/workflows/macos.yml/badge.svg)](https://github.com/bduggan/raku-slang-comments/actions/workflows/macos.yml)

NAME
====

Slang::Comments - Use comments to provide diagnostics for a Raku program

SYNOPSIS
========

First,

    export RAKUDO_RAKUAST=1

Then, in your program:

    #!/usr/bin/env raku
    use Slang::Comments;

    say "starting!";

    for 100 .. 110 {  #= ### running
      sleep 1;
    }

    say "we are done!";

Output:

    starting!
    --> for 100 .. 110 { #= ### running [####             ] 3/11 (27%).  about 5 seconds remaining
    we are done!

DESCRIPTION
===========

[Slang::Comments](Slang::Comments) is inspired by the excellent [Smart::Comments](https://metacpan.org/pod/Smart::Comments), and provides a way to use comments to get diagnostics about your program while it is running.

To use it, attach a comment to a for-loop using Raku's pod-declarator syntax (#=), and start the comment with three #s, as shown above. This line will be printed, along with a progress bar.

    use Slang::Comments;
    for 1..10 {  #= ### calculating ...
      do-something-complicated;
    }

If the comment ends with three of the same character, those will be used instead of a '#'. So the above will show a progress bar like this:

    --> for 100 .. 110 { #= ### calculating ... [....              ] 3/11 (27%)

A percentage, count and estimated time remaining will be shown if the number of elements can be easily computed.

To turn off the diagnostics, just don't "use" the module, For instance, comment it out, like so:

    # use Slang::Comments;
    for 1..10 {  #= ### calculating ...
      do-something-complicated;
    }

This module only works with RakuAST, so you need to set the RAKUDO_RAKUAST environment variable to a true value.

    export RAKUDO_RAKUAST=1

AUTHOR
======

Brian Duggan

