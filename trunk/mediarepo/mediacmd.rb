#!/usr/bin/ruby -w

require "digest/md5"
require "fileutils"
require "set"
require "mediarepo"
require "stringio"
require "commandline"

include MediaRepo

$cc_license_html = <<EOF
<!-- Creative Commons License -->
<a rel="license" href="http://creativecommons.org/licenses/by-sa/2.0/"><img alt="Creative Commons License" border="0" src="http://creativecommons.org/images/public/somerights20.gif" /></a><br />
This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/2.0/">Creative Commons License</a>.
<!-- /Creative Commons License -->
EOF

class Renderer
  # FIXME: all the thumbnailers aren't save to use on filenames with
  # spaces and such
  def initialize()
    
  end

  def render(file, type)
    ### Read file and apply thumbnailer for type, return either a list
    ### of renders of the images, [] if the image is itself a render
    ### or nil on error (type not known and such)
    case type
    when "blend"
      return render_blend(file)
    when "xcf"
      return render_xcf(file)
    when "png", "jpg", "bmp", "tga", "jpeg"
      return render_image(file)
    when "wings"
      return render_wings(file)
    when "svg"
      return render_svg(file)
    else
      return nil
    end
  end

  def render_self(file)
    # Used for images that don't need to render
    return []
  end

  def render_image(file)
    output = IO.popen("convert -scale '512x512' '#{file}' 'jpg:/dev/stdout'").read()
    return [output]
  end

  def render_wings(file)
    puts "Rendering Wings3d: %s" % [file]
    FileUtils.cp(file, "/tmp/tmp.wings")
    system("blender", "-P", "wings2blender.py")
    File.unlink("/tmp/tmp.wings")
    return render_blend("/tmp/tmp.blend")
    # return []
  end

  def render_svg(file)
    tmpfile  = "/tmp/svgout.png"
    tmpfile2 = "/tmp/svgout.svg"
    if File.exists?(tmpfile) then File.unlink(tmpfile) end
    FileUtils.cp(file, tmpfile2)

    system("inkscape", "-w", "512", "-f", tmpfile2, "-e", "/tmp/svgout.png")
    output = IO.popen("convert -scale '512x512' '#{tmpfile}' 'jpg:/dev/stdout'").read()
    return [output]
  end

  def render_xcf(xcf)
    out = "/tmp/out.jpg"
    system("/usr/bin/xcftopnm '#{xcf}' | ppmtojpeg > '#{out}'")
    return render_image(out)
  end

  def render_blend(blend)
    thumb = "/tmp/out/0001"
    FileUtils.mkdir("/tmp/out") if not File.exists?("/tmp/out")
    system("blender", "-b", blend, "-P", "blender_thumb.py")
    system("blender", "-b", "/tmp/out/tmp.blend", "-a")
    if File.exists?(thumb + ".png") then
      return [IO.popen("convert -scale '512x512' 'png:#{thumb}.png' 'jpg:/dev/stdout'").read()]
    else
      return [IO.popen("convert -scale '512x512' 'png:#{thumb}' 'jpg:/dev/stdout'").read()]
    end
  end
end

def print_help()
  puts "Usage: mediarepo COMMAND [ARGS]"
  puts ""
  puts "Commands:"
  puts "========="
  puts "  add <filename>"
  puts "    add the file given by <filename> to the repository"
  puts ""
  puts "  get <id>"
  puts "    retrieve an entry from the database and output it to stdout"
  puts ""
  puts "  propset <id> <name> <value>"
  puts "    set the property <name> to <value> for item <id>"
  puts ""
  puts "  show <id>:"
  puts "    display item with id"
  puts ""
  puts "  clean:"
  puts "    removes dangling references from the db"
  puts ""
  puts "  check:"
  puts "    check the repository for inconsistencies and dangling links"
  puts ""
end

$categories = \
["animation", "sketch", "texture", "sprite", "material", "template", "reference",
 "vehicle", "tank", "helicopter", "plane", "car", "truck", "spaceship", "ship", "boat",
 "human", "animal", "male", "female", "robot", "humanoid",
 "horse", "dog", "bird", "cat", "cow", "bunny", "fish", "whale",
 "plant", "tree",
 "building", "house", "bridge", "window", "utility",
 "weapon", "pistol", "rifle",
 "scenery", "object", "detail", 
 "photography", "pencil", "rendered", "painted", 
 "abstract", "metallic", "water", "rust", "wood", "glass", "realistic", 
 "highpoly", "lowpoly" ]

def gen_renders_cmd(*args)
  puts "Generating renders..."
  renderer = Renderer.new()
  if args.empty? then 
    $repository
  else
    args
  end.each { |md5|
    entry = $repository.get(md5)
    if (not entry) then
      puts "Error: no entry for #{md5}"
    else 
      res = renderer.render(entry.path + "/data.dat", entry.filetype)
      if (res) then
        res.each {|data|
          f = File.new(entry.path + "/renders/" + Digest::MD5.hexdigest(data) + ".jpg", "w")
          f.write(data)
          f.close()
        }
      else
        puts "Error: Couldn't render #{md5}"
      end
    end
  }
