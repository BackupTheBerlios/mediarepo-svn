#!/usr/bin/ruby -w

require "digest/md5"
require "cgi"
require "mediarepo"

include MediaRepo

cgi = CGI.new

repository = Repository.new("testrepo")

if cgi.has_key?("md5") && (entry = repository.get(cgi['md5'])) then
  filename = entry.filename || ("unnamed." + ( entry.filetype || "dat"))

  filename.gsub!(/[\\\"]/) { |s| "\\" + s}
  filename.gsub!("\n", "")

# puts entry.filename
# puts entry.filetype 

  print <<EOF
Content-Type: #{entry.mime_type}
Content-Disposition: inline; filename="#{filename}"

EOF

  print entry.data
else
  print <<EOF
Content-Type: text/plain

Error: Couldn't find '#{cgi["md5"]}' in database

EOF
end

# EOF #
