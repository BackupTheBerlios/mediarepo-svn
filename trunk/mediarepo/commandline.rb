module CommandLine
  class Option
    attr_accessor :short_option, :long_option, :argument, :help
    def initialize(key, long_option, argument, help)
      @short_option = key
      @long_option  = long_option
      @argument     = argument
      @help         = help
    end
  end

  class Parser
    def initialize()
      @options = []
    end
    
    def add_option(short_option = nil,
                   long_option  = nil, 
                   argument     = nil,
                   help         = nil)
      @options.push(Option.new(short_option, long_option, argument, help))
    end

    def parse_args(args)
      result = [[], []]
      args.reverse!
      while not args.empty? 
        arg = args.pop
        
        if arg == "--" then
          result[1] += args
        else
          if arg[0] == ?- then
            if arg[1] == ?- then # Long option
              res = @options.find {|opt| opt.long_option == arg}
              if res then
                if res.argument then # needs argument
                  oarg = args.pop
                  if oarg == nil then
                    raise "Error: Argument for #{res.long_option} is missing"
                  else
                    result[0].push([res.long_option, oarg])
                  end
                else # does not need an argument
                  result[0].push([res.long_option, nil])
                end
              else 
                raise "Error: Unknown option #{arg}"
              end

            else # Short option
              res = @options.find {|opt| opt.short_option == arg}
              if res then
                if res.argument then # needs argument
                  oarg = args.pop
                  if oarg == nil then
                    raise "Error: Argument for #{res.short_option} is missing"
                  else
                    result[0].push([res.long_option, oarg])
                  end
                else # does not need an argument
                  result[0].push([res.long_option, nil])
                end
              else 
                raise "Error: Unknown option #{arg}"
              end           
            end
          else
            result[1].push(arg)
          end
        end
      end
      return result
    end
    
    def print_help()
      @options.each { |opt|
        if (opt.short_option) then
          puts "  #{opt.short_option}, #{opt.long_option} #{opt.argument}   #{opt.help}"
        else
          puts "  #{opt.long_option} #{opt.argument}   #{opt.help}"
        end
      }
    end
  end
end

# EOF #
