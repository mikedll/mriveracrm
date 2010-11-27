
/**
 Requires jQuery to have already been loaded.
 */

var MathSettings = {
  server : 'http://math.mikedll.com/mathtex.cgi?',
  preamble : '\\usepackage[usenames]{color}\\gammacorrection{1}\\png'
};

function renderMath() {
    $(this).addClass("renderedMath");
    $(this).html( '<center><img src=\'' + 
                  MathSettings.server + 
                  MathSettings.preamble + 
                  encodeURI( $(this).html() ) +
                  '\'/></center>' );
}

function renderMathBrush() {
    // New way to format code
    $('pre.math code').each( renderMath );

    // Backwards compatible, pre-October 2009 posts
    $('pre code.math').each( renderMath );
}

$( renderMathBrush );
