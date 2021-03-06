class RuneBlog::Default

# This will all become much more generic later.

BlogTemplate = <<-TEXT
.mixin liveblog

.title Fake Blog, Fake Title, Fake Author

<table>
  <tr>
    <td>
.image fakeimage.jpg
    </td>
    <td valign=top>
.h3 Yet another blog... 
.h4 by Kilgore Trout
.br 2
      If you're the kind of person who likes this sort of thing,
      then this is the sort of thing a person like you will like.
.br 2
      Don't you feel more like you do now than before you read this?
    </td>
  </tr>
</table>
.hr
TEASERS
TEXT

def RuneBlog.post_template(title: "No title", date: nil, view: "test_view", 
                       teaser: "No teaser", body: "No body", tags: ["untagged"], 
                       views: [], back: "javascript:history.go(-1)", home: "no url")
  viewlist = (views + [view.to_s]).join(" ")
  taglist = ".tags " + tags.join(" ")
<<-TEXT
.mixin liveblog
 
.title #{title}
.pubdate #{date}
.views #{viewlist}
#{taglist}
 
.teaser
#{teaser}
.end
#{body}
<hr>
<a href='#{back}' style='text-decoration: none'>Back</a>
<br>
<a href='#{home}' style='text-decoration: none'>Home</a>
TEXT

end

def RuneBlog.teaser_template(title: "No title", date:, view: "test_view", 
                         teaser: "No teaser", body: "No body", slug:)
<<-TEXT
<html>

<body>

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
     js.src = '//connect.facebook.net/en_US/sdk.js';
     fjs.parentNode.insertBefore(js, fjs);
   }(document, 'script', 'facebook-jssdk'));
</script>
    <!-- meta property='fb:admins' content='767352779' /> -->
    <meta property='og:url' content='http://rubyhacker.com/blog2/#{slug}.html'/>
    <meta property='og:type' content='article'/>
    <meta property='og:title' content='#{title}'/>
    <meta property='og:image' content='http://rubyhacker.com/blog2/blog3b.gif'/>
    <meta property='og:description' content='#{teaser}'/>

    <table bgcolor=#eeeeee cellspacing=5>
      <tr>
        <td valign=top>
          <br> <font size=+2 color=red>#{title}</font> <br> #{date}
        </td>
        <td width=2% bgcolor=red></td>
        <td valign=top>
          <a href='https://twitter.com/share' 
          class='twitter-share-button' 
          data-text='#{title}' 
          data-url='#{'url'}' 
          data-via='hal_fulton' 
          data-related='hal_fulton'>Tweet</a>
             <script>!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0],p=/^http:/.test(d.location)?'http':'https';if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src=p+'://platform.twitter.com/widgets.js';fjs.parentNode.insertBefore(js,fjs);}}(document, 'script', 'twitter-wjs');</script>
          <br>
          <a href='https://twitter.com/hal_fulton' class='twitter-follow-button' data-show-count='false'>Follow @hal_fulton</a>
          <script>!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0],p=/^http:/.test(d.location)?'http':'https';if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src=p+'://platform.twitter.com/widgets.js';fjs.parentNode.insertBefore(js,fjs);}}(document, 'script', 'twitter-wjs');</script>

          <br>
            <div
              class='fb-like'
              data-share='true'
              data-width='450'
              data-show-faces='true'>
            </div>
          </td>
       </tr>
     </table>
<hr>

#{body}

<hr>
<a href="http://rubyhacker.com/blog2" style="text-decoration: none">Back</a> 
<a href="http://rubyhacker.com" style="text-decoration: none">Home</a>
TEXT
end

end
