require "mediarepo"
require "digest/md5"
require "rexml/document"

module MediaRepo
  class XMLComment
    attr_accessor :user, :subject, :message, :reference, :ip, :ctime

    def XMLComment.load(repopath, md5, messageid)
      return XMLComment.load_from_file("#{repopath}/#{md5}/comments/#{messageid}.xml")
    end

    def XMLComment.load_from_file(filename)
      file = File.new(filename, "r")
      doc = REXML::Document.new file

      comment = XMLComment.new

      @ctime = 0

      doc.elements.each("comment/reference") { |element| comment.reference = element.texts().map{|i| i.value}.to_s }
      doc.elements.each("comment/user")      { |element| comment.user      = element.texts().map{|i| i.value}.to_s }
      doc.elements.each("comment/creation-time") { |element| comment.ctime   = element.texts().map{|i| i.value}.to_s.to_i }
      doc.elements.each("comment/ip")        { |element| comment.ip        = element.texts().map{|i| i.value}.to_s }
      doc.elements.each("comment/subject")   { |element| comment.subject   = element.texts().map{|i| i.value}.to_s }
      doc.elements.each("comment/message")   { |element| comment.message   = element.texts().map{|i| i.value}.to_s }

      return comment
    end

    def initialize()
      @user    = "Guest"
      @ctime   = Time.now.to_i
      @ip      = ""
      @subject = ""
      @message = ""
      @reference = ""
    end
    
    def message_id()
      return Digest::MD5.hexdigest(@user + @subject + @message)
    end

    def save(repopath, md5)
      return save_to_file("#{repopath}/#{md5}/comments/#{self.message_id}.xml")
    end

    def save_to_file(filename)
      puts "### reference: ", @reference
      puts "### user: ", @user
      puts "### subject: ", @subject
      puts "### message: ", @message

      # Create a XMLDocument and fill it with content
      doc = REXML::Document.new 
      doc << REXML::XMLDecl.new
      
      entry = doc.add_element("comment")
      entry.add_element("reference").text  = @reference
      entry.add_element("user").text       = @user
      entry.add_element("ip").text         = @ip
      entry.add_element("creation-time").text = @ctime.to_s
      entry.add_element("subject").text    = @subject
      entry.add_element("message").text    = @message

      file = File.new(filename, "w")
      doc.write(file, 0)
      file.puts ""
      file.close()
    end

  end  
end

# EOF #
