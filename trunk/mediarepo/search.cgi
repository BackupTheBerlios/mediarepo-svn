#!/usr/bin/ruby -w

require "cgi"
require "mediarepo"
require "open3"

include MediaRepo


begin
  $repository = Repository.new("testrepo")

  cgi = CGI.new
  if (!cgi.has_key?("search")) then
    print cgi.header("text/html")
    print File.new("header.html").read()

    puts "Incorrect form data"

    print File.new("footer.html").read()  
  else
    search = cgi["search"]
    fin, fout, ferr = Open3.popen3("/home/grumbel/root/bin/swish-search", 
                                   "-f", "/home/grumbel/public_html/dbindex",
                                   "-c", "/home/grumbel/public_html/swish-e.cfg",
                                   "-x", "%r %p\n",
                                   "-w", search)

    print cgi.header("text/html")
    print File.new("header.html").read()
    
    fout.each_line { |line|
      if line.empty? or line[0] == ?. or line[0] == ?# then
        # do nothing
      elsif line =~ /^err:/ then
        puts "Search didn't give any results:<br>"
        puts "#{CGI.escapeHTML(line)}<br>"
        puts "<br>"
      else
        rank, md5 = line.split
        if md5 and is_md5(md5) then
          entry = $repository.get(md5)
          if entry then
            puts "#{rank}: <a href=\"show.cgi?md5=#{md5}\"><img src=\"testrepo/#{md5}/thumbnails/#{entry.thumbnails[0]}\"></a>" 
          else
            puts "Invalid entry: #{md5}<br>"
          end
        else
          puts "Invalid line: '#{line}'"
        end
      end
    }
    fin.close()
    fout.close()
    ferr.close()

    print File.new("footer.html").read()
  end
rescue
  puts "Something went wrong: #{$!}<br>"
  puts $!.backtrace.join("<br>")
end

# EOF #
