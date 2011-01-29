
/**
 * Google Blogger API
 * http://code.google.com/apis/blogger/docs/1.0/developers_guide_js.html
 */

google.load("feeds", "1");

function results_callback(results) {
  if (!results.error) {
  	for (var i = 0, entry; entry = results.feed.entries[i]; i++) {
  	    var d = new Date( entry.publishedDate );
  	    var n = '<li><a href=":href">:title</a> <span class="date">:date</span></li>'
		.replace( /:href/, entry.link )
		.replace( /:title/, entry.title )
		.replace( /:date/, prettyDate( d ) );

  	    $('#blog_entries').append( n );
  	}
  }
}
function initialize() {
    var feed = new google.feeds.Feed("http://blog.mikedll.com/feeds/posts/default");

    feed.setNumEntries( 4 );
    feed.load( results_callback );
}

$(initialize);

function setupGallery() {

    var transition = function( out, into ) {
	out.fadeOut( 200, function() { into.fadeIn( 700 ); } );
    };

    var homeToProjects = function() {
	transition( $('#main'), $('.pg_content').add('#thumbContainter') );
    };

    var projectsToHome = function() {
	transition( $('.pg_content').add('#thumbContainter'), $('#main') );
    };

    $('#projects_link').bind('click', homeToProjects );
    $('#home_link').bind('click', projectsToHome );    
}
$(setupGallery);
