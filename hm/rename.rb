require 'monadt'

require_relative 'expr'
require_relative 'namegen'

module Rename
  include Expressions

  def self.rename(expr0)
    gen = NameGen.new

    rename_env = lambda do |expr, env|
      match expr,
            with(Expr::Int) { |val| expr },
            with(Expr::Bool) { |val| expr },
            with(Expr::Builtin) { |op| expr },
            with(Expr::Var) { |name|
              raise ArgumentError, "Undefined variable: #{name}" unless env.has_key? name
              Expr.var(env[name])
            },
            with(Expr::Lam) { |name, expr1|
              n = gen.gen(name)
              env[name] = n
              Expr.lam(n, rename_env.call(expr1, env))
            },
            with(Expr::App) { |expr, app|
              Expr.app(rename_env.call(expr, env), rename_env.call(app, env))
            },
            with(Expr::Let) { |name, bind, expr|
              n = gen.gen(name)
              env[name] = n
              Expr.let(n, rename_env.call(bind, env), rename_env.call(expr, env))
            }
    end
    rename_env.call(expr0, Hash.new)
  end
end
