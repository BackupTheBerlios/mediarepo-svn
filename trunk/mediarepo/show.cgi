#!/usr/bin/ruby -w

require "cgi"
require "digest/md5"
require "fileutils"
require "set"
require "mediarepo"

include MediaRepo

$cc_license_html = <<EOF
<!-- Creative Commons License -->
<a rel="license" href="http://creativecommons.org/licenses/by-sa/2.0/"><img alt="Creative Commons License" border="0" src="http://creativecommons.org/images/public/somerights20.gif" ></a><br >
This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/2.0/">Creative Commons License</a>.
<!-- /Creative Commons License -->
EOF

$categories = \
["animation", "sketch", "texture", "sprite", "material", "template", "reference",
 "vehicle", "tank", "helicopter", "plane", "car", "truck", "spaceship", "ship", "boat",
 "human", "animal", "male", "female", "robot", "humanoid",
 "horse", "dog", "bird", "cat", "cow", "bunny", "fish", "whale",
 "plant", "tree",
 "building", "house", "bridge", "window", "utility",
 "weapon", "pistol", "rifle",
 "scenery", "object", "detail", 
 "photography", "pencil", "rendered", "painted", "screenshot",
 "abstract", "metallic", "water", "rust", "wood", "glass", "realistic", 
 "highpoly", "lowpoly" ]

# FIXME: hack
oldpath = ENV["PATH"]
ENV["PATH"] = oldpath + ":/home/grumbel/bin/"

def make_links(str)
  return str.gsub(/(https?:\/\/[^ <>]+)/, '<a href="\1">\1</a>')
end

def render_entries(entries, col, per_page, page_num)
  puts "<table align=\"center\">"
  count = 0
  puts "<tr>"

  entries.slice(page_num * per_page, per_page).each {|entry|
    if count >= col then
      count = 0
      puts "</tr>"
      puts "<tr>"
    end
    
    puts "<td>"
    if entry then
      entry.render_html()
    else
      puts "<a href=\"download.cgi?md5=#{md5}\"><img src=\"images/404render.png\"></a>"
    end
    puts "</td>"
    
    count += 1
  }

  puts "</tr>"
  puts "</table>"
end

def render_page_line(total, per_page, page_num)
  if total > per_page then
    puts "<p align=\"center\">[ "
    ((total / per_page)+1).times { |i|
      if i == page_num then
        puts " #{i} "
      else
        puts " <a href=\"#{yield(i)}\">#{i}</a> "
    end
    }
    puts " ]</p>"
  end
end

def search_results_page(searchexpr, per_page = 30, page_num = 0)
  results = $repository.search(searchexpr)
  if results.empty? then
    puts "<p>No items found matching '#{searchexpr}'</p>"
  else
    render_page_line(results.size, per_page, page_num) { |i|
      "show.cgi?search=#{CGI.escape(searchexpr)}&per_page=#{per_page}&page_num=#{i}"
    }
    render_entries(results.map {|i| $repository.get(i)}, 6, per_page, page_num)
    render_page_line(results.size, per_page, page_num) { |i|
      "show.cgi?search=#{CGI.escape(searchexpr)}&per_page=#{per_page}&page_num=#{i}"
    }
  end
end

