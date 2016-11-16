# coding: utf-8
require 'd-parse'

require_relative 'types.rb'
require_relative 'expr.rb'

# :(
module Grammar
  include Expressions
  
  extend DParse::DSL

  DIGIT = char_in('0'..'9')
  LETTER = char_in('a'..'z')
  WSPACE_CH = char_in([' ', "\t"])
  WSPACE = repeat(WSPACE_CH)

  RESERVED = alt(string('let'), string('in'), string('if'),
                 string('true'), string('false'))

  NAME = seq(LETTER, repeat(alt(LETTER, DIGIT))).capture

  EVAR = except(NAME, RESERVED).map { |d| Expr.var(d) }

  EINT =
    seq(
      DIGIT,
      repeat(DIGIT),
    ).capture.map { |d| Expr.int(d.to_i) }

  EBOOL = alt(
    string('true').capture.map { |b| Expr.bool(true) } ,
    string('false').capture.map { |b| Expr.bool(false) })

  EBUILTIN = string('if').map { |b| Expr.builtin(Builtin.if) }
  
  ATOM = alt(
    EINT, EBOOL, EVAR, EBUILTIN,
    seq(char('(').ignore,
        lazy { EXPR },
        char(')').ignore).compact.first)

  def self.reduce_app(apps)
    apps[1].reduce(apps.first) { |acc, a| Expr.app(acc, a) }
  end

  EAPP = seq(ATOM,
             repeat(seq(WSPACE.ignore, ATOM).compact.first)
            ).map { |a| reduce_app(a) }

  BPLUSOP = char('+').map { |o| Expr.builtin(Builtin.plus) }
  BMINUSOP = char('-').map { |o| Expr.builtin(Builtin.minus) }
  BMULOP = char('*').map { |o| Expr.builtin(Builtin.mul) }
  BEQLOP = string('==').map { |o| Expr.builtin(Builtin.eql) }

  def self.reduce_ops(toks)
    toks = toks.flatten
    while toks.length != 1 do
      toks = [Expr.app(Expr.app(toks[1], toks[0]), toks[2])] + toks.drop(3)
    end
    toks.first
  end

  BMUL = seq(EAPP, WSPACE.ignore,
             repeat(seq(BMULOP, WSPACE.ignore,
                        EAPP, WSPACE.ignore).compact)
            ).compact.map { |o| reduce_ops(o) }
  BSUM = seq(BMUL, WSPACE.ignore,
             repeat(seq(alt(BPLUSOP, BMINUSOP), WSPACE.ignore,
                        BMUL, WSPACE.ignore).compact),
            ).compact.map { |o| reduce_ops(o) }
  BEQL = seq(BSUM, WSPACE.ignore,
             repeat(seq(BEQLOP, WSPACE.ignore, BSUM, WSPACE.ignore).compact)
            ).compact.map { |o| reduce_ops(o) }

  ELET = alt(seq(string('let').ignore, WSPACE.ignore,
             NAME, WSPACE.ignore,
             char('='), WSPACE.ignore,
             lazy { EXPR }, WSPACE.ignore,
             string('in'), WSPACE.ignore,
             lazy { EXPR }).compact.map { |l| Expr.let(l[0], l[1], l[3]) },
             BEQL)

  ELAM = alt(seq(char("\\").ignore,
             WSPACE.ignore,
             NAME,
             WSPACE.ignore,
             string("->").ignore,
             WSPACE.ignore,
             lazy { EXPR }).compact.map { |l| Expr.lam(l[0], l[1]) },
             ELET)

  EXPR = ELAM
end

def parse(input)
  res = Grammar::EXPR.apply(input)
  case res
  when DParse::Success
    puts res.data.to_s
    res.data
  when DParse::Failure
    $stderr.puts res.pretty_message
    exit 1
  end
end
