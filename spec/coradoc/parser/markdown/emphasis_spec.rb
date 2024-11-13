require "spec_helper"

def split_on_emph(text)
  text.split(/([\*_]+)/).filter { |t| !t.empty? }.map { |t| {text: t} }
end

RSpec.describe Coradoc::Parser::Markdown::InlineParser do
  describe "emphasis and strong emphasis" do
    markdown_example 350, "*foo bar*", [{emph: [{text: "foo bar"}]}], strip: false
    markdown_example 351, "a * foo bar*", split_on_emph("a * foo bar*"), strip: false
    markdown_example 352, %q(a*"foo"*), split_on_emph(%q(a*"foo"*)), strip: false
    markdown_example 353, "* a *", split_on_emph("* a *"), strip: false
    markdown_example 354, %q(*$*alpha.

*£*bravo.

*€*charlie.), split_on_emph(%q(*$*alpha.

*£*bravo.

*€*charlie.)), strip: false
    markdown_example 355, "foo*bar*", [{text: "foo"}, {emph: [{text: "bar"}]}], strip: false
    markdown_example 356, "5*6*78", [{text: "5"}, {emph: [{text: "6"}]}, {text: "78"}], strip: false
    markdown_example 357, "_foo bar_", [{emph: [{text: "foo bar"}]}], strip: false
    markdown_example 358, "_ foo bar_", split_on_emph("_ foo bar_"), strip: false
    markdown_example 359, %q(a_"foo"_), split_on_emph(%q(a_"foo"_)), strip: false
    markdown_example 360, "foo_bar_", split_on_emph("foo_bar_"), strip: false
    markdown_example 361, "5_6_78", split_on_emph("5_6_78"), strip: false
    markdown_example 362, "пристаням_стремятся_", split_on_emph("пристаням_стремятся_"), strip: false
    markdown_example 363, %q(aa_"bb"_cc), split_on_emph(%q(aa_"bb"_cc)), strip: false
    markdown_example 364, "foo-_(bar)_", [{text: "foo-"}, {emph: [{text: "(bar)"}]}], strip: false
    markdown_example 365, "_foo*", split_on_emph("_foo*"), strip: false
    markdown_example 366, "*foo bar *", split_on_emph("*foo bar *"), strip: false
    markdown_example 367, %q(*foo bar
*), split_on_emph(%q(*foo bar
*)), strip: false
    markdown_example 368, "*(*foo)", split_on_emph("*(*foo)"), strip: false
    markdown_example 369, "*(*foo*)*", [{emph: [{text: "("}, {emph: [{text: "foo"}]}, {text: ")"}]}], strip: false
    markdown_example 370, "*foo*bar", [{emph: [{text: "foo"}]}, {text: "bar"}], strip: false
    markdown_example 371, "_foo bar _", split_on_emph("_foo bar _"), strip: false
    markdown_example 372, "_(_foo)", split_on_emph("_(_foo)"), strip: false
    markdown_example 373, "_(_foo_)_", [{emph: [{text: "("}, {emph: [{text: "foo"}]}, {text: ")"}]}], strip: false
    markdown_example 374, "_foo_bar", split_on_emph("_foo_bar"), strip: false
    markdown_example 375, "_пристаням_стремятся", split_on_emph("_пристаням_стремятся"), strip: false
    markdown_example 376, "_foo_bar_baz_", [{emph: split_on_emph("foo_bar_baz")}], strip: false
    markdown_example 377, "_(bar)_.", [{emph: [{text: "(bar)"}]}, {text: "."}], strip: false
    markdown_example 378, "**foo bar**", [{strong: [{text: "foo bar"}]}], strip: false
    markdown_example 379, "** foo bar**", split_on_emph("** foo bar**"), strip: false
    markdown_example 380, %q(a**"foo"**), split_on_emph(%q(a**"foo"**)), strip: false
    markdown_example 381, "foo**bar**", [{text: "foo"}, {strong: [{text: "bar"}]}], strip: false
    markdown_example 382, "__foo bar__", [{strong: [{text: "foo bar"}]}], strip: false
    markdown_example 383, "__ foo bar__", split_on_emph("__ foo bar__"), strip: false
    markdown_example 384, %q(__
foo bar__), split_on_emph(%q(__
foo bar__)), strip: false
    markdown_example 385, %q(a__"foo"__), split_on_emph(%q(a__"foo"__)), strip: false
    markdown_example 386, "foo__bar__", split_on_emph("foo__bar__"), strip: false
    markdown_example 387, "5__6__78", split_on_emph("5__6__78"), strip: false
    markdown_example 388, "пристаням__стремятся__", split_on_emph("пристаням__стремятся__"), strip: false
    markdown_example 389, "__foo, __bar__, baz__", [{strong: [{text: "foo, "}, {strong: [{text: "bar"}]}, {text: ", baz"}]}], strip: false
    markdown_example 390, "foo-__(bar)__", [{text: "foo-"}, {strong: [{text: "(bar)"}]}], strip: false
    markdown_example 391, "**foo bar **", split_on_emph("**foo bar **"), strip: false
    markdown_example 392, "**(**foo)", split_on_emph("**(**foo)"), strip: false
    markdown_example 393, "*(**foo**)*", [{emph: [{text: "("}, {strong: [{text: "foo"}]}, {text: ")"}]}], strip: false
    markdown_example 394, %q(**Gomphocarpus (*Gomphocarpus physocarpus*, syn.
*Asclepias physocarpa*)**), [{strong: [
      {text: "Gomphocarpus ("},
      {emph: [{text: "Gomphocarpus physocarpus"}]},
      {text: ", syn.\n"},
      {emph: [{text: "Asclepias physocarpa"}]},
      {text: ")"},
    ]}], strip: false
    markdown_example 395, %q(**foo "*bar*" foo**), [{strong: [{text: "foo \""}, {emph: [{text: "bar"}]}, {text: "\" foo"}]}], strip: false
    markdown_example 396, "**foo**bar", [{strong: [{text: "foo"}]}, {text: "bar"}], strip: false
    markdown_example 397, "__foo bar __", split_on_emph("__foo bar __"), strip: false
    markdown_example 398, "__(__foo)", split_on_emph("__(__foo)"), strip: false
    markdown_example 399, "_(__foo__)_", [{emph: [{text: "("}, {strong: [{text: "foo"}]}, {text: ")"}]}], strip: false
    markdown_example 400, "__foo__bar", split_on_emph("__foo__bar"), strip: false
    markdown_example 401, "__пристаням__стремятся", split_on_emph("__пристаням__стремятся"), strip: false
    markdown_example 402, "__foo__bar__baz__", [{strong: split_on_emph("foo__bar__baz")}], strip: false
    markdown_example 403, "__(bar)__.", [{strong: [{text: "(bar)"}]}, {text: "."}], strip: false
    # 404 not found heh (pending: links)
    markdown_example 405, %q(*foo
bar*), [{emph: [{text: %q(foo
bar)}]}], strip: false
    markdown_example 406, "_foo __bar__ baz_", [{emph: [{text: "foo "}, {strong: [{text: "bar"}]}, {text: " baz"}]}], strip: false
    markdown_example 407, "_foo _bar_ baz_", [{emph: [{text: "foo "}, {emph: [{text: "bar"}]}, {text: " baz"}]}], strip: false
    markdown_example 408, "__foo_ bar_", [{emph: [{emph: [{text: "foo"}]}, {text: " bar"}]}], strip: false
    markdown_example 409, "*foo *bar**", [{emph: [{text: "foo "}, {emph: [{text: "bar"}]}]}], strip: false
    markdown_example 410, "*foo **bar** baz*", [{emph: [{text: "foo "}, {strong: [{text: "bar"}]}, {text: " baz"}]}], strip: false
    markdown_example 411, "*foo**bar**baz*", [{emph: [{text: "foo"}, {strong: [{text: "bar"}]}, {text: "baz"}]}], strip: false
    markdown_example 412, "*foo**bar*", [{emph: split_on_emph("foo**bar")}], strip: false
    markdown_example 413, "***foo** bar*", [{emph: [{strong: [{text: "foo"}]}, {text: " bar"}]}], strip: false
    markdown_example 414, "*foo **bar***", [{emph: [{text: "foo "}, {strong: [{text: "bar"}]}]}], strip: false
    markdown_example 415, "*foo**bar***", [{emph: [{text: "foo"}, {strong: [{text: "bar"}]}]}], strip: false
    markdown_example 416, "foo***bar***baz", [{text: "foo"}, {emph: [{strong: [{text: "bar"}]}]}, {text: "baz"}], strip: false
    markdown_example 417, "foo******bar*********baz", [{text: "foo"}, {strong: [{strong: [{strong: [{text: "bar"}]}]}]}, {text: "***"}, {text: "baz"}], strip: false
    markdown_example 418, "*foo **bar *baz* bim** bop*", [{emph: [{text: "foo "}, {strong: [{text: "bar "}, {emph: [{text: "baz"}]}, {text: " bim"}]}, {text: " bop"}]}], strip: false
    # 419 (pending: links)
    markdown_example 420, "** is not an empty emphasis", split_on_emph("** is not an empty emphasis"), strip: false
    markdown_example 421, "**** is not an empty strong emphasis", split_on_emph("**** is not an empty strong emphasis"), strip: false
    # 422 (pending: links)
    markdown_example 423, %q(**foo
bar**), [{strong: [{text: "foo\nbar"}]}], strip: false
    markdown_example 424, %q(__foo _bar_ baz__), [{strong: [{text: "foo "}, {emph: [{text: "bar"}]}, {text: " baz"}]}], strip: false
    markdown_example 425, %q(__foo __bar__ baz__), [{strong: [{text: "foo "}, {strong: [{text: "bar"}]}, {text: " baz"}]}], strip: false
    markdown_example 426, %q(____foo__ bar__), [{strong: [{strong: [{text: "foo"}]}, {text: " bar"}]}], strip: false
    markdown_example 427, %q(**foo **bar****), [{strong: [{text: "foo "}, {strong: [{text: "bar"}]}]}], strip: false
    markdown_example 428, %q(**foo *bar* baz**), [{strong: [{text: "foo "}, {emph: [{text: "bar"}]}, {text: " baz"}]}], strip: false
    markdown_example 429, %q(**foo*bar*baz**), [{strong: [{text: "foo"}, {emph: [{text: "bar"}]}, {text: "baz"}]}], strip: false
    markdown_example 430, %q(***foo* bar**), [{strong: [{emph: [{text: "foo"}]}, {text: " bar"}]}], strip: false
    markdown_example 431, %q(**foo *bar***), [{strong: [{text: "foo "}, {emph: [{text: "bar"}]}]}], strip: false
    markdown_example 432, %q(**foo *bar **baz**
bim* bop**), [{strong: [{text: "foo "}, {emph: [{text: "bar "}, {strong: [{text: "baz"}]}, {text: "\nbim"}]}, {text: " bop"}]}], strip: false
    # 433 (pending: links)
    markdown_example 434, %q(__ is not an empty emphasis), [{text: "__"}, {text: " is not an empty emphasis"}], strip: false
    markdown_example 435, %q(____ is not an empty strong emphasis), [{text: "____"}, {text: " is not an empty strong emphasis"}], strip: false
    markdown_example 436, %q(foo ***), [{text: "foo "}, {text: "***"}], strip: false
    markdown_example 437, %q(foo *\**), [{text: "foo "}, {emph: [{text: "*"}]}], strip: false
    markdown_example 438, %q(foo *_*), [{text: "foo "}, {emph: [{text: "_"}]}], strip: false
    markdown_example 439, %q(foo *****), [{text: "foo "}, {text: "*****"}], strip: false
    markdown_example 440, %q(foo **\***), [{text: "foo "}, {strong: [{text: "*"}]}], strip: false
    markdown_example 441, %q(foo **_**), [{text: "foo "}, {strong: [{text: "_"}]}], strip: false
    markdown_example 442, %q(**foo*), [{text: "*"}, {emph: [{text: "foo"}]}], strip: false
    markdown_example 443, %q(*foo**), [{emph: [{text: "foo"}]}, {text: "*"}], strip: false
    markdown_example 444, %q(***foo**), [{text: "*"}, {strong: [{text: "foo"}]}], strip: false
    markdown_example 445, %q(****foo*), [{text: "***"}, {emph: [{text: "foo"}]}], strip: false
    markdown_example 446, %q(**foo***), [{strong: [{text: "foo"}]}, {text: "*"}], strip: false
    markdown_example 447, %q(*foo****), [{emph: [{text: "foo"}]}, {text: "***"}], strip: false
    markdown_example 448, %q(foo ___), [{text: "foo "}, {text: "___"}], strip: false
    markdown_example 449, %q(foo _\__), [{text: "foo "}, {emph: [{text: "_"}]}], strip: false
    markdown_example 450, %q(foo _*_), [{text: "foo "}, {emph: [{text: "*"}]}], strip: false
    markdown_example 451, %q(foo _____), [{text: "foo "}, {text: "_____"}], strip: false
    markdown_example 452, %q(foo __\___), [{text: "foo "}, {strong: [{text: "_"}]}], strip: false
    markdown_example 453, %q(foo __*__), [{text: "foo "}, {strong: [{text: "*"}]}], strip: false
    markdown_example 454, %q(__foo_), [{text: "_"}, {emph: [{text: "foo"}]}], strip: false
    markdown_example 455, %q(_foo__), [{emph: [{text: "foo"}]}, {text: "_"}], strip: false
    markdown_example 456, %q(___foo__), [{text: "_"}, {strong: [{text: "foo"}]}], strip: false
    markdown_example 457, %q(____foo_), [{text: "___"}, {emph: [{text: "foo"}]}], strip: false
    markdown_example 458, %q(__foo___), [{strong: [{text: "foo"}]}, {text: "_"}], strip: false
    markdown_example 459, %q(_foo____), [{emph: [{text: "foo"}]}, {text: "___"}], strip: false
    markdown_example 460, %q(**foo**), [{strong: [{text: "foo"}]}], strip: false
    markdown_example 461, %q(*_foo_*), [{emph: [{emph: [{text: "foo"}]}]}], strip: false
    markdown_example 462, %q(__foo__), [{strong: [{text: "foo"}]}], strip: false
    markdown_example 463, %q(_*foo*_), [{emph: [{emph: [{text: "foo"}]}]}], strip: false
    markdown_example 464, %q(****foo****), [{strong: [{strong: [{text: "foo"}]}]}], strip: false
    markdown_example 465, %q(____foo____), [{strong: [{strong: [{text: "foo"}]}]}], strip: false
    markdown_example 466, %q(******foo******), [{strong: [{strong: [{strong: [{text: "foo"}]}]}]}], strip: false
    markdown_example 467, %q(***foo***), [{emph: [{strong: [{text: "foo"}]}]}], strip: false
    markdown_example 468, %q(_____foo_____), [{emph: [{strong: [{strong: [{text: "foo"}]}]}]}], strip: false
    markdown_example 469, %q(*foo _bar* baz_), [{emph: split_on_emph("foo _bar")}, *split_on_emph(" baz_")], strip: false
    markdown_example 470, %q(*foo __bar *baz bim__ bam*), [{emph: [{text: "foo "}, {strong: split_on_emph("bar *baz bim")}, {text: " bam"}]}], strip: false
    markdown_example 471, %q(**foo **bar baz**), [*split_on_emph("**foo "), {strong: [{text: "bar baz"}]}], strip: false
    markdown_example 472, %q(*foo *bar baz*), [*split_on_emph("*foo "), {emph: [{text: "bar baz"}]}], strip: false
    # 473 (pending: links)
    # 474 (pending: links)
    # 475 (pending: html)
    # 476 (pending: html)
    # 477 (pending: html)
    # 478 (pending: inline code)
    # 479 (pending: inline code)
    # 480 (pending: links)
    # 481 (pending: links)
  end
end
