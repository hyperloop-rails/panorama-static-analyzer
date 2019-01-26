  var c, colorScale, color_scale, colors, cost, i, j, len, results1, time;
  var s = 70
  var l = 75
  var base = 0
  array_unique = function(a) {
    var j, key, output, ref, results1, value;
    output = {};
    for (key = j = 0, ref = a.length; 0 <= ref ? j < ref : j > ref; key = 0 <= ref ? ++j : --j) {
      output[a[key]] = a[key];
    }
    results1 = [];
    for (key in output) {
      value = output[key];
      results1.push(value);
    }
    return results1;
  };
  var btn_div = document.createElement("DIV")
  btn_div.setAttribute('id', 'panorama-btn-div-id')
  var btn = document.createElement("BUTTON");        // Create a <button> element
  var t = document.createTextNode("Real-time");       // Create a text node
  btn.appendChild(t);    
  btn_div.style = "z-index:10000;top:35px;left:0;position:absolute;border-style:solid;border-width:thin;text-align: center;background-color:white"                       // Append the text to <button>
  if (document.getElementById("panorama-btn-div-id")){
    document.body.removeChild(btn_div);
  }
  document.body.appendChild(btn_div) 
  btn_div.appendChild(btn)
  
  var btn2 = document.createElement("BUTTON");        // Creaspane a <button> element
  var t2 = document.createTextNode("Relative");       // Create a text node
  btn2.appendChild(t2);      

  btn_div.appendChild(document.createElement("br") )                            // Append the text to <button>
  btn_div.appendChild(btn2);

  var btn3 = document.createElement("BUTTON");        // Create a <button> element
  var t3 = document.createTextNode("Split");       // Create a text node
  btn3.appendChild(t3);  
  btn_div.appendChild(document.createElement("br") )                              // Append the text to <button>
  btn_div.appendChild(btn3);
  btn_div.appendChild(document.createElement("hr"))
  
  function dragElement(elmnt) {
    var pos1 = 0, pos2 = 0, pos3 = 0, pos4 = 0;
    if (document.getElementById(elmnt.id + "header")) {
      /* if present, the header is where you move the DIV from:*/
      document.getElementById(elmnt.id + "header").onmousedown = dragMouseDown;
    } else {
      /* otherwise, move the DIV from anywhere inside the DIV:*/
      elmnt.onmousedown = dragMouseDown;
    }
    function dragMouseDown(e) {
      e = e || window.event;
      e.preventDefault();
      // get the mouse cursor position at startup:
      pos3 = e.clientX;
      pos4 = e.clientY;
      document.onmouseup = closeDragElement;
      // call a function whenever the cursor moves:
      document.onmousemove = elementDrag;
    }

    function elementDrag(e) {
      e = e || window.event;
      e.preventDefault();
      // calculate the new cursor position:
      pos1 = pos3 - e.clientX;
      pos2 = pos4 - e.clientY;
      pos3 = e.clientX;
      pos4 = e.clientY;
      // set the element's new position:
      elmnt.style.top = (elmnt.offsetTop - pos2) + "px";
      elmnt.style.left = (elmnt.offsetLeft - pos1) + "px";
    }

    function closeDragElement() {
      /* stop moving when mouse button is released:*/
      document.onmouseup = null;
      document.onmousemove = null;
    }
  }
  $(btn3).addClass("btn btn-secondary")
  $(btn2).addClass("btn btn-secondary")
  $(btn).addClass("btn btn-secondary")
    colorScale = function(sorted_array) {
      var end, fn, i, j, ref, results, scale, start;
      results = {};
      start = 0.45;
      end = 0.95;
      start = 0
      end = 1
      scale = (end - start) / (sorted_array.length);
      fn = function(i) {
        var value;
        value = sorted_array[i];
        var h = (1 - i*scale) * 100 + base
        var h_color = "hsl(" + h + ","  + s+ "%," + l + "%)";
        
        return results[value] = h_color;
        //value = i;
        //return results[value] = "hsl(30, 80%," + (end - i * scale) * 100 + "%)";
      };
      for (i = j = 0, ref = sorted_array.length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
        fn(i);
      }
      return results;
    };
    color_bar = function(size){
      var whole_div = document.createElement("DIV");
      var color_bar_id = "color_bar_id"
      whole_div.setAttribute("id", color_bar_id);
      scale = 1/(size)
      var color_bar_div = document.createElement("DIV");
      for(var i = 0; i < size; i ++){
        var div = document.createElement("DIV");
        color_bar_div.appendChild(div)
        //var h = (1.0 - i * scale) * 240
        var value = i * scale
        var h = (1 - value) * 100 + base
        var h_color = "hsl(" + h + ","  + s+ "%," + l + "%)";
        div.style = "width:80px;height:40px;background-color:" + h_color ; 
      }
      color_bar_div.appendChild(document.createElement("DIV"))
      
      var previous = document.getElementById(color_bar_id)
      if(previous)
        previous.remove()
      image_block = document.createElement("DIV")
      image_div = document.createElement('DIV')
      image = document.createElement("IMG")
      image.setAttribute('src', '/assets/arrow.png')
      image.style="height:" + (size*40) + "px"
      image_div.appendChild(image)
      whole_div.appendChild(color_bar_div)
      image_block.appendChild(image_div)
      image_block.style="display:inline-block;vertical-align: top;height:" + (40*size) + "px"
      color_bar_div.style="display:inline-block;vertical-align: top;"
      whole_div.appendChild(image_block)
      btn_div.appendChild(whole_div);
      
      //whole_div.appendChild(arrow)
      //whole_div.style = "top:110px; left:0; position:absolute";
      }

    dragElement(btn_div);
    render = function(cost){
      cost.sort(function(a, b) {
        return a[1] - b[1];
      });
      time = cost.map(function(x) {
          return x[1];
      });
      time = time.filter(function(x){
        return x > 0;
      });
      time = array_unique(time)
      time.sort(function(a, b) {
        return a-b;
      });
      color_scale = colorScale(time);
      i = 0;
      results1 = [];
      for (j = 0, len = cost.length; j < len; j++) {
        c = cost[j];
        results1.push((function(c) {
          var color, id, t;
          id = c[0];
          t = c[1];
          color = color_scale[c[1]];
      $(id).css("background-color", color);
        })(c));
      }
      color_bar(time.length)
    }
    remove_bg = function(cost){
      for (j = 0, len = cost.length; j < len; j++) {
        c = cost[j];
        var color, id, t;
        id = c[0];
        $(id).css("background-color", 'transparent');
      }
    }

    //render(cost_w)

    $(btn).on('click', function() {
      $(btn).removeClass()
      $(btn).addClass("btn btn-primary")
      $(btn2).removeClass()
      $(btn2).addClass("btn btn-secondary")
      var myClass = $(btn3).attr("class");
      if(myClass.indexOf("btn-primary") >= 0){
        remove_bg(cost_rs)
        render(cost_ws)
      }
      else{
        remove_bg(cost_r)
        render(cost_w)
      }
    });
    $(btn2).on('click', function() {
      $(btn2).removeClass()
      $(btn2).addClass("btn btn-primary")
      $(btn).removeClass()
      $(btn).addClass("btn btn-secondary")
      var myClass = $(btn3).attr("class");
      if(myClass.indexOf("btn-primary") >= 0){
        remove_bg(cost_ws)
        render(cost_rs)
      }
      else{
        remove_bg(cost_w)
        render(cost_r)
      }
    });
    $(btn2).click();
    $(btn3).on('click', function() {
      var myClass = $(btn3).attr("class");
      var btnClass = $(btn).attr("class");
      var btn_primary = btnClass.indexOf("btn-primary");
      if(myClass.indexOf("btn-primary") >= 0){
        $(btn3).removeClass("btn btn-primary")
        $(btn3).addClass("btn btn-secondary")
        if(btn_primary < 0){
          remove_bg(cost_rs)
          render(cost_r)
        }else{
          remove_bg(cost_ws)
          render(cost_w)
        }
      }
      else{
        $(btn3).removeClass()
        $(btn3).addClass("btn btn-primary")
        if(btn_primary < 0){
          remove_bg(cost_r)
          render(cost_rs)
        }else{
          remove_bg(cost_w)
          render(cost_ws)
        }
      }

    });
    // return results1;
    results2 = [];
    send_request = function(request){
      $.ajax({
          url : "/requests/request_handle",
          type : "post",
          data : { data_value: request }
      });
    };
    for (j = 0, len = choices.length; j < len; j++) {
      c = choices[j];
      results2.push((function(c) {
        var id, t;
        id = c[0];
        t = c[1]
        var k = 0;
        var button_strings = '';
        for(k = 0; k < t.length; k++){
          var alt = t[k]
          var alt_without = alt.split("_")[0]
          var btn_id = j + '_' + k + '_' + alt
      var request = "'" + id + '___' + alt + "'"
      button_strings += '<button id="' + btn_id + '" type="button" onclick="send_request('+ request + ')" class="btn btn-primary popover-submit" >' + '<i class="icon-ok icon-white">' + alt_without + '</i></button>';
        }
    $(id).on('click', function() {
      return $(this).popover({
        trigger: 'click',
        content: 'Design Choices',
        template: '<div class="popover">' + '<div class="popover-content" >' + '</div><div  align="center" class="popover-footer">' + button_strings + '&nbsp;</div></div>',
        placement: 'right'
      });
    });
      })(c));
    }
    return results2;
