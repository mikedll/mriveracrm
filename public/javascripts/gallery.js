
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
    PROJECTS: 1,
    GALLERY: 2
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

    $(document)
        .bind('click', function() {
                         if(GLOBAL_STATE == STATES.PROJECTS)  {
                             projectsToHome();
                         }
              })
        .bind('keyup', function(e) {
                  //
                  // This is ugly because it depends on a lot of selectors that are repeated in the below
                  // gallery setup. Such is what happens when you merge disparate pieces of code.
                  //
                  if (GLOBAL_STATE == STATES.MAIN) {
                      $('body').data('hotkeys').handleKeyUp(e);
                  }
                  else if (GLOBAL_STATE == STATES.PROJECTS) {
                      if(e.keyCode === 38 || e.keyCode === 40) {
                          e.stopPropagation();
                          var allThumbnails = $('#thumbScroller .content');
                          var nextIndex = -1;
                          console.log( $('.pg_content').data('current-project') );
                          if( e.keyCode === 38 && $('.pg_content').data('current-project') > 0) {
                              nextIndex = $('.pg_content').data('current-project') - 1;
                          }
                          else if (e.keyCode === 40 && $('.pg_content').data('current-project')  < allThumbnails.length - 1) {
                              nextIndex = $('.pg_content').data('current-project') + 1;
                          }

                          if(nextIndex !== -1 ) {
                              allThumbnails.eq( nextIndex ).trigger('click');
                          }
                      }
                      else if(e.keyCode === 27) {
                          e.stopPropagation();
                          projectsToHome();
                      }
                      else if(e.keyCode === 13) {
                          e.stopPropagation();
                          if( $('#pg_large').length === 0) {
                              $('#pg_preview .pg_thumb_block').eq( $('.pg_content').data('current-project') )
                                  .find('.pg_thumb').first().trigger('click');
                          }
                      }
                  }

              });
}
$(setupGallery);



