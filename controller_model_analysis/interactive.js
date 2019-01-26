(function() {
 jQuery(function($) {
  var choices = [], cost_w = [], cost_r=[];
  cost_w = [["span#blog-num", 58.9], ["span#user-num", 2.7], ["p#insert16", 18.1], ["p#insert18", 18.1], ["p#insert20", 18.1], ["p#insert22", 18.1], ["p#insert6", 39.3], ["p#insert8", 39.3], ["p#insert10", 39.3]]
  cost_r = [["span#blog-num", 1], ["span#user-num", 1], ["p#insert16", 10], ["p#insert18", 10], ["p#insert20", 10], ["p#insert22", 10], ["p#insert6", 2], ["p#insert8", 2], ["p#insert10", 2], ["div#blogs", 2]]
  var c, colorScale, color_scale, colors, cost, i, j, len, results1, time;
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
  var btn = document.createElement("BUTTON");        // Create a <button> element
	var t = document.createTextNode("Real-time");       // Create a text node
	btn.appendChild(t);    
	btn.style = "top:0;left:0;width:80px;position:absolute;"                       // Append the text to <button>
	document.body.appendChild(btn);
	var btn2 = document.createElement("BUTTON");        // Create a <button> element
	var t2 = document.createTextNode("Relative");       // Create a text node
	btn2.appendChild(t2);                                // Append the text to <button>
	document.body.appendChild(btn2);
	btn2.style = "top:30px;left:0;width:80px;position:absolute;" 
    colorScale = function(sorted_array) {
      var end, fn, i, j, ref, results, scale, start;
      results = {};
      start = 0.45;
      end = 0.95;
      start = 0
      end = 1
      scale = (end - start) / (sorted_array.length - 1);
      fn = function(i) {
        var value;
        value = sorted_array[i];
        var h = (1.0 - i * scale) * 240
        return results[value] = "hsl(" + h + ", 80%, 75%)";
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
      scale = 1/(size - 1)
      for(var i = 0; i < size; i ++){
        var div = document.createElement("DIV");
        whole_div.appendChild(div)
        var h = (1.0 - i * scale) * 240
        var h_color = "hsl(" + h + ", 80%, 75%)";
        div.style = "width:80px;height:40px;background-color:" + h_color; 
      }
      var previous = document.getElementById(color_bar_id)
      if(previous)
        previous.remove()
      document.body.appendChild(whole_div);
      whole_div.style = "top:60px; left:0; position:absolute";
    }
    render = function(cost){
      cost.sort(function(a, b) {
        return a[1] - b[1];
      });
      time = cost.map(function(x) {
        return x[1];
      });
      time = array_unique(time)
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
    render(cost_w)
    $(btn).on('click', function() {
      $(btn).addClass("btn btn-primary popover-submit")
      $(btn2).removeClass("btn btn-primary popover-submit")
      remove_bg(cost_r)
  		render(cost_w)
  	});
  	$(btn2).on('click', function() {
      $(btn2).addClass("btn btn-primary popover-submit")
      $(btn).removeClass("btn btn-primary popover-submit")
      remove_bg(cost_w)
  		render(cost_r)
  	});

    // return results1;
    results2 = [];
    send_request = function(requst){
    	$.ajax({
	        url : "/requests/request_handle",
	        type : "post",
	        data : { data_value: requst }
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
        	var btn_id = j + '_' + k + '_' + alt
 			var request = "'" + id + '___' + alt + "'"
 			button_strings += '<button id="' + btn_id + '" type="button" onclick="send_request('+ request + ')" class="btn btn-primary popover-submit" >' + '<i class="icon-ok icon-white">' + alt + '</i></button>';
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
 });
}).call(this);
