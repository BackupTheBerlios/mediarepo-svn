require "rexml/document"
require "rexml/streamlistener"

module MediaRepo

  class XMLEntryParser
    include REXML::StreamListener
    
    def initialize(entry)
      @entry   = entry
      @text    = 0
    end
    
    def tag_start(name, attrs)
      #puts "tag_start: #{name} #{attrs}"
      @text = ""
    end
    
    def tag_end(name)
      # puts "#{name} => #{@text}"
      case name
      when "version"
        @entry.version = @text.to_i
      when "ctime"
        @entry.ctime = @text.to_i
      when "md5"
        @entry.md5 = @text
      when "filesize"
        @entry.filesize = @text.to_i
      when "name"
        @entry.name = @text
      when "description"
        @entry.description = @text
      when "author"
        @entry.author = @text
      when "license"
        @entry.license = @text
      when "filetype"
        @entry.filetype = @text
      when "filename"
        @entry.filename = @text
      when "keyword"
        @entry.keywords.push(@text)
      when "category"
        @entry.categories.push(@text)
      when "parent"
        @entry.parents.push(@text)
      when "related"
        @entry.relateds.push(@text)
      when "categories", "keywords", "relateds", "parents", "entry"
        # ignore for faster parsing
      else
        puts "Warning: Unhandled tag: #{name}"
      end
      #puts "tag_end: #{name}"
    end

    def text(text)
      @text += text
    end
  end

  class XMLEntry
    attr_reader(:path)
    attr_accessor(:version, :ctime, :md5, :filesize,
                  :name, :description, :keywords, :categories,
                  :author, :license, :filetype, :filename, 
                  :relateds, :parents)

    def XMLEntry.create_from_file(repopath, filename, nosave = false)
      entry = XMLEntry.create_from_data(repopath, File.new(filename).read(), true)

      # Write type
      entry.filename = File.basename(filename)
      entry.filetype = File.extname(filename).gsub(".", "")
      if not nosave then
        entry.save()
      end

      return entry
    end

    def XMLEntry.create_from_data(repopath, data, nosave = false)
      md5 = Digest::MD5.hexdigest(data)
      
      entrypath = repopath + "/" + md5
      # Write
      begin
        FileUtils.mkdir(entrypath)
        FileUtils.mkdir(entrypath + "/renders")
        FileUtils.mkdir(entrypath + "/thumbnails")
        FileUtils.mkdir(entrypath + "/comments")

        f = File.new(entrypath + "/" + "data.dat", "w")
        f.write(data)
        f.close()
        
      rescue Errno::EEXIST
        # Do nothing if entry is already there
      end

      entry = XMLEntry.new(repopath, md5)
      entry.md5      = md5
      entry.ctime    = Time.now().to_i
      entry.filesize = File.size(entrypath + "/" + "data.dat")

      if not(nosave) then
        entry.save()
      end

      return entry
    end

    ## The path argument must be the path to the entry in the
    ## repository and the entry must be present
    def initialize(repopath, md5)
      @path = repopath + "/" + md5
      @md5  = md5
      self.init_defaults()
      @ready = false
      self.prepare()
    end

    def prepare()
      if not @ready then
        #puts "Loading..."
        #raise "bla"
        self.load() 
        @ready = true
      end
    end

    def init_defaults()
      @version     = 1
      @ctime       = 0
      @md5         = ""
      @filesize    = 0
      @name        = "" # Human readable name of the object
      @description = "" # Human readable description of the object
      @author      = ""
      @license     = ""
      @filename    = ""
      @filetype    = ""
      @keywords    = [] # free-form keywords that can be used to search 
      @categories  = [] 
      @relateds    = []
      @parents     = []
    end

if false then
    def ctime() 
      self.prepare()
      return @ctime
    end

    def filesize() 
      self.prepare()
      return @filesize
    end

    def name() 
      self.prepare()
      return @name
    end

    def description() 
      self.prepare()
      return @description
    end

    def keywords() 
      self.prepare()
      return @keywords
    end

    def categories() 
      self.prepare()
      return @categories
    end

    def author() 
      self.prepare()
      return @author
    end

    def filetype() 
      self.prepare()
      return @filetype
    end

    def filename() 
      self.prepare()
      return @filename
    end

    def relateds() 
      self.prepare()
      return @relateds
    end
     
    def parents() 
      self.prepare()
      return @parents
    end

