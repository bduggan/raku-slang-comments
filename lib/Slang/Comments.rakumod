module Slang::Comments {

=begin pod

=head1 NAME

Slang::Comments - Use comments to show diagnostics from a running program.

=head1 SYNOPSIS

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
  --> for 100 .. 110 { #= ### running [####             ] 3/11 (27%).  Elapsed: 2 seconds, Remaining: 5 seconds
  we are done!

=head1 DESCRIPTION

L<Slang::Comments> is inspired by the excellent L<Smart::Comments|https://metacpan.org/pod/Smart::Comments>,
and provides a way to use comments to get diagnostics about your program while it is running.

To use it, attach a comment to a for-loop using Raku's pod-declarator syntax (#=), and start
the comment with three #s, as shown above.  This line will be printed, along with a progress
bar.

  use Slang::Comments;
  for 1..10 {  #= ### calculating ...
    do-something-complicated;
  }

If you end your comment with three of the same character, those will be used in the hash mark
instead of a '#'.

To turn off the diagnostics, just don't "use" the module, For instance, comment it out, like so:

  # use Slang::Comments;
  for 1..10 {  #= ### calculating ...
    do-something-complicated;
  }

This module only works with RakuAST, so you need to set the RAKUDO_RAKUAST environment variable to a true value.

  export RAKUDO_RAKUAST=1

=head1 AUTHOR

Brian Duggan

=end pod

}

use Terminal::ANSI::OO 't';

use experimental :rakuast;

sub approx-time($s) {
  my $seconds = $s.Int;
  return "1 second" if $seconds == 1;
  return "$seconds seconds" if $seconds < 60;
  return "about { $seconds div 60 } minutes" if $seconds < 3600;
  return "about { $seconds div 3600 } hours" if $seconds < 86400;
  return "about { $seconds div 86400 } days";
}

INIT {
  note "sorry, Slang::Comments requires AST support: please set RAKUDO_RAKUAST to a true value" unless %*ENV<RAKUDO_RAKUAST>;
}

my class Progress {
  has $.source;
  has $.code;
  has $.why;
  has $.desc;
  has $.columns = try qx[tput cols].trim;
  has $.progress-char = '#';

  has $.i = 1;
  has $.expected;
  has DateTime $.started;

  method TWEAK {
    my $src = try $!source.EVAL;
    $!expected = $src.elems unless $!;
    $!started = DateTime.now;
    $!desc = $!code.lines.head;
    my $ends = $!why.trim.substr(* - 3);
    if $ends.comb.unique == 1 {
      $!progress-char = $ends.comb[0];
    }
  }

  method update {
    if $!expected {
      self.update-expected
    } else {
      self.update-no-expected
    }
    self;
  }

  method update-expected {
    my $elapsed = approx-time(DateTime.now - $!started);
    my $remaining-items = $!expected - $!i;
    my $approx-time-per-item = ($!i > 0) ?? (DateTime.now - $!started) / $!i !! 0;
    my $remaining = approx-time($remaining-items * $approx-time-per-item);
    my $width = 50;
    with $.columns -> $c {
      $width =  ( $c - "--> $!desc [] XXX/XXX (XX%).  Elapsed: XX minutes, Remaining: XX minutes".chars ) * 3 div 4;
    }
    my $progress-bar = ( $!progress-char x ($!i / $!expected * $width).Int ).fmt('%-' ~ $width ~ 's');
    my $percent = ($!i / $!expected * 100).fmt("%2d");
    print "\r--> $!desc [$progress-bar] $!i/$!expected ({ $percent }%).  Elapsed: $elapsed, Remaining: $remaining ";
    if $!i >= $!expected {
      print "\r" ~ t.erase-to-end-of-line;
    }
    $!i++;
  }

  method update-no-expected {
    my $elapsed = approx-time(DateTime.now - $!started);
    $!i++;
    print "\r--> $!desc [$!i of ??? ].  Elapsed: $elapsed";
  }
}

my %updaters;

sub slang-comments-update-progress(
  $source, # the for loop "source" (e.g. a range)
  $code,   # parsed code
  $why,    # the declarator pod
  $file,   # file name
  $from    # starting character position in the source file
) is export {
  my $key = $file ~ ':' ~ $from;
  with %updaters{ $key } -> $u {
    $u.update;
  } else {
    %updaters{ $key } := Progress.new(:$source, :$code, :$why).update;
  }
}

role Comments::Actions {
  method statement-control:sym<for>(|match) {
    my $ast = callsame;
    my $file = $*ORIGIN-SOURCE.original-file;
    my $from = $ast.origin.from;
    my $orig-body = $ast.body.DEPARSE;
    my $orig-code = $ast.DEPARSE;
    my $why = $ast.body.WHY.trailing;
    my $new =
      '{'
       ~ 'slang-comments-update-progress('
       ~ 'q[[[' ~ $ast.source.DEPARSE ~ ']]],'
       ~ 'q[[[' ~ $orig-code ~ ']]],'
       ~ 'q[[[' ~ $why ~ ']]],'
       ~ 'q[[[' ~ $file ~ ']]],'
       ~ 'q[[[' ~ $from ~ ']]],'
       ~ ');'
       ~ $orig-body
       ~ ';'
      ~ '}';
    $ast.body.replace-body($new.AST);
  }
}

use Slangify Mu, Comments::Actions;
