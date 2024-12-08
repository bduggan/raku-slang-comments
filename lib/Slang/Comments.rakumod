module Slang::Comments {
=begin pod

=head1 NAME

Slang::Comments - Use comments to get diagnostics from a running program.

=head1 SYNOPSIS

  use Slang::Comments;

  say "starting!";

  for 100 .. 110 {  #= ### running ...
    sleep 1;
  }

  say "we are done!";

Output:

  starting!
  --> for 100 .. 110 { #= ### running ... [##########                                        ] 3/11 (18%).  Elapsed: 2 seconds, Remaining: 9 seconds
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

To turn off the diagnostics, just don't "use" the module, For instance, comment it out, like so:

  # use Slang::Comments;
  for 1..10 {  #= ### calculating ...
    do-something-complicated;
  }

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

sub start-slang-comments($source,$code,$why,$file,$from) is export {
  warn "sorry, Slang::Comments requires ast: RAKUDO_RAKUAST is not set" unless %*ENV<RAKUDO_RAKUAST>:exists;
  # source is the for loop "source" (e.g. a range)
  # code is the code, parsed.
  # why is the declarator pod
  # file is the file name
  # from is the starting character 
  state Int $i = 0;
  state DateTime $started;
  state $expected;
  if ($i == 0) {
    my $src = try $source.EVAL;
    $expected = $src.elems unless $!;
    $started = DateTime.now;
    print "### Starting";
  }
  my $elapsed = approx-time(DateTime.now - $started);
  my $desc = $code.lines.head;

  if ($expected) {
    my $remaining-items = $expected - $i;
    my $approx-time-per-item = ($i > 0) ?? (DateTime.now - $started) / $i !! 0;
    my $remaining = approx-time($remaining-items * $approx-time-per-item);
    my $progress-bar = ( "#" x ($i / ( $expected - 1) * 50).Int ).fmt('%-50s');

    if $i == $expected - 1 {
      print "\r" ~ t.erase-to-end-of-line;
      return;
    }
    my $percent = ($i / $expected * 100).fmt("%2d");
    $i++;
    print "\r--> $desc [$progress-bar] $i/$expected ({ $percent }%).  Elapsed: $elapsed, Remaining: $remaining ";
  } else {
    $i++;
    print "\r--> $desc [$i of ??? ].  Elapsed: $elapsed";
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
       ~ 'start-slang-comments('
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
