function makeColorScale(scaleData, scaleProps) {

  // Add the svg 
  d3.select(scaleProps.sp_divId)
    .append("svg")
    .attr("id", "svgColorScale")
    .attr("height", 50)
    .attr("width", scaleData.color_values.length * scaleProps.sp_width + 2 * scaleProps.sp_xoff);

  // Draw the colored boxes
  d3.select(scaleProps.sp_svgId)
    .selectAll("rect")
    .data(scaleData.color_values)
    .enter()
    .append("rect")
    .attr("width", scaleProps.sp_width)
    .attr("height", scaleProps.sp_height)
    .attr("x", function(d, i) { return i * scaleProps.sp_width + scaleProps.sp_xoff; })
    .attr("y", scaleProps.sp_yoff)
    .style("fill", function(d) {
      return "rgb(" + Math.round(d[0]*255) + "," + Math.round(d[1]*255) + "," + Math.round(d[2]*255) + ")";
    })
    .style("stroke", "black")
    .style("stroke-width", "1px");

  // Put the size values in the boxes (v2 only)












  // Draw the ticks
  d3.select(scaleProps.sp_svgId)
    .selectAll("line")
    .data(scaleData.color_breaks)
    .enter()
    .append("line")
    .attr("x1", function(d, i) { return (i+1) * scaleProps.sp_width + scaleProps.sp_xoff; })
    .attr("y1", scaleProps.sp_tick_yoff)
    .attr("x2", function(d, i) { return (i+1) * scaleProps.sp_width + scaleProps.sp_xoff; })
    .attr("y2", scaleProps.sp_tick_yoff + scaleProps.sp_tick_len)
    .style("stroke", "black")
    .style("stroke-width", "1px");

  // Draw the tick labels
  d3.select(scaleProps.sp_svgId)
    .selectAll("text.tick")
    .data(scaleData.color_breaks)
    .enter()
    .append("text")
    .attr("class", "tick")
    .attr("x", function(d, i) { return (i+1) * scaleProps.sp_width + scaleProps.sp_xoff; })
    .attr("y", scaleProps.sp_tick_text_yoff)
    .attr("font-size", scaleProps.sp_tick_font_size)
    .attr("text-anchor", "middle")
    .text(function(d) { return d; });

  // Draw the scale title
  var color_title = ("color_title" in scaleData) ? scaleData.color_title : ["Pin Colors"];
  d3.select(scaleProps.sp_svgId)
    .selectAll("text.title")
    .data(color_title)
    .enter()
    .append("text")
    .attr("class", "title")
    .attr("x", 0.5 * (scaleData.color_values.length * scaleProps.sp_width) + scaleProps.sp_xoff)
    .attr("y", scaleProps.sp_xHeight + 2)
    .attr("font-size", scaleProps.sp_tick_font_size)
    .attr("text-anchor", "middle")
    .text(function(d) { return d; });
}
