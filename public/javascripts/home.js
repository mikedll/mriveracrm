
/**
 * Google Blogger API
 * http://code.google.com/apis/blogger/docs/1.0/developers_guide_js.html
 */

google.load("feeds", "1");

function results_callback(results) {
    if (!results.error) {
	for (var i = 0, entry; entry = results.feed.entries[i]; i++) {
	    var d = new Date( entry.publishedDate );
	    var n = Builder.node( 'li',
				  [ Builder.node( 'a', { href: entry.link }, entry.title ),
				    " ",
				    Builder.node( 'span', { className: 'date' }, prettyDate( d ) )
				    ]
				  );
	    $('blog_entries').appendChild( n );
	}
    }
}

function initialize() {
    var feed = new google.feeds.Feed("http://blog.mikedll.com/feeds/posts/default");

    feed.setNumEntries( 4 );
    feed.load( results_callback );
}

google.setOnLoadCallback(initialize);
 
function m_vanish( strHide ) {
  new Effect.Fade( strHide, { from: 1, to: 0, duration: 0, queue: 'front' } );
}

function m_show(strShow) {
  new Effect.Appear( strShow, { from: 0, to: 1, duration: .5, queue: 'end' } );
}

