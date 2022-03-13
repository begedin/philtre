const FOCUS = '|||FOCUS|||';

const splitAtCaret = (element) => {
  const selection = document.getSelection();
  const range = selection.getRangeAt(0);

  // generates dom container for selection from start of contenteditable to caret
  const preCaretRange = range.cloneRange();
  preCaretRange.selectNodeContents(element);
  preCaretRange.setEnd(range.endContainer, range.endOffset);
  const preContainer = document.createElement('div');
  preContainer.append(preCaretRange.cloneContents());

  // generates dom container for selection from caret to end of contenteditable
  const postCaretRange = range.cloneRange();
  postCaretRange.selectNodeContents(element);
  postCaretRange.setStart(range.startContainer, range.startOffset);
  const postContainer = document.createElement('div');
  postContainer.append(postCaretRange.cloneContents());

  return [preContainer.innerHTML, postContainer.innerHTML];
};

const pushEventTo = (hook, target, event, payload) =>
  new Promise((resolve) => {
    hook.pushEventTo(target, event, payload, resolve);
  });

const setStyles = (el: HTMLElement) => {
  el.style.outline = 'none';
  el.style.cursor = 'text';
  el.style.whiteSpace = 'pre-wrap';
};

const ContentEditable: {
  mounted: () => void;
  updated?: () => void;
  getTarget: () => string;
  getId: () => string;
  resolveFocus: () => void;
  selectedRange?: Range;
} = {
  mounted() {
    const el: HTMLElement = this.el;
    setStyles(el);

    // we store the pending update as a promise to await
    let pendingUpdate;
    // we also debounce the pending update and store a ref to the timeout so
    // we can cancel and keep debouncing
    let pendingUpdateRef;

    el.addEventListener('input', () => {
      // debounce
      if (pendingUpdateRef) {
        clearTimeout(pendingUpdateRef);
      }

      // store promise
      pendingUpdate = new Promise((resolve) => {
        pendingUpdateRef = setTimeout(async () => {
          const [pre, post] = splitAtCaret(el);

          await pushEventTo(this, this.getTarget(), 'update', { pre, post });
          resolve(null);
        }, 200);
      });
    });

    el.addEventListener('keydown', async (event: KeyboardEvent) => {
      if (event.key === 'Backspace') {
        const [pre, post] = splitAtCaret(el);

        if (pre.length > 0) {
          return;
        }

        event.preventDefault();

        if (pendingUpdate) {
          await pendingUpdate;
        }

        const target = this.getTarget();
        pushEventTo(this, target, 'backspace_from_start', { pre, post });
      }
    });

    el.addEventListener('keypress', async (event: KeyboardEvent) => {
      if (event.key === 'Enter') {
        event.preventDefault();

        if (pendingUpdate) {
          await pendingUpdate;
        }

        const [pre, post] = splitAtCaret(el);
        const pushEvent = event.shiftKey ? 'split_line' : 'split_block';
        const target = this.getTarget();
        pushEventTo(this, target, pushEvent, { pre, post });
      }
    });

    el.addEventListener('paste', (event: ClipboardEvent) => {
      event.preventDefault();
      const [pre, post] = splitAtCaret(el);
      const target = this.getTarget();
      pushEventTo(this, target, 'paste_blocks', { pre, post });
    });

    this.resolveFocus();
  },

  updated() {
    const el: HTMLElement = this.el;
    setStyles(el);
    this.resolveFocus();
  },

  resolveFocus() {
    const el: HTMLElement = this.el;
    const node = Array.from(el.childNodes).find((n) =>
      n.textContent.includes(FOCUS)
    );

    if (!node) {
      return;
    }
    const start = node.textContent.indexOf(FOCUS);

    el.focus();

    const selection = document.getSelection();
    const range = selection.getRangeAt(0);
    range.selectNodeContents(node);
    range.setStart(node, start);
    range.setEnd(node, start + FOCUS.length);
    range.deleteContents();
    selection.deleteFromDocument();
  },

  getTarget(): string {
    return this.el.getAttribute('phx-target');
  },

  getId(): string {
    return this.el.id;
  },
};

export default ContentEditable;
