require 'monadt'
require 'set'
require 'singleton'

require_relative 'expr'

module Types
  
  class BuiltinType
    Int = data
    Bool = data
  end

  decorate_adt BuiltinType

  BuiltinType::Int.class_eval do
    def ==(other)
      self.class == other.class
    end
    
    def to_s
      "Int"
    end
  end

  BuiltinType::Bool.class_eval do
    def ==(other)
      self.class == other.class
    end
    
    def to_s
      "Bool"
    end
  end

  class Type
    Builtin = data :t
    Var = data :name
    Arr = data :t1, :t2
  end

  decorate_adt Type

  Type::Builtin.class_eval do
    def to_s
      t.to_s
    end
  end

  Type::Var.class_eval do
    def to_s
      name
    end
  end

  Type::Arr.class_eval do
    def to_s
      "#{t1} -> #{t2}"
    end
  end

  IntType = Type.builtin BuiltinType.int
  BoolType = Type.builtin BuiltinType.bool

  def choose_builtin(op)
    match op,
          with(Expressions::Builtin::Plus) { free_scheme(Type.arr(IntType, Type.arr(IntType, IntType))) },
          with(Expressions::Builtin::Minus) { free_scheme(Type.arr(IntType, Type.arr(IntType, IntType))) },
          with(Expressions::Builtin::Mul) { free_scheme(Type.arr(IntType, Type.arr(IntType, IntType))) },
          with(Expressions::Builtin::Eql) { free_scheme(Type.arr(IntType, Type.arr(IntType, BoolType))) },
          with(Expressions::Builtin::If) {
            varA = Type.var("a")
            scheme(["a"].to_set, Type.arr(BoolType, Type.arr(varA, Type.arr(varA, varA))))
          }
  end

  Scheme = Struct.new(:vars, :type)

  def scheme(vars, type)
    Scheme.new(vars, type)
  end

  def free_scheme(type)
    Scheme.new(Set.new, type)
  end
end
