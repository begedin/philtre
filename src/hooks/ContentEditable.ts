import { ViewHook } from './types';
import { getTarget } from './utils';

const resolveCell = (node: Node | HTMLElement): HTMLElement | null => {
  // the current node is the cell we are looking for
  if ('dataset' in node && node.dataset.cellId) {
    return node;
  }

  // the current node is the block container. if we got here, means we (probably)
  // only have one cell to pick
  if ('dataset' in node && 'block' in node.dataset) {
    return node.querySelector('[data-cell-id]');
  }

  // the current node is a fragment child node of the cell
  if (node.parentElement?.dataset.cellId) {
    return node.parentElement;
  }

  return null;
};

const applyFixes = (el: HTMLElement) => {
  const zeroth = el.childNodes[0];

  if (!zeroth) {
    return;
  }

  // this means we had a blank cell. since we can't put a carret into black inline elements, it was
  // placed on an extra text node outside in the block, but before the first cell
  if (zeroth.nodeName === '#text') {
    // we first have to remove the text log
    el.removeChild(zeroth);

    // then we prepend the content of the removed text node into the actual first cell element
    el.childNodes[0].textContent = (zeroth.textContent || '').concat(
      el.childNodes[0].textContent || ''
    );

    // finally, since the caret was at the end of that node, we move it into the node
    const selection = document.getSelection();
    if (!selection) {
      return;
    }

    const range = selection.getRangeAt(0);
    range.selectNode(el.childNodes[0]);
    selection.collapseToEnd();
  }

  if (zeroth?.nodeName === 'BR') {
    el.removeChild(zeroth);
  }
};

const getPreCaretText = (element: HTMLElement): string => {
  const selection = document.getSelection();
  if (!selection) {
    return '';
  }
  const range = selection.getRangeAt(0);

  // generates dom container for selection from start of contenteditable to caret
  const preCaretRange = range.cloneRange();
  preCaretRange.selectNodeContents(element);
  preCaretRange.setEnd(range.startContainer, range.startOffset);
  const preContainer = document.createElement('div');
  preContainer.append(preCaretRange.cloneContents());
  return preContainer.innerText;
};

const isAtStartOfBlock = (element: HTMLElement): boolean =>
  getPreCaretText(element).length === 0;

const getSelection = () => {
  const selection = document.getSelection();
  if (!selection || !selection.anchorNode || !selection.focusNode) {
    return;
  }

  const startElement = resolveCell(selection.anchorNode);
  const endElement = resolveCell(selection.focusNode);

  if (!startElement) {
    return null;
  }

  if (!endElement) {
    return null;
  }

  const startId = startElement.dataset.cellId;
  const endId = endElement.dataset.cellId;

  const [startOffset, endOffset] =
    selection.anchorOffset < selection.focusOffset
      ? [selection.anchorOffset, selection.focusOffset]
      : [selection.focusOffset, selection.anchorOffset];

  return {
    start_id: startId,
    start_offset: startOffset,
    end_id: endId,
    end_offset: endOffset,
  };
};

type Cell = {
  id: string;
  modifiers: ('strong' | 'italic')[];
  text: string;
};

const getCells = (el: HTMLElement): Cell[] => {
  const children = Array.from(el.children) as HTMLElement[];

  return children.map((child) => {
    const modifiers: ('strong' | 'italic')[] = [];

    if (child.tagName === 'strong') {
      modifiers.push('strong');
    }

    if (child.tagName === 'em') {
      modifiers.push('italic');
    }

    return {
      id: child.dataset.cellId || '',
      text: child.innerText,
      modifiers,
    };
  });
};

const resolveCommand = (e: KeyboardEvent) => {
  if (e.key === 'Backspace') {
    if (isAtStartOfBlock(e.target as HTMLElement)) {
      return 'backspace_from_start';
    }
  }

  if (e.shiftKey && e.key === 'Enter') {
    return 'split_line';
  }

  if (e.key === 'Enter') {
    return 'split_block';
  }

  if (e.metaKey && e.key === 'b') {
    return 'toggle.bold';
  }

  if (e.metaKey && e.key === 'i') {
    return 'toggle.italic';
  }
};

const restoreSelection = (el: HTMLElement): void => {
  // if the block is the focused block, the backend will insert these data
  // attributes onto the containing element
  const {
    selectionStartId,
    selectionEndId,
    selectionStartOffset,
    selectionEndOffset,
  } = el.dataset;

  if (
    !selectionStartId ||
    !selectionEndId ||
    !selectionStartOffset ||
    !selectionEndOffset
  ) {
    return;
  }

  // we know the element needs to be focused, just not fully clear where yet
  el.focus();

  const selection = el.ownerDocument.getSelection();
  if (!selection) {
    return;
  }
  selection.removeAllRanges();

  const range = document.createRange();

  const focusStart = el.querySelector(`[data-cell-id="${selectionStartId}"]`);
  if (!focusStart) {
    return;
  }

  const offsetStart = parseInt(selectionStartOffset);

  if (!focusStart.childNodes[0]) {
    focusStart.appendChild(document.createTextNode(''));
  }
  range.setStart(focusStart.childNodes[0], offsetStart);

  const focusEnd = el.querySelector(`[data-cell-id="${selectionEndId}"]`);
  if (!focusEnd) {
    return;
  }
  const offsetEnd = parseInt(selectionEndOffset);
  range.setEnd(focusEnd.childNodes[0], offsetEnd);
  selection.addRange(range);
};

export const ContentEditable = {
  mounted() {
    const el: HTMLElement = this.el;

    let saveRef: null | number = null;
    let savePromise: Promise<void> | null = null;

    el.addEventListener('input', () => {
      if (saveRef) {
        clearTimeout(saveRef);
      }

      const eventName = 'update';
      const target = getTarget(this.el);

      savePromise = new Promise((resolve) => {
        applyFixes(el);
        const cells = getCells(el);
        const selection = getSelection();
        const params = { selection, cells };

        saveRef = window.setTimeout(async () => {
          this.pushEventTo(target, eventName, params, () => {
            saveRef = null;
            savePromise = null;
            resolve();
          });
        });
      });
    });

    el.addEventListener('keydown', async (event: KeyboardEvent) => {
      const command = resolveCommand(event);

      if (!command) {
        return;
      }

      event.preventDefault();

      const selection = getSelection();

      if (savePromise && command) {
        await savePromise;
      }

      this.pushEventTo(getTarget(el), command, { selection });
    });

    el.addEventListener('paste', (event: ClipboardEvent) => {
      event.preventDefault();
      const target = getTarget(el);
      this.pushEventTo(target, 'paste_blocks', { selection: getSelection() });
    });

    restoreSelection(el);
  },

  updated() {
    restoreSelection(this.el);
  },
} as ViewHook;
