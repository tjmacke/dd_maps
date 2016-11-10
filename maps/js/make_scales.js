function makeScales(scaleData) {

  var colorScaleConfig = {}
  colorScaleConfig.sc_tick_font_size = 12;
  colorScaleConfig.sc_xoff           = 5;
  colorScaleConfig.sc_width          = 40;
  colorScaleConfig.sc_height         = 15;
  colorScaleConfig.sc_tick_len       = 5;
  colorScaleConfig.sc_xHeight        = Math.round(0.7 * colorScaleConfig.sc_tick_font_size);
  colorScaleConfig.sc_yoff           = colorScaleConfig.sc_tick_font_size + 2;
  colorScaleConfig.sc_tick_yoff      = colorScaleConfig.sc_yoff + colorScaleConfig.sc_height;
  colorScaleConfig.sc_tick_text_yoff = colorScaleConfig.sc_tick_yoff + colorScaleConfig.sc_tick_len + colorScaleConfig.sc_xHeight;
  makeColorScale(scaleData, colorScaleConfig);

  var v2ScaleConfig = {};
  v2ScaleConfig.sc_tick_font_size = 12;
  v2ScaleConfig.sc_xoff           = 5;
  v2ScaleConfig.sc_width          = 70;
  v2ScaleConfig.sc_height         = 15;
  v2ScaleConfig.sc_tick_len       = 5;
  v2ScaleConfig.sc_xHeight        = Math.round(0.7 * v2ScaleConfig.sc_tick_font_size);
  v2ScaleConfig.sc_yoff           = v2ScaleConfig.sc_tick_font_size + 2;
  v2ScaleConfig.sc_tick_yoff      = v2ScaleConfig.sc_yoff + v2ScaleConfig.sc_height;
  v2ScaleConfig.sc_tick_text_yoff = v2ScaleConfig.sc_tick_yoff + v2ScaleConfig.sc_tick_len + v2ScaleConfig.sc_xHeight;
  makeV2Scale(scaleData, v2ScaleConfig);
}

function makeColorScale(scaleData, scaleConfig) {

  // Add the svg 
  d3.select("#colorScale")
    .append("svg")
    .attr("id", "svgColorScale")
    .attr("height", 50)
    .attr("width", scaleData.color_values.length * scaleConfig.sc_width + 2 * scaleConfig.sc_xoff);

  // Draw the colored boxes
  d3.select("#svgColorScale")
    .selectAll("rect")
    .data(scaleData.color_values)
    .enter()
    .append("rect")
    .attr("width", scaleConfig.sc_width)
    .attr("height", scaleConfig.sc_height)
    .attr("x", function(d, i) { return i * scaleConfig.sc_width + scaleConfig.sc_xoff; })
    .attr("y", scaleConfig.sc_yoff)
    .style("fill", function(d) {
      return "rgb(" + Math.round(d[0]*255) + "," + Math.round(d[1]*255) + "," + Math.round(d[2]*255) + ")";
    })
    .style("stroke", "black")
    .style("stroke-width", "1px");

  // Draw the ticks
  d3.select("#svgColorScale")
    .selectAll("line")
    .data(scaleData.color_breaks)
    .enter()
    .append("line")
    .attr("x1", function(d, i) { return (i+1) * scaleConfig.sc_width + scaleConfig.sc_xoff; })
    .attr("y1", scaleConfig.sc_tick_yoff)
    .attr("x2", function(d, i) { return (i+1) * scaleConfig.sc_width + scaleConfig.sc_xoff; })
    .attr("y2", scaleConfig.sc_tick_yoff + scaleConfig.sc_tick_len)
    .style("stroke", "black")
    .style("stroke-width", "1px");

  // Draw the tick labels
  d3.select("#svgColorScale")
    .selectAll("text.tick")
    .data(scaleData.color_breaks)
    .enter()
    .append("text")
    .attr("class", "tick")
    .attr("x", function(d, i) { return (i+1) * scaleConfig.sc_width + scaleConfig.sc_xoff; } )
    .attr("y", scaleConfig.sc_tick_text_yoff)
    .attr("font-size", scaleConfig.sc_tick_font_size)
    .attr("text-anchor", "middle")
    .text(function(d) { return d; });

  // Draw the scale title
  var color_title = ("color_title" in scaleData) ? scaleData.color_title : ["Pin Colors"];
  d3.select("#svgColorScale")
    .selectAll("text.title")
    .data(color_title)
    .enter()
    .append("text")
    .attr("class", "title")
    .attr("x", 0.5 * (scaleData.color_values.length * scaleConfig.sc_width) + scaleConfig.sc_xoff)
    .attr("y", scaleConfig.sc_xHeight + 2)
    .attr("font-size", scaleConfig.sc_tick_font_size)
    .attr("text-anchor", "middle")
    .text(function(d) { return d; });
}

