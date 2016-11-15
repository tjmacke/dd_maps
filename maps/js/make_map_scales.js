function makeMapScales(scaleData) {

  if("data_stats" in scaleData) {
    document.getElementById("dataStats").innerHTML = "Stats: " + scaleData.data_stats;
  }

  var colorScaleProps = {}
  // properties that define the scale
  colorScaleProps.sp_tick_font_size = 12;
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
  colorScaleProps.sp_breaks = scaleData.color_breaks;
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

  var v2ScaleProps = {};
  // properties that define the scale
  v2ScaleProps.sp_tick_font_size = 12;
  v2ScaleProps.sp_xoff           = 5;
  v2ScaleProps.sp_width          = 75;
  v2ScaleProps.sp_height         = 15;
  v2ScaleProps.sp_tick_len       = 5;
  v2ScaleProps.sp_xHeight        = Math.round(0.7 * v2ScaleProps.sp_tick_font_size);
  v2ScaleProps.sp_yoff           = v2ScaleProps.sp_tick_font_size + 2;
  v2ScaleProps.sp_tick_yoff      = v2ScaleProps.sp_yoff + v2ScaleProps.sp_height;
  v2ScaleProps.sp_tick_text_yoff = v2ScaleProps.sp_tick_yoff + v2ScaleProps.sp_tick_len + v2ScaleProps.sp_xHeight;

  // properties that provide the scale data
  v2ScaleProps.sp_divId = "#v2Scale";
  v2ScaleProps.sp_svgId = "#svgV2Scale";
  v2ScaleProps.sp_values = scaleData.v2_values;
  v2ScaleProps.sp_breaks = scaleData.v2_breaks;
  v2ScaleProps.sp_title = ("v2_title" in scaleData) ? scaleData.v2_title : ["Pin Sizes"];
  v2ScaleProps.sp_fill_boxes_func = function(d, i) {
    return "white";
  }
  if(!("v2_stats" in scaleData)) {
    v2ScaleProps.sp_box_text = scaleData.v2_values;
  } else {
    v2ScaleProps.sp_box_text = scaleData.v2_values;
    var v2_box_text = [];
    for(var i = 0; i < scaleData.v2_stats.length; i++){
      v2_box_text.push(scaleData.v2_values[i] + ", " + scaleData.v2_stats[i][1] + "%"); 
    }
    v2ScaleProps.sp_box_text = v2_box_text;
  }
  v2ScaleProps.sp_box_text_color = "black";

  makeScale(v2ScaleProps);
}
