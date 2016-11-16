#!/usr/bin/env ruby

require_relative 'parse'
require_relative 'inference'
require_relative 'rename'

def main
  if ARGV.length != 1
    puts "Usage: #{$PROGRAM_NAME} [expression]"
  else
    str = ARGV[0] # '\x -> let f = if true in f 1 x'
    ast = parse(str)
    begin
      renamed = Rename::rename(ast)
      (type, constraints) = infer_constraints(renamed)
      puts "Inferred type: #{type},"
      puts "  with constraints:"
      constraints.each do |c|
        puts "  (#{c.left}) ~ (#{c.right})"
      end
      puts
      puts "Final inferred type: #{infer(renamed)}"
    rescue ArgumentError => e
      puts "Error occured while inferring types:" 
      puts "  #{e}"
    end
  end
end

if __FILE__ == $0
  main
end