function makeV2Scale(scaleData, scaleConfig) {

  d3.select("#v2Scale")
    .append("svg")
    .attr("id", "svgV2Scale")
    .attr("height", 50)
    .attr("width", scaleData.v2_values.length * scaleConfig.sc_width + 2 * scaleConfig.sc_xoff);

  // Draw white boxes
  d3.select("#svgV2Scale")
    .selectAll("rect")
    .data(scaleData.v2_values)
    .enter()
    .append("rect")
    .attr("width", scaleConfig.sc_width)
    .attr("height", scaleConfig.sc_height)
    .attr("x", function(d, i) { return i * scaleConfig.sc_width + scaleConfig.sc_xoff; })
    .attr("y", scaleConfig.sc_yoff)
    .style("fill", "white")
    .style("stroke", "black")
    .style("stroke-width", "1px");

  // Put the size values in the boxes
  d3.select("#svgV2Scale")
    .selectAll("text.label")
    .data(scaleData.v2_values)
    .enter()
    .append("text")
    .attr("class", "label")
    .attr("x", function(d, i) { return (i + 0.5) * scaleConfig.sc_width + scaleConfig.sc_xoff; })
    .attr("y", scaleConfig.sc_tick_yoff - 4)
    .attr("font-size", scaleConfig.sc_tick_font_size)
    .attr("text-anchor", "middle")
    .text(function(d) { return d; });

  // Draw the ticks
  d3.select("#svgV2Scale")
    .selectAll("line")
    .data(scaleData.v2_breaks)
    .enter()
    .append("line")
    .attr("x1", function(d, i) { return (i+1) * scaleConfig.sc_width + scaleConfig.sc_xoff; })
    .attr("y1", scaleConfig.sc_tick_yoff)
    .attr("x2", function(d, i) { return (i+1) * scaleConfig.sc_width + scaleConfig.sc_xoff; })
    .attr("y2", scaleConfig.sc_tick_yoff + scaleConfig.sc_tick_len)
    .style("stroke", "black")
    .style("stroke-width", "1px");

  // Draw the tick labels
  d3.select("#svgV2Scale")
    .selectAll("text.tick")
    .data(scaleData.v2_breaks)
    .enter()
    .append("text")
    .attr("class", "tick")
    .attr("x", function(d, i) { return (i+1) * scaleConfig.sc_width + scaleConfig.sc_xoff; })
    .attr("y", scaleConfig.sc_tick_text_yoff)
    .attr("font-size", scaleConfig.sc_tick_font_size)
    .attr("text-anchor", "middle")
    .text(function(d) { return d; });

  // Draw the scale title
  var v2_title = ("v2_title" in scaleData) ? scaleData.v2_title : ["Pin Sizes"];
  d3.select("#svgV2Scale")
    .selectAll("text.title")
    .data(v2_title)
    .enter()
    .append("text")
    .attr("class", "title")
    .attr("x", 0.5 * (scaleData.v2_values.length * scaleConfig.sc_width) + scaleConfig.sc_xoff)
    .attr("y", scaleConfig.sc_xHeight + 2)
    .attr("font-size", scaleConfig.sc_tick_font_size)
    .attr("text-anchor", "middle")
    .text(function(d) { return d; });
}
