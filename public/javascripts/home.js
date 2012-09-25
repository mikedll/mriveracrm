
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

var STATES = {
    MAIN: 0,
    PROJECTS: 1
};

var GLOBAL_STATE = STATES.MAIN;

function setupGallery() {

    var transition = function( out, into, new_state ) {
	      out.fadeOut( 200, function() { 
                         into.fadeIn( 700 ); 
                         GLOBAL_STATE = new_state;
                     } );
    };

    var homeToProjects = function() {
	      transition( $('#main'), $('.pg_content').add('#thumbContainter'), STATES.PROJECTS );
    };

    var projectsToHome = function() {
        $('#overlay').fadeOut(200);
	      transition( $('.pg_content').add('#thumbContainter'), $('#main'), STATES.MAIN );
    };

    $('#projects_link').bind('click', homeToProjects );

    $('#thumbContainter').add('.pg_content')
        .bind('click', function(e) {
                         e.stopPropagation();
                     });


    $(document).bind('click', function() {
                         if(GLOBAL_STATE == STATES.PROJECTS)  {
                             projectsToHome();
                         }
                     });

}
$(setupGallery);
