#!/usr/bin/ruby -w

require "mediarepo"

# MediaRepo::XMLEntry.new(".", "73eaaa99acafa1bed120c4ba07e01975")
a = MediaRepo::XMLEntry.create_from_file(".", "metadata.xml")
puts "# Loaded: %s" % a.load()
puts "Name:        #{a.name}"
puts "Author:      #{a.author}"
puts "Filename:    #{a.filename}"
puts "Description: #{a.description}"
puts "Parents:     #{a.parents.join(', ')}"
puts "Relates:     #{a.relateds.join(', ')}"
puts "# Wrote to: %s" % a.save("metadata_out.xml")
# puts "# Wrote to: %s" % a.save()

# EOF #