end

def gen_thumbnail_cmd(*args)
  puts "Generating thumbnails..."
  
  # Generate thumbnails for the given id's
  if args.empty? then 
    $repository
  else
    args
  end.each { |md5|
    entry = $repository.get(md5)
    
    if (not entry) then
      puts "Error: #{md5} not in database"
    else
      #puts "Md5: #{md5} => #{entry.md5}"
      
      if (entry.renders.empty?) then
        puts "Generating render for: %s\n" % [entry.md5]
        gen_renders_cmd(entry.md5)
      end
      
      entry.renders.each { |render|
        if File.exist?(entry.path + "/thumbnails/" + render + ".jpg") then
          # puts "Have thumbnail for: #{render}"
        else
          command = "convert -sample '128x128' '%s/renders/%s' 'jpg:/dev/stdout'" % [entry.path, render]
          output = IO.popen(command).read()
          
          f = File.new(entry.path + "/thumbnails/" + render + ".jpg", "w")
          f.write(output)
          f.close()
        end
      }     
    end
  }
end

def add_cmd(*args)
  parser = CommandLine::Parser.new()
  parser.add_option(nil, "--cut-path",    "PATH", "Remove the given regex from the pathname entry")
  parser.add_option(nil, "--author",      "AUTHOR", "Set author to AUTHOR")
  parser.add_option(nil, "--name",        "NAME",   "Set name to NAME")
  parser.add_option(nil, "--license",     "LICENSE",   "Set license to LICENSE")
  parser.add_option(nil, "--keywords",    "KEYWORDS",   "Set keywords to KEYWORDS")
  parser.add_option(nil, "--description", "DESC",   "Set description to DESC")
  parser.add_option(nil, "--description-from-file", "FILE",   "Set description to the content of FILE")
  parser.add_option(nil, "--relateds", "MD5",   "Add a related entries to this file")
  parser.add_option(nil, "--group", nil, "Groups all entries")
  parser.add_option("-h", "--help", nil,   "Print this help")
  options, rest = parser.parse_args(args)

  author      = nil
  license     = nil
  description = nil
  name        = nil
  keywords    = nil
  cut_path    = nil
  relateds    = nil
  group       = false

  options.each { |option, argument|
    case option 
    when "--cut-path"
      cut_path = Regexp.new(argument)
    when "--author"
      author = argument
    when "--group"
      group = true
    when "--license"
      license = argument
    when "--keywords"
      keywords = argument.read.gsub(",", " ").split(" ")
    when "--name"
      name = argument
    when "--description"
      description = argument
    when "--description-from-file"
      description = File.new(argument, "r").read()
    when "--relateds"
      relateds = argument.split
    else
      puts "Usage: mediacmd add [OPTIONS] [FILES]"
      puts ""
      parser.print_help()
      puts ""
      return nil
    end
  }

  recursive = true
  rest.each { |filename|
    print "Adding '%s'... " % [filename]
    if File.directory?(filename) then
      if recursive then
        Dir.new(filename).each { |i|
          if (i != "." && i != ".." && i != ".thumbnails" && i != ".xvpics") then
            # FIXME: Recursion is evil without a filetype
            if (File.extname(i) == ".blend") or (File.directory?(filename + "/" + i)) then
              add_cmd(filename + "/" + i)
            else
              puts "Ignoring: #{i}"
            end
          end
        }
      else
        puts "error, '%s' is a directory" % filename
      end
    else
      entry = $repository.create_entry_from_file(filename, true)
      if cut_path then
        entry.pathname    = filename.sub(cut_path, "")
      else
        entry.pathname    = filename
      end
      entry.author      = author if author
      entry.name        = name if name
      entry.license     = license if license
      entry.description = description if description
      entry.relateds    += relateds if relateds

      if group then
        entry.relateds += rest.map { |i| filename2md5(i) }
      end
      
      entry.save()

      print "done => %s\n" % [entry.md5]
    end
  }
end

def get_cmd(*args)
  args.each { |md5|
    entry = $repository.get(md5)
    if not entry then
      puts "Entry '%s' not in the repository" % [md5]
    else
      print entry.data()
    end
  }
end

def list_cmd(*args)
  $repository.each { |i| show_cmd(i) }
end

def check_cmd(*rest)
  errors = 0
  $repository.each { |i|
    entry = $repository.get(i)
    if not entry.check() then
      print "Error: entry '%s' doesn't validate" % i
      errors += 1
    end

    # Checks to add:
    # ==============
    # - check for 'relateds' to itself
    # - check for duplicate thumbnails
    # - check for empty thumbnails
    # - check for non-backlinking relateds
    # - check for non-backlinking versions
    # - check for non-hidden renders
  }
  puts "Validation done, %s errors" % errors
end

def search_cmd(searchexpr)
  results = $repository.search(searchexpr)
  results.each { |i|
    puts i
  }
end

