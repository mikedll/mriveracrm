/**
 * Requires jquery to be loaded.
 */


$(function() {

      function path()
      {
          var args = arguments, result = [];

          for(var i = 0; i < args.length; i++)
              result.push(args[i].replace('@', 'http://alexgorbatchev.com/pub/sh/3.0.83/scripts/'));
          
          return result;
      };
      
      alert(path(
                'bash shell @shBrushBash.js'
            )
           );

      SyntaxHighlighter.autoloader.apply(null, 
                                         path(
                                             'bash shell @shBrushBash.js'
                                         )
                                        );

      
      SyntaxHighlighter.config.bloggerMode=true;
      SyntaxHighlighter.config.tagName = 'code';
      SyntaxHighlighter.all();
  });


