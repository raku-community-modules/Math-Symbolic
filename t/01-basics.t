use v6;

use Test;
plan 11;

use Math::Symbolic;

isa-ok Math::Symbolic.new('0'), Math::Symbolic, ".new() works";

is Math::Symbolic.new('x+y=1').isolate('x').Str, 'x=1-y', '.isolate() works';

is Math::Symbolic.new('x+y').evaluate(y => 2).Str, 'x+2', '.evaluate() works';

is Math::Symbolic.new('a^3+b*2').expand.Str, 'a*a*a+b+b', '.expand() works';

is Math::Symbolic.new('x*x*x*x').condense.Str, 'x^4', '.condense() works';

is Math::Symbolic.new('m=(y2-y1)/(x2-x1)').expression('y2').Str, 'm*(x2-x1)+y1', '.expression() works';

is
    Math::Symbolic.new('y=m*x+b').isolate('x').evaluate(:m(1), :b(0)).Str,
    'x=y',
    'README slope-intercept example works';

is Math::Symbolic.new("a+-b").simplify.Str, 'a-b', '.simplify documentation is correct';

is Math::Symbolic.new("x²").routine(< x >).EVAL.(4), 16, '.routine().EVAL works';

is
    Math::Symbolic.new('a²+b²=c²').expression('c')\
        .evaluate(:a<x2-x1>, :b<y2-y1>).compile(<x1 y1 x2 y2>).( -1,-1, 2,3 ),
    5,
    'can convert Pythagorean theorem into Perl distance subroutine';

is
    Math::Symbolic.new('t²=x²').evaluate(:x<V*t+P>)\
        .evaluate(:V(2), :P(-3)).expression('t').list».Numeric.sort,
    "1 3",
    'quadratic solution to the leading problem in 1D seems correct';

