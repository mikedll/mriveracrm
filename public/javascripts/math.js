
/**
 Requires jQuery to have already been loaded.
 */

var MathSettings = {
  server : 'http://www.cyberroadie.org/cgi-bin/mathtex.cgi?',
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
    $('pre.math code').each( renderMath );
}

$( renderMathBrush );