def search2_cmd(prop, *regexs)
  regexs.each { |regex|
    re = Regexp.new(regex)
    
    # Potentially quite slow...
    Dir.new($repository_path).each { |i|
      if (i != "." && i != "..")
        entry = $repository.get(i)
        match = case prop
                when "type"
                  re.match(entry.filetype)
                when "name"
                  re.match(entry.name)
                when "filename"
                  re.match(entry.filename)
                else
                  raise "Couldn't detect prop type"
                end
        
        if match then
          puts entry.md5
        end
      end
    }

  }
end

def has_cmd(*rest)
  rest = rest.map { |i|
    if File.exist?(i) then   
      Digest::MD5.hexdigest(File.new(i).read())
    else
      i
    end
  }

  rest.each { |i| 
    e = $repository.get(i)
    if e then
      puts "#{i} ok"
    else
      puts "#{i} missing"
    end
  }
end

def add_directory_cmd(name, *rest)
  rest = rest.map { |i|
    if File.exist?(i) then   
      Digest::MD5.hexdigest(File.new(i).read())
    else
      i
    end
  }
  
  rest = rest.delete_if { |i| not $repository.has(i) }

  entry = $repository.create_entry_from_data(rest.join("\n"), true)
  entry.filetype = "directory"
  entry.name     = name
  entry.filename = name
  entry.save()
  puts "Added directory: #{entry.md5}"
end

def clean_cmd(*args)
  $repository.each { |md5|
    entry = $repository.get(md5)

    thumb = entry.thumbnails
    thumb.delete_if { |md5| not $repository.has(md5) }
    entry.thumbnails = thumb

    renders = entry.renders
    renders.delete_if { |md5|  not $repository.has(md5) }
    entry.renders = renders
  }
end

def gen_index_cmd(*args)
  if args.empty? then
    md5s = $repository.md5sums()
  else
    md5s = []
    args.map! { |i|
    if File.exist?(i) then   
      md5s.push(Digest::MD5.hexdigest(File.new(i).read()))
    elsif is_md5(i)
      md5s.push(i)
    else
      $stderr.puts "Error: Couldn't resolve '#{i}'"
    end
    }
  end

  md5s.each { |md5|
    entry = $repository.get(md5)
    
    if entry then
      f = StringIO.new
      entry.save(f)
#    f.puts(entry.author)
#    f.puts(entry.filename)
#    f.puts(entry.license)
#    f.puts(entry.keywords)
#    f.puts(entry.categories)
#    f.puts(entry.description)
      str = f.string
      
      if str then
        puts("Path-Name: #{md5}")
        puts("Content-Length: #{str.length}")
        # puts("Last-Mtime: #{entry.mtime}")
        puts("Document-Type: XML")
        puts("")
        puts(str)
      end
    end
  }  
end

def show_cmd(*args)
  args.each { |md5|
    begin
      entry = $repository.get(md5)
      if (entry) then
        print "Identifer:     %s\n" % [md5]
        print "Realpath:      %s\n" % (entry.path + "/" + "data.dat")
        print "Name:          %s\n" % [entry.name]
        print "Filename:      %s\n" % [entry.filename]
        print "Creation Date: %s\n" % [entry.ctime]
        print "Type:          %s\n" % [entry.filetype]
        print "Size:          %s bytes\n" % [entry.filesize]
        print "Keywords:      %s\n" % [entry.keywords.join(", ")]
        print "Renders:       %s\n" % [entry.renders.join("\n               ")]
        print "Relateds:      %s\n" % [entry.relateds.join("\n               ")]
        print "Thumbnails:    %s\n" % [entry.thumbnails.join("\n               ")]
        print "\n"
      else
        puts "Entry '%s' not in the repository" % [md5]
      end
    rescue Errno::ENOENT
      puts "Entry '%s' not in the repository" % [md5]
    end
  }
end

# main function
$repository_path = "testrepo"
$repository = Repository.new($repository_path)

if ARGV.length == 0 then
  puts "Usage: mediarepo COMMAND [ARGS]"
  exit()
else
  rest = ARGV.slice(1, ARGV.length())
  case ARGV[0]
  when "adddir"
    add_directory_cmd(*rest)
  when "add"
    add_cmd(*rest)
  when "get"
    get_cmd(*rest)
  when "has"
    has_cmd(*rest)
  when "check"
    check_cmd(*rest)
  when "list"
    list_cmd(*rest)
  when "show"
    show_cmd(*rest)
#  when "propshow"
#    propshow_cmd(*rest)
#  when "propset"
#    propset_cmd(*rest)
  when "genthumb"
    gen_thumbnail_cmd(*rest)
  when "genrenders"
    gen_renders_cmd(*rest)
  when "search"
    search_cmd(*rest)
  when "search2"
    search2_cmd(*rest)
  when "makerelated"
    make_related_cmd(*rest)
  when "clean"
    clean_cmd(*rest)
  when "genindex"
    gen_index_cmd(*rest)
  when "help"
    print_help()
    exit()
  else
    puts "Error: Unknown command '%s'" % [ARGV[0]]
  end
end

# EOF #
