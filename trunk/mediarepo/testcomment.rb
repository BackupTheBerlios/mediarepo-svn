#!/usr/bin/ruby -w

require "mediarepo"

comment = MediaRepo::XMLComment.load_from_file("comment.xml")

puts "# Reference: ", comment.reference
puts "# User: ",      comment.user
puts "# Subject: ",   comment.subject
puts "# Message: ",   comment.message

comment.user = "Ingo Ruhnke <bla.blub>"

comment.save_to_file("comment_out.xml")

# EOF #
