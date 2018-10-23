require 'helpers-blog'
require 'runeblog'

class RuneBlog::Post

  attr_reader :id, :title, :date, :views, :num, :slug

  include RuneBlog::Helpers

  def self.files(num, root)
    files = Find.find(root).to_a
    result = files.grep(/#{tag(num)}-/)
    result
  end
  
  def self.load(post)
    # FIXME weird logic here
    raise "RuneBlog.blog is not set!" if RuneBlog.blog.nil?
    pdir = RuneBlog.blog.view.dir + "/" + post
    meta = nil
    Dir.chdir(pdir) do
      meta = read_config("metadata.txt")
      meta.date = Date.parse(meta.date)
      meta.views = meta.views.split
      meta.tags = meta.tags.split
      meta.teaser = File.read("teaser.txt")
      meta.body = File.read("body.txt")
    end
    meta
  end

  def initialize(meta, view_name)
    # FIXME weird logic here
    raise "RuneBlog.blog is not set!" if RuneBlog.blog.nil?
    @blog = RuneBlog.blog
    @title = meta.title
    @view = @blog.str2view(view_name)
    @num, @slug = make_slug
    @date = Time.now.strftime("%Y-%m-%d")
    template = RuneBlog::Default::PostTemplate
    @meta = meta
    html = interpolate(template)
    @draft = "#{@blog.root}/src/#@slug.lt3"
    dump(html, @draft)
  end

  def edit
    result = system("vi #@draft +8")
    raise "Problem editing #@draft" unless result
    nil
  rescue => err
    error(err)
  end 

  def publish
    livetext = Livetext.new(STDOUT)
    @meta = livetext.process_file(@draft, binding)
    raise "process_file returned nil" if @meta.nil?

    @meta.views.each do |view_name|   # Create dir using slug (index.html, metadata?)
      view = @blog.str2view(view_name)
      vdir = view.dir
      dir = vdir + @slug + "/"
      Dir.mkdir(dir)
      Dir.chdir(dir) do
        create_post_subtree(vdir)
        @blog.generate_index(view)
      end
    end
  rescue => err
    p err
    puts err.backtrace
  end

  private

  def create_post_subtree(vdir)
    create_dir("assets") 
#   dump(@meta.to_yaml, "metadata.yaml")
    write_metadata(@meta)
    template = RuneBlog::Default::TeaserTemplate   # FIXME template into custom dir?
    text = interpolate(template)
    dump(text, "index.html")   # FIXME write_index ?
  end

  def make_slug(postnum = nil)
    postnum ||= @blog.next_sequence
    num = tag(postnum)   # FIXME can do better
    slug = @title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
    [postnum, "#{num}-#{slug}"]
  end

  def tag(num)
    "#{'%04d' % num}"
  end

def write_metadata(meta)
  fname2 = "metadata.txt"
  hash = meta.to_h
  
  File.write("teaser.txt", hash[:teaser])
  File.write("body.txt", hash[:body])
  hash.delete(:teaser)
  hash.delete(:body)
  
  hash[:views] = hash[:views].join(" ")
  hash[:tags]  = hash[:tags].join(" ")
  
  fields = [:title, :date, :pubdate, :views, :tags]
  
  f2 = File.new(fname2, "w")
  fields.each do |fld|
    f2.puts "#{fld}: #{hash[fld]}"
  end
  f2.close
end

end