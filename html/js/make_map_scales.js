function makeMapScales(scaleData) {

  var fontSize = window.devicePixelRatio == 2 ? 12 : 10;

  if("data_stats" in scaleData) {
    document.getElementById("dataStats").innerHTML = "Stats: " + scaleData.data_stats;
  }

  var colorScaleProps = {}
  // properties that define the scale
  colorScaleProps.sp_tick_font_size = fontSize;
  colorScaleProps.sp_xoff           = 5;
  colorScaleProps.sp_width          = 40;
  colorScaleProps.sp_height         = 15;
  colorScaleProps.sp_tick_len       = 5;
  colorScaleProps.sp_xHeight        = Math.round(0.7 * colorScaleProps.sp_tick_font_size);
  colorScaleProps.sp_yoff           = colorScaleProps.sp_tick_font_size + 2;
  colorScaleProps.sp_tick_yoff      = colorScaleProps.sp_yoff + colorScaleProps.sp_height;
  colorScaleProps.sp_tick_text_yoff = colorScaleProps.sp_tick_yoff + colorScaleProps.sp_tick_len + colorScaleProps.sp_xHeight;

  // properties that provide the scale data
  colorScaleProps.sp_divId = "#colorScale";
  colorScaleProps.sp_svgId = "#svgColorScale";
  colorScaleProps.sp_values = scaleData.color_values;
  var color_sp_breaks = scaleData.color_breaks;
  colorScaleProps.sp_breaks_idx_off = 1;
  if (("color_min_value" in scaleData) || ("color_max_value" in scaleData)) {
    color_sp_breaks = [];
    if ("color_min_value" in scaleData) {
      color_sp_breaks.push(Math.floor(scaleData.color_min_value[0]));
      colorScaleProps.sp_breaks_idx_off = 0;
    }
    for(var i = 0; i < scaleData.color_breaks.length; i++)
      color_sp_breaks.push(scaleData.color_breaks[i]);
    if ("color_max_value" in scaleData) {
      var color_max_value = Math.ceil(scaleData.color_max_value[0]);
      var color_breaks_max_value = scaleData.color_breaks[scaleData.color_breaks.length - 1];
      color_sp_breaks.push(color_max_value > color_breaks_max_value ? color_max_value : color_breaks_max_value);
    }
  }
  colorScaleProps.sp_breaks = color_sp_breaks;
  colorScaleProps.sp_title = ("color_title" in scaleData) ? scaleData.color_title : ["Pin Colors"];
  colorScaleProps.sp_fill_boxes_func = function(d, i) {
    return "rgb(" + Math.round(d[0]*255) + "," + Math.round(d[1]*255) + "," + Math.round(d[2]*255) + ")";
  };
  if(!("color_stats" in scaleData)) {
    colorScaleProps.sp_box_text = null;
  } else {
    var color_box_text = [];
    for(var i = 0; i < scaleData.color_stats.length; i++){
      color_box_text.push(scaleData.color_stats[i][1] + "%");
    }
    colorScaleProps.sp_box_text = color_box_text;
    if("color_box_text_color" in scaleData){
      colorScaleProps.sp_box_text_color = scaleData.color_box_text_color[0]
    } else {
      colorScaleProps.sp_box_text_color = "rgb(255,255,255)";
    }
  }

  makeScale(colorScaleProps);

  var sizeScaleProps = {};
  // properties that define the scale
  sizeScaleProps.sp_tick_font_size = fontSize;
  sizeScaleProps.sp_xoff           = 9;	// will work up to 999
  sizeScaleProps.sp_width          = 75;
  sizeScaleProps.sp_height         = 15;
  sizeScaleProps.sp_tick_len       = 5;
  sizeScaleProps.sp_xHeight        = Math.round(0.7 * sizeScaleProps.sp_tick_font_size);
  sizeScaleProps.sp_yoff           = sizeScaleProps.sp_tick_font_size + 2;
  sizeScaleProps.sp_tick_yoff      = sizeScaleProps.sp_yoff + sizeScaleProps.sp_height;
  sizeScaleProps.sp_tick_text_yoff = sizeScaleProps.sp_tick_yoff + sizeScaleProps.sp_tick_len + sizeScaleProps.sp_xHeight;

  // properties that provide the scale data
  sizeScaleProps.sp_divId = "#sizeScale";
  sizeScaleProps.sp_svgId = "#svgSizeScale";
  sizeScaleProps.sp_values = scaleData.size_values;
  var size_sp_breaks = scaleData.size_breaks;
  sizeScaleProps.sp_breaks_idx_off = 1;
  if (("size_min_value" in scaleData) || ("size_max_value" in scaleData)) {
    size_sp_breaks = [];
    if ("size_min_value" in scaleData) {
      size_sp_breaks.push(Math.floor(scaleData.size_min_value[0]));
      sizeScaleProps.sp_breaks_idx_off = 0;
    }
    for(var i = 0; i < scaleData.size_breaks.length; i++)
      size_sp_breaks.push(scaleData.size_breaks[i]);
    if ("size_max_value" in scaleData) {
      var size_max_value = Math.ceil(scaleData.size_max_value[0]);
      var size_breaks_max_value = scaleData.size_breaks[scaleData.size_breaks.length - 1];
      size_sp_breaks.push(size_max_value > size_breaks_max_value ? size_max_value : size_breaks_max_value);
    }
  }
  sizeScaleProps.sp_breaks = size_sp_breaks;
  sizeScaleProps.sp_title = ("size_title" in scaleData) ? scaleData.size_title : ["Pin Sizes"];
  sizeScaleProps.sp_fill_boxes_func = function(d, i) {
    return "white";
  }
  if(!("size_stats" in scaleData)) {
    sizeScaleProps.sp_box_text = scaleData.size_values;
  } else {
    sizeScaleProps.sp_box_text = scaleData.size_values;
    var size_box_text = [];
    for(var i = 0; i < scaleData.size_stats.length; i++){
      size_box_text.push(scaleData.size_values[i] + ", " + scaleData.size_stats[i][1] + "%"); 
    }
    sizeScaleProps.sp_box_text = size_box_text;
  }
  sizeScaleProps.sp_box_text_color = "black";

  makeScale(sizeScaleProps);
}
