import {CumulativeGrapher} from "./grapher";

export class StatsPage {
  constructor(el, opts) {
    this.el = $(el);

    new CumulativeGrapher("#cumulative_modules", opts.graphs.cumulative_modules, {
      label: "Cumulative modules",
      no_dots: true,
      days_per_unit: 7
    });

    new CumulativeGrapher("#cumulative_users", opts.graphs.cumulative_users, {
      label: "Cumulative users",
      no_dots: true,
      days_per_unit: 7
    });

    new CumulativeGrapher("#cumulative_versions", opts.graphs.cumulative_versions, {
      label: "Cumulative versions",
      no_dots: true,
      days_per_unit: 7
    });
  }
}
