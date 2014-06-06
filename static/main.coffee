window.M ||= {}

class M.Index
  constructor: (el, downloads_daily) ->
    @el = $ el
    new M.Grapher "#downloads_graph", downloads_daily, {
      label: "Views"
      num_days: 30
      x_ticks: 7
    }

format_number = (num) ->
  if num > 10000
    "#{Math.floor(num / 1000)}k"
  else if num > 1000
    "#{Math.floor(num / 100) / 10}k"
  else
    "#{num}"

# (C) 2020 itch.io systems
class M.Grapher
  margin_left: 40
  margin_bottom: 30
  margin_right: 5
  margin_top: 20

  axis_spacing: 8

  default_opts: {
    label: "Count"
    min_y: 10
    x_ticks: 10
  }

  constructor: (el, @data, opts) ->
    @el = $ el
    @opts = $.extend {}, @default_opts, opts
    @draw()

  draw: ->
    @w = @el.width()
    @h = @el.height()
    @time_format = d3.time.format "%Y-%m-%d"

    @svg = d3.select(@el[0]).append("svg")
      .attr("class", "chart")
      .attr("width", @w)
      .attr("height", @h)

    data = @format_data()
    x = @_x_scale = @x_scale data
    y = @_y_scale = @y_scale data

    # y guides
    y_guides = @svg.append("g")
      .attr("class", "y_guides")

    y_guides.selectAll("line").data(y.ticks @y_ticks()).enter()
        .append("line")
        .attr("x1", x.range()[0])
        .attr("y1", y)
        .attr("x2", x.range()[1])
        .attr("y2", y)

    # x guides
    @svg.append("g")
      .attr("class", "x_guides")
      .selectAll("line").data(x.ticks @x_ticks()).enter()
        .append("line")
          .attr("x1", x)
          .attr("y1", y.range()[0])
          .attr("x2", x)
          .attr("y2", y.range()[1])

    # area
    area = d3.svg.area()
      .x(@get_x_scaled)
      .y1(@get_y_scaled)
      .y0(@h - @margin_bottom)

    @svg.append("g")
      .attr("class", "graph")
      .append("path")
        .attr("d", area data)

    # y axis
    y_axis = d3.svg.axis().scale(y)
      .orient("left")
      .tickFormat(@format_y_axis)
      .ticks(@y_ticks())

    @svg.append("g")
      .attr("transform", "translate(#{x.range()[0] - @axis_spacing}, 0)")
      .attr("class", "y_axis axis")
      .call y_axis

    # y axis
    x_axis = d3.svg.axis().scale(x)
      .orient("bottom")
      .ticks(@x_ticks())

    @svg.append("g")
      .attr("transform", "translate(0, #{y.range()[0] + @axis_spacing})")
      .attr("class", "x_axis axis")
      .call x_axis

    @draw_dots data

  draw_dots: (data) ->
    # popups
    dots = @svg.append("g")
      .attr("class", "dots")
      .selectAll("g").data(data)
        .enter()

    # dots
    dots
      .append("circle")
      .attr("cx", @get_x_scaled)
      .attr("cy", @get_y_scaled)
      .attr("r", 4)

  popup_label: (d) ->
    "#{@opts.label}: #{d.count}"

  get_x: (d) => @time_format.parse d.date
  get_y: (d) => d.count

  get_x_scaled: => @_x_scale @get_x arguments...
  get_y_scaled: => @_y_scale @get_y arguments...

  format_y_axis: (num) => format_number num

  x_ticks: -> @opts.x_ticks
  y_ticks: -> Math.min 5, @opts.min_y

  format_data: ->
    today = d3.time.day new Date
    ago = d3.time.day.offset today, -(@opts.num_days - 1)

    counts_by_date = {}
    for v in @data
      counts_by_date[v.date] = v

    counts_dense = []
    t = ago
    while t <= today
      formatted = @time_format t
      counts_dense.push counts_by_date[formatted] || {
        count: 0
        date: formatted
      }
      t = d3.time.day.offset t, 1

    counts_dense

  x_scale: (data) ->
    today = d3.time.day new Date
    ago = d3.time.day.offset today, -(@opts.num_days - 1)

    d3.time.scale()
      .domain([ago, today])
      .rangeRound([@margin_left + 10, @w - @margin_right])

  y_scale: (data) ->
    max = d3.max data, @get_y

    d3.scale.linear()
      .domain([0, Math.max Math.floor(max*1.3) || 0, @opts.min_y])
      .rangeRound([@h - @margin_bottom, @margin_top])

