function makeV2Scale(scaleData, scaleProps) {

  // Add the svg
  d3.select("#v2Scale")
    .append("svg")
    .attr("id", "svgV2Scale")
    .attr("height", 50)
    .attr("width", scaleData.v2_values.length * scaleProps.sp_width + 2 * scaleProps.sp_xoff);

  // Draw white boxes
  d3.select("#svgV2Scale")
    .selectAll("rect")
    .data(scaleData.v2_values)
    .enter()
    .append("rect")
    .attr("width", scaleProps.sp_width)
    .attr("height", scaleProps.sp_height)
    .attr("x", function(d, i) { return i * scaleProps.sp_width + scaleProps.sp_xoff; })
    .attr("y", scaleProps.sp_yoff)
    .style("fill", "white")	// uses a function for color


    .style("stroke", "black")
    .style("stroke-width", "1px");

  // Put the size values in the boxes
  d3.select("#svgV2Scale")
    .selectAll("text.label")
    .data(scaleData.v2_values)
    .enter()
    .append("text")
    .attr("class", "label")
    .attr("x", function(d, i) { return (i + 0.5) * scaleProps.sp_width + scaleProps.sp_xoff; })
    .attr("y", scaleProps.sp_tick_yoff - 4)
    .attr("font-size", scaleProps.sp_tick_font_size)
    .attr("text-anchor", "middle")
    .text(function(d) { return d; });

  // Draw the ticks
  d3.select("#svgV2Scale")
    .selectAll("line")
    .data(scaleData.v2_breaks)
    .enter()
    .append("line")
    .attr("x1", function(d, i) { return (i+1) * scaleProps.sp_width + scaleProps.sp_xoff; })
    .attr("y1", scaleProps.sp_tick_yoff)
    .attr("x2", function(d, i) { return (i+1) * scaleProps.sp_width + scaleProps.sp_xoff; })
    .attr("y2", scaleProps.sp_tick_yoff + scaleProps.sp_tick_len)
    .style("stroke", "black")
    .style("stroke-width", "1px");

  // Draw the tick labels
  d3.select("#svgV2Scale")
    .selectAll("text.tick")
    .data(scaleData.v2_breaks)
    .enter()
    .append("text")
    .attr("class", "tick")
    .attr("x", function(d, i) { return (i+1) * scaleProps.sp_width + scaleProps.sp_xoff; })
    .attr("y", scaleProps.sp_tick_text_yoff)
    .attr("font-size", scaleProps.sp_tick_font_size)
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
    .attr("x", 0.5 * (scaleData.v2_values.length * scaleProps.sp_width) + scaleProps.sp_xoff)
    .attr("y", scaleProps.sp_xHeight + 2)
    .attr("font-size", scaleProps.sp_tick_font_size)
    .attr("text-anchor", "middle")
    .text(function(d) { return d; });
}
