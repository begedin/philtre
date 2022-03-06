const FOCUS = '%%%focuspoint%%%';

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

const debounce = (func, timeout = 300) => {
  let timer;
  return (...args) => {
    clearTimeout(timer);
    timer = setTimeout(() => {
      func.call(args);
    }, timeout);
  };
};

const pushEventTo = (hook, target, event, payload) =>
  new Promise((resolve) => {
    hook.pushEventTo(target, event, payload, resolve);
  });

const pushUpdate = (hook) => {
  const el = hook.el;
  const [pre, post] = splitAtCaret(el);
  const value = pre + FOCUS + post;
  console.log('pushing update', { value, pre, post });
  return pushEventTo(hook, hook.getTarget(), 'update', { value });
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

    el.addEventListener(
      'input',
      debounce(() => {
        console.log('regular update');
        pushUpdate(this);
      }, 300)
    );

    el.addEventListener('keydown', async (event: KeyboardEvent) => {
      if (event.key === 'Backspace') {
        const [pre] = splitAtCaret(el);
        if (pre.length === 0) {
          event.preventDefault();

          const target = this.getTarget();
          await pushUpdate(this);
          pushEventTo(this, target, 'backspace_from_start', null);
        }
      }
    });

    el.addEventListener('keypress', (event: KeyboardEvent) => {
      if (event.key === 'Enter') {
        event.preventDefault();

        const [pre, post] = splitAtCaret(el);
        const pushEvent = event.shiftKey ? 'split_line' : 'split_block';
        const target = this.getTarget();
        pushEventTo(this, target, pushEvent, { pre, post: FOCUS + post });
      }
    });

    el.addEventListener('paste', (event: ClipboardEvent) => {
      const selection = window.getSelection();
      event.preventDefault();
      this.pushEventTo(this.getTarget(), 'paste_blocks', {
        index: selection.anchorOffset,
      });
    });

    this.resolveFocus();
  },

  updated() {
    console.log('updated');
    this.resolveFocus();
  },

  resolveFocus() {
    console.log('resolveFocus');
    const el: HTMLElement = this.el;
    const node = Array.from(el.childNodes).find((n) =>
      n.textContent.includes(FOCUS)
    );

    if (!node) {
      return;
    }
    const start = node.textContent.indexOf(FOCUS);
    console.log({
      node,
      children: node.hasChildNodes(),
      textLength: node.textContent.length,
      start,
      end: start + FOCUS.length,
      text: node.textContent,
    });

    el.focus();

    const selection = document.getSelection();
    const range = selection.getRangeAt(0);
    range.selectNodeContents(node);
    range.setStart(node, start);
    range.setEnd(node, start + FOCUS.length);
    console.log(range);
    range.deleteContents();
    selection.deleteFromDocument();

    console.log('after focus', el.innerHTML);
  },

  getTarget(): string {
    return this.el.getAttribute('phx-target');
  },

  getId(): string {
    return this.el.id;
  },
};

export default ContentEditable;
