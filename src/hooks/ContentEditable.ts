import { ViewHook } from './types';
import { getTarget } from './utils';

/**
 * Resolves closest cell element to the specified node or dom element.
 * This could be the specified record itself, or a parent, or a child.
 */
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

const getChildIndex = (node: Node): number =>
  Array.prototype.indexOf.call(node.parentNode?.children || [], node);

const isAtStartOfBlock = (): boolean => {
  const selection = document.getSelection();
  if (!selection) {
    return false;
  }
  const node = selection.anchorNode;
  if (!node) {
    return false;
  }
  const indexedNode = node.nodeType === Node.TEXT_NODE ? node.parentNode : node;
  if (!indexedNode) {
    return false;
  }
  return getChildIndex(indexedNode) === 0 && selection.anchorOffset == 0;
};

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
  modifiers: ('strong' | 'italic' | 'br')[];
  text: string;
};

const getCells = (el: HTMLElement): Cell[] => {
  const cells = el.querySelectorAll<HTMLSpanElement>('[data-cell-id]');

  return Array.from(cells).map((child) => {
    const modifiers: ('strong' | 'italic' | 'br')[] = [];

    if (child.classList.contains('strong')) {
      modifiers.push('strong');
    }

    if (child.classList.contains('italic')) {
      modifiers.push('italic');
    }

    if (child.classList.contains('br')) {
      modifiers.push('br');
    }

    return {
      id: child.dataset.cellId || '',
      text: child.innerText.replace(' ', ' '),
      modifiers,
    };
  });
};

const resolveCommand = (e: KeyboardEvent) => {
  if (e.key === 'Backspace') {
    if (isAtStartOfBlock()) {
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

  if (e.metaKey && e.key === 'i' && !e.shiftKey) {
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
        const cells = getCells(el);
        const selection = getSelection();
        const params = { selection, cells };

        saveRef = window.setTimeout(async () => {
          this.pushEventTo(target, eventName, params, () => {
            saveRef = null;
            savePromise = null;
            resolve();
          });
        }, 300);
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
