#!/usr/bin/ruby -w

require "cgi"
require "digest/md5"
require "fileutils"
require "set"
require "mediarepo"

include MediaRepo

def debug_parameter(cgi)
  cgi.params.each { |key, value|
    puts "'#{key}' =&gt; #{value}<br>"
  }
end

def has_all_required_fields(cgi, fields)
  has_all = true
    fields.each { |i|
    has_all = has_all && cgi.has_key?(i)
  }
  return has_all
end

begin
  $logger = Logger.new("logs")

  required_fields = ["user", "subject", "message", "md5"]

  cgi = CGI.new
  print "Content-Type: text/html\n\n" 

  if has_all_required_fields(cgi, required_fields) then
    md5             = cgi["md5"]
    
    comment = XMLComment.new()
     
    comment.user    = cgi["user"].to_s
    comment.subject = cgi["subject"].to_s
    comment.message = cgi["message"].to_s
    if cgi.has_key?("reference") then
      comment.reference = cgi["reference"].to_s
    end
    comment.ip      = cgi.remote_addr

    puts "User:",     CGI.escapeHTML(comment.user), "<br>"
    puts "Subject: ", CGI.escapeHTML(comment.subject), "<br>"
    puts "Message: ", CGI.escapeHTML(comment.message), "<br>"
    
    comment.save("testrepo", md5)
    
    $logger.log("'#{cgi.remote_ident}@#{cgi.remote_addr}' added a comment to '#{md5}'")

    puts "<br>"
    puts "Port: #{cgi.server_port.to_s}<br>"
    puts "ServerName: #{cgi.server_name}<br>"
    puts "Host: #{cgi.host}<br>"
    puts "From: #{cgi.from}<br>"
    puts "remoteaddr: #{cgi.remote_addr}<br>"
    puts "remotehost: #{cgi.remote_host}<br>"
    puts "Comment submitted ok"
  else
    print "Required field missing:"
    debug_parameter(cgi)
  end
rescue
  puts "Something went wrong: #{$!}<br>"
  puts $!.backtrace.join("<br>")
end

# EOF #
