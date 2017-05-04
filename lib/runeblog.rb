
class RuneBlog
  VERSION = "0.0.8"

  Path  = File.expand_path(File.join(File.dirname(__FILE__)))
end

# FIXME lots of structure changes

require 'yaml'

=begin

Post
----
Create a blog post
Process it
Link it
Upload to server


data
  views
    computing
      compiled
      custom
      deployment

=end

require 'rubygems'
require 'ostruct'
# require 'livetext'


### ask

def ask(prompt, meth = :to_s)
  print prompt
  STDOUT.flush
  STDIN.gets.chomp.send(meth)
end

### new_blog!

def new_blog!
  unless File.exist?(".blog")
    yn = ask("No .blog found. Create new blog?")
    if yn.upcase == "Y"
      system("mkdir data")
      File.open(".blog", "w") {|f| f.puts data }
      File.open("data/sequence", "w") {|f| f.puts 0 }
    end
  end
end

### next_sequence

def next_sequence
  @config.sequence += 1
  File.open("data/sequence", "w") {|f| f.puts @config.sequence }
  @config.sequence
end

### make_slug

def make_slug(title, seq=nil)
  num = '%04d' % (seq || next_sequence)   # FIXME can do better
  slug = title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
  "#{num}-#{slug}"
end

### read_config

def read_config
  @config = OpenStruct.new
  # What views are there? Deployment, etc.
  # Crude - FIXME later
  root = File.readlines(".blog").first.chomp rescue "myblog"
  dirs = Dir.entries("#{root}/views/") - %w[. ..]
  dirs.reject! {|x| ! File.directory?("#{root}/views/#{x}") }
  @config.root = root
  @config.views = dirs
  @config.sequence = File.read(root + "/sequence").to_i
rescue => err
  if root != "myblog"
    raise err
  end

  new_blog!
  STDERR.puts "Created. Now run again."
  exit
end

### create_empty_post

def create_empty_post
  @template = <<-EOS
.mixin liveblog

.liveblog_version 

.title #{@title}
.pubdate #{@date}
.categories elixir ruby
.views computing

Teaser goes here.
.readmore
Remainder of post goes here.
EOS

  @slug = make_slug(@title)
  @fname = @slug + ".lt3"
  File.open("#{@config.root}/src/#{@fname}", "w") {|f| f.puts @template }
  @fname
end

### edit_post

def edit_post(file)
  system("vi #{@config.root}/src/#{file}")
end

### process_post

def process_post(file)
  lt ||= Livetext.new
  puts "  Processing: #{file}"
  lt.process_file(file)
  @meta = lt.main.instance_eval { @meta }
  @meta.slug = file.sub(/.lt3$/, "")
  @meta
end

### reload_post

def reload_post(file)
  @main ||= Livetext.new
  @meta = process_post("#{@config.root}/src/#{file}")
  @meta.slug = file.sub(/.lt3$/, "")
  @meta
end

### posting

def posting(meta)
  <<-HTML
    <br>
    <font size=+1>#{meta.pubdate}&nbsp;&nbsp;</font>
    <font size=+2 color=blue><a href=../#{"FAKEREF"} style="text-decoration: none">#{meta.title}</font></a>
    <br>
    #{meta.teaser}  
    <a href=../#{"FAKEREF2"} style="text-decoration: none">Read more...</a>
    <br><br>
    <hr>
  HTML
end

### generate_index

def generate_index(view)
  # Gather all posts, create list
  vdir = "#{@config.root}/views/#{view}"
  posts = Dir.entries(vdir).grep /^\d\d\d\d/
  posts = posts.sort.reverse
  # Add view header/trailer
  @bloghead = File.read("#{vdir}/custom/blogheader.html") rescue ""
  @blogtail = File.read("#{vdir}/custom/blogtrailer.html") rescue ""
  # Output view
  posts.map! do |post|
    YAML.load(File.read("#{vdir}/#{post}/metadata.yaml"))
  end
  out = @bloghead.dup
  posts.each do |post|
    out << posting(post)
  end
  out << @blogtail
  File.open("#{vdir}/index.html", "w") do |f|
    f.puts out
  end
end

### link_post_view

def link_post_view(view)
  # Create dir using slug (index.html, metadata?)
  vdir = "#{@config.root}/views/#{view}"
  dir = "#{vdir}/#{@meta.slug}"
  cmd = "mkdir -p #{dir}"
  puts "    Running: #{cmd}"
  system(cmd)
  File.write("#{dir}/metadata.yaml", @meta.to_yaml)
  # Add header/trailer to post index
  @posthead ||= File.read("#{vdir}/postheader.html") rescue ""
  @posttail ||= File.read("#{vdir}/posttrailer.html") rescue ""
  File.open("#{dir}/index.html", "w") do |f|
    f.puts @posthead
    f.puts @meta.body
    f.puts @posttail
  end
  generate_index(view)