def entry_page(md5, show_edit)
  entry = $repository.get(md5, (not $cgi.has_key?("nofollow")))
  
  if entry == nil then
    puts "<p><b>Error:</b> Entry #{md5} not in the database.</p>"
    puts "[<a href=\"show.cgi\">back</a>]<br>"
  else
    puts "<center>"
    puts "[<a href=\"show.cgi\">back</a>]<br><br>"

    puts "<table><tr>"
    
    if (entry.filetype == "directory") then
    puts "<td valign=\"top\" align=\"center\">"
      puts "<table><tr>"
      column = 0
      entry.data.each { |md5|
        md5.chomp!
        dentry = $repository.get(md5)
        if (dentry) then
          dentry.thumbnails.each { |thumb|
            puts "<td width=\"128\" height=\"128\" valign=\"middle\" align=\"center\"><a href=\"?md5=#{dentry.md5}\"><img border=\"0\" src=\"#{dentry.path}/thumbnails/#{thumb}\"></a></td>"
            column += 1
            if column >= 4 then
              column = 0
              puts("</tr><tr>")
            end
          }
        else
          puts "Warning: #{md5} not in database<br>"
        end
      }
      puts "</tr></table>"
    puts "<br></td>"
    elsif (entry.filetype == "txt") then
      puts "<td>"
      puts "<pre>#{CGI.escapeHTML(entry.data)}</pre>"
      puts "</td>"
    else
    puts "<td valign=\"top\" align=\"center\">"
      if entry.renders.empty? then
        puts "<a href=\"download.cgi?md5=#{md5}\"><img src=\"images/404render.png\"></a><br>"
      else
        entry.renders.each { |render|
          puts "<a href=\"download.cgi?md5=#{md5}\"><img src=\"#{entry.path}/renders/#{render}\"></a><br>"
        }
      end
    puts "<br></td>"
    end
    puts "<td valign=\"top\">"
    
    puts "<h3>#{entry.print_name}</h3>"  
    puts "<b>Filename:</b> <a href=\"download.cgi?md5=#{md5}\">#{entry.filename}</a><br>"
    puts "<b>Pathname:</b> #{File.dirname(entry.pathname)}<br>"
    puts "<b>MD5:</b>      #{entry.md5}<br>"
    if is_md5(entry.license) and (el = $repository.get(entry.license)) then
      puts "<b>License:</b>  <a href=\"show.cgi?md5=#{entry.license}\">see #{el.name}</a><br>"
    else
      puts "<b>License:</b>  #{entry.license}<br>"
    end
    puts "<b>Type:</b>     #{entry.filetype}<br>"

    if is_md5(entry.author) and (el = $repository.get(entry.author)) then
      puts "<b>License:</b>  <a href=\"show.cgi?md5=#{entry.author}\">see #{el.name}</a><br>"
    else
      puts "<b>Author:</b>   #{CGI.escapeHTML(entry.author)}<br>"
    end

    puts "<b>Creation:</b> #{Time.at(entry.ctime).to_s}<br>"
    puts "<b>Size:</b>     #{entry.filesize}<br>"
    puts "<b>Keywords:</b> #{entry.keywords.join(", ")}<br>"
    puts "<b>Description:</b><br>"
    puts "<p class=\"description\">#{make_links(CGI.escapeHTML((entry.description || "")).gsub("\n", "<br>"))}</p>"
    puts "<p>"
#    puts "[<a href=\"show.cgi?md5=#{entry.md5}&edit\" onClick=\"toggleElementVisibility('editEntry')\">Edit this entry</a>]"
    puts "[<a href=\"javascript:toggleElementVisibility('editEntry')\">Edit this entry</a>]"

    if not entry.next_versions.empty? then
      puts "<b>Next Revisions:</b><br>"
      entry.next_versions.each { |i|
        puts "<a href=\"show.cgi?md5=#{i}\">#{i}</a><br>"
      }
    end

    if not entry.prev_versions.empty? then
      puts "<b>Previous Revisions:</b><br>"
      entry.prev_versions.each { |i|
        puts "<a href=\"show.cgi?md5=#{i}\">#{i}</a><br>"
      }
    end

    puts "</td>"
    puts "</tr>"
    puts "</table>"

    if not entry.relateds.empty? then
    puts "<h3>See also:</h3>"
      puts "<p>"
      entry.relateds.each { |related|
        rel_entry = $repository.get(related)
        rel_entry.thumbnails.each { |thumb|
          puts "<a href=\"show.cgi?md5=#{related}\"><img src=\"#{rel_entry.path}/thumbnails/#{thumb}\" ></a>"
        }
      }
      puts "</p>"
    end
    
    comments_section(entry)

    # puts "<center>[<a href=\"\">Post a new comment</a>]</center><br>"
    puts "[<a href=\"javascript:toggleElementVisibility('writeComment')\">Write a comment</a>]<br>"
    puts "<div id=\"writeComment\">"
    puts "<FORM action=\"comment.cgi\" method=\"post\">"
    puts '<TABLE border="0">'
    form_field_hidden("md5", entry.md5)
    form_field_text("User:", "user", "Guest")
    form_field_text("Subject:", "subject", "")
    form_field_textarea("Message:", "message", "")
    puts '<tr><td></td><td align="right"><INPUT type="submit" value="Submit"></td></tr>'
    puts '</TABLE>'
    puts "</FORM>"
    puts "</div><script>toggleElementVisibility('writeComment')</script>"