$(function() {
			//index of current item
      $('.pg_content').data('current-project', 0);
			//speeds / ease type for animations
			var fadeSpeed			= 400;
			var animSpeed			= 600;
			var easeType			= 'easeOutCirc';
			//caching
			var $thumbScroller		= $('#thumbScroller');
			var $scrollerContainer	= $thumbScroller.find('.container');
			var $scrollerContent	= $thumbScroller.find('.content');
			var $pg_title 			= $('#pg_title');
			var $pg_preview 		= $('#pg_preview');
			var $pg_desc1 			= $('#pg_desc1');
			var $pg_desc2 			= $('#pg_desc2');
			var $overlay			= $('#overlay');
			//number of items
			var scrollerContentCnt  = $scrollerContent.length;
			var sliderHeight		= $(window).height();
			//we will store the total height
			//of the scroller container in this variable
			var totalContent		= 0;
			//one items height
			var itemHeight			= 0;

      var mostRecentStartPosition = {
              'top': '0px',
              'left': '250px',
              'width': '360px',
              'height': '300px'
          };

			
			//First let's create the scrollable container,
			//after all its images are loaded
			var cnt		= 0;
			$thumbScroller.find('img').each(function(){
					                                var $img 	= $(this);
					                                $('<img/>').load(function(){
						                                                   ++cnt;
						                                                   if(cnt == scrollerContentCnt){
							                                                     //one items height
							                                                     itemHeight = $thumbScroller.find('.content:first').height();
							                                                     buildScrollableItems();
							                                                     //show the scrollable container
							                                                     $thumbScroller.stop().animate({'left':'0px'},animSpeed);
						                                                   }
					                                                 }).attr('src',$img.attr('src'));
				                              });
			
			//when we click an item from the scrollable container
			//we want to display the items content
			//we use the index of the item in the scrollable container
			//to know which title / image / descriptions we will sho
			$scrollerContent.bind('click',function(e){
					                      var $this 				= $(this);
					                      
					                      var idx 				= $this.index();
					                      //if we click on the one shown then return
					                      if($('.pg_content').data('current-project')==idx) return;
					                      
					                      //if the current image is enlarged,
					                      //then we will remove it but before
					                      //we animate it just like we would do with the thumb
					                      var $pg_large			= $('#pg_large');
					                      if($pg_large.length > 0){
						                        $pg_large.animate({'left':'350px','opacity':'0'},animSpeed,function(){
							                                            $pg_large.remove();
						                                          });
					                      }
					                      
					                      //get the current and clicked items elements
                                var current = $('.pg_content').data('current-project');
					                      var $currentTitle 		= $pg_title.find('h1:nth-child('+(current+1)+')');
					                      var $nextTitle 			= $pg_title.find('h1:nth-child('+(idx+1)+')');
					                      var $currentThumb		= $pg_preview.find('.pg_thumb_block:eq('+current+')');
					                      var $nextThumb			= $pg_preview.find('.pg_thumb_block:eq('+idx+')');
					                      var $currentDesc1 		= $pg_desc1.find('div:nth-child('+(current+1)+')');
					                      var $nextDesc1 			= $pg_desc1.find('div:nth-child('+(idx+1)+')');
					                      var $currentDesc2 		= $pg_desc2.find('div:nth-child('+(current+1)+')');
					                      var $nextDesc2 			= $pg_desc2.find('div:nth-child('+(idx+1)+')');
					                      
					                      //the new current is now the index of the clicked scrollable item
					                      $('.pg_content').data('current-project', idx);
					                      
					                      //animate the current title up,
					                      //hide it, and animate the next one down
					                      $currentTitle.stop().animate({'top':'-50px'},animSpeed,function(){
						                                                     $(this).hide();
						                                                     $nextTitle.show().stop().animate({'top':'5px'},animSpeed);
					                                                   });
					                      
					                      //show the next image,
					                      //animate the current to the left and fade it out
					                      //so that the next gets visible
					                      $nextThumb.show();
					                      $currentThumb.stop().animate({'left': '350px','opacity':'0'},animSpeed,function(){
						                                                     $(this).hide().css({
							                                                                          'left'		: '250px',
							                                                                          'opacity'	: 1,
							                                                                          'z-index'	: 1
						                                                                        });
						                                                     $nextThumb.css({'z-index':9999});
					                                                   });
					                      
					                      //animate both current descriptions left / right and fade them out
					                      //fade in and animate the next ones right / left
					                      $currentDesc1.stop().animate({'left':'205px','opacity':'0'},animSpeed,function(){
						                                                     $(this).hide();
						                                                     $nextDesc1.show().stop().animate({'left':'250px','opacity':'1'},animSpeed);
					                                                   });
					                      $currentDesc2.stop().animate({'left':'695px','opacity':'0'},animSpeed,function(){
						                                                     $(this).hide();
						                                                     $nextDesc2.show().stop().animate({'left':'650px','opacity':'1'},animSpeed);
					                                                   });
					                      e.preventDefault();
				                    });
			
			//when we click a thumb, the thumb gets enlarged,
			//to the sizes of the large image (fixed values).
			//then we load the large image, and insert it after
			//the thumb. After that we hide the thumb so that
			//the large one gets displayed
			$pg_preview.find('.pg_thumb').bind('click',showLargeImage);


      function unzoomGallery(){
          $overlay.fadeOut(200);
          var $largeImg = $('#pg_large');
          var $thumb = $pg_preview.find('.pg_thumb').eq($largeImg.data('thumb-index'));
          $largeImg.stop().animate(mostRecentStartPosition,500, function() {
                                       $largeImg.remove();
                                       $thumb
                                           .css({'z-index': 9999});
                                       
			                                 $pg_preview.find('.pg_thumb').bind('click', showLargeImage);
                                       GLOBAL_STATE = STATES.PROJECTS;
                                   });
      }
	    
      function keyCatcher(e) {
          if( e.keyCode === 39 || e.keyCode === 37) {
              e.stopPropagation();              
              var thumbs = $('#pg_preview .pg_thumb_block').eq( $('.pg_content').data('current-project') ).find('.pg_thumb');
              var large = $('#pg_large');
              var nextIndex = -1, nextThumb;

              if( e.keyCode === 39 && large.data('thumb-index') < thumbs.length - 1 ) {
                  nextIndex = large.data('thumb-index') + 1;
              }
              else if (e.keyCode === 37 && large.data('thumb-index') > 0 ) {
                  nextIndex = large.data('thumb-index') - 1;                  
              }

              if(nextIndex !== -1 ) {
                  nextThumb = thumbs.eq( nextIndex );
                  large
                      .attr('src', nextThumb.attr('alt'))
                      .data('thumb-index', nextIndex);                  
              }
          }
          else if (e.keyCode === 27) {
              unzoomGallery();
              e.stopPropagation();
          }
      }

      $(document).bind('keyup', keyCatcher);

			//enlarges the thumb
      function showLargeImage(){
          //if theres a large one remove
          $('#pg_large').remove();
          $('#grower').remove();
          var $thumb 		= $(this);

			    $pg_preview.find('.pg_thumb').unbind('click');
          var large_src 	= $thumb.attr('alt');

          $overlay.fadeIn(200);

          var padding = parseInt($thumb.css('padding'));
          var left = padding + ($thumb.index() * (padding * 2)) + ($thumb.index() * parseInt($thumb.css('width'))); // leftmost padding, plus padding inbetween elements (collapsed), plus 
          var top = padding;
          mostRecentStartPosition = {
              'top': top,
              'left': left,
              'width': '360px',
              'height': '300px'
          };
          var endPosition = {
              'top': '0px',
              'left': '250px',
              'width': '900px',
              'height': '750px'
          };

          // grow image
          var $growerImg = $('<img id="grower"/>').css(mostRecentStartPosition);
          $growerImg.attr('src', $thumb.attr('src'));
          $growerImg.insertBefore($thumb);
          $growerImg.animate(endPosition,
                             500,
                             function() {
							                   $thumb.css({
								                                'opacity'	: 1,
								                                'z-index'	: 1
							                              });
                                 
                                 $('<img src="' + large_src + '" id="pg_large" data-thumb-index="' + $thumb.index() + '"/>').css(endPosition).load(function() {
                                                                                                             var $largeImg = $(this);
                                                                                                             $largeImg.insertAfter($thumb).show(); // the positioning after the thumb is arbitrary orderwise, since this is absolutely positioned...
                                                                                                             $growerImg.remove();
                                                                                                             GLOBAL_STATE = STATES.GALLERY;
							                                                                                               $largeImg.bind('click', unzoomGallery);
                                                                                                         });
                             });          
			}
			
			//resize window event:
			//the scroller container needs to update
			//its height based on the new windows height
			$(window).resize(function() {
					                 var w_h			= $(window).height();
					                 $thumbScroller.css('height',w_h);
					                 sliderHeight	= w_h;
				               });
			
			//create the scrollable container
			//taken from Manos :
			//http://manos.malihu.gr/jquery-thumbnail-scroller
			function buildScrollableItems(){
					totalContent = (scrollerContentCnt-1)*itemHeight;
					$thumbScroller.css('height',sliderHeight)
					    .mousemove(function(e){
						                 if($scrollerContainer.height()>sliderHeight){
							                   var mouseCoords		= (e.pageY - this.offsetTop);
							                   var mousePercentY	= mouseCoords/sliderHeight;
							                   var destY			= -(((totalContent-(sliderHeight-itemHeight))-sliderHeight)*(mousePercentY));
							                   var thePosA			= mouseCoords-destY;
							                   var thePosB			= destY-mouseCoords;
							                   if(mouseCoords==destY)
								                     $scrollerContainer.stop();
							                   else if(mouseCoords>destY)
								                 $scrollerContainer.stop()
							                       .animate({
								                                  top: -thePosA
							                                },
							                                animSpeed,
							                                easeType);
							                   else if(mouseCoords<destY)
								                 $scrollerContainer.stop()
							                       .animate({
								                                  top: thePosB
							                                },
							                                animSpeed,
							                                easeType);
						                 }
					               }).find('.thumb')
					    .fadeTo(fadeSpeed, 0.6)
					    .hover(
					        function(){ //mouse over
						          $(this).fadeTo(fadeSpeed, 1);
					        },
					        function(){ //mouse out
						          $(this).fadeTo(fadeSpeed, 0.6);
					        }
				      );
			}
	});
