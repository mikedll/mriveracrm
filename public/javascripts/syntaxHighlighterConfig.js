/**
 * Requires jquery to be loaded.
 */
$(function() {
    $(document).ready(function() {
                          var fixOld = function(el) {
                              var node = $(el);
                              var matches = node.attr('class').match(/^brush: (\w+); gutter: false;?$/);
                              if( matches !== null ) {                                  
                                  var lang = matches[1];
                                  node.attr('class', lang);
                                  console.debug(lang);
                              }
                              return node.first().get()[0];
                          };
                          $('pre code').each(function(i, e) { 
                                                 
                                                 hljs.highlightBlock(fixOld(e), '  '); 
                                             });
    });
  });


