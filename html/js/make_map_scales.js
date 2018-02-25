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
  // TODO: Deal with missing "main" scale
  if ("main" in scaleData) {
    var msp = scaleData["main"];
    mainScaleProps.sp_values = msp.values;
    var main_sp_breaks = msp.breaks;
    mainScaleProps.sp_breaks_idx_off = 1;
    if (("min_value" in msp) || ("max_value" in msp)) {
      main_sp_breaks = [];
      if ("min_value" in msp) {
        main_sp_breaks.push(Math.floor(msp.min_value[0]));
        mainScaleProps.sp_breaks_idx_off = 0;
      }
      for(var i = 0; i < msp.breaks.length; i++)
        main_sp_breaks.push(msp.breaks[i]);
      if ("max_value" in msp) {
        var main_max_value = Math.ceil(msp.max_value[0]);
        var main_breaks_max_value = msp.breaks[msp.breaks.length - 1];
        main_sp_breaks.push(main_max_value > main_breaks_max_value ? main_max_value : main_breaks_max_value);
      }
    }
    mainScaleProps.sp_breaks = main_sp_breaks;
    mainScaleProps.sp_title = ("title" in msp) ? msp.title : ["Main Scale"];
    mainScaleProps.sp_fill_boxes_func = function(d, i) {
      return "rgb(" + Math.round(d[0]*255) + "," + Math.round(d[1]*255) + "," + Math.round(d[2]*255) + ")";	// DIFF!
    };
    if("stats" in msp) {
      var main_box_text = [];
      for(var i = 0; i < msp.stats.length; i++) {
        main_box_text.push(msp.stats[i][1] + "%");								// DIFF!
      }
      mainScaleProps.sp_box_text = main_box_text;
      if("box_text_color" in msp){										// DIFF!
        mainScaleProps.sp_box_text_color = msp.box_text_color[0];						// DIFF!
      } else {													// DIFF!
        mainScaleProps.sp_box_text_color = "rgb(255,255,255)";							// DIFF!
      }														// DIFF!
    } else if("keys" in msp) {
      var main_box_text = [];
      for(var i = 0; i < msp.keys.length; i++) {
        main_box_text.push(msp.keys[i]);									// DIFF!
      }
      mainScaleProps.sp_box_text = main_box_text;
    } else {
      mainScaleProps.sp_box_text = null;									// DIFF!
    }
    makeScale(mainScaleProps);
  } else {
    // Clear the div
  }

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
  auxScaleProps.sp_divId = "#auxScale";
  auxScaleProps.sp_svgId = "#svgAuxScale";
  // TODO: deal with missing aux scale
  if ("aux" in scaleData) {
    var asp = scaleData["aux"];
    auxScaleProps.sp_values = asp.values;
    var aux_sp_breaks = asp.breaks;
    auxScaleProps.sp_breaks_idx_off = 1;
    if (("min_value" in asp) || ("max_value" in asp)) {
      aux_sp_breaks = [];
      if ("min_value" in asp) {
        aux_sp_breaks.push(Math.floor(asp.min_value[0]));
        auxScaleProps.sp_breaks_idx_off = 0;
      }
      for(var i = 0; i < asp.breaks.length; i++)
        aux_sp_breaks.push(asp.breaks[i]);
      if ("max_value" in asp) {
        var aux_max_value = Math.ceil(asp.max_value[0]);
        var aux_breaks_max_value = asp.breaks[asp.breaks.length - 1];
        aux_sp_breaks.push(aux_max_value > aux_breaks_max_value ? aux_max_value : aux_breaks_max_value);
      }
    }
    auxScaleProps.sp_breaks = aux_sp_breaks;
    auxScaleProps.sp_title = ("title" in asp) ? asp.title : ["Aux. Scale"];
    auxScaleProps.sp_fill_boxes_func = function(d, i) {
      return "white";											// DIFF!
    }
    if("stats" in asp) {
      auxScaleProps.sp_box_text = scaleData.size_values;
      var aux_box_text = [];
      for(var i = 0; i < asp.stats.length; i++){
        aux_box_text.push(asp.values[i] + ", " + asp.stats[i][1] + "%"); 
      }
      auxScaleProps.sp_box_text = aux_box_text;
    } else if("keys" in asp) {
    } else {
      auxScaleProps.sp_box_text = asp.values;
    }
    auxScaleProps.sp_box_text_color = "black";
    makeScale(auxScaleProps);
  } else {
    // Clear the div
  }
}
