const Clipboard = {
  mounted() {
    document.addEventListener("copy", (event: ClipboardEvent) => {
      const selected = document.querySelectorAll<HTMLElement>(
        ".philtre__editor [data-selected]"
      );
      if (selected.length > 0) {
        this.pushEventTo(this.getTarget(), "copy_blocks", {
          block_ids: Array.from(selected).map((el) => el.dataset.blockId),
        });
        event.preventDefault();
      }
    });
  },

  updated() {},

  getTarget(): string {
    return this.el.getAttribute("phx-target");
  },
};

export default Clipboard;
