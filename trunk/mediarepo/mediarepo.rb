require "digest/md5"
require "fileutils"
require "set"
require "xmlentry.rb"
require "xmlcomment.rb"

module MediaRepo

  def is_md5(md5) 
    return (md5.size == 32) && ((/[^0123456789abcdef]/ =~ md5) == nil)
  end

  class Repository
    attr_reader :path

    def initialize(path)
      @path = path
      @num_entries = nil
    end

    def has(md5)
      if not is_md5(md5) then
        return false
      end

      entrypath = @path + "/" + md5
      
      return File.exist?(entrypath)
    end

    def num_entries()
      if @num_entries then
        return @num_entries
      else
        count = 0
        Dir.new(@path).each { |i|
          if (is_md5(i) && File.exist?("#{@path}/#{i}//data.dat"))
            count += 1
          end
        }
        @num_entries = count
        return @num_entries
      end
    end
    
    def slice(start, length)
      entries = []
      Dir.new(@path).each { |i|
        if (is_md5(i))
          entries.push(i)
        end
      }
      res = []
      entries.slice(start, length).each{ |i| 
        el = self.get(i)
        if el then
          res.push(el)
        end
      }
      return res
    end

    def entries()
      entries = []
      self.each { |i| 
        a = get(i)
        if a != nil then
          entries += [a]
        end
      }
      return entries
    end

    def each_entry()
      if block_given? then
        Dir.new(@path).each { |i|
          if (is_md5(i))
            yield(get(i))
          end
        }
      end     
    end

    def md5sums()
      entries = []
      self.each { |i| entries.push(i) }
      return entries
    end

    def each()
      if block_given? then
        Dir.new(@path).each { |i|
          if (is_md5(i))
            yield(i)
          end
        }
      end
    end
    
    def get(md5)
      if not is_md5(md5) then
        return nil 
      else
        entrypath = @path + "/" + md5
        if File.exist?(entrypath + "/data.dat") then   
          return XMLEntry.new(@path, md5)
        else
          return nil
        end
      end
    end

    def create_entry_from_data(data, nosave = false)
      return XMLEntry.create_from_data(@path, data, nosave)
    end

    def create_entry_from_file(filename)
      return XMLEntry.create_from_file(@path, filename)
    end
  end
end

# EOF #
