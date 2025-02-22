function format_number(num) {
  if (num > 10000) {
    return `${Math.floor(num / 1000)}k`;
  } else if (num >= 1000) {
    return `${Math.floor(num / 100) / 10}k`;
  } else {
    return `${num}`;
  }
}

export class Grapher {
  default_opts = {
    label: "Count",
    min_y: 10,
    x_ticks: 10,
    fit_dots: false,
    days_per_unit: 1
  }

  margin_left = 50;
  margin_bottom = 30;
  margin_right = 30;
  margin_top = 5;

  dot_hitbox_w = 30;
  dot_hitbox_h = 120;

  axis_spacing = 8;
  axis_graph_padding = 10;

  constructor(el, data, opts) {
    this.el = $(el);
    this.data = data;
    this.opts = Object.assign({}, this.default_opts, opts);
    this.draw();
  }

  draw() {
    this.w = this.el.width();
    this.h = this.el.height();

    this.time_format = d3.timeFormat("%Y-%m-%d");
    this.time_parse = d3.timeParse("%Y-%m-%d");

    this.svg = d3.select(this.el[0])
      .append("svg")
      .attr("class", "chart")
      .attr("width", this.w)
      .attr("height", this.h);

    const data = this.format_data();
    const x = this._x_scale = this.x_scale(data);
    const y = this._y_scale = this.y_scale(data);

    // y guides
    this.svg.append("g")
      .attr("class", "y_guides")
      .selectAll("line").data(y.ticks(this.y_ticks())).enter()
        .append("line")
        .attr("x1", x.range()[0])
        .attr("y1", y)
        .attr("x2", x.range()[1])
        .attr("y2", y);

    // x guides
    this.svg.append("g")
      .attr("class", "x_guides")
      .selectAll("line").data(x.ticks(this.x_ticks())).enter()
        .append("line")
        .attr("x1", x)
        .attr("y1", y.range()[0])
        .attr("x2", x)
        .attr("y2", y.range()[1]);

    // area
    const area = d3.area()
      .x(this.get_x_scaled)
      .y1(this.get_y_scaled)
      .y0(this.h - this.margin_bottom);

    this.svg.append("g")
      .attr("class", "graph")
      .append("path")
      .attr("d", area(data));

    // y axis
    const y_axis = d3.axisLeft().scale(y)
      .tickFormat(this.format_y_axis)
      .ticks(this.y_ticks());

    this.svg.append("g")
      .attr("transform", `translate(${x.range()[0] - this.axis_spacing}, 0)`)
      .attr("class", "y_axis axis")
      .call(y_axis);

    // y axis
    const x_axis = d3.axisBottom().scale(x).ticks(this.x_ticks());
    this.svg.append("g")
      .attr("transform", `translate(0, ${y.range()[0] + this.axis_spacing})`)
      .attr("class", "x_axis axis")
      .call(x_axis);

    this.draw_dots(data);
  }

  draw_dots(data) {
    data = this.filter_dots_data(data);

    if (this.opts.num_days > 60 || this.opts.no_dots) {
      return;
    }

    const dots = this.svg.append("g")
      .attr("class", "dots")
      .selectAll("g").data(data).enter();

    dots.append("circle").attr("cx", this.get_x_scaled).attr("cy", this.get_y_scaled).attr("r", 4);

    if (this.opts.label_dots) {
      // label
      const label = this.svg.append("g")
        .attr("class", "label dots")
        .attr("transform", `translate(${this.margin_left}, 25)`);

      label.append("circle").attr("cx", 0).attr("cy", -5).attr("r", 4);

      label.append("text").text(this.opts.label).attr("x", 10);
    }
  }

  filter_dots_data(data) {
    if (this.opts.fit_dots) {
      const real_w = this.w - this.margin_left - this.margin_right - this.axis_graph_padding;
      const can_fit = Math.floor(real_w / this.dot_hitbox_w);
      if (data.length > can_fit) {
        // this isn't exact because hitboxes go out of graph but oh well
        const dots_to_fit = Math.floor((real_w - this.dot_hitbox_w * 2) / this.dot_hitbox_w);
        const take_every = Math.floor((data.length - 2) / dots_to_fit);

        const subset = data
          .slice(1, data.length - 1)
          .filter((_, i) => i % take_every === 0);

        subset.push(data[data.length - 1]);
        subset.unshift(data[1]);
        return subset;
      }
    }
    return data;
  }

  get_x = (d) => {
    return this.time_parse(d.date);
  }

  get_y = (d) => {
    return d.count;
  }
get_x_scaled = (...args) => {
    return this._x_scale(this.get_x(...args));
  }

  get_y_scaled = (...args) => {
    return this._y_scale(this.get_y(...args));
  }

  format_y_axis = (num) => {
    return format_number(num);
  }

  x_ticks() {
    return this.opts.x_ticks;
  }

  y_ticks() {
    return Math.min(5, this.opts.min_y);
  }

  get_range() {
    const today = d3.timeDay(new Date());
    const offset = this.opts.day_offset || 0;

    const left = d3.timeDay.offset(today, -(this.opts.num_days + offset - 1));
    const right = d3.timeDay.offset(today, -offset);

    return [left, right];
  }

  // map range 1 day at a time
  map_range(fn) {
    const [left, right] = this.get_range();

    let t = left;
    const results = [];
    while (t <= right) {
      results.push(fn(t));
      t = d3.timeDay.offset(t, this.opts.days_per_unit);
    }
    return results;
  }

  format_data() {
    const counts_by_date = this.data.reduce((acc, v) => {
      acc[v.date] = v;
      return acc;
    }, {});

    return this.map_range((t) => {
      const formatted = this.time_format(t);
      return counts_by_date[formatted] || {
        count: 0,
        date: formatted
      };
    });
  }

  x_scale(data) {
    const [left, right] = this.get_range();
    return d3.scaleTime()
      .domain([left, right])
      .rangeRound([this.margin_left + this.axis_graph_padding, this.w - this.margin_right]);
  }

  y_scale(data) {
    const max = d3.max(data, this.get_y);
    return d3.scaleLinear()
      .domain([0, Math.max(Math.floor(max * 1.3) || 0, this.opts.min_y)])
      .rangeRound([this.h - this.margin_bottom, this.margin_top]);
  }
}


export class RangeGrapher extends Grapher {
  // get thne range from the data, with a minimum range
  get_range() {
    const format = d3.timeParse("%Y-%m-%d");

    let first = format(this.data[0].date);
    const last = format(this.data[this.data.length - 1].date);

    const min_range = this.opts.min_range || 7;
    const range_ago = d3.timeDay.offset(last, -min_range);

    if (range_ago < first) {
      first = range_ago;
    }

    return [first, last];
  }
}

export class CumulativeGrapher extends RangeGrapher {
  default_opts = {
    min_y: 100,
    x_ticks: 8,
    fit_dots: true,
    min_range: 7, // min number of days
    days_per_unit: 1
  }

  format_data() {
    const by_date = this.data.reduce((acc, v) => {
      acc[v.date] = v;
      return acc;
    }, {});

    let last = 0;
    return this.map_range((t) => {
      const formatted = this.time_format(t);
      last = by_date[formatted]?.count || last;
      return {
        count: last,
        date: formatted
      };
    });
  }
}

