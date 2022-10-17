import { ViewHook } from './types';
import { getTarget } from './utils';

/**
 * This hook can be used directly on a contenteditable,
 * or a parent of a contenteditable
 */
const resolveContentEditabe = (el: HTMLElement) =>
  el.contentEditable ? el : el.querySelector<HTMLElement>('[contenteditable]');

/**
 * Used to match the closest cell from selection anchor or offset node.
 *
 * Reason for this is, when moving selection using hotkeys, we can end up in a
 * text node within the block, but outside the cell.
 *
 * This usually happens on a new block, or close to the end of the cell.
 *
 * When we serialize the selection to send to backend, we want to match it to
 * the closest cell.
 */
const resolveCell = (node: Node | HTMLElement | null): HTMLElement | null => {
  if (node === null) {
    return null;
  }

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

/**
 * Used to determine whether the current selection is at start of block
 * That means 0 offset in first cell.
 *
 * We use the selection and cell serializer functions to determine this.
 */
const isAtStartOfBlock = (el: HTMLElement): boolean => {
  const selection = getBlockSelection(el);
  const cells = getCells(el);
  return selection.start_id === cells[0].id && selection.start_offset === 0;
};

/**
 * Type guard to determine whether the specified node is an element
 */
const isElement = (node: Node): node is HTMLElement =>
  node.nodeType === node.ELEMENT_NODE;

/**
 * Resolves cell id from an anchor node
 */
const getCellId = (node: Node | null): string | null => {
  if (!node) {
    return null;
  }
  if (!isElement(node)) {
    return null;
  }
  if (!node.dataset.cellId) {
    return null;
  }
  return node.dataset.cellId;
};

const IRREGULAR_WHITESPACE = ' ';
/**
 * Content editable will sometimes insert &nbsp; or a special space character.
 *
 * When looking at el.innerText, this is given as `IRREGULAR_WHITESPACE`
 *
 * We need to replace it with regular space when sending to backend.
 */
const sanitizeText = (text: string) => text.replace(IRREGULAR_WHITESPACE, ' ');

/**
 * Used to determine whether current selection is outside a cell whilw we've already been typing .
 *
 * This usually needs at the start of the block, before the first cell.
 */
const getIsOutOfCell = (el: HTMLElement): boolean => {
  const cells = Array.from(
    el.querySelectorAll<HTMLSpanElement>('[data-cell-id]')
  );

  return (
    cells.length === 0 ||
    (cells.length === 1 && cells[0].innerText === '' && el.innerText !== '')
  );
};

type Selection = {
  start_id: string;
  end_id: string;
  start_offset: number;
  end_offset: number;
};

/**
 * Returns inferred default selection, when the actual selection is not inside a valid cell
 */
const getDefaultSelection = (el: HTMLElement): Selection => {
  const cell = el.querySelector<HTMLElement>('[data-cell-id]');
  const cellId = getCellId(cell);
  const offset = el.innerText.length;

  console.log('getDefaultSelection', el, cell, cellId);

  if (!cell || !cellId) {
    return {
      start_id: el.id,
      end_id: el.id,
      start_offset: offset,
      end_offset: offset,
    };
  }

  return {
    start_id: cellId,
    start_offset: offset,
    end_id: cellId,
    end_offset: offset,
  };
};

/**
 * Returns proper selection from within a range of cells.
 */
const getProperSelection = (): Selection => {
  const selection = document.getSelection();
  if (!selection) {
    throw new Error('No selection during update');
  }

  const startElement = resolveCell(selection.anchorNode);
  const startId = getCellId(startElement);
  const endElement = resolveCell(selection.focusNode);
  const endId = getCellId(endElement);

  console.log('getProperSelection', startElement, endElement);

  if (!startId || !endId) {
    throw new Error('Invalid selection');
  }

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

/**
 * Returns either the proper or the inferred default seleciton
 */
const getBlockSelection = (el: HTMLElement): Selection =>
  getIsOutOfCell(el) ? getDefaultSelection(el) : getProperSelection();

type Cell = {
  id: string;
  modifiers: ('bold' | 'italic' | 'br')[];
  text: string;
};

/**
 * Returns all cell elements within the specified block element
 */
const getCellElements = (el: HTMLElement): HTMLElement[] =>
  Array.from(el.querySelectorAll<HTMLSpanElement>('[data-cell-id]'));

/**
 * Returns inferred default cells, when the cell structure is not valid.
 *
 * Usual case is, due to invalid selection, block text is in a text node before
 * the first cell.
 *
 * When shift deleting the contents of a block, we also have the case of there
 * being no cells in the block at all.
 */
const getDefaultCells = (el: HTMLElement): Cell[] => {
  const cells = getCellElements(el);
  const id = cells.length === 0 ? el.id : getCellId(cells[0]);
  if (!id) {
    throw new Error('Completely invalid block');
  }
  const text = sanitizeText(el.innerText);

  return [
    {
      id,
      text,
      modifiers: [],
    },
  ];
};

/**
 * Takes data from a cell element and outputs a proper cell
 */
const cellElementToCell = (child: HTMLElement): Cell => {
  const modifiers: ('bold' | 'italic' | 'br')[] = [];

  if (child.classList.contains('bold')) {
    modifiers.push('bold');
  }

  if (child.classList.contains('italic')) {
    modifiers.push('italic');
  }

  if (child.classList.contains('br')) {
    modifiers.push('br');
  }

  return {
    id: child.dataset.cellId || '',
    text: sanitizeText(child.innerText),
    modifiers,
  };
};

/**
 * Returns proper cells from a block, when everything is valid.
 */
const getProperCells = (el: HTMLElement): Cell[] =>
  getCellElements(el).map((child) => cellElementToCell(child));

/**
 * Returns either proper or default inferred cells from a block, depending on
 * block structure being valid or not.
 */
const getCells = (el: HTMLElement): Cell[] =>
  getIsOutOfCell(el) ? getDefaultCells(el) : getProperCells(el);

/**
 * Resolves command for a keyboard event preformed on a block, if any.
 */
const resolveCommand = (e: KeyboardEvent, el: HTMLElement) => {
  if (e.key === 'Backspace') {
    if (isAtStartOfBlock(el)) {
      return 'backspace_from_start';
    }
  }

  if (e.shiftKey && e.key === 'Enter' && !e.metaKey) {
    return 'split_line';
  }

  if (e.key === 'Enter') {
    return 'split_block';
  }

  if (e.metaKey && !e.shiftKey && !e.altKey && e.key === 'b') {
    return 'toggle.bold';
  }

  if (e.metaKey && !e.shiftKey && !e.altKey && e.key === 'i') {
    return 'toggle.italic';
  }
};

/**
 * Restores block selection from the structure given by backend
 */
const restoreSelection = (container: HTMLElement): void => {
  const el = resolveContentEditabe(container);
  if (!el) {
    throw new Error('Component does not contain a contenteditable');
  }
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

  // if the element is blank, we can't focus on the cell, so we keep focus on the contenteditable
  if (el.innerText === '') {
    return;
  }

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
        const selection = getBlockSelection(el);
        const params = { selection, cells };

        saveRef = window.setTimeout(async () => {
          console.log('event', eventName, params);
          this.pushEventTo(target, eventName, params, () => {
            saveRef = null;
            savePromise = null;
            resolve();
          });
        }, 50);
      });
    });

    el.addEventListener('keydown', async (event: KeyboardEvent) => {
      const command = resolveCommand(event, el);

      if (!command) {
        return;
      }

      event.preventDefault();

      if (savePromise && command) {
        await savePromise;
      }

      const selection = getBlockSelection(el);
      this.pushEventTo(getTarget(el), command, { selection });
    });

    el.addEventListener('paste', (event: ClipboardEvent) => {
      event.preventDefault();
      const target = getTarget(el);
      this.pushEventTo(target, 'paste_blocks', {
        selection: getBlockSelection(el),
      });
    });

    restoreSelection(el);
  },

  updated() {
    restoreSelection(this.el);
  },
} as ViewHook;
