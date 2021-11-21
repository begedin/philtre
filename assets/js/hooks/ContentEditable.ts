const ContentEditable = {
  mounted() {
    const el: HTMLElement = this.el;
    el.style.whiteSpace = "pre-wrap";
    el.style.wordBreak = "break-word";

    el.addEventListener("input", () => {
      const selection = window.getSelection();
      const oldIndex = selection.focusOffset;
      const oldNode = selection.focusNode;

      this.pushEventTo(
        this.getTarget(),

        "update_block",
        {
          value: el.innerHTML,
          block_id: el.dataset.blockId,
        },
        () => {
          if (selection.focusOffset === oldIndex) {
            return;
          }
          const index =
            oldIndex > el.innerText.length ? el.innerText.length : oldIndex;

          selection.setPosition(oldNode, index);
        }
      );
    });

    el.addEventListener("keydown", (event: KeyboardEvent) => {
      if (event.key === "Backspace") {
        const selection = window.getSelection();
        if (selection.focusOffset === 0) {
          event.preventDefault();
          this.pushEventTo(this.getTarget(), "downgrade_block", {
            block_id: el.dataset.blockId,
          });
        }
      }
    });

    el.addEventListener("keypress", (event: KeyboardEvent) => {
      if (event.key === "Enter") {
        event.preventDefault();

        this.pushEventTo(this.getTarget(), "add_block_after", {
          block_id: el.dataset.blockId,
        });
      }
    });

    el.focus();
  },

  updated() {},

  getTarget(): string {
    return this.el.getAttribute("phx-target");
  },
};

export default ContentEditable;
