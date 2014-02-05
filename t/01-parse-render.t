#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Text::Nimble;

my $test_input = test_input();
my $exp_parsetree = exp_parsetree();
my $exp_html = exp_html();

subtest "parse" => sub {
  my $act_parsetree = Text::Nimble::parse($test_input);
  is_deeply($act_parsetree, $exp_parsetree, "Verify parsetree matches expected output");
};

subtest "parse+render html (scalar)" => sub {
  my $act_parsetree = Text::Nimble::parse($test_input);
  my $act_html = Text::Nimble::render(html => $act_parsetree);
  is($act_html, $exp_html);
};

subtest "parse+render html (list)" => sub {
  my $act_parsetree = Text::Nimble::parse($test_input);
  my ($act_html, $act_meta, $act_error) = Text::Nimble::render(html => $act_parsetree);
  is($act_html, $exp_html);
  is_deeply($act_meta, $exp_parsetree->{meta});
  is_deeply($act_error, $exp_parsetree->{error});
};

subtest "render html (scalar)" => sub {
  my $act_html = Text::Nimble::render(html => $test_input);
  is($act_html, $exp_html);
};

subtest "render html (list)" => sub {
  my ($act_html, $act_meta, $act_error) = Text::Nimble::render(html => $test_input);
  is($act_html, $exp_html);
  is_deeply($act_meta, $exp_parsetree->{meta});
  is_deeply($act_error, $exp_parsetree->{error});
};

done_testing();



sub test_input { my $d = <<'EOF'; chomp($d); $d }
@title The title of the document with literal /slashes/ and `backticks`.

A regular paragraph.

Text can be *bold* or /italic/ or `code` or normal.

What about parts of mount*ain*ous, ramb/unct/ious, or alu`min`ium?

*paragraphs* can start with formats or end with /them/

