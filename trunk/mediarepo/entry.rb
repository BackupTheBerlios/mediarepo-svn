# Obsolete

    def create_entry_from_data(data)
      md5 = Digest::MD5.hexdigest(data)
      entrypath = @path + "/" + md5
      puts "Entrypath: #{entrypath}"
      # Write
      begin
        FileUtils.mkdir(entrypath)

        f = File.new(entrypath + "/" + "=data", "w")
        f.write(data)
        f.close()

        # Write time
        f = File.new(entrypath + "/" + "=ctime", "w")
        f.write(Time.now.to_i.to_s)
        f.close()
      rescue Errno::EEXIST
        # Do nothing if entry is already there
      end

      return self.get(md5)
    end

    def create_entry_from_file(filename)
      entry = create_entry_from_data(File.new(filename).read())

      # Write type
      type = File.extname(filename)
      if (not type.empty?) then
        f = File.new(entry.path + "/" + "=type", "w")
        f.write(type[1, type.length])
        f.close()
      end
      
      entry.filename = File.basename(filename)

      return entry
    end
  end


  class Entry
    attr_reader :md5, :entrypath

    # Get a handle to an entry without error checking, use repository.get instead
    def initialize(repository_path, md5)
      @md5       = md5
      @entrypath = repository_path + "/" + @md5
    end

    def path()
      return @entrypath
    end

    def print_name()
      if (self.filetype == "directory") then
        return "#{self.name}"
      else
        return self.name || self.filename || self.md5
      end
    end

    def size()
      return File.size(@entrypath + "/" + "=data")
    end

    def description()
      begin
        return File.new(@entrypath + "/" + "=description", "r").read()
      rescue ArgumentError, Errno::ENOENT
        return ""
      end    
    end

    def description=(value)
      f = File.new(@entrypath + "/" + "=description", "w")
      f.write(value)
      f.close()
    end

    def special=(value)
      f = File.new(@entrypath + "/" + "=special", "w")
      f.write(value)
      f.close()
    end

    def special()
      begin
        return File.new(@entrypath + "/" + "=special", "r").read()
      rescue ArgumentError, Errno::ENOENT
        return nil
      end    
    end
    
    def autogenerated=(value)
      f = File.new(@entrypath + "/" + "=autogenerated", "w")
      if value then
        f.write(1)
      else
        f.write(0)
      end
      f.close()
    end

    def autogenerated()
      begin
        if File.new(@entrypath + "/" + "=autogenerated", "r").read().to_i != 0
          return true
        else
          return false
        end
      rescue ArgumentError, Errno::ENOENT
        return false
      end
    end

    def check()
      begin
        return (Digest::MD5.hexdigest(File.new(@entrypath + "/" + "=data").read()) == @md5)
      rescue
        return false
      end
    end
    
    def data()
      begin
        return File.new(@entrypath + "/" + "=data", "r").read()
      rescue ArgumentError, Errno::ENOENT
        return nil
      end
    end

    def parent=(value)
      f = File.new(@entrypath + "/" + "=parent", "w")
      f.write(value)
      f.close()
    end

    def parent()
      begin
        return File.new(@entrypath + "/" + "=parent", "r").read()
      rescue ArgumentError, Errno::ENOENT
        return nil
      end    
    end

    def author=(value)
      f = File.new(@entrypath + "/" + "=author", "w")
      f.write(value)
      f.close()
    end

    def author()
      begin
        return File.new(@entrypath + "/" + "=author", "r").read()
      rescue ArgumentError, Errno::ENOENT
        return ""
      end    
    end

    def name=(value)
      f = File.new(@entrypath + "/" + "=name", "w")
      f.write(value)
      f.close()
    end

    def name()
      begin
        return File.new(@entrypath + "/" + "=name", "r").read()
      rescue ArgumentError, Errno::ENOENT
        return nil
      end    
    end

    def mime_type()
      case self.filetype
      when "blend"
        return "application/x-blender"
      when "ogg"
        return "application/x-ogg"
      when "jpg", "jpeg"
        return "image/jpeg"
      when "png"
        return "image/png"
      when "xcf"
        return "application/x-gimp-image"
      else
        return "application/octet-stream"
      end
    end

    def file_type()
      begin
        return File.new(@entrypath + "/" + "=type", "r").read()
      rescue ArgumentError, Errno::ENOENT
        return nil
      end
    end

    def file_type=(value)
      f = File.new(@entrypath + "/" + "=type", "w")
      f.write(value)
      f.close()
    end

    def type()
      self.file_type
    end

    def type=(value)
      self.file_type = value
    end

    def filename=(value)
      f = File.new(@entrypath + "/" + "=filename", "w")
      f.write(value)
      f.close()
    end

    def filename()
      begin
        return File.new(@entrypath + "/" + "=filename", "r").read()
      rescue ArgumentError, Errno::ENOENT
        return nil
      end    
    end

    def ctime()
      begin
        return Time.at(Integer(File.new(@entrypath + "/" + "=ctime", "r").read()))
      rescue ArgumentError, Errno::ENOENT
        return nil
      end
    end

    def read_prop_list(prop)
      begin
        return File.new(@entrypath + "/" + "=" + prop, "r").read().split()
      rescue ArgumentError, Errno::ENOENT
        return []
      end    
    end

    def write_prop_list(prop, value)
      f = File.new(@entrypath + "/" + "=" + prop, "w")
      
      value.each { |i|
        f.write(i)
        f.write(" ")
      }
      f.close()
    end

    def renders() read_prop_list("renders") end
    def renders=(value) 
      write_prop_list("renders", value) 
    end
    def render_add(text)
      a = self.renders
      r = Set.new(a)
      r.add(text)
      self.renders = r.to_a
    end

    def thumbnails() read_prop_list("thumbnails") end
    def thumbnails=(value) write_prop_list("thumbnails", value) end
    def thumbnail_add(text)
      a = self.thumbnails()
      r = Set.new(a)
      r.add(text)
      self.thumbnails = r.to_a
    end

    def related() read_prop_list("related").sort() end
    def related=(value) write_prop_list("related", value) end
    def related_add(text)
      if (text != md5) then
        a = self.relateds()
        r = Set.new(a)
        r.add(text)
        self.relateds = r.to_a
      end
    end

    def keywords() read_prop_list("keywords") end
    def keywords=(value) write_prop_list("keywords", value) end
  end
