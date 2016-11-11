function makeScales(scaleData) {

  var colorScaleProps = {}
  colorScaleProps.sp_tick_font_size = 12;
  colorScaleProps.sp_xoff           = 5;
  colorScaleProps.sp_width          = 40;
  colorScaleProps.sp_height         = 15;
  colorScaleProps.sp_tick_len       = 5;
  colorScaleProps.sp_xHeight        = Math.round(0.7 * colorScaleProps.sp_tick_font_size);
  colorScaleProps.sp_yoff           = colorScaleProps.sp_tick_font_size + 2;
  colorScaleProps.sp_tick_yoff      = colorScaleProps.sp_yoff + colorScaleProps.sp_height;
  colorScaleProps.sp_tick_text_yoff = colorScaleProps.sp_tick_yoff + colorScaleProps.sp_tick_len + colorScaleProps.sp_xHeight;
  makeColorScale(scaleData, colorScaleProps);

  var v2ScaleProps = {};
  v2ScaleProps.sp_tick_font_size = 12;
  v2ScaleProps.sp_xoff           = 5;
  v2ScaleProps.sp_width          = 70;
  v2ScaleProps.sp_height         = 15;
  v2ScaleProps.sp_tick_len       = 5;
  v2ScaleProps.sp_xHeight        = Math.round(0.7 * v2ScaleProps.sp_tick_font_size);
  v2ScaleProps.sp_yoff           = v2ScaleProps.sp_tick_font_size + 2;
  v2ScaleProps.sp_tick_yoff      = v2ScaleProps.sp_yoff + v2ScaleProps.sp_height;
  v2ScaleProps.sp_tick_text_yoff = v2ScaleProps.sp_tick_yoff + v2ScaleProps.sp_tick_len + v2ScaleProps.sp_xHeight;
  makeV2Scale(scaleData, v2ScaleProps);
}