#    if show_edit then
    puts "<div id=\"editEntry\">"
    edit_entry_section(entry)
    puts "</div><script>toggleElementVisibility('editEntry')</script>"
 #   end

  end
end

def render_thread(entry, args, level)
  if level > 5 then
    level = 5
  end

  (comment, *threads) = args

  puts "<table width=\"100%\" style=\"padding-left: #{level*2}em;\" cellspacing=\"0\">"
  puts "  <tr style=\"padding-top: 0; padding-bottom: 0; margin: 0;\">"
  puts "   <td align=\"left\" style=\"border-style: solid; border-width: thin;\" bgcolor=\"#bbcccc\"><strong>#{CGI.escapeHTML(comment.subject)}</strong> posted by <strong>#{CGI.escapeHTML(comment.user)} @ #{comment.ip}</strong> at #{Time.at(comment.ctime).to_s}</td>"
  puts "   <td align=\"right\">[<a href=\"javascript:toggleElementVisibility('writeComment#{comment.message_id}')\">Reply</a>]</td>"
  puts "  </tr>"
  #puts "  <tr>"
  #puts "   <td colspan=\"2\">#{comment.message_id} -> #{comment.reference}</td>"
  #puts "  </tr>"
  puts "  <tr><td colspan=\"2\" align=\"left\" style=\"border-style: solid; border-width: thin;\" >#{CGI.escapeHTML(comment.message).gsub("\n", "<br>")}</td></tr>"
  puts "</table>"
  puts "<br>"

  puts "<div id=\"writeComment#{comment.message_id}\">"
  puts "<FORM action=\"comment.cgi\" method=\"post\">"
  puts '<TABLE border="0">'
  form_field_hidden("md5", entry.md5)
  form_field_hidden("reference", comment.message_id)
  form_field_text("User:", "user", "Guest")
  form_field_text("Subject:", "subject", "")
  form_field_textarea("Message:", "message", "")
  puts '<tr><td></td><td align="right"><INPUT type="submit" value="Submit"></td></tr>'
  puts '</TABLE>'
  puts "</FORM>"
  puts "</div><script>toggleElementVisibility('writeComment#{comment.message_id}')</script>"
  
  threads.each { |comment| 
    render_thread(entry, comment, level+1)
  }
end

def comments_section(entry)
  entry.comments.each { |thread|
    puts "<table width=\"80%\" style=\"border-style: solid; border-width: thin; margin-bottom: 1em;\"><tr><td>"
    render_thread(entry, thread, 0)
    puts "</td></tr></table>"
  }
end

def form_field_textarea(label, name, value)
  puts "<tr>"
  puts "  <td valign=\"top\"><label>#{label}</label></td>"
  puts "  <td><TEXTAREA name=\"#{name}\" rows=\"10\" cols=\"80\">#{value}</TEXTAREA></td>"
  puts "</tr>"
end

