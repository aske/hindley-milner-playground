require 'monadt'

module Expressions
  
  class Builtin
    Plus = data
    Minus = data
    Mul = data
    Eql = data
    If = data
  end

  decorate_adt Builtin

  Builtin::Plus.class_eval do
    def to_s
      "+"
    end
  end

  Builtin::Minus.class_eval do
    def to_s
      "-"
    end
  end

  Builtin::Mul.class_eval do
    def to_s
      "*"
    end
  end

  Builtin::Eql.class_eval do
    def to_s
      "=="
    end
  end

  Builtin::If.class_eval do
    def to_s
      "if"
    end
  end

  class Expr
    Int = data :int
    Bool = data :bool
    Builtin = data :builtin
    Var = data :name
    Lam = data :name, :expr
    App = data :expr1, :expr2
    Let = data :name, :expr1, :expr2
  end

  decorate_adt Expr

  Expr::Let.class_eval do
    def to_s
      "(let #{self.name} = #{self.expr1.to_s} in #{self.expr2.to_s})"
    end
  end
  
  Expr::App.class_eval do
    def to_s
      "(#{self.expr1} #{self.expr2})"
    end
  end
  
  Expr::Lam.class_eval do
    def to_s
      "\\#{name} -> #{expr.to_s}"
    end
  end

  Expr::Var.class_eval do
    def to_s
      self.name
    end
  end

  Expr::Int.class_eval do
    def to_s
      self.int.to_s
    end
  end

  Expr::Bool.class_eval do
    def to_s
      self.bool.to_s
    end
  end

  Expr::Builtin.class_eval do
    def to_s
      self.builtin.to_s
    end
  end
end