end

### link_post

def link_post(meta)
  # First gather the views
  views = meta.views
  views.each {|view| puts "Handling view '#{view}'"; link_post_view(view) }
end

### rebuild

def rebuild
  files = Dir.entries("#{@config.root}/src/").grep /\d\d\d\d.*.lt3$/
  files = files.sort.reverse
  files.each do |file|
    reload_post(file)
    link_post(@meta)
    publish_post
  end
end

### relink

def relink
  @config.views.each do |view|
    generate_index(view)
  end
end

### publish?

def publish?
  yn = ask("Publish? y/n ")
  yn.upcase == "Y"
end

### publish_post

def publish_post
  # Grab destination data
  # scp changed files over
  puts "    Publish: Not implemented yet"
end

### list_views

def list_views
  read_config unless @config
  puts @config.views
end

### change_view

def change_view(arg = nil)
  raise "view #{arg} does not exist" unless @config.views.include?(arg)
  @view = arg
end

### new_view

def new_view(arg = nil)
  arg = nil if arg == ""
  read_config unless @config
  arg ||= ask("New view: ")  # check validity later
  raise "view #{arg} already exists" if @config.views.include?(arg)
  dir = @config.root + "/views/" + arg
  cmd = "mkdir -p #{dir}/custom"
  system(cmd)
  File.write("#{dir}/custom/blog_header.html",  RuneBlog::BlogHeader)
  File.write("#{dir}/custom/blog_trailer.html", RuneBlog::BlogTrailer)
  File.write("#{dir}/custom/post_header.html",  RuneBlog::PostHeader)
  File.write("#{dir}/custom/post_trailer.html", RuneBlog::PostTrailer)
  @config.views << arg
end

### import

def import(arg = nil)
  read_config unless @config
  arg = nil if arg == ""
  arg ||= ask("Filename: ")  # check validity later
  name = arg
  grep = `grep ^.title #{name}`
  @title = grep.sub(/^.title /, "")
  @slug = make_slug(@title)
  @fname = @slug + ".lt3"
  system("cp #{name} #{@config.root}/src/#@fname")
  edit_post(@fname)
  process_post(@fname)
  if publish?
    link_post(@meta)
    publish_post
  end
end

### new_post

def new_post
  read_config unless @config
  @title = ask("Title: ")
  @today = Time.now.strftime("%Y%m%d")
  @date = Time.now.strftime("%Y-%m-%d")

  file = create_empty_post
  edit_post(file)
  process_post(file)
  if publish?
    link_post(@meta)
    publish_post
  end
end

### list_posts

def list_posts
  system("ls -l #{@config.root}/views/#@view/")
end


### templates

class RuneBlog

  # Default BlogHeader: TITLE, IMAGE

  BlogHeader = <<-EOF
<html>
<body background=speckle-texture-vector.jpg>

<title>TITLE</title>

<table>
  <tr>
    <td>
        <img src=IMAGE.jpg width=400 height=300>
    </td>
    <td>
      <h3>Yet another blog by Hal Fulton</h3>
      <br>
      <br>
      <b>Note</b>: I can never find a blogging engine I like! <br>
      For now, this will just be a set of static pages.
      <br>
      <br>
      If you want to comment, just <a href=mailto:rubyhacker@gmail.com>email me</a>.
    </td>
  </tr>
</table>

<hr>
  EOF

  # Default BlogTrailer

  BlogTrailer = <<-EOF
  EOF

  # Default PostHeader

  PostHeader = <<-EOF
<html>

<script>
  window.fbAsyncInit = function() {
    FB.init({
      appId      : '1176481582378716',
      xfbml      : true,
      version    : 'v2.4'
    });
  };

  (function(d, s, id){
     var js, fjs = d.getElementsByTagName(s)[0];
     if (d.getElementById(id)) {return;}
     js = d.createElement(s); js.id = id;
     js.src = "//connect.facebook.net/en_US/sdk.js";
     fjs.parentNode.insertBefore(js, fjs);
   }(document, 'script', 'facebook-jssdk'));
</script>

<body>
<div
  class="fb-like"
  data-share="true"
  data-width="450"
  data-show-faces="true">
</div>

<hr>
  EOF

  # Default PostTrailer: BACK, HOME

  PostTrailer = <<-EOF
<hr>
<a href="http://rubyhacker.com/BACK" style="text-decoration: none">Back</a>
<a href="http://rubyhacker.com/HOME" style="text-decoration: none">Home</a>
  EOF
end