def form_field_text(label, name, value)
  puts "<tr>"
  puts "  <td valign=\"top\"><label>#{label}</label></td>"
  puts "  <td><INPUT type=\"text\" name=\"#{name}\" value=\"#{value}\" size=80><br>"
  puts "</tr>"
end

def form_field_file(label, name)
  puts "<tr>"
  puts "  <td valign=\"top\"><label>#{label}</label>"
  puts '  <td><INPUT type="file" name="content" value="[use this to upload a new, better version of the data]" size="80"><BR>'
end

def form_field_hidden(name, value)
  puts "<input type=\"hidden\" name=\"#{name}\" value=\"#{value}\">"
end

$other_license_tooltip = "If you need another license, then those in the list, then upload your license as a seperate entry, select 'Other' from the list and enter the md5 of your other license into the 'Other License' field."

def submit_page()
  puts "<center>"
  puts "<h2>Submit Media</h2>"
  puts "<p>"
  puts "Before you make larger edits to the repositories metadata make sure you have checked out our <a href=\"\">Policy</a> and <a href=\"\">Guidelines</a> first."
  puts "</p>"
  puts '<FORM action="upload.cgi" enctype="multipart/form-data" method="post">'
  puts '<TABLE border="0">'
  puts '<tr><td valign="top"><label>License:</label>'
  puts '<td><SELECT name="license">'
  puts '<OPTION value="default">Default: GNU GPL V2.0 + CC-BY-SA-V2</OPTION>'
  puts '<OPTION value="gpl">GNU GPL V2.0 or later</OPTION>'
  puts '<OPTION value="ccbysa">Creative Commons Attributions Sharealike V2.0</OPTION>'
  puts '<OPTION value="publicdomain">Public Domain</OPTION>'
  puts '<OPTION value="other">Other</OPTION>'
  puts '</SELECT>'
  puts "<label title=\"#{$other_license_tooltip}\">Other License:</label><INPUT type=\"text\" name=\"other-license\" value=\"\">"
  puts '<br>'

  form_field_text("Name",     "name",     "")
  form_field_text("Author",   "author",   "")
  form_field_text("Filename", "filename", "")
  form_field_textarea("Description", "description", "")

  form_field_text("Keywords",   "keywords",  "")
  
  puts "<tr>"
  puts "  <td valign=\"top\">Categories:</td>"
  puts "<td>"

  count = 0
  puts "<table><tr>"
  $categories.each { |i|
    puts "<td>"
    puts "<INPUT name=\"category\"  type=\"checkbox\" value=\"#{i}\" tabindex=\"20\">#{i}</INPUT>"
    puts "</td>"
    count += 1
    if count >= 8 then
      puts "</tr><tr>"
      count = 0
    end
  }
  puts '</td></tr></table></td>'
  puts "</center>"
  form_field_file("File:", "content") 
 
  puts '</table>'
  puts '  <INPUT type="submit" value="Submit the File"><td align="right">'
  puts '  </FORM>'
  
end

