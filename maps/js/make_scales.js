function makeScales(config) {

  // get everything parameterized.
  // color values
  var cv_tick_font_size = 12;
  var cv_xoff = 5;
  var cv_width = 40;
  var cv_height = 15;
  var cv_tick_len = 5
  var cv_xHeight = Math.round(0.7 * cv_tick_font_size);
  var cv_yoff = cv_tick_font_size + 2;
  var cv_tick_yoff = cv_yoff + cv_height
  var cv_tick_text_yoff = cv_tick_yoff + cv_tick_len + cv_xHeight;

  // TODO: check that the scale(s) can be made

  // BEGIN Pin color scale
  // Add the svg 
  d3.select("#colorScale")
    .append("svg")
    .attr("id", "svgColorScale")
    .attr("height", 50)
    .attr("width", config.color_values.length * cv_width + 2 * cv_xoff);

  // Draw the colored boxes
  d3.select("#svgColorScale")
    .selectAll("rect")
    .data(config.color_values)
    .enter()
    .append("rect")
    .attr("width", cv_width)
    .attr("height", cv_height)
    .attr("x", function(d, i) { return i * cv_width + cv_xoff; })
    .attr("y", cv_yoff)
    .style("fill", function(d) {
      return "rgb(" + Math.round(d[0]*255) + "," + Math.round(d[1]*255) + "," + Math.round(d[2]*255) + ")";
    })
    .style("stroke", "black")
    .style("stroke-width", "1px");

  // Draw the ticks
  d3.select("#svgColorScale")
    .selectAll("line")
    .data(config.color_breaks)
    .enter()
    .append("line")
    .attr("x1", function(d, i) { return (i+1) * cv_width + cv_xoff; })
    .attr("y1", cv_tick_yoff)
    .attr("x2", function(d, i) { return (i+1) * cv_width + cv_xoff; })
    .attr("y2", cv_tick_yoff + cv_tick_len)
    .style("stroke", "black")
    .style("stroke-width", "1px");

  // Draw the tick labels
  d3.select("#svgColorScale")
    .selectAll("text.tick")
    .data(config.color_breaks)
    .enter()
    .append("text")
    .attr("class", "tick")
    .attr("x", function(d, i) { return (i+1) * cv_width + cv_xoff; } )
    .attr("y", cv_tick_text_yoff)
    .attr("font-size", cv_tick_font_size)
    .attr("text-anchor", "middle")
    .text(function(d) { return d; });

  // Draw the scale title
  var color_title = ("color_title" in config) ? config.color_title : ["Pin Colors"];
  d3.select("#svgColorScale")
    .selectAll("text.title")
    .data(color_title)
    .enter()
    .append("text")
    .attr("class", "title")
    .attr("x", 0.5 * (config.color_values.length * cv_width) + cv_xoff)
    .attr("y", cv_xHeight + 2)
    .attr("font-size", cv_tick_font_size)
    .attr("text-anchor", "middle")
    .text(function(d) { return d; });
  // END Pin color scale

  // TODO: merge this with cv_*
  var cb_tick_font_size = 12;
  var cb_xoff = 5;
  var cb_width = 70;
  var cb_height = 15;
  var cb_tick_len = 5;
  var cb_xHeight = Math.round(0.7 * cb_tick_font_size);
  var cb_yoff = cb_tick_font_size + 2;
  var cb_tick_yoff = cb_yoff + cb_height;
  var cb_tick_text_yoff = cb_tick_yoff + cb_tick_len + cb_xHeight;

  // BEGIN Pin size scale
  d3.select("#v2Scale")
    .append("svg")
    .attr("id", "svgV2Scale")
    .attr("height", 50)
    .attr("width", config.v2_values.length * cb_width + 2 * cb_xoff);

  // Draw white boxes
  d3.select("#svgV2Scale")
    .selectAll("rect")
    .data(config.v2_values)
    .enter()
    .append("rect")
    .attr("width", cb_width)
    .attr("height", cb_height)
    .attr("x", function(d, i) { return i * cb_width + cb_xoff; })
    .attr("y", cb_yoff)
    .style("fill", "white")
    .style("stroke", "black")
    .style("stroke-width", "1px");

  // Put the size values in the boxes
  d3.select("#svgV2Scale")
    .selectAll("text.label")
    .data(config.v2_values)
    .enter()
    .append("text")
    .attr("class", "label")
    .attr("x", function(d, i) { return (i + 0.5) * cb_width + cb_xoff; })
    .attr("y", cb_tick_yoff - 4)
    .attr("font-size", cb_tick_font_size)
    .attr("text-anchor", "middle")
    .text(function(d) { return d; });

  // Draw the ticks
  d3.select("#svgV2Scale")
    .selectAll("line")
    .data(config.v2_breaks)
    .enter()
    .append("line")
    .attr("x1", function(d, i) { return (i+1) * cb_width + cb_xoff; })
    .attr("y1", cb_tick_yoff)
    .attr("x2", function(d, i) { return (i+1) * cb_width + cb_xoff; })
    .attr("y2", cb_tick_yoff + cb_tick_len)
    .style("stroke", "black")
    .style("stroke-width", "1px");

  // Draw the tick labels
  d3.select("#svgV2Scale")
    .selectAll("text.tick")
    .data(config.v2_breaks)
    .enter()
    .append("text")
    .attr("class", "tick")
    .attr("x", function(d, i) { return (i+1) * cb_width + cb_xoff; })
    .attr("y", cb_tick_text_yoff)
    .attr("font-size", cb_tick_font_size)
    .attr("text-anchor", "middle")
    .text(function(d) { return d; });

  var v2_title = ("v2_title" in config) ? config.v2_title : ["Pin Sizes"];
  d3.select("#svgV2Scale")
    .selectAll("text.title")
    .data(v2_title)
    .enter()
    .append("text")
    .attr("class", "title")
    .attr("x", 0.5 * (config.v2_values.length * cb_width) + cb_xoff)
    .attr("y", cb_xHeight + 2)
    .attr("font-size", cb_tick_font_size)
    .attr("text-anchor", "middle")
    .text(function(d) { return d; });

  // END Pin size scale

}