## SNIP
    def ctime=(value) 
      self.prepare()
      @ctime = value
    end

    def filesize=(value) 
      self.prepare()
      @filesize = value
    end

    def name=(value) 
      self.prepare()
      @name = value
    end

    def description=(value) 
      self.prepare()
      @description = value
    end

    def keywords=(value) 
      self.prepare()
      @keywords = value
    end

    def categories=(value) 
      self.prepare()
      @categories = value
    end

    def author=(value) 
      self.prepare()
      @author = value
    end

    def filetype=(value) 
      self.prepare()
      @filetype = value
    end

    def filename=(value) 
      self.prepare()
      @filename = value
    end

    def relateds=(value) 
      self.prepare()
      @relateds = value
    end
     
    def parents=(value) 
      self.prepare()
      @parents = value
    end
end
    def renders()
      return Dir.new("#{@path}/renders/").entries.grep(/(.png|.jpg)$/)
    end

    def thumbnails()
      return Dir.new("#{@path}/thumbnails/").entries.grep(/(.png|.jpg)$/)
    end
    
    # Return comments to this xmlentry in a tree structured array:
    # [[reply1, 
    #  [reply1.1], 
    #  [reply1.2, 
    #   reply1.2.1]]
    #  [reply2]]
    def comments()
      # FIXME: add tree sorter here
      if File.exists?("#{@path}/comments/") &&  File.stat("#{@path}/comments/").directory? then
        comments = Dir.new("#{@path}/comments/").entries.grep(/(.xml)$/).map { |i|
          XMLComment.load_from_file("#{@path}/comments/#{i}")
        }

        if true then
          threads_by_id = {}
          comments.each { |comment|
            #puts "msgid: #{comment.message_id}<br>"
            threads_by_id.merge!({comment.message_id => [comment]})
          }

          threads = []
          # puts "threads_by_id: #{threads_by_id.to_s}<br>"
          threads_by_id.each { |msgid, thread|
            # puts "run: #{msgid} #{thread[0].message_id}<br>"
            comment = thread[0]
            if comment.reference.empty? then
              threads.push(thread)
            else
              ref = threads_by_id[comment.reference]
              if ref then
                ref.push(thread)
              else
                # Reference doesn't resolve, bug in database
                # FIXME: add logging
                # puts "## ERROR ###"
                threads.push(thread)
              end
            end
          }
          return threads
        else
          threads_by_id = {}
          threads = []
          while not comments.empty?
            comments.each_index { |i|
              comment = comments[i]
              
              if comment.reference.empty? then
                thread = [comment]
              else
                thread = threads_by_id[comment.reference]
                
                if not thread then
                  el = comments.find {|j| j.message_id == comment.reference}
                  if not el then
                    # Reference doesn't resolve, bug in database
                    # FIXME: add logging
                    puts "## ERROR ###"
                    thread = [comment]
                  end
                end
              end
              
              if thread then
                threads.push(thread)
                threads_by_id.merge({comment.message_id => thread})
                comments.delete_at(i)
              end
            }
          end

          return threads
        end
      else
        return []
      end
    end

    def load()
      # insert loading code here
      version = -1
      Dir.new(@path).each { |i|
        res = i.scan(/metadata.xml.([0-9]+)/)
        if res != [] then
          new_version = res[0][0].to_i
          if (new_version > version) then
            version = new_version
          end
        end
      }

      if (version < 0) then
        # no metadata is ok
      else
        filename = "metadata.xml.#{version}"

        file = File.new( @path + "/" + filename, "r")

        if false then
          doc  = REXML::Document.new file
          
          doc.elements.each("entry/version")          { |element|  @version     = element.texts().map{|i| i.value}.to_s.to_i }
          doc.elements.each("entry/ctime")            { |element|  @ctime       = element.texts().map{|i| i.value}.to_s.to_i }
          doc.elements.each("entry/md5")              { |element|  @md5         = element.texts().map{|i| i.value}.to_s }
          doc.elements.each("entry/filesize")         { |element|  @filesize    = element.texts().map{|i| i.value}.to_s.to_i }
          doc.elements.each("entry/name")             { |element|  @name        = element.texts().map{|i| i.value}.to_s }
          doc.elements.each("entry/description")      { |element|  @description = element.texts().map{|i| i.value}.to_s }
          doc.elements.each("entry/author")           { |element|  @author      = element.texts().map{|i| i.value}.to_s }
          doc.elements.each("entry/filename")         { |element|  @filename    = element.texts().map{|i| i.value}.to_s }
          doc.elements.each("entry/filetype")         { |element|  @filetype    = element.texts().map{|i| i.value}.to_s }
          doc.elements.each("entry/keywords/keyword") { |element|  @keywords.push(element.texts().map{|i| i.value}.to_s) }
          doc.elements.each("entry/categories/category") { |element| @categories.push(element.texts().map{|i| i.value}.to_s) }
          doc.elements.each("entry/relateds/related") { |element|  @relateds.push(element.texts().map{|i| i.value}.to_s) }
          doc.elements.each("entry/parents/parent")   { |element|  @parents.push(element.texts().map{|i| i.value}.to_s) }
        else
          # puts "Parse: #{@path + "/" + filename}"
          REXML::Document.parse_stream(file, XMLEntryParser.new(self))
        end

        return filename
      end
    end

    def save(arg_filename = nil)
      # Create a XMLDocument and fill it with content
      doc = REXML::Document.new 
      doc << REXML::XMLDecl.new
      
      entry = doc.add_element("entry")
      entry.add_element("version").text     = @version.to_s
      entry.add_element("ctime").text       = @ctime.to_s
      entry.add_element("md5").text         = @md5
      entry.add_element("filesize").text    = @filesize.to_s
      entry.add_element("name").text        = @name
      entry.add_element("description").text = @description
      entry.add_element("author").text      = @author
      entry.add_element("filename").text    = @filename
      entry.add_element("filetype").text    = @filetype
    
      keywords = entry.add_element("keywords")
      @keywords.each { |keyword|
        keywords.add_element("keyword").text = keyword
      }

      categories = entry.add_element("categories")
      @categories.each { |category|
        categories.add_element("category").text = category
      }

      relateds = entry.add_element("relateds")
      @relateds.each { |related|
        relateds.add_element("related").text = related
      }
      
      parents = entry.add_element("parents")
      @parents.each { |parent|
        parents.add_element("parent").text = parent
      }
      
      # Write down the created XMLDocument to a file

      # Some simple versioned file access
      file = nil 
      if (arg_filename == nil) then
        count = 0
        file  = nil
        while file == nil
          begin
            version  = "#{Time.now.to_i.to_s}%02d" % count
            out_filename = "#{@path}/metadata.xml.#{version}"
            file = File.new(out_filename, File::WRONLY | File::CREAT | File::EXCL)
          rescue Errno::EEXIST
            count += 1
          end
        end
      elsif arg_filename.is_a?(String) then
        out_filename = arg_filename
        file = File.new(out_filename, File::WRONLY | File::CREAT)
      elsif arg_filename.is_a?(StringIO) then
        file = arg_filename
      end

      if file then
        doc.write(file, 0)
        file.puts "" # Write a trailing newline for a nicer look
        if not(file.is_a?(StringIO)) then
          file.close
        end

        return out_filename
      else
        raise "Error: Couldn't create file: '#{out_filename}'"
      end
    end

    def data()
      return File.new(@path + "/data.dat").read()
    end

    # Check the data integrity, return true if everything is ok, false otherwise
    def check()
      return (Digest::MD5.hexdigest(File.new(@path + "/" + "data.dat").read()) == @md5)
    end

    # Return a human readable name for the entry
    def print_name()
      if !@name.empty? then
        return @name
      else
        return @filename 
      end
    end

    def mime_type()
      case self.filetype
      when "blend"
        return "application/x-blender"
      when "ogg"
        return "application/x-ogg"
      when "jpg"
        return "image/jpeg"
      when "png"
        return "image/png"
      when "xcf"
        return "application/x-gimp-image"
      else
        return "application/octet-stream"
      end
    end
  end
end

# EOF #
