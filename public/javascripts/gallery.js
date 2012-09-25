$(function() {
			//index of current item
			var current				= 0;
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
					                      if(current==idx) return;
					                      
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
					                      var $currentTitle 		= $pg_title.find('h1:nth-child('+(current+1)+')');
					                      var $nextTitle 			= $pg_title.find('h1:nth-child('+(idx+1)+')');
					                      var $currentThumb		= $pg_preview.find('.pg_thumb_block:eq('+current+')');
					                      var $nextThumb			= $pg_preview.find('.pg_thumb_block:eq('+idx+')');
					                      var $currentDesc1 		= $pg_desc1.find('div:nth-child('+(current+1)+')');
					                      var $nextDesc1 			= $pg_desc1.find('div:nth-child('+(idx+1)+')');
					                      var $currentDesc2 		= $pg_desc2.find('div:nth-child('+(current+1)+')');
					                      var $nextDesc2 			= $pg_desc2.find('div:nth-child('+(idx+1)+')');
					                      
					                      //the new current is now the index of the clicked scrollable item
					                      current		 			= idx;
					                      
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
          var startPosition = {
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
          var $growerImg = $('<img id="grower"/>').css(startPosition);
          $growerImg.attr('src', $thumb.attr('src'));
          $growerImg.insertBefore($thumb);
          $growerImg.animate(endPosition,
                             500,
                             function() {
                                 
							                   $thumb.css({
								                                'opacity'	: 1,
								                                'z-index'	: 1
							                              });

                                 $('<img src="' + large_src + '" id="pg_large"/>').css(endPosition).load(function() {
                                                                                            var $largeImg = $(this);
                                                                                            $largeImg.insertAfter($thumb).show();
                                                                                            $growerImg.remove();
							                                                                              $largeImg.bind('click',function(){
                                                                                                               // $thumb.show();
                                                                                                               $overlay.fadeOut(200);
                                                                                                               $(this).stop().animate(startPosition,500, function() {
                                                                                                                                          $largeImg.remove();
                                                                                                                                          $thumb
                                                                                                                                              .css({'z-index': 9999});

			                                                                                                                                    $pg_preview.find('.pg_thumb').bind('click', showLargeImage);
                                                                                                                                      });
                                                                                                           });
                                                                                            
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
