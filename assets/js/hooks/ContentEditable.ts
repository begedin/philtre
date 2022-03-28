const splitAtCaret = (element): [string, string, string] => {
  const selection = document.getSelection();
  const range = selection.getRangeAt(0);

  // generates dom container for selection from start of contenteditable to caret
  const preCaretRange = range.cloneRange();
  preCaretRange.selectNodeContents(element);
  preCaretRange.setEnd(range.endContainer, range.endOffset);
  const preContainer = document.createElement('div');
  preContainer.append(preCaretRange.cloneContents());

  const selectionRange = range.cloneRange();
  selectionRange.selectNodeContents(element);
  selectionRange.setStart(range.endContainer, range.endOffset);
  selectionRange.setEnd(range.startContainer, range.startOffset);
  const selectionContainer = document.createElement('div');
  selectionContainer.append(selectionRange.cloneContents());

  // generates dom container for selection from caret to end of contenteditable
  const postCaretRange = range.cloneRange();
  postCaretRange.selectNodeContents(element);
  postCaretRange.setStart(range.startContainer, range.startOffset);
  const postContainer = document.createElement('div');
  postContainer.append(postCaretRange.cloneContents());

  return [
    preContainer.innerHTML,
    selectionContainer.innerHTML,
    postContainer.innerHTML,
  ];
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
          const [pre, selection, post] = splitAtCaret(el);

          await pushEventTo(this, this.getTarget(), 'update', {
            pre,
            selection,
            post,
          });
          resolve(null);
        }, 200);
      });
    });

    el.addEventListener('keydown', async (event: KeyboardEvent) => {
      if (event.key !== 'Backspace') {
        return;
      }

      const [pre, selection, post] = splitAtCaret(el);

      if (pre.length > 0) {
        return;
      }

      event.preventDefault();

      if (pendingUpdate) {
        await pendingUpdate;
      }

      const target = this.getTarget();
      pushEventTo(this, target, 'backspace_from_start', {
        pre,
        selection,
        post,
      });
    });

    el.addEventListener('keypress', async (event: KeyboardEvent) => {
      if (event.key !== 'Enter') {
        return;
      }

      event.preventDefault();

      if (pendingUpdate) {
        await pendingUpdate;
      }

      const [pre, selection, post] = splitAtCaret(el);
      const pushEvent = event.shiftKey ? 'split_line' : 'split_block';
      const target = this.getTarget();
      pushEventTo(this, target, pushEvent, { pre, selection, post });
    });

    el.addEventListener('paste', (event: ClipboardEvent) => {
      event.preventDefault();
      const [pre, selection, post] = splitAtCaret(el);
      const target = this.getTarget();
      pushEventTo(this, target, 'paste_blocks', { pre, selection, post });
    });

    setStyles(el);
    this.resolveFocus();
  },

  updated() {
    const el: HTMLElement = this.el;
    setStyles(el);
    this.resolveFocus();
  },

  resolveFocus() {
    const el: HTMLElement = this.el;
    // the backend will insert special spans indicating the start and the end
    // of the current selection
    const focusStart = el.querySelector('[data-selection-start]');
    const focusEnd = el.querySelector('[data-selection-end]');
    if (!focusStart || !focusEnd) {
      return;
    }

    el.focus();

    // we first select the entire block defined by the special selection start/end elements
    const selection = document.getSelection();
    const range = selection.getRangeAt(0);
    range.setStartBefore(focusStart);
    range.setEndAfter(focusEnd);

    // then, we remove the special elements only, from the document

    const rangeStart = new Range();
    rangeStart.selectNode(focusStart);
    rangeStart.deleteContents();

    const rangeEnd = new Range();
    rangeEnd.selectNode(focusEnd);
    rangeEnd.deleteContents();
  },

  getTarget(): string {
    return this.el.getAttribute('phx-target');
  },

  getId(): string {
    return this.el.id;
  },
};

export default ContentEditable;
