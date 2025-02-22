
function slugify(str) {
  return str.replace(/\s+/g, "-")
    .replace(/[^\w_.-]/g, "")
    .replace(/^[_.-]+/, "")
    .replace(/[_.-]+$/, "")
    .toLowerCase()
}

export class EditModulePage {
  constructor(el, opts) {
    this.el = $(el);

    const input = this.el.find(".labels_input");
    const items = input.data("json_value") || [];
    const options = opts.suggested_labels.concat(items).map(x => ({ slug: x }));

    input.selectize({
      items: items,
      options: options,
      delimiter: ',',
      plugins: ['remove_button'],

      persist: false,

      valueField: 'slug',
      labelField: 'slug',

      searchField: ['slug'],
      closeAfterSelect: true,
      create: (tag) => ({ slug: slugify(tag) })
    });
  }
}
