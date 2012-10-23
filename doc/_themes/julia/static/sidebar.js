/*
 * sidebar.js
 * ~~~~~~~~~~
 *
 * This script manages the Sphinx sidebar position, scrolling and collapsing
 * for the Julia theme.
 *
 * Based on the sidebar script for the default sphinx theme.
 *
 * default sphinx theme:
 * :copyright: Copyright 2007-2011 by the Sphinx team, see AUTHORS.
 * :license: BSD, see LICENSE for details.
 *
 * julia theme:
 * :copyright: Copyright 2012 by the Julia authors, see AUTHORS.
 * :license: MIT, see  LICENSE for details.
 *
 */

$(function() {
  // global elements used by the functions.
  var body= $('div.body');
  var bodywrapper = $('.bodywrapper');
  var footerwrapper = $('.footerwrapper');
  var sidebar = $('.sphinxsidebar');
  var sidebarview = $('.sphinxsidebarview');
  var sidebarcontent = $('.sphinxsidebarcontent');
  var sidebarscrollerwrapper = $('.sphinxsidebarscrollerwrapper');
  var sidebarscroller = $('.sphinxsidebarscroller');
  var sidebarbuttondiv = $('.sphinxsidebarbutton');
  var sidebarbutton = $('#sidebarbutton');

  var uncollapsed_height = 0;

  var sidebarscroll_startY = 0;
  var sidebarscroll_start_scroll = 0;
  var sidebarscroller_rate = 1;

  body.prepend('<p id="printf">TEST</p>');
  var printf = $('#printf');
  printf.css({
      'position': 'fixed',
      'top': 10,
      'left': 400,
      'border-width': 2,
      'border-style': 'solid',
      'background-color': 'red'
  });
  var pfcntr = 0;

  // if for some reason the document has no sidebar, do not run into errors
  if (!sidebar.length) return;

  // original margin-left of the bodywrapper and width of the sidebar
  // with the sidebar expanded
  var bw_margin_expanded = bodywrapper.css('margin-left');
  var ssb_width_expanded = sidebar.width();

  // margin-left of the bodywrapper and width of the sidebar
  // with the sidebar collapsed
  var bw_margin_collapsed = '40px';
  var ssb_width_collapsed = '30px';

  // sidebar paddings
  var barpadtop = parseFloat(sidebar.css('padding-top'));
  var barpadbottom = parseFloat(sidebar.css('padding-bottom'));
  var barpad = barpadtop + barpadbottom;

  var barscroll = 0;

  function viewOffsetTop(elem) {
    // NOTE: jQuery's offset() doesn't work (evaluates nodes
    //       as being disconnected and returns 0); plus we need
    //       the offset relative to the viewport, so this approach
    //       is more direct
    return elem[0].getBoundingClientRect().top;
  }

  function sidebar_is_collapsed() {
    return sidebarcontent.is(':not(:visible)');
  }

  function toggle_sidebar() {
    if (sidebar_is_collapsed())
      expand_sidebar();
    else
      collapse_sidebar();
  }

  function compute_uncollapsed_height() {
    var isc = sidebar_is_collapsed();
    if (isc)
      expand_sidebar();
    uncollapsed_height = sidebarcontent.height();
    if (isc)
      collapse_sidebar();
  }

  function get_collapsed_height() {
    var bartop = viewOffsetTop(sidebar);
    return Math.min(uncollapsed_height, $(window).height() - barpad - bartop);
  }

  function get_scroller_height() {
    var bartop = viewOffsetTop(sidebar);
    var barheight = sidebarbuttondiv.height();
    //var buttonheight = sidebarbutton.height();
    var barscroll = sidebarview.scrollTop();

    var visibleheight = Math.min(barheight, $(window).height() - barpad - bartop);
    printf.text("bar_h=" + visibleheight +
                " uncoll_h=" + barheight +
                " frac=" + visibleheight / barheight +
                " result=" + visibleheight * visibleheight / barheight +
                " cntr=" + pfcntr
                );
    pfcntr += 1;
    return visibleheight * visibleheight / barheight;
  }

  function set_button_margin() {
    var bartop = viewOffsetTop(sidebar);
    var barheight = sidebarbuttondiv.height();
    var buttonheight = sidebarbutton.height();
    var buttonscroll = sidebarview.scrollTop();
    //printf.text("buttonscroll=" + buttonscroll);
    var newmargin = (Math.min(barheight, $(window).height() - barpad - bartop) - buttonheight) / 2 + buttonscroll;
    sidebarbutton.css('margin-top', newmargin);
  }

  function set_scroller_pos() {
    var bartop = viewOffsetTop(sidebar);
    var barheight = sidebarbuttondiv.height();

    var visibleheight = Math.min(barheight, $(window).height() - barpad - bartop);
    //printf.text("bar_h=" + visibleheight +
                //" uncoll_h=" + barheight +
                //" frac=" + visibleheight / barheight +
                //" result=" + visibleheight * visibleheight / barheight +
                //" cntr=" + pfcntr
                //);
    //pfcntr += 1;
    sidebarscroller_rate = visibleheight / barheight;
    var scroller_height = visibleheight * sidebarscroller_rate;

    //var bartop = viewOffsetTop(sidebar);
    //var barheight = sidebar.height();
    //var barscroll = sidebarview.scrollTop();
    ////var newmargin = barscroll - scroller_height / 2;
    //var newmargin = (Math.min(barheight, $(window).height() - barpad - bartop) - scroller_height) / 2 + barscroll;
    //printf.text("barscroll=" + barscroll + " barheight=" + barheight + " newmargin=" + newmargin +
                //" scroller_height=" + scroller_height);
    var barscroll = sidebarview.scrollTop();
    var add_scroll = barscroll * sidebarscroller_rate;
    //printf.text("barscroll=" + barscroll +
                //" add_scroll=" + add_scroll +
                //" cntr=" + pfcntr
                //);
    //pfcntr += 1;
    sidebarscroller.css({
      'height': scroller_height,
      'margin-top': barscroll + add_scroll
    });
  }

  function collapse_sidebar() {
    barscroll = sidebarview.scrollTop();
    sidebarview.scrollTop(0);

    var newheight = get_collapsed_height();

    sidebarcontent.hide();
    sidebarscrollerwrapper.hide();
    sidebar.css('width', ssb_width_collapsed);
    var newmargins = {
      'margin-left': bw_margin_collapsed,
      'margin-right': bw_margin_collapsed,
    };
    bodywrapper.css(newmargins);
    footerwrapper.css(newmargins);
    sidebarbuttondiv.css({
      'height': newheight,
      'border-radius': '5px'
    });
    sidebarbutton.find('span').text('»');
    sidebarbuttondiv.attr('title', _('Expand sidebar'));
    set_button_margin();
    document.cookie = 'sidebar=collapsed';
  }

  function expand_sidebar() {
    var newmargins = {
      'margin-left': bw_margin_expanded,
      'margin-right': bw_margin_expanded,
    };
    bodywrapper.css(newmargins);
    footerwrapper.css(newmargins);
    sidebar.css('width', ssb_width_expanded);
    sidebarcontent.show();
    sidebarscrollerwrapper.show();
    sidebarbuttondiv.css({
      'height': '',
      'border-radius': '0 5px 5px 0'
    });
    sidebarbutton.find('span').text('«');
    sidebarbuttondiv.attr('title', _('Collapse sidebar'));
    sidebarview.css('height', sidebar.height());
    sidebar.css('width', sidebarview[0].scrollWidth);
    set_button_margin();
    set_scroller_pos();
    sidebarview.scrollTop(barscroll);
    document.cookie = 'sidebar=expanded';
  }

  function prepare_sidebar_button() {
    sidebarbuttondiv.click(toggle_sidebar);
    sidebarbuttondiv.attr('title', _('Collapse sidebar'));
  }

  function set_state_from_cookie() {
    if (!document.cookie)
      return;
    var items = document.cookie.split(';');
    for(var k=0; k<items.length; k++) {
      var key_val = items[k].split('=');
      var key = key_val[0];
      if (key == 'sidebar') {
        var value = key_val[1];
        if ((value == 'collapsed') && (!sidebar_is_collapsed()))
          collapse_sidebar();
        else if ((value == 'expanded') && (sidebar_is_collapsed()))
          expand_sidebar();
      }
    }
  }

  function set_sidebar_pos() {
    var bodyoff = viewOffsetTop(body);
    sidebar.css('top', Math.max(bodyoff,0));
    sidebarview.css('height', sidebar.height());
    if (!sidebar_is_collapsed()) {
      sidebar.css('width', sidebarview[0].scrollWidth);
      set_scroller_pos();
    } else {
      var newheight = get_collapsed_height();
      sidebarbuttondiv.css('height', newheight);
    }
    set_button_margin();
  }

  function initiate_sidebarscroll(e) {
    if (e.which != 1) {
      return;
    }
    sidebarscroll_startY = e.clientY;
    sidebarscroll_start_scroll = sidebarview.scrollTop();
    document.body.focus();
    //document.body.style.cursor = "move";
    //$('body').addClass('moving');
    sidebarcontent.css('cursor', 'move');
    printf.text("mousedown startY=" + sidebarscroll_startY +
                " start_scroll=" + sidebarscroll_start_scroll);
    document.onmouseup = end_sidebarscroll;
    document.onmousemove = do_sidebarscroll;

    // prevent text selection in IE
    document.onselectstart = function () { return false; };
    // prevent IE from trying to drag an image
    //e.srcElement.ondragstart = function() { return false; };

    // prevent text selection (except IE)
    return false;
  }

  function do_sidebarscroll(e) {
    var sidebarscroll_Y = e.clientY;
    //var scrollby = (sidebarscroll_Y - sidebarscroll_startY) / sidebarscroller_rate; // scrollbar version
    var scrollby = sidebarscroll_startY - sidebarscroll_Y;
    var newscroll = sidebarscroll_start_scroll + scrollby;

    sidebarview.scrollTop(newscroll);

    printf.text("mousedown startY=" + sidebarscroll_startY +
                " currentY=" + sidebarscroll_Y +
                " oldscroll=" + sidebarscroll_start_scroll + 
                " scrollby=" + scrollby
                );
  }

  function end_sidebarscroll() {
    printf.text("mouseup");
    //document.body.style.cursor = 'auto';
    //$('body').removeClass('moving');
    sidebarcontent.css('cursor', 'auto');
    document.onmousemove = null;
    document.onmouseup = null;
  }

  prepare_sidebar_button();
  sidebarview.css('height', sidebar.height());
  sidebarview.css('width', sidebar.width());
  sidebar.css('width', sidebarview[0].scrollWidth);
  set_state_from_cookie();
  compute_uncollapsed_height();
  set_sidebar_pos();

  $(window).scroll(set_sidebar_pos);
  sidebarview.scroll(set_button_margin);
  sidebarview.scroll(set_scroller_pos);
  $(window).resize(set_sidebar_pos);

  //sidebarscroller.mousedown(window.event, initiate_sidebarscroll);
  sidebarcontent.mousedown(window.event, initiate_sidebarscroll);
});
