#!/usr/bin/ruby -w

require "digest/md5"
require "cgi"
require "mediarepo"

include MediaRepo

print "Content-Type: text/html\n\n"

print <<EOF
<html>
      <head>
      <title>Upload script</title>
</head>
      <body>
EOF

$required_fields = ["name", "author", "filename", "description", "content", "keywords"]

def debug_parameter(cgi)
  cgi.params.each { |key, value|
    puts "'#{key}' => "
    value.each { |value|
      v = value.read
      puts "'#{CGI.escapeHTML(v)}'"
      puts "read: #{v} #{Digest::MD5.hexdigest(v)}<br>"                  # <== body of value
      puts "local_path: #{value.local_path}<br>"            # <== path to local file of value
      puts "original_filename: #{value.original_filename}<br>"     # <== original filename of value
      puts "content_type: #{value.content_type}<br>"          # <== content_type of value
    }
    puts "<P>"
  }
end

def has_required_fields(cgi)
  has_all = true
  $required_fields.each { |i|
    has_all = has_all && cgi.has_key?(i)
  }
  return has_all
end

begin
  $logger = Logger.new("logs")
  cgi = CGI.new

  #debug_parameter(cgi)

  if has_required_fields(cgi) then
    name        = cgi["name"].read
    author      = cgi["author"].read
    filename    = cgi["filename"].read
    description = cgi["description"].read
    keywords    = cgi["keywords"].read.gsub(",", " ").split(" ")
    content     = cgi["content"].read

    if (cgi.has_key?("md5")) then
      md5         = cgi["md5"].read
    end
    
    if not content.empty? then
      filename    = cgi["content"].original_filename   
    end

    repository = Repository.new("testrepo")
    
    if content.empty?  then
      if cgi.has_key?("md5") then
        entry = repository.get(md5)
      else
        raise "You need to submit a file"
      end
    else
      entry = repository.create_entry_from_data(content, true)
      if entry.filetype.empty? then
        entry.filetype = File.extname(filename).gsub(".", "")
      end
    end
    
    if not entry then
      puts "Error: Couldn't find '#{md5}'<br>"
    end

    entry.name        = name
    entry.author      = author
    entry.filename    = filename
    entry.description = description
    entry.keywords    = keywords

    outfile = entry.save()

    $logger.log("'#{cgi.remote_addr}' changed entry '#{md5}' to '#{outfile}'")

    puts "commit successfull: <a href=\"show.cgi?md5=#{entry.md5}\">#{entry.md5}</a>"
  else
    
    puts "Error: incorrect form data"

  end
rescue
  puts "Something went wrong: #{$!}<br>"
  puts $!.backtrace.join("<br>")
end

print <<EOF
</body>
</html>
EOF

# EOF #
