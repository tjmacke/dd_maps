function makeMapScales(scaleData) {

  var fontSize = window.devicePixelRatio == 2 ? 12 : 10;

  if("data_stats" in scaleData) {
    document.getElementById("dataStats").innerHTML = "Stats: " + scaleData.data_stats;
  }

  var mainScaleProps = {}
  // properties that define the scale
  mainScaleProps.sp_tick_font_size = fontSize;
  mainScaleProps.sp_xoff           = 5;
  mainScaleProps.sp_width          = 40;
  mainScaleProps.sp_height         = 15;
  mainScaleProps.sp_tick_len       = 5;
  mainScaleProps.sp_xHeight        = Math.round(0.7 * mainScaleProps.sp_tick_font_size);
  mainScaleProps.sp_yoff           = mainScaleProps.sp_tick_font_size + 2;
  mainScaleProps.sp_tick_yoff      = mainScaleProps.sp_yoff + mainScaleProps.sp_height;
  mainScaleProps.sp_tick_text_yoff = mainScaleProps.sp_tick_yoff + mainScaleProps.sp_tick_len + mainScaleProps.sp_xHeight;

  // properties that provide the scale data
  mainScaleProps.sp_divId = "#mainScale";
  mainScaleProps.sp_svgId = "#svgMainScale";
  // TODO: fix!
  mainScaleProps.sp_values = scaleData.color_values;								// <-- FIX
  var main_sp_breaks = scaleData.color_breaks;									// <-- FIX
  mainScaleProps.sp_breaks_idx_off = 1;
  if (("color_min_value" in scaleData) || ("color_max_value" in scaleData)) {					// <-- FIX
    main_sp_breaks = [];
    if ("color_min_value" in scaleData) {									// <-- FIX
      main_sp_breaks.push(Math.floor(scaleData.color_min_value[0]));						// <-- FIX
      mainScaleProps.sp_breaks_idx_off = 0;
    }
    for(var i = 0; i < scaleData.color_breaks.length; i++)							// <-- FIX
      main_sp_breaks.push(scaleData.color_breaks[i]);								// <-- FIX
    if ("color_max_value" in scaleData) {									// <-- FIX
      var main_max_value = Math.ceil(scaleData.color_max_value[0]);						// <-- FIX
      var main_breaks_max_value = scaleData.color_breaks[scaleData.color_breaks.length - 1];			// <-- FIX
      main_sp_breaks.push(main_max_value > main_breaks_max_value ? main_max_value : main_breaks_max_value);
    }
  }
  mainScaleProps.sp_breaks = main_sp_breaks;
  mainScaleProps.sp_title = ("color_title" in scaleData) ? scaleData.color_title : ["Pin Colors"];		// <-- FIX
  mainScaleProps.sp_fill_boxes_func = function(d, i) {
    return "rgb(" + Math.round(d[0]*255) + "," + Math.round(d[1]*255) + "," + Math.round(d[2]*255) + ")";
  };
  if(!("color_stats" in scaleData)) {										// <-- FIX
    mainScaleProps.sp_box_text = null;
  } else {
    var main_box_text = [];
    for(var i = 0; i < scaleData.color_stats.length; i++){							// <-- FIX
      main_box_text.push(scaleData.color_stats[i][1] + "%");							// <-- FIX
    }
    mainScaleProps.sp_box_text = main_box_text;
    if("color_box_text_color" in scaleData){									// <-- FIX
      mainScaleProps.sp_box_text_color = scaleData.color_box_text_color[0]					// <-- FIX
    } else {
      mainScaleProps.sp_box_text_color = "rgb(255,255,255)";
    }
  }

  makeScale(mainScaleProps);

  var auxScaleProps = {};
  // properties that define the scale
  auxScaleProps.sp_tick_font_size = fontSize;
  auxScaleProps.sp_xoff           = 9;	// will work up to 999
  auxScaleProps.sp_width          = 75;
  auxScaleProps.sp_height         = 15;
  auxScaleProps.sp_tick_len       = 5;
  auxScaleProps.sp_xHeight        = Math.round(0.7 * auxScaleProps.sp_tick_font_size);
  auxScaleProps.sp_yoff           = auxScaleProps.sp_tick_font_size + 2;
  auxScaleProps.sp_tick_yoff      = auxScaleProps.sp_yoff + auxScaleProps.sp_height;
  auxScaleProps.sp_tick_text_yoff = auxScaleProps.sp_tick_yoff + auxScaleProps.sp_tick_len + auxScaleProps.sp_xHeight;

  // properties that provide the scale data
  auxScaleProps.sp_divId = "#aux";
  aux.sp_svgId = "#svgAuxScale";
  // TODO: fix!
  auxScaleProps.sp_values = scaleData.size_values;
  var aux_sp_breaks = scaleData.size_breaks;
  auxScaleProps.sp_breaks_idx_off = 1;
  if (("size_min_value" in scaleData) || ("size_max_value" in scaleData)) {
    aux_sp_breaks = [];
    if ("size_min_value" in scaleData) {
      aux_sp_breaks.push(Math.floor(scaleData.size_min_value[0]));
      auxScaleProps.sp_breaks_idx_off = 0;
    }
    for(var i = 0; i < scaleData.size_breaks.length; i++)
      aux_sp_breaks.push(scaleData.size_breaks[i]);
    if ("size_max_value" in scaleData) {
      var aux_max_value = Math.ceil(scaleData.size_max_value[0]);
      var aux_breaks_max_value = scaleData.size_breaks[scaleData.size_breaks.length - 1];
      aux_sp_breaks.push(aux_max_value > aux_breaks_max_value ? aux_max_value : aux_breaks_max_value);
    }
  }
  auxScaleProps.sp_breaks = aux_sp_breaks;
  auxScaleProps.sp_title = ("size_title" in scaleData) ? scaleData.size_title : ["Pin Sizes"];
  auxScaleProps.sp_fill_boxes_func = function(d, i) {
    return "white";
  }
  if(!("size_stats" in scaleData)) {
    auxScaleProps.sp_box_text = scaleData.size_values;
  } else {
    auxScaleProps.sp_box_text = scaleData.size_values;
    var aux_box_text = [];
    for(var i = 0; i < scaleData.size_stats.length; i++){
      aux_box_text.push(scaleData.size_values[i] + ", " + scaleData.size_stats[i][1] + "%"); 
    }
    auxScaleProps.sp_box_text = size_box_text;
  }
  auxScaleProps.sp_box_text_color = "black";

  makeScale(auxScaleProps);
}
