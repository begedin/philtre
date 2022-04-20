const findCellParent = (node: Node | HTMLElement): HTMLElement =>
  'dataset' in node && node.dataset.cellId
    ? node
    : findCellParent(node.parentNode || node.parentElement);

const getPreCaretText = (element): string => {
  const selection = document.getSelection();
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

  // a blank block with an empty cell will have
  // itself as the anchor node
  if ('dataset' in selection.anchorNode) {
    const startElement = (
      selection.anchorNode as HTMLElement
    ).querySelector<HTMLElement>('[data-cell-id]');
    const startId = startElement.dataset.cellId;
    const endId = startElement.dataset.cellId;
    const startOffset = 0;
    const endOffset = 0;

    return {
      start_id: startId,
      start_offset: startOffset,
      end_id: endId,
      end_offset: endOffset,
    };
  }

  const startElement = findCellParent(selection.anchorNode);
  const startId = startElement.dataset.cellId;

  const endElement = findCellParent(selection.focusNode);
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
      id: child.dataset.cellId,
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

  if (!selectionStartId || !selectionEndId) {
    return;
  }

  // we know the element needs to be focused, just not fully clear where yet
  el.focus();

  const selection = el.ownerDocument.getSelection();
  selection.removeAllRanges();

  const range = document.createRange();

  const focusStart = el.querySelector(`[data-cell-id="${selectionStartId}"]`);
  const offsetStart = parseInt(selectionStartOffset);

  if (focusStart.childNodes[0]) {
    range.setStart(focusStart.childNodes[0], offsetStart);
  } else {
    range.selectNode(focusStart);
    selection.addRange(range);
    return;
  }

  const focusEnd = el.querySelector(`[data-cell-id="${selectionEndId}"]`);
  const offsetEnd = parseInt(selectionEndOffset);
  range.setEnd(focusEnd.childNodes[0], offsetEnd);

  selection.addRange(range);
};

const ContentEditable: {
  mounted: () => void;
  updated?: () => void;
  getTarget: () => string;
  selectedRange?: Range;
} = {
  mounted() {
    const el: HTMLElement = this.el;

    let saveRef: null | number = null;
    let savePromise: Promise<void> | null = null;

    el.addEventListener('input', () => {
      if (saveRef) {
        clearTimeout(saveRef);
      }

      const eventName = 'update';
      const target = this.getTarget();

      savePromise = new Promise((resolve, reject) => {
        const selection = getSelection();
        const cells = getCells(el);
        const params = { selection, cells };

        saveRef = setTimeout(async () => {
          this.pushEventTo(
            target,
            eventName,
            params,
            () => {
              saveRef = null;
              savePromise = null;
              resolve();
            },
            reject
          );
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

      if (savePromise) {
        await savePromise;
      }

      this.pushEventTo(this.getTarget(), command, { selection });
    });

    el.addEventListener('paste', (event: ClipboardEvent) => {
      event.preventDefault();
      const target = this.getTarget();
      this.pushEventTo(target, 'paste_blocks', { selection: getSelection() });
    });

    restoreSelection(el);
  },

  updated() {
    restoreSelection(this.el);
  },

  getTarget(): string {
    return this.el.getAttribute('phx-target');
  },
};

export default ContentEditable;