def edit_entry_section(entry)
  puts "<hr>"
  puts "<h2>Edit this entry</h2>"
  puts "<p>"
  puts "Before you make larger edits to the repositories metadata make sure you have checked out our <a href=\"\">Policy</a> and <a href=\"\">Guidelines</a> first."
  puts "</p>"
  puts '<FORM action="upload.cgi" enctype="multipart/form-data" method="post">'
  puts '<TABLE border="0">'
  puts '<tr><td valign="top"><label>License:</label>'
  puts '<td><SELECT name="license">'
  puts '<OPTION value="gpl+ccbysa">Default: GNU GPL V2.0 + CC-BY-SA-V2</OPTION>'
  puts '<OPTION value="gpl">GNU GPL V2.0 or later</OPTION>'
  puts '<OPTION value="ccbysa" label="CC-BY-SA-V2">Creative Commons Attributions Sharealike V2.0</OPTION>'
  puts '                    <OPTION label="publicdomain">Public Domain</OPTION>'
  puts '</SELECT><br>'

  form_field_hidden("md5", entry.md5)
  form_field_text("Name:",     "name",     entry.name)
  form_field_text("Author:",   "author",   entry.author)
  form_field_text("Filename:", "filename", entry.filename)
  form_field_text("Filetype", "filetype",  entry.filetype)
  form_field_textarea("Description:", "description", entry.description)

  form_field_text("Keywords:",   "keywords",   entry.keywords.join(", "))
  
  puts "<tr>"
  puts "  <td valign=\"top\">Categories:</td>"
  puts "<td>"

  count = 0
  puts "<table><tr>"
  $categories.each { |i|
    puts "<td>"
    puts "<INPUT name=\"category\"  type=\"checkbox\" value=\"#{i}\" tabindex=\"20\">#{i}</INPUT>"
    puts "</td>"
    count += 1
    if count >= 8 then
      puts "</tr><tr>"
      count = 0
    end
  }
  puts '</td></tr></table></td>'

  form_field_file("Update Content:", "content") 
 
  puts '</table>'
  puts '  <INPUT type="submit" value="Update this Entry"><td align="right">'
  puts '  </FORM>'
  puts "<hr>"

end

def overview_page(count, offset)
  #.sort() {|a,b| 
  #    -1*(a.file_type <=> b.file_type)

  if offset != 0 then
    count_line = "<a href=\"?count=#{count}&offset=#{offset-count}\">&lt;&lt;</a> "
  else
    count_line = "&lt;&lt; "
  end

  (($repository.num_entries / count)+1).times { |i|
    start_value = i*count
    end_value   = i*count+count-1

    if (end_value > $repository.num_entries)
      end_value = $repository.num_entries
    end
    
    if start_value == offset then
      count_line += "[#{i}] "
    else
      count_line += "[<a href=\"?count=#{count}&offset=#{start_value}\">#{i}</a>] "
    end
  }

  if count + offset + 1 < $repository.num_entries then
    count_line += " <a href=\"?count=#{count}&offset=#{offset+count}\">&gt;&gt;</a>"
  else
    count_line += " &gt;&gt; "
  end

  puts "<center>#{count_line}</center>"
  
  puts "<table align=\"center\"><tr>"
  column = 0
  $repository.slice(offset, count).each { |entry|
    if entry then
      puts "<td valign=\"middle\" align=\"center\"  width=\"128\" height=\"128\">"
      entry.render_html()
      puts "</td>"
      
      column += 1
      if column >= 6 then
        column = 0
        puts "</tr><tr>"
      end      
    else
      puts "Error: Invalid entry: #{md5}<br>"
    end
  }
  puts "</tr></table>"

  puts "<center>#{count_line}</center>"
end

$cgi = CGI.new()

$repository = Repository.new("testrepo")

print $cgi.header("text/html")
print File.new("header.html").read()

begin
  if $cgi.has_key?("md5") then
    entry_page($cgi["md5"], $cgi.has_key?("edit"))
  elsif $cgi.has_key?("submit") then
    submit_page()
  elsif $cgi.has_key?("search") then
    if $cgi.has_key?("per_page") then
      per_page = $cgi["per_page"].to_i
    else
      per_page = 30
    end

    if $cgi.has_key?("page_num") then
      page_num = $cgi["page_num"].to_i
    else
      page_num = 0
    end
    search_results_page($cgi["search"].to_s, per_page, page_num)
  elsif $cgi.has_key?("offset") and $cgi.has_key?("count") then
    overview_page($cgi["count"].to_i, $cgi["offset"].to_i)
  else
    print File.new("start.html").read()
  end
  
rescue
  puts "<p align=\"left\">Something went wrong: #{$!}<br>"
  puts $!.backtrace.join("<br>")
  puts "</p>"
end

print File.new("footer.html").read
puts "<!-- EOF -->"

# EOF #
