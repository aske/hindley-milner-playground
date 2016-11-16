require 'set'

require_relative 'types'
require_relative 'expr'
require_relative 'namegen'

include Types
include Expressions
include Adt

Constraint = Struct.new(:left, :right)

Constraint.class_eval do
  def to_s
    "|#{self.left.to_s}| ~ |#{self.right.to_s}|"
  end
end

def apply_vars(type, vars)
  match type,
        with(Type::Builtin) { |a| type },
        with(Type::Var) { |v| vars.fetch(v, type) },
        with(Type::Arr) { |t1, t2| Type.arr(apply_vars(t1, vars), apply_vars(t2, vars)) }
end

def apply_vars_constr(constraint, vars)
  Constraint.new apply_vars(constraint.left, vars),
                 apply_vars(constraint.right, vars)
end

def infer_constraints(expr0)
  gen = NameGen.new
  constraints = []

  instantiate = lambda do |scheme|
    vmap = scheme.vars.map { |v| [v, Type.var(gen.gen(v))] }.to_h
    apply_vars(scheme.type, vmap)
  end

  infer_expr = lambda do |expr, env|
    generalize = lambda do |type|
      match type,
            with(Type::Builtin) { |a| free_scheme(type) },
            with(Type::Var) { |v|
              if env.has_key? v
                scheme(Set.new(v), type)
              else
                free_scheme(type)
              end
            },
            with(Type::Arr) { |t1, t2|
              s1 = generalize.call(t1)
              s2 = generalize.call(t2)
              scheme(s1.vars | s2.vars, Type.arr(t1, t2))
            }
    end

    match expr,
          with(Expr::Int) { |val| Type.builtin(BuiltinType.int) },
          with(Expr::Bool) { |val| Type.builtin(BuiltinType.bool) },
          with(Expr::Builtin) { |op|
            instantiate.call(choose_builtin(op))
          },
          with(Expr::Var) { |n| instantiate.call(env[n]) },
          with(Expr::Lam) { |name, expr1|
            tn = Type.var(name)
            env[name] = free_scheme(tn)
            t1 = infer_expr.call(expr1, env)
            Type.arr(tn, t1)
          },
          with(Expr::App) { |expr1, app|
            t1 = infer_expr.call(expr1, env)
            t2 = infer_expr.call(app, env)
            tn = Type.var(gen.gen("#app"))
            constraints << Constraint.new(t1, Type.arr(t2, tn))
            tn
          },
          with(Expr::Let) { |name, bind, expr|
            tb = infer_expr.call(bind, env)
            sc = generalize.call(tb)
            env[name] = sc
            infer_expr.call(expr, env)
          }
  end

  t = infer_expr.call(expr0, Hash.new)
  [t, constraints]
end

def compose_sub(s1, s2)
  s = {}
  s2.each { |k, v| s[k] = apply_vars(v, s1) }
  s.update(s1)
  s
end

def ftv(type)
  match type,
        with(Type::Builtin) { |t| Set.new },
        with(Type::Var) { |v| [v].to_set },
        with(Type::Arr) { |t1, t2| ftv(t1) | ftv(t2) }
end

def bind_var(name, type)
  if type.instance_of? Type::Var and type.name == name
    {}
  elsif ftv(type).include? name
    raise ArgumentError, "Infinite type: #{name} ~ #{type}"
  else
    {name => type}
  end
end

def unify(t1, t2)
  if t1 == t2
    {}
  elsif t1.instance_of? Type::Var
    bind_var(t1.name, t2)
  elsif t2.instance_of? Type::Var
    bind_var(t2.name, t1)
  elsif t1.instance_of? Type::Arr and t2.instance_of? Type::Arr
    su1 = unify(t1.t1, t2.t1)
    su2 = unify(apply_vars(t1.t2, su1), apply_vars(t2.t2, su1))
    compose_sub(su2, su1)
  else
    raise ArgumentError, "Unification fail: #{t1} ~ #{t2}"
  end
end

def solve_constraints(constraints)
  sub = {}

  while constraints.length > 0 do
    su1 = unify(constraints.first.left, constraints.first.right)
    constraints = constraints.drop(1).map { |c| apply_vars_constr(c, su1) }
    sub = compose_sub(su1, sub)
  end
  sub
end

def infer(expr)
  (t, constraints) = infer_constraints(expr)
  st = solve_constraints(constraints)
  apply_vars(t, st)
end
