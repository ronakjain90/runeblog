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
    err.backtrace.each {|x| puts x }
    # error(err)
  end

  private

  def create_post_subtree(vdir)
    create_dir("assets") 
    dump(@meta.to_yaml, "metadata.yaml")
    dump(@meta.teaser, "teaser.txt")
    dump(@meta.remainder, "remainder.txt")
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
end
