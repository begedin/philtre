const ContentEditable = {
  mounted() {
    console.log("mounted", this.getBlockId(), this.getCellId());
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
          cell_id: this.getCellId(),
          block_id: this.getBlockId(),
          value: el.innerHTML,
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
            cell_id: this.getCellId(),
            block_id: this.getBlockId(),
          });
        }
      }
    });

    el.addEventListener("keypress", (event: KeyboardEvent) => {
      const selection = window.getSelection();
      console.log(selection);

      if (event.key === "Enter") {
        event.preventDefault();

        this.pushEventTo(this.getTarget(), "insert_block", {
          cell_id: this.getCellId(),
          block_id: this.getBlockId(),
          index: selection.focusOffset,
        });
      }
    });

    el.focus();
  },

  updated() {
    console.log("updated", this.getBlockId(), this.getCellId());
    // this.el.focus();
  },

  getTarget(): string {
    return this.el.getAttribute("phx-target");
  },

  getCellId(): string {
    return this.el.dataset.cellId;
  },

  getBlockId(): string {
    return this.el.dataset.blockId;
  },
};

export default ContentEditable;
