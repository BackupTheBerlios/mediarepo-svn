require "digest/md5"
require "fileutils"
require "set"
require "xmlentry.rb"
require "log.rb"
require "xmlcomment.rb"
require "open3"

module MediaRepo

  def is_md5(md5) 
    return (md5.size == 32) && ((/[^0123456789abcdef]/ =~ md5) == nil)
  end

  def filename2md5(file)
    return Digest::MD5.hexdigest(File.new(file).read())
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
    
    def search(searchexpr)
      STDOUT.flush

      # evaluate searchexpr and return all the results ordered by
      # there rank, best match comes first
      fin, fout, ferr = Open3.popen3("swish-search", # FIXME: hardcoded path
                                     "-f", "dbindex",
                                     "-c", "swish-e.cfg",
                                     "-x", "%r %p\n",
                                     "-w", searchexpr)
      
      results = []
      fout.each_line { |line|
        if line.empty? or line[0] == ?. or line[0] == ?# then
          # do nothing
        elsif line =~ /^err:/ then
          # FIXME: how to seperate no results from incorrect search term?
        else
          rank, md5 = line.split
          if md5 and is_md5(md5) then
            results.push(md5)
          else
            # line syntax wrong?
          end
        end
      }
      
      fin.close()
      fout.close()
      ferr.close()

      return results
    end
    
    def get(md5, follow_link = true, link_count = 0)
      if not is_md5(md5) then
        return nil 
      else
        entrypath = @path + "/" + md5
        if File.exist?(entrypath + "/data.dat") then   
          entry = XMLEntry.new(@path, md5)
          if follow_link and (not entry.override.empty?) and link_count < 20 then
            override = get(entry.override, true, link_count + 1)
            if override then 
              return override
            else # Override lead into void
              return entry
            end
          else
            return entry
          end
        else
          return nil
        end
      end
    end

    def create_entry_from_data(data, nosave = false)
      return XMLEntry.create_from_data(@path, data, nosave)
    end

    def create_entry_from_file(filename, nosave = false)
      return XMLEntry.create_from_file(@path, filename, nosave)
    end
  end
end

# EOF #
