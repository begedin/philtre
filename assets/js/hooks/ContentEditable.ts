const ContentEditable = {
  mounted() {
    const el: HTMLElement = this.el;
    el.style.whiteSpace = 'pre-wrap';
    el.style.wordBreak = 'break-word';

    el.addEventListener('input', () => {
      const selection = window.getSelection();
      const oldIndex = selection.focusOffset;
      const oldNode = selection.focusNode;

      this.pushEventTo(
        this.getTarget(),

        'update_block',
        {
          cell_id: this.getCellId(),
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

    el.addEventListener('keydown', (event: KeyboardEvent) => {
      if (event.key === 'Backspace') {
        const selection = window.getSelection();
        if (selection.focusOffset === 0) {
          event.preventDefault();
          this.pushEventTo(this.getTarget(), 'backspace', {
            cell_id: this.getCellId(),
          });
        }
      }
    });

    el.addEventListener('keypress', (event: KeyboardEvent) => {
      const selection = window.getSelection();

      if (event.key === 'Enter') {
        event.preventDefault();

        this.pushEventTo(this.getTarget(), 'newline', {
          cell_id: this.getCellId(),
          index: selection.focusOffset,
        });
      }
    });

    el.addEventListener('paste', (event: ClipboardEvent) => {
      const selection = window.getSelection();
      event.preventDefault();
      this.pushEventTo(this.getTarget(), 'paste_blocks', {
        cell_id: this.getCellId(),
        index: selection.focusOffset,
      });
    });

    this.resolveFocus();
  },

  updated() {
    this.resolveFocus();
  },

  resolveFocus() {
    const active = this.el.dataset.active == '';
    const cursorIndex = parseInt(this.el.dataset.cursorIndex);
    if (active && !isNaN(cursorIndex)) {
      setTimeout(() => this.focus(cursorIndex), 200);
    }
  },

  focus(cursorIndex: number): void {
    this.el.focus();
    const selection = window.getSelection();

    selection.setPosition(selection.focusNode, cursorIndex);
  },

  getTarget(): string {
    return this.el.getAttribute('phx-target');
  },

  getCellId(): string {
    return this.el.dataset.cellId;
  },

  getBlockId(): string {
    return this.el.dataset.blockId;
  },
};

export default ContentEditable;
