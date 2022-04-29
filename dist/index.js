// src/hooks/utils.ts
var getTarget = (el) => el.getAttribute("phx-target");

// src/hooks/ContentEditable.ts
var resolveCell = (node) => {
  if ("dataset" in node && node.dataset.cellId) {
    return node;
  }
  if ("dataset" in node && "block" in node.dataset) {
    return node.querySelector("[data-cell-id]");
  }
  if (node.parentElement?.dataset.cellId) {
    return node.parentElement;
  }
  return null;
};
var applyFixes = (el) => {
  const zeroth = el.childNodes[0];
  if (!zeroth) {
    return;
  }
  if (zeroth.nodeName === "#text") {
    el.removeChild(zeroth);
    el.childNodes[0].textContent = (zeroth.textContent || "").concat(el.childNodes[0].textContent || "");
    const selection = document.getSelection();
    if (!selection) {
      return;
    }
    const range = selection.getRangeAt(0);
    range.selectNode(el.childNodes[0]);
    selection.collapseToEnd();
  }
  if (zeroth?.nodeName === "BR") {
    el.removeChild(zeroth);
  }
};
var getPreCaretText = (element) => {
  const selection = document.getSelection();
  if (!selection) {
    return "";
  }
  const range = selection.getRangeAt(0);
  const preCaretRange = range.cloneRange();
  preCaretRange.selectNodeContents(element);
  preCaretRange.setEnd(range.startContainer, range.startOffset);
  const preContainer = document.createElement("div");
  preContainer.append(preCaretRange.cloneContents());
  return preContainer.innerText;
};
var isAtStartOfBlock = (element) => getPreCaretText(element).length === 0;
var getSelection = () => {
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
  const [startOffset, endOffset] = selection.anchorOffset < selection.focusOffset ? [selection.anchorOffset, selection.focusOffset] : [selection.focusOffset, selection.anchorOffset];
  return {
    start_id: startId,
    start_offset: startOffset,
    end_id: endId,
    end_offset: endOffset
  };
};
var getCells = (el) => {
  const children = Array.from(el.children);
  return children.map((child) => {
    const modifiers = [];
    if (child.tagName === "strong") {
      modifiers.push("strong");
    }
    if (child.tagName === "em") {
      modifiers.push("italic");
    }
    return {
      id: child.dataset.cellId || "",
      text: child.innerText,
      modifiers
    };
  });
};
var resolveCommand = (e) => {
  if (e.key === "Backspace") {
    if (isAtStartOfBlock(e.target)) {
      return "backspace_from_start";
    }
  }
  if (e.shiftKey && e.key === "Enter") {
    return "split_line";
  }
  if (e.key === "Enter") {
    return "split_block";
  }
  if (e.metaKey && e.key === "b") {
    return "toggle.bold";
  }
  if (e.metaKey && e.key === "i") {
    return "toggle.italic";
  }
};
var restoreSelection = (el) => {
  const {
    selectionStartId,
    selectionEndId,
    selectionStartOffset,
    selectionEndOffset
  } = el.dataset;
  if (!selectionStartId || !selectionEndId || !selectionStartOffset || !selectionEndOffset) {
    return;
  }
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
    focusStart.appendChild(document.createTextNode(""));
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
var ContentEditable = {
  mounted() {
    const el = this.el;
    let saveRef = null;
    let savePromise = null;
    el.addEventListener("input", () => {
      if (saveRef) {
        clearTimeout(saveRef);
      }
      const eventName = "update";
      const target = getTarget(this.el);
      savePromise = new Promise((resolve, reject) => {
        applyFixes(el);
        const cells = getCells(el);
        const selection = getSelection();
        const params = { selection, cells };
        saveRef = setTimeout(async () => {
          this.pushEventTo(target, eventName, params, () => {
            saveRef = null;
            savePromise = null;
            resolve();
          });
        });
      });
    });
    el.addEventListener("keydown", async (event) => {
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
    el.addEventListener("paste", (event) => {
      event.preventDefault();
      const target = getTarget(el);
      this.pushEventTo(target, "paste_blocks", { selection: getSelection() });
    });
    restoreSelection(el);
  },
  updated() {
    restoreSelection(this.el);
  }
};

// src/hooks/History.ts
var History = {
  mounted() {
    document.addEventListener("keydown", (e) => {
      if (e.key === "z" && e.metaKey && e.shiftKey) {
        this.pushEventTo(getTarget(this.el), "redo");
        e.preventDefault();
        return;
      }
      if (e.key === "z" && e.metaKey) {
        this.pushEventTo(getTarget(this.el), "undo");
        e.preventDefault();
        return;
      }
      if (e.key === "y" && e.metaKey) {
        this.pushEventTo(getTarget(this.el), "redo");
        e.preventDefault();
      }
    });
  }
};

// src/hooks/Selection.ts
var overlaps = (a, b) => {
  const aRect = a.getBoundingClientRect();
  const bRect = b.getBoundingClientRect();
  return !(aRect.top > bRect.bottom || aRect.right < bRect.left || aRect.bottom < bRect.top || aRect.left > bRect.right);
};
var initCopy = (hook) => {
  document.addEventListener("copy", (event) => {
    const selected = document.querySelectorAll(".philtre__editor [data-selected]");
    if (selected.length === 0) {
      return;
    }
    event.preventDefault();
    hook.pushEventTo(getTarget(hook.el), "copy_blocks", {
      block_ids: Array.from(selected).map((el) => el.id)
    });
  });
};
var getWidth = (state) => Math.abs(state.toX - state.fromX);
var getHeight = (state) => Math.abs(state.toY - state.fromY);
var getLeft = (state) => Math.min(state.fromX, state.toX);
var getTop = (state) => Math.min(state.fromY, state.toY);
var showDOM = (selection) => {
  selection.style.display = "none";
  selection.style.background = "rgba(0,0,255,0.1)";
  selection.style.position = "fixed";
  selection.style.display = "block";
};
var updateDOM = (selection, state) => {
  selection.style.left = `${getLeft(state)}px`;
  selection.style.top = `${getTop(state)}px`;
  selection.style.width = `${getWidth(state)}px`;
  selection.style.height = `${getHeight(state)}px`;
};
var resetDOM = (selection, state) => {
  selection.style.left = `${getLeft(state)}px`;
  selection.style.top = `${getTop(state)}px`;
  selection.style.width = `0px`;
  selection.style.height = `0px`;
};
var hideDOM = (selection) => {
  selection.style.display = "none";
};
var Selection = {
  mounted() {
    initCopy(this);
    const selection = this.el;
    const selectionState = {
      fromX: 0,
      fromY: 0,
      toX: 0,
      toY: 0,
      selecting: false
    };
    document.addEventListener("mousedown", (event) => {
      selectionState.selecting = true;
      selectionState.fromX = event.x;
      selectionState.fromY = event.y;
      showDOM(selection);
    });
    document.addEventListener("mousemove", (event) => {
      if (!selectionState.selecting) {
        return;
      }
      selectionState.toX = event.x;
      selectionState.toY = event.y;
      updateDOM(selection, selectionState);
    });
    document.addEventListener("mouseup", () => {
      selectionState.selecting = false;
      if (getWidth(selectionState) < 5 || getHeight(selectionState) < 5) {
        return;
      }
      const allBlocks = document.querySelectorAll("[data-block]");
      const results = Array.from(allBlocks).filter((block) => overlaps(block, selection));
      const payload = {
        block_ids: results.map((el) => el.id)
      };
      resetDOM(selection, selectionState);
      hideDOM(selection);
      this.pushEventTo(getTarget(this.el), "select_blocks", payload);
    });
  }
};
export {
  ContentEditable,
  History,
  Selection
};
//# sourceMappingURL=index.js.map
