
function slideAbstract(absId) {
    // $(absId).slideToggle("fast", "swing", window.MathJax.Hub.Reprocess());
    // $(absId).slideToggle("fast");
    if ($(absId).hasClass('collapsed-abstract')) {
     	$(absId).removeClass('collapsed-abstract');
    } else {
	$(absId).addClass('collapsed-abstract');
    }
    return false;
}


function showAllAbstracts() {
    $(".abstract").removeClass('collapsed-abstract');
    return false;
}

function hideAllAbstracts() {
    $(".abstract").addClass('collapsed-abstract');
    return false;
}

$(function() {
    $("input.colorpicker").minicolors();
    window.MathJax.Hub.Queue(["Typeset",MathJax.Hub]);
});
