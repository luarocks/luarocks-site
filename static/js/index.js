
import {Grapher} from "./grapher";

export class IndexPage {
  constructor(el, {downloads_daily}) {
    this.el = $(el);
    new Grapher("#downloads_graph", downloads_daily, {
      label: "Views",
      num_days: 30,
      x_ticks: 7
    });
  }
}