What about */nesting/* different /`combinations`/ of `*format codes*`?

paragraphs *can
wrap* /across
multiple/ lines

Suppose you want actual \\backslashes\\, \*asterisks\*, \/slashes\/, \`backticks\`, \[square brackets\], \http:\/\/abcde...

What about...
* word* word* word
* word *word *word
* *word *word* word*
* word*word word*word
* word * word * word
* bolding a single *\\*

```
here is some

``totally * verbatim / and \ weird

<programming> &" code
```

````
here is some code that has
```
regular markers
```
inside it
````

Within code, ``*, /, \, <, >, ", &, ` `` should be literal!

Outside code, <, >, ", & should be literal!

Code can be `a`, ``a``, `  a  `, ``  a  ``, `` ` ``, ````` ```` `````...

*this* paragraph starts with an asterisk.
*it* isn't a list.

This paragraph
* has a
* bulleted list
dividing it in two.

Link with weird chars?  [http://example.com/?a=\\&b=\]] and stuff that shouldn't be included]

Or a regular link? [http://example.com/?a=1&b=2 link label]

Or a formatted link? *[http://example.com/?a=1&b=2 link /label/ with `code` and \] stuff]*

Or a link containing a backslash or a closing bracket? *[http://example.com/?a=\\&b=\] link /label/ with `code` and \\ and \] stuff\\\] and so on]*

But this isn't linked:  \http://example.com/?a=1&b=2

Nor this: \[http://example.com/?a=1&b=2 link label]

Nor this: *\[http://example.com/?a=2&b=2 link /label/ with `code` and \] stuff]*

*   this li starts with too many spaces
*   *   this sub-element does too

" Here is a
  quoted block
  of text

* bulleted lists
  can have items
  which span multiple lines
* or items that sit on one big line
* or,
  * items which themselves
  * contain lists
* * or items
  * which are just lists
  * themselves

* this list
  
  contains several
  
  paragraphs of text
* i guess that's fine...

* this list

  contains several

  paragraphs
* but it didn't indent the blanks between them...

* #. this list
  #. is auto-numbered
* 2. this list
  4. is force-numbered
* 10. this
      list
  #. automatically
     continues
  #. from
     the start
* #. this list starts
     with auto-numbering
  10. and then switches
      to force-numbering

1.  * this
    * list
10. * jumps
    * to ten

% a plain figure

% a figure with
  = the caption last

% = the caption before
  the figure content

% a figure which
  
  contains multiple paragraphs
  = and finally a caption

% " a figure which
    itself is a blockquote
    
    which itself spans multiple paragraphs
  = and finally a caption

" a quote which

  ```
  goes for
  ```

  several paragraphs
- by I Like Typing, Esq

%  =  a figure with

   *  too many spaces

   *  before everything
      *  even this
      *  and this

% ? a figure which
  = contains a dl
  ? the dl's dd's shouldn't
  = become figcaptions instead

  = this /should/ be a figcaption, though

? dt1
= dd1
? dt2
= ? dd2_dt1
  = dd2_dd1
  ? dd2_dt2
  = dd2_dd2
? dt3
= dd3

?  dt1
=  dd1
?  dt2
=  ?  dd2_dt1
   =  dd2_dd1
   ?  dd2_dt2
   =  dd2_dd2
?  dt3
=  dd3

* ? 1q
  = 1a
* ? 2q
  = 2a

* in a list, *formats
  still* flow /over
  line/ breaks

? this *also
  happens* /within
  <dt>s/ correctly
= this *also
  happens* /within
  <dd>s/ correctly

"  *  bq with
   *  too many
   *  spaces

Let's test some syntax errors!

Broken * strong...

Broken / emphasis...

Broken ` code...

[http://asdf.com/ broken link...

Strong *which finishes* and *restarts...

Wrongly *nested /inline* styles/...

{ section I
I content
{ ! section a
  (subtitle for section a)
a content
{ section a1
  goes for several
  lines of input
a1 content
}{ section a2
   
   is two /paragraphs/?
a2 content

}

a content

}

I content

{ section b

\{ regular paragraph

b content

\}

}

I content
}

!  hard header
   *  with a list
   *  that shouldn't parse

Here's Kitsu when she was a puppy:

[img kitsu-thumb.jpg Kitsu when she was a *puppy*]  <-- the markup in the alt should be literal

[kitsu-thumb.jpg [img kitsu-thumb.jpg maybe a \\ backslash or \] closing bracket?]]  <-- the markup in the alt should be literal

[kitsu-thumb.jpg [img kitsu-thumb.jpg maybe a \\ backslash or \] closing bracket?]  <-- this shouldn't crash or hang

[img kitsu-thumb.jpg maybe a \\ backslash or \] closing bracket?]  <-- backslash and closing bracket in alt should not be preceeded by backslashes

Here's the picture again with a link to the bigger picture: [kitsu-full.jpg start link &hearts; ==> &#x2665; [img kitsu-thumb.jpg Kitsu when she was a puppy] &#9829; <== &hearts; link end]

Deep recursion during [http://php.net/clone clone] will cause a *segfault*.

What about just [] stray brackets, or [http://example.com/ [\]] ones inside of a link?

#macro lightbox
  #arg thumb   raw
  #arg full    raw
  #arg caption raw
  #arg alt     raw thumb
  #arg group   raw lightbox
  #result html
    <a href="{{full|xmlenc}}" data-lightbox="{{group|xmlenc}}" title="{{caption|xmlenc}}"><img src="{{thumb|xmlenc}}" alt="{{alt|xmlenc}}" width="200" height="150"/></a>

$lightbox
  thumb: kitsu-thumb.jpg
  full: kitsu-full.jpg
  caption: Kitsu when she was a puppy
  alt: <some> *obnoxious* /symbols/

#macro phplink
  #arg topic raw
  #result html
    <a class="phplink" href="http://php.net/{{topic|urlenc|xmlenc}}">{{topic|xmlenc}}</a>

Deep recursion during [$phplink topic=clone\]] will cause a *segfault*.

Deep recursion during [$phplink topic="a bunch of text"] will cause a *segfault*.

#macro aside
  #arg contents nimble
  #result html
    <aside>{{contents}}</aside>

$aside
  contents:
    * stuff
    * [$phplink topic=clone]
    * here

#macro warning
  #arg title nimble some /formatted/ title
  #arg body nimble
    * this is a
    * default list
  #result html
    <div class="warningbox"
      ><h1>{{title}}</h1
      >{{body}}</div
    >

$warning
  title: don't use [$phplink topic=clone]
  body:
    * could segfault
    * no really

#macro inlinetest
  #arg a raw
  #arg b raw
  #arg c raw
  #result html <span style="color:red;">{{a|xmlenc}}</span><span style="color:green;">{{b|xmlenc}}</span><span style="color:blue;">{{c|xmlenc}}</span>

Macro inlinetest --> [$inlinetest a="a1 a2 \" a3 a4" b='b1 " b2 \' b3 b4' c="c1 c2 ' c3 c4"] <-- end macro

Macro inlinetest --> [$inlinetest a="a1 a2 [ a3 a4" b="b1 ] b2 [ b3 b4" c="c1 c2 ] c3 c4"] <-- end macro

Macro inlinetest --> [$inlinetest a="a1 a2 [ a3 a4" b="b1 ] b2 [ b3 b4" c="c1 c2 ] <-- end macro

Macro inlinetest --> [$inlinetest a=aaaa'aaa b="b1 b2 b3 b4" c=ccc"ccc] <-- end macro

#raw html <p><s>Strikethrough!</s></p>

Or, a paragraph with an [raw html <s>inline</s>] strikethrough!

#raw html
  <ul>
    <li>This UL is made of raw HTML.</li>
    <li>It's not nimble code.</li>
    <li>Why?</li>
    <li>Why not?</li>
  </ul>

{ Let's test some error handling

#macro errortest
  #arg a raw
  #arg b raw
  #result html MACRO RENDERED (a={{a|xmlenc}})

Inline macro invocation of unknown macro: [$dne]

Inline macro invocation with 1x duplicate argument: [$errortest a=1 b=1 a=1]

Inline macro invocation with 2x duplicate argument: [$errortest a=1 a=1 b=1 a=1]

Inline macro invocation with 1x unknown argument: [$errortest a=1 c=1 b=1]

Inline macro invocation with 2x unknown argument: [$errortest a=1 c=1 b=1 c=1]

Inline macro invocation with duplicate argument and unknown argument: [$errortest a=1 a=1 c=1]

Duplicate macro definition:

#macro errortest

Macro definition with duplicate arguments:

#macro invalidmacro
  #arg a raw
  #arg a raw

Macro definition with invalid argument types:

#macro invalidmacro
  #arg a invalid

Macro definition with duplicate format definitions:

#macro invalidmacro
  #result html a
  #result html a

Macro definition with duplicate arguments, invalid argument types, and duplicate formats definitions:

#macro invalidmacro
  #arg a raw
  #arg a raw
  #arg b invalid

Block macro invocation of unknown macro:

$dne

Block macro invocation with 1x duplicate argument:

$errortest
  a: 1
  b: 1
  a: 1

Block macro invocation with 2x duplicate argument:

$errortest
  a: 1
  a: 1
  b: 1
  a: 1

Block macro invocation with 1x unknown argument:

$errortest
  a: 1
  c: 1
  b: 1

Block macro invocation with 2x unknown argument:

$errortest
  a: 1
  c: 1
  b: 1
  c: 1

Block macro invocation with duplicate argument and unknown argument:

$errortest
  a: 1
  a: 1
  c: 1

}

And we can end in just raw text, too.
EOF

sub exp_html { my $d = <<'EOF'; chomp($d); $d }
<p>A regular paragraph.</p
><p>Text can be <strong>bold</strong> or <em>italic</em> or <code>code</code> or normal.</p
><p>What about parts of mount<strong>ain</strong>ous, ramb<em>unct</em>ious, or alu<code>min</code>ium?</p
><p><strong>paragraphs</strong> can start with formats or end with <em>them</em></p
><p>What about <strong><em>nesting</em></strong> different <em><code>combinations</code></em> of <code>*format codes*</code>?</p
><p>paragraphs <strong>can wrap</strong> <em>across multiple</em> lines</p
><p>Suppose you want actual \backslashes\, *asterisks*, /slashes/, `backticks`, [square brackets], http://abcde...</p
><p>What about...</p
><ul><li>word* word* word</li><li>word *word *word</li><li><strong>word <strong>word</strong> word</strong></li><li>word<strong>word word</strong>word</li><li>word * word * word</li><li>bolding a single <strong>\</strong></li></ul
><pre>here is some

``totally * verbatim / and \ weird

&lt;programming&gt; &amp;&quot; code</pre
><pre>here is some code that has
```
regular markers
```
inside it</pre
><p>Within code, <code>*, /, \, &lt;, &gt;, &quot;, &amp;, `</code> should be literal!</p
><p>Outside code, &lt;, &gt;, &quot;, &amp; should be literal!</p
><p>Code can be <code>a</code>, <code>a</code>, <code>a</code>, <code>a</code>, <code>`</code>, <code>````</code>...</p
><p><strong>this</strong> paragraph starts with an asterisk. <strong>it</strong> isn't a list.</p
><p>This paragraph</p
><ul><li>has a</li><li>bulleted list</li></ul
><p>dividing it in two.</p
><p>Link with weird chars?  <a href="http://example.com/?a=\&amp;b=]">http://example.com/?a=\&amp;b=]</a> and stuff that shouldn't be included]</p
><p>Or a regular link? <a href="http://example.com/?a=1&amp;b=2">link label</a></p
><p>Or a formatted link? <strong><a href="http://example.com/?a=1&amp;b=2">link <em>label</em> with <code>code</code> and ] stuff</a></strong></p
><p>Or a link containing a backslash or a closing bracket? <strong><a href="http://example.com/?a=\&amp;b=]">link <em>label</em> with <code>code</code> and \ and ] stuff\] and so on</a></strong></p
><p>But this isn't linked:  http:/<em>example.com</em>?a=1&amp;b=2</p
><p>Nor this: [http:/<em>example.com</em>?a=1&amp;b=2 link label]</p
><p>Nor this: <strong>[http:/<em>example.com</em>?a=2&amp;b=2 link <em>label</em> with <code>code</code> and ] stuff]</strong></p
><ul><li>this li starts with too many spaces</li><li><ul><li>this sub-element does too</li></ul
></li></ul
><blockquote>Here is a quoted block of text</blockquote
><ul><li>bulleted lists can have items which span multiple lines</li><li>or items that sit on one big line</li><li><p>or,</p
><ul><li>items which themselves</li><li>contain lists</li></ul
></li><li><ul><li>or items</li><li>which are just lists</li><li>themselves</li></ul
></li></ul
><ul><li><p>this list</p
><p>contains several</p
><p>paragraphs of text</p
></li><li>i guess that's fine...</li></ul
><ul><li><p>this list</p
><p>contains several</p
><p>paragraphs</p
></li><li>but it didn't indent the blanks between them...</li></ul
><ul><li><ol><li>this list</li><li>is auto-numbered</li></ol
></li><li><ol><li value="2">this list</li><li value="4">is force-numbered</li></ol
></li><li><ol><li value="10">this list</li><li>automatically continues</li><li>from the start</li></ol
></li><li><ol><li>this list starts with auto-numbering</li><li value="10">and then switches to force-numbering</li></ol
></li></ul
><ol><li value="1"><ul><li>this</li><li>list</li></ul
></li><li value="10"><ul><li>jumps</li><li>to ten</li></ul
></li></ol
><figure>a plain figure</figure
><figure><p>a figure with</p
><figcaption>the caption last</figcaption
></figure
><figure><figcaption>the caption before</figcaption
><p>the figure content</p
></figure
><figure><p>a figure which</p
><p>contains multiple paragraphs</p
><figcaption>and finally a caption</figcaption
></figure
><figure><blockquote><p>a figure which itself is a blockquote</p
><p>which itself spans multiple paragraphs</p
></blockquote
><figcaption>and finally a caption</figcaption
></figure
><figure class="quote"><blockquote><p>a quote which</p
><pre>goes for</pre
><p>several paragraphs</p
></blockquote
><figcaption>by I Like Typing, Esq</figcaption></figure
><figure><figcaption>a figure with</figcaption
><ul><li>too many spaces</li></ul
><ul><li><p>before everything</p
><ul><li>even this</li><li>and this</li></ul
></li></ul
></figure
><figure><dl><dt>a figure which</dt><dd>contains a dl</dd><dt>the dl's dd's shouldn't</dt><dd>become figcaptions instead</dd></dl
><figcaption>this <em>should</em> be a figcaption, though</figcaption
></figure
><dl><dt>dt1</dt><dd>dd1</dd><dt>dt2</dt><dd><dl><dt>dd2_dt1</dt><dd>dd2_dd1</dd><dt>dd2_dt2</dt><dd>dd2_dd2</dd></dl
></dd><dt>dt3</dt><dd>dd3</dd></dl
><dl><dt>dt1</dt><dd>dd1</dd><dt>dt2</dt><dd><dl><dt>dd2_dt1</dt><dd>dd2_dd1</dd><dt>dd2_dt2</dt><dd>dd2_dd2</dd></dl
></dd><dt>dt3</dt><dd>dd3</dd></dl
><ul><li><dl><dt>1q</dt><dd>1a</dd></dl
></li><li><dl><dt>2q</dt><dd>2a</dd></dl
></li></ul
><ul><li>in a list, <strong>formats still</strong> flow <em>over line</em> breaks</li></ul
><dl><dt>this <strong>also happens</strong> <em>within &lt;dt&gt;s</em> correctly</dt><dd>this <strong>also happens</strong> <em>within &lt;dd&gt;s</em> correctly</dd></dl
><blockquote><ul><li>bq with</li><li>too many</li><li>spaces</li></ul
></blockquote
><p>Let's test some syntax errors!</p
><p>Broken * strong...</p
><p>Broken / emphasis...</p
><p>Broken ` code...</p
><p>[http:/<em>asdf.com</em> broken link...</p
><p>Strong <strong>which finishes</strong> and *restarts...</p
><p>Wrongly *nested <em>inline* styles</em>...</p
><section
><header><h1>section I</h1
></header
><p>I content</p
><section
><header><h1>section a</h1
><p>(subtitle for section a)</p
></header
><p>a content</p
><section
><header><h1>section a1 goes for several lines of input</h1
></header
><p>a1 content</p
></section
><section
><header><p>section a2</p
><p>is two <em>paragraphs</em>?</p
></header
><p>a2 content</p
></section
><p>a content</p
></section
><p>I content</p
><section
><header><h1>section b</h1
></header
><p>{ regular paragraph</p
><p>b content</p
><p>}</p
></section
><p>I content</p
></section
><h1>hard header *  with a list *  that shouldn't parse</h1
><p>Here's Kitsu when she was a puppy:</p
><p><img src="kitsu-thumb.jpg" alt="Kitsu when she was a *puppy*"/>  &larr; the markup in the alt should be literal</p
><p><a href="kitsu-thumb.jpg"><img src="kitsu-thumb.jpg" alt="maybe a \ backslash or ] closing bracket?"/></a>  &larr; the markup in the alt should be literal</p
><p>[kitsu-thumb.jpg <img src="kitsu-thumb.jpg" alt="maybe a \ backslash or ] closing bracket?"/>  &larr; this shouldn't crash or hang</p
><p><img src="kitsu-thumb.jpg" alt="maybe a \ backslash or ] closing bracket?"/>  &larr; backslash and closing bracket in alt should not be preceeded by backslashes</p
><p>Here's the picture again with a link to the bigger picture: <a href="kitsu-full.jpg">start link &hearts; &rArr; &#x2665; <img src="kitsu-thumb.jpg" alt="Kitsu when she was a puppy"/> &#9829; &lArr; &hearts; link end</a></p
><p>Deep recursion during <a href="http://php.net/clone">clone</a> will cause a <strong>segfault</strong>.</p
><p>What about just [] stray brackets, or [http:/<em>example.com</em> <a href="]">]</a> ones inside of a link?</p
><a href="kitsu-full.jpg" data-lightbox="lightbox" title="Kitsu when she was a puppy"><img src="kitsu-thumb.jpg" alt="&lt;some&gt; *obnoxious* /symbols/" width="200" height="150"/></a><p>Deep recursion during <a class="phplink" href="http://php.net/clone%5D">clone]</a> will cause a <strong>segfault</strong>.</p
><p>Deep recursion during <a class="phplink" href="http://php.net/a+bunch+of+text">a bunch of text</a> will cause a <strong>segfault</strong>.</p
><aside><ul><li>stuff</li><li><a class="phplink" href="http://php.net/clone">clone</a></li><li>here</li></ul
></aside><div class="warningbox"
  ><h1>don't use <a class="phplink" href="http://php.net/clone">clone</a></h1
  ><ul><li>could segfault</li><li>no really</li></ul
></div
><p>Macro inlinetest &rarr; <span style="color:red;">a1 a2 &quot; a3 a4</span><span style="color:green;">b1 &quot; b2 ' b3 b4</span><span style="color:blue;">c1 c2 ' c3 c4</span> &larr; end macro</p
><p>Macro inlinetest &rarr; <span style="color:red;">a1 a2 [ a3 a4</span><span style="color:green;">b1 ] b2 [ b3 b4</span><span style="color:blue;">c1 c2 ] c3 c4</span> &larr; end macro</p
><p>Macro inlinetest &rarr; [$inlinetest a=&quot;a1 a2 [ a3 a4&quot; b=&quot;b1 ] b2 [ b3 b4&quot; c=&quot;c1 c2 ] &larr; end macro</p
><p>Macro inlinetest &rarr; <span style="color:red;">aaaa'aaa</span><span style="color:green;">b1 b2 b3 b4</span><span style="color:blue;">ccc&quot;ccc</span> &larr; end macro</p
><p><s>Strikethrough!</s></p><p>Or, a paragraph with an <s>inline</s> strikethrough!</p
><ul>
<li>This UL is made of raw HTML.</li>
<li>It's not nimble code.</li>
<li>Why?</li>
<li>Why not?</li>
</ul><section
><header><h1>Let's test some error handling</h1
></header
><p>Inline macro invocation of unknown macro: <span class="nimble-error">Nimble error while building inline macro 'dne' invocation: no macro by that name is defined</span
></p
><p>Inline macro invocation with 1x duplicate argument: <span class="nimble-error">Nimble error while building inline macro 'errortest' invocation: duplicate argument 'a'</span
></p
><p>Inline macro invocation with 2x duplicate argument: <span class="nimble-error">Nimble error while building inline macro 'errortest' invocation: duplicate argument 'a'; duplicate argument 'a'</span
></p
><p>Inline macro invocation with 1x unknown argument: <span class="nimble-error">Nimble error while building inline macro 'errortest' invocation: unknown argument 'c'</span
></p
><p>Inline macro invocation with 2x unknown argument: <span class="nimble-error">Nimble error while building inline macro 'errortest' invocation: unknown argument 'c'; unknown argument 'c'</span
></p
><p>Inline macro invocation with duplicate argument and unknown argument: <span class="nimble-error">Nimble error while building inline macro 'errortest' invocation: duplicate argument 'a'; unknown argument 'c'</span
></p
><p>Duplicate macro definition:</p
><span class="nimble-error">Nimble error while defining macro 'errortest': a macro named 'errortest' already exists</span
><p>Macro definition with duplicate arguments:</p
><span class="nimble-error">Nimble error while defining macro 'invalidmacro': duplicate definition for argument 'a'</span
><p>Macro definition with invalid argument types:</p
><span class="nimble-error">Nimble error while defining macro 'invalidmacro': invalid type 'invalid' for argument 'a'</span
><p>Macro definition with duplicate format definitions:</p
><span class="nimble-error">Nimble error while defining macro 'invalidmacro': duplicate definition of 'html'-format result</span
><p>Macro definition with duplicate arguments, invalid argument types, and duplicate formats definitions:</p
><span class="nimble-error">Nimble error while defining macro 'invalidmacro': duplicate definition for argument 'a'; invalid type 'invalid' for argument 'b'</span
><p>Block macro invocation of unknown macro:</p
><span class="nimble-error">Nimble error while building block macro 'dne' invocation: no macro by that name is defined</span
><p>Block macro invocation with 1x duplicate argument:</p
><span class="nimble-error">Nimble error while building block macro 'errortest' invocation: duplicate argument 'a'</span
><p>Block macro invocation with 2x duplicate argument:</p
><span class="nimble-error">Nimble error while building block macro 'errortest' invocation: duplicate argument 'a'; duplicate argument 'a'</span
><p>Block macro invocation with 1x unknown argument:</p
><span class="nimble-error">Nimble error while building block macro 'errortest' invocation: unknown argument 'c'</span
><p>Block macro invocation with 2x unknown argument:</p
><span class="nimble-error">Nimble error while building block macro 'errortest' invocation: unknown argument 'c'; unknown argument 'c'</span
><p>Block macro invocation with duplicate argument and unknown argument:</p
><span class="nimble-error">Nimble error while building block macro 'errortest' invocation: duplicate argument 'a'; unknown argument 'c'</span
></section
><p>And we can end in just raw text, too.</p
>
EOF


sub exp_parsetree {
  my $VAR1;
  $VAR1 = {error=>[{context=>"defining macro 'errortest'",errors=>["a macro named 'errortest' already exists"],type=>"error"},{context=>"defining macro 'invalidmacro'",errors=>["duplicate definition for argument 'a'"],type=>"error"},{context=>"defining macro 'invalidmacro'",errors=>["invalid type 'invalid' for argument 'a'"],type=>"error"},{context=>"defining macro 'invalidmacro'",errors=>["duplicate definition of 'html'-format result"],type=>"error"},{context=>"defining macro 'invalidmacro'",errors=>["duplicate definition for argument 'a'","invalid type 'invalid' for argument 'b'"],type=>"error"},{context=>"building block macro 'dne' invocation",errors=>["no macro by that name is defined"],type=>"error"},{context=>"building block macro 'errortest' invocation",errors=>["duplicate argument 'a'"],type=>"error"},{context=>"building block macro 'errortest' invocation",errors=>["duplicate argument 'a'","duplicate argument 'a'"],type=>"error"},{context=>"building block macro 'errortest' invocation",errors=>["unknown argument 'c'"],type=>"error"},{context=>"building block macro 'errortest' invocation",errors=>["unknown argument 'c'","unknown argument 'c'"],type=>"error"},{context=>"building block macro 'errortest' invocation",errors=>["duplicate argument 'a'","unknown argument 'c'"],type=>"error"},{context=>"building inline macro 'dne' invocation",errors=>["no macro by that name is defined"],type=>"error"},{context=>"building inline macro 'errortest' invocation",errors=>["duplicate argument 'a'"],type=>"error"},{context=>"building inline macro 'errortest' invocation",errors=>["duplicate argument 'a'","duplicate argument 'a'"],type=>"error"},{context=>"building inline macro 'errortest' invocation",errors=>["unknown argument 'c'"],type=>"error"},{context=>"building inline macro 'errortest' invocation",errors=>["unknown argument 'c'","unknown argument 'c'"],type=>"error"},{context=>"building inline macro 'errortest' invocation",errors=>["duplicate argument 'a'","unknown argument 'c'"],type=>"error"}],macro=>{aside=>{args=>{contents=>{default=>[],type=>"nimble"}},results=>{html=>{output=>"<aside>{{contents}}</aside>"}}},errortest=>{args=>{a=>{default=>"",type=>"raw"},b=>{default=>"",type=>"raw"}},results=>{html=>{output=>"MACRO RENDERED (a={{a|xmlenc}})"}}},inlinetest=>{args=>{a=>{default=>"",type=>"raw"},b=>{default=>"",type=>"raw"},c=>{default=>"",type=>"raw"}},results=>{html=>{output=>"<span style=\"color:red;\">{{a|xmlenc}}</span><span style=\"color:green;\">{{b|xmlenc}}</span><span style=\"color:blue;\">{{c|xmlenc}}</span>"}}},lightbox=>{args=>{alt=>{default=>"thumb",type=>"raw"},caption=>{default=>"",type=>"raw"},full=>{default=>"",type=>"raw"},group=>{default=>"lightbox",type=>"raw"},thumb=>{default=>"",type=>"raw"}},results=>{html=>{output=>"<a href=\"{{full|xmlenc}}\" data-lightbox=\"{{group|xmlenc}}\" title=\"{{caption|xmlenc}}\"><img src=\"{{thumb|xmlenc}}\" alt=\"{{alt|xmlenc}}\" width=\"200\" height=\"150\"/></a>"}}},phplink=>{args=>{topic=>{default=>"",type=>"raw"}},results=>{html=>{output=>"<a class=\"phplink\" href=\"http://php.net/{{topic|urlenc|xmlenc}}\">{{topic|xmlenc}}</a>"}}},warning=>{args=>{body=>{default=>[{list=>[[{content=>[{text=>"this is a",type=>"text"}],type=>"paragraph"}],[{content=>[{text=>"default list",type=>"text"}],type=>"paragraph"}]],type=>"ul"}],type=>"nimble"},title=>{default=>[{text=>"some ",type=>"text"},{content=>[{text=>"formatted",type=>"text"}],type=>"emphasis"},{text=>" title",type=>"text"}],type=>"nimble"}},results=>{html=>{output=>"<div class=\"warningbox\"\n  ><h1>{{title}}</h1\n  >{{body}}</div\n>"}}}},meta=>{title=>"The title of the document with literal /slashes/ and `backticks`."},tree=>[{content=>[{text=>"A regular paragraph.",type=>"text"}],type=>"paragraph"},{content=>[{text=>"Text can be ",type=>"text"},{content=>[{text=>"bold",type=>"text"}],type=>"strong"},{text=>" or ",type=>"text"},{content=>[{text=>"italic",type=>"text"}],type=>"emphasis"},{text=>" or ",type=>"text"},{text=>"code",type=>"code"},{text=>" or normal.",type=>"text"}],type=>"paragraph"},{content=>[{text=>"What about parts of mount",type=>"text"},{content=>[{text=>"ain",type=>"text"}],type=>"strong"},{text=>"ous, ramb",type=>"text"},{content=>[{text=>"unct",type=>"text"}],type=>"emphasis"},{text=>"ious, or alu",type=>"text"},{text=>"min",type=>"code"},{text=>"ium?",type=>"text"}],type=>"paragraph"},{content=>[{content=>[{text=>"paragraphs",type=>"text"}],type=>"strong"},{text=>" can start with formats or end with ",type=>"text"},{content=>[{text=>"them",type=>"text"}],type=>"emphasis"}],type=>"paragraph"},{content=>[{text=>"What about ",type=>"text"},{content=>[{content=>[{text=>"nesting",type=>"text"}],type=>"emphasis"}],type=>"strong"},{text=>" different ",type=>"text"},{content=>[{text=>"combinations",type=>"code"}],type=>"emphasis"},{text=>" of ",type=>"text"},{text=>"*format codes*",type=>"code"},{text=>"?",type=>"text"}],type=>"paragraph"},{content=>[{text=>"paragraphs ",type=>"text"},{content=>[{text=>"can wrap",type=>"text"}],type=>"strong"},{text=>" ",type=>"text"},{content=>[{text=>"across multiple",type=>"text"}],type=>"emphasis"},{text=>" lines",type=>"text"}],type=>"paragraph"},{content=>[{text=>"Suppose you want actual \\backslashes\\, *asterisks*, /slashes/, `backticks`, [square brackets], http://abcde...",type=>"text"}],type=>"paragraph"},{content=>[{text=>"What about...",type=>"text"}],type=>"paragraph"},{list=>[[{content=>[{text=>"word* word* word",type=>"text"}],type=>"paragraph"}],[{content=>[{text=>"word *word *word",type=>"text"}],type=>"paragraph"}],[{content=>[{content=>[{text=>"word ",type=>"text"},{content=>[{text=>"word",type=>"text"}],type=>"strong"},{text=>" word",type=>"text"}],type=>"strong"}],type=>"paragraph"}],[{content=>[{text=>"word",type=>"text"},{content=>[{text=>"word word",type=>"text"}],type=>"strong"},{text=>"word",type=>"text"}],type=>"paragraph"}],[{content=>[{text=>"word * word * word",type=>"text"}],type=>"paragraph"}],[{content=>[{text=>"bolding a single ",type=>"text"},{content=>[{text=>"\\",type=>"text"}],type=>"strong"}],type=>"paragraph"}]],type=>"ul"},{lang=>undef,lines=>["here is some","","``totally * verbatim / and \\ weird","","<programming> &\" code"],type=>"codeblock"},{lang=>undef,lines=>["here is some code that has","```","regular markers","```","inside it"],type=>"codeblock"},{content=>[{text=>"Within code, ",type=>"text"},{text=>"*, /, \\, <, >, \", &, `",type=>"code"},{text=>" should be literal!",type=>"text"}],type=>"paragraph"},{content=>[{text=>"Outside code, <, >, \", & should be literal!",type=>"text"}],type=>"paragraph"},{content=>[{text=>"Code can be ",type=>"text"},{text=>"a",type=>"code"},{text=>", ",type=>"text"},{text=>"a",type=>"code"},{text=>", ",type=>"text"},{text=>"a",type=>"code"},{text=>", ",type=>"text"},{text=>"a",type=>"code"},{text=>", ",type=>"text"},{text=>"`",type=>"code"},{text=>", ",type=>"text"},{text=>"````",type=>"code"},{text=>"...",type=>"text"}],type=>"paragraph"},{content=>[{content=>[{text=>"this",type=>"text"}],type=>"strong"},{text=>" paragraph starts with an asterisk. ",type=>"text"},{content=>[{text=>"it",type=>"text"}],type=>"strong"},{text=>" isn't a list.",type=>"text"}],type=>"paragraph"},{content=>[{text=>"This paragraph",type=>"text"}],type=>"paragraph"},{list=>[[{content=>[{text=>"has a",type=>"text"}],type=>"paragraph"}],[{content=>[{text=>"bulleted list",type=>"text"}],type=>"paragraph"}]],type=>"ul"},{content=>[{text=>"dividing it in two.",type=>"text"}],type=>"paragraph"},{content=>[{text=>"Link with weird chars?  ",type=>"text"},{content=>[{text=>"http://example.com/?a=\\&b=]",type=>"text"}],type=>"link",url=>"http://example.com/?a=\\&b=]"},{text=>" and stuff that shouldn't be included]",type=>"text"}],type=>"paragraph"},{content=>[{text=>"Or a regular link? ",type=>"text"},{content=>[{text=>"link label",type=>"text"}],type=>"link",url=>"http://example.com/?a=1&b=2"}],type=>"paragraph"},{content=>[{text=>"Or a formatted link? ",type=>"text"},{content=>[{content=>[{text=>"link ",type=>"text"},{content=>[{text=>"label",type=>"text"}],type=>"emphasis"},{text=>" with ",type=>"text"},{text=>"code",type=>"code"},{text=>" and ] stuff",type=>"text"}],type=>"link",url=>"http://example.com/?a=1&b=2"}],type=>"strong"}],type=>"paragraph"},{content=>[{text=>"Or a link containing a backslash or a closing bracket? ",type=>"text"},{content=>[{content=>[{text=>"link ",type=>"text"},{content=>[{text=>"label",type=>"text"}],type=>"emphasis"},{text=>" with ",type=>"text"},{text=>"code",type=>"code"},{text=>" and \\ and ] stuff\\] and so on",type=>"text"}],type=>"link",url=>"http://example.com/?a=\\&b=]"}],type=>"strong"}],type=>"paragraph"},{content=>[{text=>"But this isn't linked:  http:/",type=>"text"},{content=>[{text=>"example.com",type=>"text"}],type=>"emphasis"},{text=>"?a=1&b=2",type=>"text"}],type=>"paragraph"},{content=>[{text=>"Nor this: [http:/",type=>"text"},{content=>[{text=>"example.com",type=>"text"}],type=>"emphasis"},{text=>"?a=1&b=2 link label]",type=>"text"}],type=>"paragraph"},{content=>[{text=>"Nor this: ",type=>"text"},{content=>[{text=>"[http:/",type=>"text"},{content=>[{text=>"example.com",type=>"text"}],type=>"emphasis"},{text=>"?a=2&b=2 link ",type=>"text"},{content=>[{text=>"label",type=>"text"}],type=>"emphasis"},{text=>" with ",type=>"text"},{text=>"code",type=>"code"},{text=>" and ] stuff]",type=>"text"}],type=>"strong"}],type=>"paragraph"},{list=>[[{content=>[{text=>"this li starts with too many spaces",type=>"text"}],type=>"paragraph"}],[{list=>[[{content=>[{text=>"this sub-element does too",type=>"text"}],type=>"paragraph"}]],type=>"ul"}]],type=>"ul"},{quote=>[{content=>[{text=>"Here is a quoted block of text",type=>"text"}],type=>"paragraph"}],type=>"blockquote"},{list=>[[{content=>[{text=>"bulleted lists can have items which span multiple lines",type=>"text"}],type=>"paragraph"}],[{content=>[{text=>"or items that sit on one big line",type=>"text"}],type=>"paragraph"}],[{content=>[{text=>"or,",type=>"text"}],type=>"paragraph"},{list=>[[{content=>[{text=>"items which themselves",type=>"text"}],type=>"paragraph"}],[{content=>[{text=>"contain lists",type=>"text"}],type=>"paragraph"}]],type=>"ul"}],[{list=>[[{content=>[{text=>"or items",type=>"text"}],type=>"paragraph"}],[{content=>[{text=>"which are just lists",type=>"text"}],type=>"paragraph"}],[{content=>[{text=>"themselves",type=>"text"}],type=>"paragraph"}]],type=>"ul"}]],type=>"ul"},{list=>[[{content=>[{text=>"this list",type=>"text"}],type=>"paragraph"},{content=>[{text=>"contains several",type=>"text"}],type=>"paragraph"},{content=>[{text=>"paragraphs of text",type=>"text"}],type=>"paragraph"}],[{content=>[{text=>"i guess that's fine...",type=>"text"}],type=>"paragraph"}]],type=>"ul"},{list=>[[{content=>[{text=>"this list",type=>"text"}],type=>"paragraph"},{content=>[{text=>"contains several",type=>"text"}],type=>"paragraph"},{content=>[{text=>"paragraphs",type=>"text"}],type=>"paragraph"}],[{content=>[{text=>"but it didn't indent the blanks between them...",type=>"text"}],type=>"paragraph"}]],type=>"ul"},{list=>[[{content=>[{content=>[{content=>[{text=>"this list",type=>"text"}],type=>"paragraph"}],type=>"li",value=>undef},{content=>[{content=>[{text=>"is auto-numbered",type=>"text"}],type=>"paragraph"}],type=>"li",value=>undef}],type=>"ol"}],[{content=>[{content=>[{content=>[{text=>"this list",type=>"text"}],type=>"paragraph"}],type=>"li",value=>2},{content=>[{content=>[{text=>"is force-numbered",type=>"text"}],type=>"paragraph"}],type=>"li",value=>4}],type=>"ol"}],[{content=>[{content=>[{content=>[{text=>"this list",type=>"text"}],type=>"paragraph"}],type=>"li",value=>10},{content=>[{content=>[{text=>"automatically continues",type=>"text"}],type=>"paragraph"}],type=>"li",value=>undef},{content=>[{content=>[{text=>"from the start",type=>"text"}],type=>"paragraph"}],type=>"li",value=>undef}],type=>"ol"}],[{content=>[{content=>[{content=>[{text=>"this list starts with auto-numbering",type=>"text"}],type=>"paragraph"}],type=>"li",value=>undef},{content=>[{content=>[{text=>"and then switches to force-numbering",type=>"text"}],type=>"paragraph"}],type=>"li",value=>10}],type=>"ol"}]],type=>"ul"},{content=>[{content=>[{list=>[[{content=>[{text=>"this",type=>"text"}],type=>"paragraph"}],[{content=>[{text=>"list",type=>"text"}],type=>"paragraph"}]],type=>"ul"}],type=>"li",value=>1},{content=>[{list=>[[{content=>[{text=>"jumps",type=>"text"}],type=>"paragraph"}],[{content=>[{text=>"to ten",type=>"text"}],type=>"paragraph"}]],type=>"ul"}],type=>"li",value=>10}],type=>"ol"},{content=>[{content=>[{text=>"a plain figure",type=>"text"}],type=>"paragraph"}],type=>"figure"},{content=>[{content=>[{text=>"a figure with",type=>"text"}],type=>"paragraph"},{content=>[{content=>[{text=>"the caption last",type=>"text"}],type=>"paragraph"}],type=>"figcaption"}],type=>"figure"},{content=>[{content=>[{content=>[{text=>"the caption before",type=>"text"}],type=>"paragraph"}],type=>"figcaption"},{content=>[{text=>"the figure content",type=>"text"}],type=>"paragraph"}],type=>"figure"},{content=>[{content=>[{text=>"a figure which",type=>"text"}],type=>"paragraph"},{content=>[{text=>"contains multiple paragraphs",type=>"text"}],type=>"paragraph"},{content=>[{content=>[{text=>"and finally a caption",type=>"text"}],type=>"paragraph"}],type=>"figcaption"}],type=>"figure"},{content=>[{quote=>[{content=>[{text=>"a figure which itself is a blockquote",type=>"text"}],type=>"paragraph"},{content=>[{text=>"which itself spans multiple paragraphs",type=>"text"}],type=>"paragraph"}],type=>"blockquote"},{content=>[{content=>[{text=>"and finally a caption",type=>"text"}],type=>"paragraph"}],type=>"figcaption"}],type=>"figure"},{cite=>[{content=>[{text=>"by I Like Typing, Esq",type=>"text"}],type=>"paragraph"}],quote=>[{content=>[{text=>"a quote which",type=>"text"}],type=>"paragraph"},{lang=>undef,lines=>["goes for"],type=>"codeblock"},{content=>[{text=>"several paragraphs",type=>"text"}],type=>"paragraph"}],type=>"blockquote"},{content=>[{content=>[{content=>[{text=>"a figure with",type=>"text"}],type=>"paragraph"}],type=>"figcaption"},{list=>[[{content=>[{text=>"too many spaces",type=>"text"}],type=>"paragraph"}]],type=>"ul"},{list=>[[{content=>[{text=>"before everything",type=>"text"}],type=>"paragraph"},{list=>[[{content=>[{text=>"even this",type=>"text"}],type=>"paragraph"}],[{content=>[{text=>"and this",type=>"text"}],type=>"paragraph"}]],type=>"ul"}]],type=>"ul"}],type=>"figure"},{content=>[{content=>[{content=>[{content=>[{text=>"a figure which",type=>"text"}],type=>"paragraph"}],type=>"dt"},{content=>[{content=>[{text=>"contains a dl",type=>"text"}],type=>"paragraph"}],type=>"dd"},{content=>[{content=>[{text=>"the dl's dd's shouldn't",type=>"text"}],type=>"paragraph"}],type=>"dt"},{content=>[{content=>[{text=>"become figcaptions instead",type=>"text"}],type=>"paragraph"}],type=>"dd"}],type=>"dl"},{content=>[{content=>[{text=>"this ",type=>"text"},{content=>[{text=>"should",type=>"text"}],type=>"emphasis"},{text=>" be a figcaption, though",type=>"text"}],type=>"paragraph"}],type=>"figcaption"}],type=>"figure"},{content=>[{content=>[{content=>[{text=>"dt1",type=>"text"}],type=>"paragraph"}],type=>"dt"},{content=>[{content=>[{text=>"dd1",type=>"text"}],type=>"paragraph"}],type=>"dd"},{content=>[{content=>[{text=>"dt2",type=>"text"}],type=>"paragraph"}],type=>"dt"},{content=>[{content=>[{content=>[{content=>[{text=>"dd2_dt1",type=>"text"}],type=>"paragraph"}],type=>"dt"},{content=>[{content=>[{text=>"dd2_dd1",type=>"text"}],type=>"paragraph"}],type=>"dd"},{content=>[{content=>[{text=>"dd2_dt2",type=>"text"}],type=>"paragraph"}],type=>"dt"},{content=>[{content=>[{text=>"dd2_dd2",type=>"text"}],type=>"paragraph"}],type=>"dd"}],type=>"dl"}],type=>"dd"},{content=>[{content=>[{text=>"dt3",type=>"text"}],type=>"paragraph"}],type=>"dt"},{content=>[{content=>[{text=>"dd3",type=>"text"}],type=>"paragraph"}],type=>"dd"}],type=>"dl"},{content=>[{content=>[{content=>[{text=>"dt1",type=>"text"}],type=>"paragraph"}],type=>"dt"},{content=>[{content=>[{text=>"dd1",type=>"text"}],type=>"paragraph"}],type=>"dd"},{content=>[{content=>[{text=>"dt2",type=>"text"}],type=>"paragraph"}],type=>"dt"},{content=>[{content=>[{content=>[{content=>[{text=>"dd2_dt1",type=>"text"}],type=>"paragraph"}],type=>"dt"},{content=>[{content=>[{text=>"dd2_dd1",type=>"text"}],type=>"paragraph"}],type=>"dd"},{content=>[{content=>[{text=>"dd2_dt2",type=>"text"}],type=>"paragraph"}],type=>"dt"},{content=>[{content=>[{text=>"dd2_dd2",type=>"text"}],type=>"paragraph"}],type=>"dd"}],type=>"dl"}],type=>"dd"},{content=>[{content=>[{text=>"dt3",type=>"text"}],type=>"paragraph"}],type=>"dt"},{content=>[{content=>[{text=>"dd3",type=>"text"}],type=>"paragraph"}],type=>"dd"}],type=>"dl"},{list=>[[{content=>[{content=>[{content=>[{text=>"1q",type=>"text"}],type=>"paragraph"}],type=>"dt"},{content=>[{content=>[{text=>"1a",type=>"text"}],type=>"paragraph"}],type=>"dd"}],type=>"dl"}],[{content=>[{content=>[{content=>[{text=>"2q",type=>"text"}],type=>"paragraph"}],type=>"dt"},{content=>[{content=>[{text=>"2a",type=>"text"}],type=>"paragraph"}],type=>"dd"}],type=>"dl"}]],type=>"ul"},{list=>[[{content=>[{text=>"in a list, ",type=>"text"},{content=>[{text=>"formats still",type=>"text"}],type=>"strong"},{text=>" flow ",type=>"text"},{content=>[{text=>"over line",type=>"text"}],type=>"emphasis"},{text=>" breaks",type=>"text"}],type=>"paragraph"}]],type=>"ul"},{content=>[{content=>[{content=>[{text=>"this ",type=>"text"},{content=>[{text=>"also happens",type=>"text"}],type=>"strong"},{text=>" ",type=>"text"},{content=>[{text=>"within <dt>s",type=>"text"}],type=>"emphasis"},{text=>" correctly",type=>"text"}],type=>"paragraph"}],type=>"dt"},{content=>[{content=>[{text=>"this ",type=>"text"},{content=>[{text=>"also happens",type=>"text"}],type=>"strong"},{text=>" ",type=>"text"},{content=>[{text=>"within <dd>s",type=>"text"}],type=>"emphasis"},{text=>" correctly",type=>"text"}],type=>"paragraph"}],type=>"dd"}],type=>"dl"},{quote=>[{list=>[[{content=>[{text=>"bq with",type=>"text"}],type=>"paragraph"}],[{content=>[{text=>"too many",type=>"text"}],type=>"paragraph"}],[{content=>[{text=>"spaces",type=>"text"}],type=>"paragraph"}]],type=>"ul"}],type=>"blockquote"},{content=>[{text=>"Let's test some syntax errors!",type=>"text"}],type=>"paragraph"},{content=>[{text=>"Broken * strong...",type=>"text"}],type=>"paragraph"},{content=>[{text=>"Broken / emphasis...",type=>"text"}],type=>"paragraph"},{content=>[{text=>"Broken ` code...",type=>"text"}],type=>"paragraph"},{content=>[{text=>"[http:/",type=>"text"},{content=>[{text=>"asdf.com",type=>"text"}],type=>"emphasis"},{text=>" broken link...",type=>"text"}],type=>"paragraph"},{content=>[{text=>"Strong ",type=>"text"},{content=>[{text=>"which finishes",type=>"text"}],type=>"strong"},{text=>" and *restarts...",type=>"text"}],type=>"paragraph"},{content=>[{text=>"Wrongly *nested ",type=>"text"},{content=>[{text=>"inline* styles",type=>"text"}],type=>"emphasis"},{text=>"...",type=>"text"}],type=>"paragraph"},{content=>[{content=>[{text=>"section I",type=>"text"}],type=>"paragraph"}],type=>"section_start"},{content=>[{text=>"I content",type=>"text"}],type=>"paragraph"},{content=>[{content=>[{text=>"section a",type=>"text"}],depth=>1,type=>"h"},{content=>[{text=>"(subtitle for section a)",type=>"text"}],type=>"paragraph"}],type=>"section_start"},{content=>[{text=>"a content",type=>"text"}],type=>"paragraph"},{content=>[{content=>[{text=>"section a1 goes for several lines of input",type=>"text"}],type=>"paragraph"}],type=>"section_start"},{content=>[{text=>"a1 content",type=>"text"}],type=>"paragraph"},{type=>"section_end"},{content=>[{content=>[{text=>"section a2",type=>"text"}],type=>"paragraph"},{content=>[{text=>"is two ",type=>"text"},{content=>[{text=>"paragraphs",type=>"text"}],type=>"emphasis"},{text=>"?",type=>"text"}],type=>"paragraph"}],type=>"section_start"},{content=>[{text=>"a2 content",type=>"text"}],type=>"paragraph"},{type=>"section_end"},{content=>[{text=>"a content",type=>"text"}],type=>"paragraph"},{type=>"section_end"},{content=>[{text=>"I content",type=>"text"}],type=>"paragraph"},{content=>[{content=>[{text=>"section b",type=>"text"}],type=>"paragraph"}],type=>"section_start"},{content=>[{text=>"{ regular paragraph",type=>"text"}],type=>"paragraph"},{content=>[{text=>"b content",type=>"text"}],type=>"paragraph"},{content=>[{text=>"}",type=>"text"}],type=>"paragraph"},{type=>"section_end"},{content=>[{text=>"I content",type=>"text"}],type=>"paragraph"},{type=>"section_end"},{content=>[{text=>"hard header *  with a list *  that shouldn't parse",type=>"text"}],depth=>1,type=>"h"},{content=>[{text=>"Here's Kitsu when she was a puppy:",type=>"text"}],type=>"paragraph"},{content=>[{alt=>"Kitsu when she was a *puppy*",src=>"kitsu-thumb.jpg",type=>"img"},{text=>"  ",type=>"text"},{html=>"&larr;",type=>"entity"},{text=>" the markup in the alt should be literal",type=>"text"}],type=>"paragraph"},{content=>[{content=>[{alt=>"maybe a \\ backslash or ] closing bracket?",src=>"kitsu-thumb.jpg",type=>"img"}],type=>"link",url=>"kitsu-thumb.jpg"},{text=>"  ",type=>"text"},{html=>"&larr;",type=>"entity"},{text=>" the markup in the alt should be literal",type=>"text"}],type=>"paragraph"},{content=>[{text=>"[kitsu-thumb.jpg ",type=>"text"},{alt=>"maybe a \\ backslash or ] closing bracket?",src=>"kitsu-thumb.jpg",type=>"img"},{text=>"  ",type=>"text"},{html=>"&larr;",type=>"entity"},{text=>" this shouldn't crash or hang",type=>"text"}],type=>"paragraph"},{content=>[{alt=>"maybe a \\ backslash or ] closing bracket?",src=>"kitsu-thumb.jpg",type=>"img"},{text=>"  ",type=>"text"},{html=>"&larr;",type=>"entity"},{text=>" backslash and closing bracket in alt should not be preceeded by backslashes",type=>"text"}],type=>"paragraph"},{content=>[{text=>"Here's the picture again with a link to the bigger picture: ",type=>"text"},{content=>[{text=>"start link ",type=>"text"},{html=>"&hearts;",type=>"entity"},{text=>" ",type=>"text"},{html=>"&rArr;",type=>"entity"},{text=>" ",type=>"text"},{html=>"&#x2665;",type=>"entity"},{text=>" ",type=>"text"},{alt=>"Kitsu when she was a puppy",src=>"kitsu-thumb.jpg",type=>"img"},{text=>" ",type=>"text"},{html=>"&#9829;",type=>"entity"},{text=>" ",type=>"text"},{html=>"&lArr;",type=>"entity"},{text=>" ",type=>"text"},{html=>"&hearts;",type=>"entity"},{text=>" link end",type=>"text"}],type=>"link",url=>"kitsu-full.jpg"}],type=>"paragraph"},{content=>[{text=>"Deep recursion during ",type=>"text"},{content=>[{text=>"clone",type=>"text"}],type=>"link",url=>"http://php.net/clone"},{text=>" will cause a ",type=>"text"},{content=>[{text=>"segfault",type=>"text"}],type=>"strong"},{text=>".",type=>"text"}],type=>"paragraph"},{content=>[{text=>"What about just [] stray brackets, or [http:/",type=>"text"},{content=>[{text=>"example.com",type=>"text"}],type=>"emphasis"},{text=>" ",type=>"text"},{content=>[{text=>"]",type=>"text"}],type=>"link",url=>"]"},{text=>" ones inside of a link?",type=>"text"}],type=>"paragraph"},{args=>{alt=>"<some> *obnoxious* /symbols/",caption=>"Kitsu when she was a puppy",full=>"kitsu-full.jpg",group=>"lightbox",thumb=>"kitsu-thumb.jpg"},macro=>"lightbox",type=>"macro"},{content=>[{text=>"Deep recursion during ",type=>"text"},{args=>{topic=>"clone]"},macro=>"phplink",type=>"macro"},{text=>" will cause a ",type=>"text"},{content=>[{text=>"segfault",type=>"text"}],type=>"strong"},{text=>".",type=>"text"}],type=>"paragraph"},{content=>[{text=>"Deep recursion during ",type=>"text"},{args=>{topic=>"a bunch of text"},macro=>"phplink",type=>"macro"},{text=>" will cause a ",type=>"text"},{content=>[{text=>"segfault",type=>"text"}],type=>"strong"},{text=>".",type=>"text"}],type=>"paragraph"},{args=>{contents=>[{list=>[[{content=>[{text=>"stuff",type=>"text"}],type=>"paragraph"}],[{content=>[{args=>{topic=>"clone"},macro=>"phplink",type=>"macro"}],type=>"paragraph"}],[{content=>[{text=>"here",type=>"text"}],type=>"paragraph"}]],type=>"ul"}]},macro=>"aside",type=>"macro"},{args=>{body=>[{list=>[[{content=>[{text=>"could segfault",type=>"text"}],type=>"paragraph"}],[{content=>[{text=>"no really",type=>"text"}],type=>"paragraph"}]],type=>"ul"}],title=>[{text=>"don't use ",type=>"text"},{args=>{topic=>"clone"},macro=>"phplink",type=>"macro"}]},macro=>"warning",type=>"macro"},{content=>[{text=>"Macro inlinetest ",type=>"text"},{html=>"&rarr;",type=>"entity"},{text=>" ",type=>"text"},{args=>{a=>"a1 a2 \" a3 a4",b=>"b1 \" b2 ' b3 b4",c=>"c1 c2 ' c3 c4"},macro=>"inlinetest",type=>"macro"},{text=>" ",type=>"text"},{html=>"&larr;",type=>"entity"},{text=>" end macro",type=>"text"}],type=>"paragraph"},{content=>[{text=>"Macro inlinetest ",type=>"text"},{html=>"&rarr;",type=>"entity"},{text=>" ",type=>"text"},{args=>{a=>"a1 a2 [ a3 a4",b=>"b1 ] b2 [ b3 b4",c=>"c1 c2 ] c3 c4"},macro=>"inlinetest",type=>"macro"},{text=>" ",type=>"text"},{html=>"&larr;",type=>"entity"},{text=>" end macro",type=>"text"}],type=>"paragraph"},{content=>[{text=>"Macro inlinetest ",type=>"text"},{html=>"&rarr;",type=>"entity"},{text=>" [\$inlinetest a=\"a1 a2 [",type=>"text"},{text=>" a3 a4\" b=\"b1 ] b2 [",type=>"text"},{text=>" b3 b4\" c=\"c1 c2 ] ",type=>"text"},{html=>"&larr;",type=>"entity"},{text=>" end macro",type=>"text"}],type=>"paragraph"},{content=>[{text=>"Macro inlinetest ",type=>"text"},{html=>"&rarr;",type=>"entity"},{text=>" ",type=>"text"},{args=>{a=>"aaaa'aaa",b=>"b1 b2 b3 b4",c=>"ccc\"ccc"},macro=>"inlinetest",type=>"macro"},{text=>" ",type=>"text"},{html=>"&larr;",type=>"entity"},{text=>" end macro",type=>"text"}],type=>"paragraph"},{content=>"<p><s>Strikethrough!</s></p>",format=>"html",type=>"raw"},{content=>[{text=>"Or, a paragraph with an ",type=>"text"},{content=>"<s>inline</s>",format=>"html",type=>"raw"},{text=>" strikethrough!",type=>"text"}],type=>"paragraph"},{content=>"<ul>\n<li>This UL is made of raw HTML.</li>\n<li>It's not nimble code.</li>\n<li>Why?</li>\n<li>Why not?</li>\n</ul>",format=>"html",type=>"raw"},{content=>[{content=>[{text=>"Let's test some error handling",type=>"text"}],type=>"paragraph"}],type=>"section_start"},{content=>[{text=>"Inline macro invocation of unknown macro: ",type=>"text"},{}],type=>"paragraph"},{content=>[{text=>"Inline macro invocation with 1x duplicate argument: ",type=>"text"},{}],type=>"paragraph"},{content=>[{text=>"Inline macro invocation with 2x duplicate argument: ",type=>"text"},{}],type=>"paragraph"},{content=>[{text=>"Inline macro invocation with 1x unknown argument: ",type=>"text"},{}],type=>"paragraph"},{content=>[{text=>"Inline macro invocation with 2x unknown argument: ",type=>"text"},{}],type=>"paragraph"},{content=>[{text=>"Inline macro invocation with duplicate argument and unknown argument: ",type=>"text"},{}],type=>"paragraph"},{content=>[{text=>"Duplicate macro definition:",type=>"text"}],type=>"paragraph"},{},{content=>[{text=>"Macro definition with duplicate arguments:",type=>"text"}],type=>"paragraph"},{},{content=>[{text=>"Macro definition with invalid argument types:",type=>"text"}],type=>"paragraph"},{},{content=>[{text=>"Macro definition with duplicate format definitions:",type=>"text"}],type=>"paragraph"},{},{content=>[{text=>"Macro definition with duplicate arguments, invalid argument types, and duplicate formats definitions:",type=>"text"}],type=>"paragraph"},{},{content=>[{text=>"Block macro invocation of unknown macro:",type=>"text"}],type=>"paragraph"},{},{content=>[{text=>"Block macro invocation with 1x duplicate argument:",type=>"text"}],type=>"paragraph"},{},{content=>[{text=>"Block macro invocation with 2x duplicate argument:",type=>"text"}],type=>"paragraph"},{},{content=>[{text=>"Block macro invocation with 1x unknown argument:",type=>"text"}],type=>"paragraph"},{},{content=>[{text=>"Block macro invocation with 2x unknown argument:",type=>"text"}],type=>"paragraph"},{},{content=>[{text=>"Block macro invocation with duplicate argument and unknown argument:",type=>"text"}],type=>"paragraph"},{},{type=>"section_end"},{content=>[{text=>"And we can end in just raw text, too.",type=>"text"}],type=>"paragraph"}]};$VAR1->{tree}[95]{content}[1] = $VAR1->{error}[11];$VAR1->{tree}[96]{content}[1] = $VAR1->{error}[12];$VAR1->{tree}[97]{content}[1] = $VAR1->{error}[13];$VAR1->{tree}[98]{content}[1] = $VAR1->{error}[14];$VAR1->{tree}[99]{content}[1] = $VAR1->{error}[15];$VAR1->{tree}[100]{content}[1] = $VAR1->{error}[16];$VAR1->{tree}[102] = $VAR1->{error}[0];$VAR1->{tree}[104] = $VAR1->{error}[1];$VAR1->{tree}[106] = $VAR1->{error}[2];$VAR1->{tree}[108] = $VAR1->{error}[3];$VAR1->{tree}[110] = $VAR1->{error}[4];$VAR1->{tree}[112] = $VAR1->{error}[5];$VAR1->{tree}[114] = $VAR1->{error}[6];$VAR1->{tree}[116] = $VAR1->{error}[7];$VAR1->{tree}[118] = $VAR1->{error}[8];$VAR1->{tree}[120] = $VAR1->{error}[9];$VAR1->{tree}[122] = $VAR1->{error}[10];
  return $VAR1;
}

