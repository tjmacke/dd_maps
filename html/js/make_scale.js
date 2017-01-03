function makeScale(scaleProps) {

  // remove old graph and release the refs
  var svg = d3.select(scaleProps.sp_divId).selectAll("svg");
  svg = svg.remove();

  // Add the svg
  d3.select(scaleProps.sp_divId)
    .append("svg")
    .attr("id", scaleProps.sp_svgId.substring(1))	// skip over the initial #
    .attr("height", 50)
    .attr("width", scaleProps.sp_values.length * scaleProps.sp_width + 2 * scaleProps.sp_xoff);

  // Draw the boxes
  d3.select(scaleProps.sp_svgId)
    .selectAll("rect")
    .data(scaleProps.sp_values)
    .enter()
    .append("rect")
    .attr("width", scaleProps.sp_width)
    .attr("height", scaleProps.sp_height)
    .attr("x", function(d, i) { return i * scaleProps.sp_width + scaleProps.sp_xoff; })
    .attr("y", scaleProps.sp_yoff)
    .style("fill", scaleProps.sp_fill_boxes_func)
    .style("stroke", "black")
    .style("stroke-width", "1px");

  // Add any box text
  if(scaleProps.sp_box_text != null){
    d3.select(scaleProps.sp_svgId)
      .selectAll("text.label")
      .data(scaleProps.sp_box_text)
      .enter()
      .append("text")
      .attr("class", "label")
      .attr("x", function(d, i) { return (i + 0.5) * scaleProps.sp_width + scaleProps.sp_xoff; })
      .attr("y", scaleProps.sp_tick_yoff - 4)
      .attr("font-size", scaleProps.sp_tick_font_size)
      .attr("text-anchor", "middle")
      .text(function(d) { return d; })
      .attr("fill", scaleProps.sp_box_text_color);
  }

  // Draw the ticks
  d3.select(scaleProps.sp_svgId)
    .selectAll("line")
    .data(scaleProps.sp_breaks)
    .enter()
    .append("line")
    .attr("x1", function(d, i) { return (i+scaleProps.sp_breaks_idx_off) * scaleProps.sp_width + scaleProps.sp_xoff; })
    .attr("y1", scaleProps.sp_tick_yoff)
    .attr("x2", function(d, i) { return (i+scaleProps.sp_breaks_idx_off) * scaleProps.sp_width + scaleProps.sp_xoff; })
    .attr("y2", scaleProps.sp_tick_yoff + scaleProps.sp_tick_len)
    .style("stroke", "black")
    .style("stroke-width", "1px");

  // Draw the tick labels
  d3.select(scaleProps.sp_svgId)
    .selectAll("text.tick")
    .data(scaleProps.sp_breaks)
    .enter()
    .append("text")
    .attr("class", "tick")
    .attr("x", function(d, i) { return (i+scaleProps.sp_breaks_idx_off) * scaleProps.sp_width + scaleProps.sp_xoff; })
    .attr("y", scaleProps.sp_tick_text_yoff)
    .attr("font-size", scaleProps.sp_tick_font_size)
    .attr("text-anchor", "middle")
    .text(function(d) { return d; });

  // Draw the scale title
  d3.select(scaleProps.sp_svgId)
    .selectAll("text.title")
    .data(scaleProps.sp_title)
    .enter()
    .append("text")
    .attr("class", "title")
    .attr("x", 0.5 * (scaleProps.sp_values.length * scaleProps.sp_width) + scaleProps.sp_xoff)
    .attr("y", scaleProps.sp_xHeight + 2)
    .attr("font-size", scaleProps.sp_tick_font_size)
    .attr("text-anchor", "middle")
    .text(function(d) { return d; });
}
