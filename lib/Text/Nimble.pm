package Text::Nimble;

use 5.010; # for recursive regexes, but also using //
use strict;
use warnings FATAL => 'all';

use Carp;

our $VERSION = '0.002001';
$VERSION = eval $VERSION;


my %renderer = (
  html => \&_renderer_html,
);


sub render {
  my ($format, $nimble) = @_;
  croak "Text::Nimble::render takes two arguments but got ".(scalar @_) unless @_ == 2;
  croak "Text::Nimble::render takes a render format name as its first argument" unless defined $_[0] && $_[0] =~ /^\w+$/;
  croak "Text::Nimble::render takes Nimble text or a Nimble parse result as its second argument" unless defined $_[1] && (!ref $_[1] || ref $_[1] eq 'ARRAY' || (ref $_[1] eq 'HASH' && $_[1]{tree} && $_[1]{macro}));
  croak "Text::Nimble::render was given an unknown render format '$_[0]'" unless $renderer{$format};

  $nimble = parse($nimble) unless ref $nimble eq 'HASH';
  my $output = $renderer{$format}($nimble);
  return wantarray ? ($output, $nimble->{meta}, $nimble->{error}) : $output;
}

sub parse {
  croak "Text::Nimble::parse takes one argument but got ".(scalar @_) unless @_ == 1;

  my (%meta, %macro, @error);

  local *_nimble_makelines = sub {
    # break input into lines
    croak "Text::Nimble::parse expects a string" unless @_==1 && defined $_[0] && !ref $_[0];
    my $input = $_[0];
    $input =~ s/\r//g;
    my @lines = split(/\n/, $input, -1);

    my $next_indent;
    for (my $i=$#lines; $i>=0; $i--) {
      if ($lines[$i] =~ /^( *)\S/) {
        $next_indent = $1;
      } elsif (defined $next_indent && $lines[$i] =~ /^\s*$/) {
        $lines[$i] = $next_indent;
      }
    }

    return \@lines;
  };

  local *_macro_arg_preprocess = sub {
    my ($type, $arg) = @_;

    if ($type eq 'nimble') {
      return ref $arg ? _nimble_parse($arg) : _nimble_parse_inline($arg);
    } elsif ($type eq 'raw') {
      return ref $arg ? join("\n", @$arg) : $arg;
    } else {
      die "unreachable: _macro_arg_preprocess tried to decode a macro argument with unrecognized type '$type'";
    }
  };

  local *_macro_invocation_preprocess = sub {
    my ($macro_name, $node) = @_;
    foreach my $arg (keys %{$macro{$macro_name}{args}}) {
      $node->{args}{$arg} =
        defined $node->{args}{$arg}
        ? _macro_arg_preprocess($macro{$macro_name}{args}{$arg}{type}, $node->{args}{$arg})
        : $macro{$macro_name}{args}{$arg}{default};
    }
  };

  my %inlinestyle = (
    '*' => 'strong',
    '/' => 'emphasis',
  );
  my $inlinestyle_re = '['.quotemeta(join('', keys %inlinestyle)).']';

  my %entityshorthand = (
    '--'  => '&ndash;',
    '---' => '&mdash;',
    '<--' => '&larr;',
    '-->' => '&rarr;',
    '<==' => '&lArr;',
    '==>' => '&rArr;',
  );
  my $entityshorthand_re = '(?:'.join('|', map {quotemeta} sort {length $b <=> length $a} keys %entityshorthand).')';

  my $inline_re = qr/
    # start at pos(), then group for delimiter-matching recursion
    # 1
    \G(
      # plain text or escapes
      # 2
        ((?:[\w\s\.\,\(\)\']+|\\.)+)
      # inline code
      # 3       4
      | (\`+)\s*(.*?)\s*\g{-2}
      # inline style
      # 5                      6
      | ($inlinestyle_re)(?!\s)((?>(?1))+?)(?<!\s)\g{-2}
      # entity literal
      # 7
      | (\&(?:\#(?:\d+|x[0-9a-fA-F]+)|\w+)\;)
      # entity shorthand
      # 8
      | ($entityshorthand_re)
      # brackets
      #   9
      | \[((?>(?1))+?)\]
      # failure; take any one character
      # 10
      | (.)
    )
  /x;

  local *_nimble_parse_inline = sub {
    my $text = shift;
    croak "_nimble_parse_inline takes exactly one nonref defined argument" if @_ || !defined $text || ref $text;

    my @output;
    my $append_text = sub {
      if (@output && $output[-1]{type} eq 'text') {
        $output[-1]{text} .= $_[0];
      } else {
        push @output, {type=>"text", text=>$_[0]};
      }
    };
    while ($text =~ /$inline_re/g) {
      my ($plain, $code, $styletype, $stylecontent, $entity_literal, $entity_shorthand, $bracketcontents, $char)
       = ($2,     $4,    $5,         $6,            $7,              $8,                $9,               $10  );

      if (defined $plain) {
        $plain =~ s/\\(.)/$1/g;
        $append_text->($plain);
      } elsif (defined $code) {
        push @output, {type=>"code", text=>$code};
      } elsif (defined $styletype) {
        push @output, {type=>$inlinestyle{$styletype}, content=>_nimble_parse_inline($stylecontent)};
      } elsif (defined $entity_literal) {
        push @output, {type=>"entity", html=>$entity_literal};
      } elsif (defined $entity_shorthand) {
        push @output, {type=>"entity", html=>$entityshorthand{$entity_shorthand}};
      } elsif (defined $bracketcontents) {
        if ($bracketcontents =~ /^\$(\w+)((?:\s+\w+\=(?:\S*|([\"\'])((?:(?!\\|\g{-2}).|\\.)*)\g{-2}))*)\s*$/) {
          my ($macro_name, $macro_args) = ($1, $2);
          my ($node, @errors);

          push @errors, "no macro by that name is defined" unless $macro{$macro_name};

          if (!@errors) {
            $node = {type=>"macro", macro=>$macro_name, args=>{}};
            while ($macro_args =~ /\G\s+(\w+)\=(?:(?![\"\'])(\S*)|([\"\'])((?:(?!\\|\g{-2}).|\\.)*)\g{-2})/g) {
              my ($arg_name, $arg_value) = ($1, $2 // $4);
              push @errors, "duplicate argument '$arg_name'" if $node->{args}{$arg_name};
              push @errors, "unknown argument '$arg_name'" unless $macro{$macro_name}{args}{$arg_name};
              next if @errors; #skip work if any errors have been seen, but keep parsing to find more errors
              $arg_value =~ s/^\[|\]$//g if $arg_value =~ /^(\[(?:(?:(?-1)*?)|[^\[\]\\]+|\\.|.)*?\])$/;
              $arg_value =~ s/\\(.)/$1/g;
              $node->{args}{$arg_name} = $arg_value;
            }
            if (!@errors) {
              _macro_invocation_preprocess($macro_name, $node);
            }
          }

          if (@errors) {
            $node = {type=>"error", context=>"building inline macro '$macro_name' invocation", errors=>\@errors};
            push @error, $node;
          }
          push @output, $node;
        } elsif ($bracketcontents =~ /^raw\s+(\w+)\s+(.+?)\s*$/) {
          my ($format, $content) = ($1, $2);
          $content =~ s/\\(.)/$1/g;
          push @output, {type=>"raw", format=>$format, content=>$content};
        } elsif ($bracketcontents =~ /^img\s+(\S+)(?:\s+(.+?))?$/) {
          my $url = $1;
          my $alt = $2 // "";
          $url =~ s/\\(.)/$1/g;
          $alt =~ s/\\(.)/$1/g;
          push @output, {type=>"img", src=>$url, alt=>$alt};
        } elsif ($bracketcontents =~ /^(?:link\s+)?(\S+)(?:\s+(.+?))?$/) {
          my $url = $1;
          my $content = $2;
          $url =~ s/\\(.)/$1/g;
          push @output, {type=>"link", url=>$url, content=>(defined $content ? _nimble_parse_inline($content) : [{type=>"text", text=>$url}])};
        } else {
          $append_text->('[');
          push @output, @{_nimble_parse_inline($bracketcontents)};
          $append_text->(']');
        }
      } elsif (defined $char) {
        $append_text->($char);
      } else {
        die "unreachable: _nimble_parse_inline matched an inline pattern but failed to determine which rule should handle it: " . substr($text, $-[0], $+[0] - $-[0]) . "\n";
      }
    }

    return \@output;
  };

  local *_nimble_parse = sub {
    croak "_nimble_parse takes 1-2 arguments but got ".(scalar @_) if @_ < 1 || @_ > 2;
    croak "_nimble_parse expects an arrayref for its second argument" if @_==2 && !ref($_[1]) eq 'ARRAY';

    my @lines = @{$_[0]};

    my @extra_rules = $_[1] ? @{$_[1]} : ();

    my $section_depth = 0;

    # parse block-level syntaxes
    my ($i, @output, $tail, $prev_i);
    OUTER_LINE: for ($i=0; $i<@lines;) {
      die "_nimble_parse: no rule advanced line index for lines[$i]" if defined $prev_i && $i == $prev_i;
      $prev_i = $i;

      foreach my $extra_rule (@extra_rules) {
        my ($extra_re, $extra_fn) = @$extra_rule;
        my @extra_matches;
        if (@extra_matches = $lines[$i] =~ $extra_re) {
          push @output, $extra_fn->(\@extra_matches, \$i, \@lines);
          next OUTER_LINE;
        }
      }

      if (0) {
      # metadata
      } elsif (my ($meta_key, $meta_value) = $lines[$i] =~ /^\@(\w+)(?:\s+(.*?))?\s*$/) {
        $meta{$meta_key} = $meta_value // "";
        $i++;
      # codeblock
      } elsif (my ($codeblock_marker, $codeblock_lang) = $lines[$i] =~ /^(\`{3,})(?:\s*(\w+))?\s*$/) {
        my $node = {type=>"codeblock", lang=>$codeblock_lang, lines=>[]};
        $i++;

        for (; $i<@lines; $i++) {
          if ($lines[$i] =~ /^\Q$codeblock_marker\E\s*$/) {
            $i++; last;
          } else {
            push @{$node->{lines}}, $lines[$i];
          }
        }
        push @output, $node;
      # ul
      } elsif (my ($ul_indent, $ul_content) = $lines[$i] =~ /^\*( +)(.*?)$/) {
        my $node = {type=>"ul", list=>[[$ul_content]]};
        $i++;
        for (; $i<@lines; $i++) {
          if (($tail) = $lines[$i] =~ /^ $ul_indent(.*?)$/) {
            push @{$node->{list}[-1]}, $tail;
          } elsif (($ul_indent, $ul_content) = $lines[$i] =~ /^\*( +)(.*?)$/) {
            push @{$node->{list}}, [$ul_content];
          } else {
            last;
          }
        }
        $node->{list} = [ map { _nimble_parse($_) } @{$node->{list}} ];
        push @output, $node;
      # ol
      } elsif (my ($ol_indent, $ol_value, $ol_content) = $lines[$i] =~ /^((?:(\d+)|\#)\. +)(.*?)$/) {
        my $node = {type=>"ol", content=>[{type=>"li", value=>$ol_value, content=>[$ol_content]}]};
        $i++;
        $ol_indent = " " x length $ol_indent;
        for (; $i<@lines; $i++) {
          if (($tail) = $lines[$i] =~ /^$ol_indent(.*?)$/) {
            push @{$node->{content}[-1]{content}}, $tail;
          } elsif (($ol_value, $ol_content) = $lines[$i] =~ /^(?:(\d+)|\#)\. (.*?)$/) {
            push @{$node->{content}}, {type=>"li", value=>$ol_value, content=>[$ol_content]};
            $ol_indent = " " x ((defined $ol_value ? length $ol_value : 1) + 2);
          } else {
            last;
          }
        }
        $_->{content} = _nimble_parse($_->{content}) for @{$node->{content}};
        push @output, $node;
      # dl
      } elsif (my ($dl_indent, $dl_content) = $lines[$i] =~ /^\?( +)(.*?)$/) {
        my $node = {type=>"dl", content=>[{type=>"dt",content=>[$dl_content]}]};
        $i++;
        for (; $i<@lines; $i++) {
          if (($tail) = $lines[$i] =~ /^ $dl_indent(.*?)$/) {
            push @{$node->{content}[-1]{content}}, $tail;
          } elsif (($dl_indent, $dl_content) = $lines[$i] =~ /^\=( +)(.*?)$/) {
            push @{$node->{content}}, {type=>"dd",content=>[$dl_content]};
          } elsif (($dl_indent, $dl_content) = $lines[$i] =~ /^\?( +)(.*?)$/) {
            push @{$node->{content}}, {type=>"dt",content=>[$dl_content]};
          } else {
            last;
          }
        }
        $_->{content} = _nimble_parse($_->{content}) for @{$node->{content}};
        push @output, $node;
      # figure / figcaption
      } elsif (my ($fig_indent, $fig_content) = $lines[$i] =~ /^\%( +)(.*?)$/) {
        my $node = {type=>"figure", content=>[$fig_content]};
        $i++;

        for (; $i<@lines; $i++) {
          if (($tail) = $lines[$i] =~ /^ $fig_indent(.*?)$/) {
            push @{$node->{content}}, $tail;
          } else {
            last;
          }
        }

        $node->{content} = _nimble_parse($node->{content}, [
          [qr/^\=( +)(.*?)$/ => sub {
            my ($matches, $i, $lines) = @_;
            my ($figcap_indent, $figcap_content) = @$matches;
            my $node = {type=>"figcaption", content=>[$figcap_content]};
            $$i++;

            my $tail;
            for (; $$i<@$lines; $$i++) {
              if (($tail) = $lines->[$$i] =~ /^ $figcap_indent(.*?)$/) {
                push @{$node->{content}}, $tail;
              } else {
                last;
              }
            }

            $node->{content} = _nimble_parse($node->{content});
            return $node;
          }],
        ]);

        push @output, $node;
      # h#
      } elsif (my ($h_indent, $h_depth, $h_content) = $lines[$i] =~ /^(\!([123456]?) +)(.*?)$/) {
        my $node = {type=>"h", content=>[$h_content], depth=>$h_depth||1};
        $i++;

        $h_indent = " " x length $h_indent;
        for (; $i<@lines; $i++) {
          if (($tail) = $lines[$i] =~ /^$h_indent(.*?)$/) {
            push @{$node->{content}}, $tail;
          } else {
            last;
          }
        }

        $node->{content} = _nimble_parse_inline(join(" ", @{$node->{content}}));
        push @output, $node;
      # blockquote
      } elsif (my ($bq_indent, $bq_content) = $lines[$i] =~ /^\"( +)(.*?)$/) {
        my $node = {type=>"blockquote", quote=>[$bq_content]};
        $i++;

        my $section = 'quote';
        for (; $i<@lines; $i++) {
          if (($bq_content) = $lines[$i] =~ /^ $bq_indent(.*?)$/) {
            push @{$node->{$section}}, $bq_content;
          } elsif ($section eq 'quote' && (($bq_indent, $bq_content) = $lines[$i] =~ /^\-( +)(.*?)$/)) {
            $section = 'cite';
            $node->{$section} = [$bq_content];
          } else {
            last;
          }
        }

        $node->{$_} = _nimble_parse($node->{$_}) for grep { defined $node->{$_} } qw(quote cite);
        push @output, $node;
      # raw data
      } elsif (my ($raw_format, $raw_inline) = $lines[$i] =~ /^\#raw\s+(\w+)(?:\s+(.*?))?\s*$/) {
        my $node = {type=>"raw", format=>$raw_format, content=>[]};
        $i++;

        if (defined $raw_inline) {
          $node->{content} = $raw_inline;
        } else {
          for (; $i<@lines; $i++) {
            if (my ($raw_line) = $lines[$i] =~ /^ +(.*?)\s*$/) {
              push @{$node->{content}}, $raw_line;
            } else {
              last;
            }
          }
          $node->{content} = join("\n", @{$node->{content}});
        }

        push @output, $node;
      # macro definition
      } elsif (my ($macro_decl) = $lines[$i] =~ /^\#macro\s+(\w+)\s*$/) {
        my $macro = {args=>{}, results=>{}};
        $i++;

        my @errors;
        push @errors, "a macro named '$macro_decl' already exists" if $macro{$macro_decl};
        # we're building $macro as a temp variable, so no need to skip altering logic based on @errors

        my ($block_type, $block_name, $block_value, $block_indent, $block_internal_indent);
        for (; $i<@lines; $i++) {
          if (defined $block_type && (my ($block_line) = $lines[$i] =~ /^$block_indent( +.*?)\s*$/)) {
            if (!defined $block_internal_indent) {
              $block_line =~ /^( +)/;
              $block_internal_indent = $1;
            }
            $block_line =~ s/^$block_internal_indent//;
            push @{$macro->{$block_type}{$block_name}{$block_value}}, $block_line;
          } elsif (my ($arg_indent, $arg_name, $arg_type, $arg_inline_default) = $lines[$i] =~ /^( +)\#arg\s+(\w+)\s+(\w+)(?:\s+(\S.*?))?\s*$/) {
            push @errors, "duplicate definition for argument '$arg_name'" if $macro->{args}{$arg_name};
            push @errors, "invalid type '$arg_type' for argument '$arg_name'" unless $arg_type =~ /^(?:nimble|raw)$/;
            $macro->{args}{$arg_name} = {type=>$arg_type, default=>[]};
            if (defined $arg_inline_default) {
              $macro->{args}{$arg_name}{default} = $arg_inline_default;
              $block_type = undef;
            } else {
              ($block_type, $block_name, $block_value, $block_indent, $block_internal_indent) = ("args", $arg_name, "default", $arg_indent, undef);
            }
          } elsif (my ($result_indent, $result_format, $result_inline_default) = $lines[$i] =~ /^( +)\#result\s+(\w+)(?:\s+(\S.*?))?\s*$/) {
            push @errors, "duplicate definition of '$result_format'-format result" if $macro->{results}{$result_format};
            $macro->{results}{$result_format} = {output=>[]};
            if (defined $result_inline_default) {
              $macro->{results}{$result_format}{output} = $result_inline_default;
              $block_type = undef;
            } else {
              ($block_type, $block_name, $block_value, $block_indent, $block_internal_indent) = ("results", $result_format, "output", $result_indent, undef);
            }
          } else {
            last;
          }
        }

        if (!@errors) {
          foreach my $arg_name (keys %{$macro->{args}}) {
            $macro->{args}{$arg_name}{default} = _macro_arg_preprocess($macro->{args}{$arg_name}{type}, $macro->{args}{$arg_name}{default});
          }
          foreach my $result_format (keys %{$macro->{results}}) {
            $macro->{results}{$result_format}{output} = join("\n", @{$macro->{results}{$result_format}{output}}) if ref $macro->{results}{$result_format}{output};
          }

          $macro{$macro_decl} = $macro;
        } else {
          my $node = {type=>"error", context=>"defining macro '$macro_decl'", errors=>\@errors};
          push @error, $node;
          push @output, $node;
        }
      # macro usage
      } elsif (my ($macro_name) = $lines[$i] =~ /^\$\s*(\w+)\s*$/) {
        my $node = {type=>"macro", macro=>$macro_name, args=>{}};
        $i++;

        my @errors;
        push @errors, "no macro by that name is defined" unless $macro{$macro_name};

        my ($block_indent, $arg_block_name, $block_internal_indent);
        for (; $i<@lines; $i++) {
          if (defined $arg_block_name && (my ($block_line) = $lines[$i] =~ /^$block_indent( +.*?)\s*$/)) {
            if (!defined $block_internal_indent) {
              $block_line =~ /^( +)/;
              $block_internal_indent = $1;
            }
            $block_line =~ s/^$block_internal_indent//;
            if (!@errors) {
              push @{$node->{args}{$arg_block_name}}, $block_line;
            }
          } elsif (my ($arg_indent, $arg_name, $arg_inline_default) = $lines[$i] =~ /^( +)(\w+)\:(?:\s+(\S.*?))?\s*$/) {
            push @errors, "duplicate argument '$arg_name'" if $node->{args}{$arg_name};
            push @errors, "unknown argument '$arg_name'" unless $macro{$macro_name}{args}{$arg_name};
            if (!@errors) {
              $node->{args}{$arg_name} = [];
            }
            if (defined $arg_inline_default) {
              if (!@errors) {
                $node->{args}{$arg_name} = $arg_inline_default;
              }
              $arg_block_name = undef;
            } else {
              ($arg_block_name, $block_indent, $block_internal_indent) = ($arg_name, $arg_indent, undef);
            }
          } else {
            last;
          }
        }

        if (!@errors) {
          _macro_invocation_preprocess($macro_name, $node);
        }

        if (@errors) {
          $node = {type=>"error", context=>"building block macro '$macro_name' invocation", errors=>\@errors};
          push @error, $node;
        }
        push @output, $node;
      # space
      } elsif ($lines[$i] =~ /^\s*$/) {
        push @output, {type=>"space"} unless @output && $output[-1]{type} eq 'space';
        $i++;
      # section start/end markers; below 'space' so at least one half of the regex matches
      } elsif (my ($section_end, $header_indent, $header_content) = $lines[$i] =~ /^(\}*)(?:(\{ +)(.*?))?$/) {
        $i++;
        if (defined $section_end) {
          my $section_end_num = length($section_end);
          if ($section_end_num > $section_depth) {
            my $node = {type=>"error", context=>"processing section end makers", errors=>["tried to end a section which wasn't open"]};
            push @error, $node;
            push @output, $node;
            $section_end_num = $section_depth;
          }
          push @output, {type=>"section_end"} for 1..$section_end_num;
          $section_depth -= $section_end_num;
        }
        if (defined $header_content) {
          my $node = {type=>"section_start", content=>[$header_content]};

          $header_indent = " " x (length($header_indent) + (defined $section_end ? length($section_end) : 0));
          for (; $i<@lines; $i++) {
            if (($tail) = $lines[$i] =~ /^$header_indent(.*?)$/) {
              push @{$node->{content}}, $tail;
            } else {
              last;
            }
          }

          $node->{content} = _nimble_parse($node->{content});
          push @output, $node;
          $section_depth++;
        }
      # paragraph
      } else {
        my $line = $lines[$i];
        $line =~ s/^\s+//; $line =~ s/\s+$//;
        if (@output && $output[-1]{type} eq 'paragraph') {
          $output[-1]{content} .= " $line";
        } else {
          push @output, {type=>"paragraph", content=>$line};
        }
        $i++;
      }
    }

    # clean up remaining sections
    push @output, {type=>"section_end"} for 1..$section_depth;

    # drop spaces; they were just to delimit paragraphs
    @output = grep {$_->{type} ne 'space'} @output;

    # parse text which has been collected into paragraphs
    $_->{content} = _nimble_parse_inline($_->{content}) for grep {$_->{type} eq 'paragraph'} @output;

    return \@output;
  };

  do {
    my $lines = _nimble_makelines($_[0]);
    my $tree = _nimble_parse($lines);
    return {tree=>$tree, meta=>\%meta, macro=>\%macro, (@error ? (error=>\@error) : ())};
  };
}

sub _renderer_html {
  croak "Text::Nimble::_renderer_html takes one argument but got ".(scalar @_) unless @_ == 1;
  croak "Text::Nimble::_renderer_html got an argument that doesn't look like the result of Text::Nimble::parse" unless ref $_[0] eq 'HASH' && $_[0]{tree} && $_[0]{macro};

  my %macro = %{$_[0]{macro}};

  my %xmlenc = (
    '&' => '&amp;',
    '"' => '&quot;',
    '<' => '&lt;',
    '>' => '&gt;',
  );
  local *_xmlenc = sub {
    my $s = $_[0];
    $s =~ s/([\&\"\<\>])/$xmlenc{$1}/g;
    return $s;
  };

  local *_urlenc = sub {
    my $s = $_[0];
    $s =~ s/([^a-zA-Z0-9\ ])/sprintf("%%%02X",ord($1))/ge;
    $s =~ s/\ /\+/g;
    return $s;
  };

  my %macro_filters = (
    xmlenc => \&_xmlenc,
    urlenc => \&_urlenc,
  );

  local *_macro_var_interpolate = sub {
    my ($macro, $arg_name, $filters) = @_;
    my @filters = defined $filters ? split(/\|/, $filters) : ();
    my @unknown_filters = grep {!$macro_filters{$_}} @filters;
    return "[nimble macro error: unknown argument filters(s): " . join(", ", @unknown_filters) . "]" if @unknown_filters;
    my $value = $macro->{args}{$arg_name};
    $value = $macro_filters{$_}($value) for @filters;
    return $value;
  };

  local *_render_html = sub {
    my $node = shift;

    # handle a list of nodes, especially the root level of Text::Nimble::parse
    if (ref $node eq 'ARRAY') {
      # a lone paragraph should just be plain text instead
      if (@$node == 1 && $node->[0]{type} eq 'paragraph') {
        return _render_html($node->[0]{content});
      } else {
        return join("", map { _render_html($_) } @$node) if ref $node eq 'ARRAY';
      }
    }

    my $type = $node->{type};
    if (0) {}
    elsif ($type eq 'paragraph'  ) { return "<p>"     ._render_html($node->{content})."</p\n>" }
    elsif ($type eq 'dl'         ) { return "<dl>"    ._render_html($node->{content})."</dl\n>" }
    elsif ($type eq 'dt'         ) { return "<dt>"    ._render_html($node->{content})."</dt>" }
    elsif ($type eq 'dd'         ) { return "<dd>"    ._render_html($node->{content})."</dd>" }
    elsif ($type eq 'emphasis'   ) { return "<em>"    ._render_html($node->{content})."</em>" }
    elsif ($type eq 'ol'         ) { return "<ol>"    ._render_html($node->{content})."</ol\n>" }
    elsif ($type eq 'figure'     ) { return "<figure>"._render_html($node->{content})."</figure\n>" }
    elsif ($type eq 'figcaption' ) { return "<figcaption>"._render_html($node->{content})."</figcaption\n>" }
    elsif ($type eq 'h'          ) { return "<h$node->{depth}>"._render_html($node->{content})."</h$node->{depth}\n>" }
    elsif ($type eq 'strong'     ) { return "<strong>"._render_html($node->{content})."</strong>" }
    elsif ($type eq 'link'       ) { return "<a href=\""._xmlenc($node->{url})."\">"._render_html($node->{content})."</a>" }
    elsif ($type eq 'img'        ) { return "<img src=\""._xmlenc($node->{src})."\" alt=\""._xmlenc($node->{alt})."\"/>" }
    elsif ($type eq 'li'         ) { return "<li".(defined $node->{value}?" value=\"$node->{value}\"":"").">"._render_html($node->{content})."</li>" }
    elsif ($type eq 'code'       ) { return "<code>"._xmlenc($node->{text})."</code>" }
    elsif ($type eq 'codeblock'  ) { return "<pre>".join("\n", map{_xmlenc($_)} @{$node->{lines}})."</pre\n>" }
    elsif ($type eq 'text'       ) { return _xmlenc($node->{text}) }
    elsif ($type eq 'entity'     ) { return $node->{html} }
    elsif ($type eq 'ul'         ) { return "<ul>".join("", map{"<li>"._render_html($_)."</li>"} @{$node->{list}})."</ul\n>" }
    elsif ($type eq 'raw'        ) { return $node->{format} eq 'html' ? $node->{content} : '' }
    elsif ($type eq 'error'      ) { return "<span class=\"nimble-error\">Nimble error while "._xmlenc($node->{context}).": ".join("; ", map{_xmlenc($_)} @{$node->{errors}})."</span\n>" }
    elsif ($type eq 'blockquote' ) {
      my $bq_html = "<blockquote>"._render_html($node->{quote})."</blockquote\n>";
      $bq_html = "<figure class=\"quote\">$bq_html<figcaption>"._render_html($node->{cite})."</figcaption></figure\n>" if $node->{cite};
      return $bq_html;
    }
    elsif ($type eq 'section_start') {
      return "<section\n>"
      . (@{$node->{content}}
         ? "<header>"._render_html(
             @{$node->{content}} == 1 && $node->{content}[0]{type} eq 'paragraph'
             ? [{%{$node->{content}[0]}, type=>"h", depth=>1}]
             : $node->{content}
           )."</header\n>"
         : ""
        )
    }
    elsif ($type eq 'section_end') { return "</section\n>" }
    elsif ($type eq 'macro') {
      return "" unless $macro{$node->{macro}}{results}{html};

      $node->{args}{$_} = _render_html($node->{args}{$_}) for grep {ref $node->{args}{$_}} keys %{$node->{args}};

      my $output = $macro{$node->{macro}}{results}{html}{output};
      $output =~ s/\{\{(\w+)(?:\|(\w+(?:\|\w+)*))?\}\}/_macro_var_interpolate($node, $1, $2)/ge;
      return $output;
    }
  };

  do {
    my $parse = $_[0];
    return _render_html($parse->{tree});
  };
}

1; # End of Text::Nimble

__END__

=head1 NAME

Text::Nimble - Parse and render Nimble markup.

=head1 SYNOPSIS

    use Text::Nimble;

    my $nimble = <<END;
    @title This title will end up in $meta->{title}.

    { Nimble Example

    This *Nimble text* demonstrates a /few/ features.

    }
    END

    # just get html
    my  $html                  = Text::Nimble::render(html => $nimble);

    # or, get html, metadata, errors
    my ($html, $meta, $errors) = Text::Nimble::render(html => $nimble);

    # or, parse and render in separate steps
    my $parsetree              = Text::Nimble::parse($nimble);
    my ($html, $meta, $errors) = Text::Nimble::render(html => $parsetree);

=head1 DESCRIPTION

This module provides a function-oriented interface for parsing and rendering
Nimble markup.

For details on Nimble syntax and the project in general, see
L<http://was.tl/projects/nimble/>.

=head1 FUNCTIONS

In case of error, these functions try to C<croak> when used improperly (such as
being invoked with invalid parameters) and C<die> when something which was
expected to be impossible happens (a bug, like the parser producing a token it
doesn't know how to handle).  Syntax errors do not C<die> or even C<warn>, but
instead are left in the parse tree as special nodes of type C<error>; these
nodes are collected and L<returned by C<parse()>|/error> or included in the output
produced by C<render()>.

=over

=item C<Text::Nimble::parse(I<$markup>)>

Converts Nimble text into a parse tree.  Takes a scalar containing an entire
Nimble document. Returns a reference to a hash with these entries:

=over

=item C<tree>

The parse tree representing the renderable parts of the document.

=item C<meta>

A reference to a hash containing the document's metadata.

=item C<macro>

A reference to a hash which defined the macros declared in the document.

=item C<error>

Omitted if there were no errors; otherwise, a reference to an array of
references to error nodes within the parsetree.  Each error node is a hash
containing a C<type> (always C<"error">), a C<context> (a string describing
what was going on when the error occurred), and C<errors>, a reference to an
array of error message strings.

=back

=item C<Text::Nimble::render(I<$format>, I<$input>)>

Renders some input (either a parse tree from C<Text::Nimble::parse> or a scalar
containing an entire Nimble document) given some render format.  In scalar
context, returns a string containing the rendered data.  In list context,
returns a string containing the rendered data, a reference to a hash of the
document's metadata, and either undef (if there were no errors) or a reference
to an array of errors copied from L<the result of C<parse()>|/error>.

=back

=head1 AUTHOR

Eric Wastl, C<< <topaz at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-nimble at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Nimble>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Nimble

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Nimble>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Nimble>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Nimble>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Nimble/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Eric Wastl.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
