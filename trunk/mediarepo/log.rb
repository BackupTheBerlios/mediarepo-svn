require "digest/md5"

module MediaRepo
  class LogEntry
    attr_accessor :ctime, :message
    # Who and on what host commited the stuff?
    attr_accessor :ident, :host
    
    def initialize(filename = nil)
      @ctime   = 0
      @message = ""

      if filename then
        file = File.new(filename, "r")
        doc = REXML::Document.new file
        
        comment = XMLComment.new
        
        doc.elements.each("log/ctime") { |element| entry.message   = element.texts().map{|i| i.value}.to_s.to_i }
        doc.elements.each("log/message") { |element| entry.message   = element.texts().map{|i| i.value}.to_s }
      end
    end
    
    def save(filename)
      doc = REXML::Document.new 
      doc << REXML::XMLDecl.new
      
      entry = doc.add_element("log")
      entry.add_element("ctime").text   = @ctime.to_s
      entry.add_element("message").text = @message

      file = File.new(filename, "w")
      doc.write(file, 0)
      file.puts ""
      file.close()
    end
  end

  class ModificationLogEntry
  end

  class AddLogEntry
    
  end

  class Logger
    def initialize(path)
      @path = path
    end

    def log(user, ident, addr, host, msg)
      entry = LogEntry.new()
      entry.ctime   = Time.now().to_i
      entry.message = "User: #{user}\nIdent: #{ident}\nAddr: #{addr}\nHost: #{host}\n#{msg}"
      entry.save(@path + "/" + Digest::MD5.hexdigest(entry.ctime.to_s + entry.message) + ".xml")
    end
  end
end

# EOF #
