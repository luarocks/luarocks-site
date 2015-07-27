window.M ||= {}

class M.Index
  constructor: (el, downloads_daily) ->
    @el = $ el
    new M.Grapher "#downloads_graph", downloads_daily, {
      label: "Views"
      num_days: 30
      x_ticks: 7
    }

class M.Stats
  constructor: (el, @opts) ->
    @el = $ el

    new M.CumulativeGrapher "#cumulative_modules", @opts.graphs.cumulative_modules, {
      label: "Cumulative modules"
      no_dots: true
      days_per_unit: 7
    }

    new M.CumulativeGrapher "#cumulative_users", @opts.graphs.cumulative_users, {
      label: "Cumulative users"
      no_dots: true
      days_per_unit: 7
    }

    new M.CumulativeGrapher "#cumulative_versions", @opts.graphs.cumulative_versions, {
      label: "Cumulative versions"
      no_dots: true
      days_per_unit: 7
    }




class M.Grapher
  @format_number: format_number = (num) ->
    if num > 10000
      "#{Math.floor(num / 1000)}k"
    else if num >= 1000
      "#{Math.floor(num / 100) / 10}k"
    else
      "#{num}"

  margin_left: 50
  margin_bottom: 30
  margin_right: 30
  margin_top: 5

  dot_hitbox_w: 30
  dot_hitbox_h: 120

  axis_spacing: 8
  axis_graph_padding: 10

  default_opts: {
    label: "Count"
    min_y: 10
    x_ticks: 10
    fit_dots: false
    days_per_unit: 1
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
    data = @filter_dots_data data

    return if @opts.num_days > 60 || @opts.no_dots

    dots = @svg.append("g")
      .attr("class", "dots")
      .selectAll("g").data(data)
        .enter()

    dots
      .append("circle")
      .attr("cx", @get_x_scaled)
      .attr("cy", @get_y_scaled)
      .attr("r", 4)

    if @opts.label_dots
      # label
      label = @svg.append("g")
       .attr("class", "label dots")
       .attr("transform", "translate(#{@margin_left}, 25)")

      label.append("circle")
       .attr("cx", 0)
       .attr("cy", -5)
       .attr("r", 4)

      label.append("text")
       .text(@opts.label)
       .attr("x", 10)


  filter_dots_data: (data) ->
    if @opts.fit_dots
      real_w = @w - @margin_left - @margin_right - @axis_graph_padding
      can_fit = Math.floor real_w / @dot_hitbox_w
      if data.length > can_fit
        # this isn't exact because hitboxes go out of graph but oh well
        dots_to_fit = Math.floor (real_w - @dot_hitbox_w*2) / @dot_hitbox_w
        take_every = Math.floor (data.length - 2) / dots_to_fit
        subset = for i in [1..data.length-2] by take_every
          data[i]

        subset.push data[data.length - 1]
        subset.unshift data[1]
        return subset

    data

  popup_label: (d) ->
    "#{@opts.label}: #{d.count}"

  get_x: (d) => @time_format.parse d.date
  get_y: (d) => d.count

  get_x_scaled: => @_x_scale @get_x arguments...
  get_y_scaled: => @_y_scale @get_y arguments...

  format_y_axis: (num) => M.Grapher.format_number num

  x_ticks: -> @opts.x_ticks
  y_ticks: -> Math.min 5, @opts.min_y

  get_range: =>
    today = d3.time.day new Date
    offset = @opts.day_offset || 0

    left = d3.time.day.offset today, -(@opts.num_days + offset - 1)
    right = d3.time.day.offset today, -(offset)

    [left, right]

  # map range 1 day at a time
  map_range: (fn) ->
    [left, right] = @get_range()

    t = left
    while t <= right
      val = fn t
      t = d3.time.day.offset t, @opts.days_per_unit
      val

  format_data: ->
    counts_by_date = {}
    for v in @data
      counts_by_date[v.date] = v

    @map_range (t) =>
      formatted = @time_format t
      counts_by_date[formatted] || {
        count: 0
        date: formatted
      }

  x_scale: (data) ->
    [left, right] = @get_range()

    d3.time.scale()
      .domain([left, right])
      .rangeRound([@margin_left + @axis_graph_padding, @w - @margin_right])

  y_scale: (data) ->
    max = d3.max data, @get_y

    d3.scale.linear()
      .domain([0, Math.max Math.floor(max*1.3) || 0, @opts.min_y])
      .rangeRound([@h - @margin_bottom, @margin_top])

class M.RangeGrapher extends M.Grapher
  # get the range from the dates provided
  get_range: =>
    format = d3.time.format "%Y-%m-%d"

    first = @data[0]
    last = @data[@data.length - 1]

    first = format.parse first.date
    last = format.parse last.date

    min_range = @opts.min_range || 7

    range_ago = d3.time.day.offset last, -min_range

    if range_ago < first
      first = range_ago

    [first, last]

class M.CumulativeGrapher extends M.RangeGrapher
  default_opts: {
    min_y: 100
    x_ticks: 8
    fit_dots: true
    min_range: 7 # min number of days
    days_per_unit: 1
  }

  get_y: (d) => d.count

  format_data: ->
    by_date = {}
    for v in @data
      by_date[v.date] = v

    last = 0
    @map_range (t) =>
      formatted = @time_format t
      last = by_date[formatted]?.count || last

      {
        count: last
        date: formatted
      }



