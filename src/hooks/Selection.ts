import { ViewHook } from './types';
import { getTarget } from './utils';

const overlaps = (a: HTMLElement, b: HTMLElement): boolean => {
  const aRect = a.getBoundingClientRect();
  const bRect = b.getBoundingClientRect();

  return !(
    aRect.top > bRect.bottom ||
    aRect.right < bRect.left ||
    aRect.bottom < bRect.top ||
    aRect.left > bRect.right
  );
};

const initCopy = (hook: ViewHook) => {
  document.addEventListener('copy', (event: ClipboardEvent) => {
    const selected = document.querySelectorAll<HTMLElement>(
      '.philtre__editor [data-selected]'
    );

    if (selected.length === 0) {
      return;
    }

    event.preventDefault();

    hook.pushEventTo(getTarget(hook.el), 'copy_blocks', {
      block_ids: Array.from(selected).map((el) => el.id),
    });
  });
};

type SelectionState = {
  fromX: number;
  fromY: number;
  toX: number;
  toY: number;
  selecting: boolean;
};

const getWidth = (state: SelectionState): number =>
  Math.abs(state.toX - state.fromX);

const getHeight = (state: SelectionState): number =>
  Math.abs(state.toY - state.fromY);

const getLeft = (state: SelectionState): number =>
  Math.min(state.fromX, state.toX);

const getTop = (state: SelectionState): number =>
  Math.min(state.fromY, state.toY);

const showDOM = (selection: HTMLElement): void => {
  selection.style.display = 'none';
  selection.style.background = 'rgba(0,0,255,0.1)';
  selection.style.position = 'fixed';
  selection.style.display = 'block';
};

const updateDOM = (selection: HTMLElement, state: SelectionState): void => {
  selection.style.left = `${getLeft(state)}px`;
  selection.style.top = `${getTop(state)}px`;
  selection.style.width = `${getWidth(state)}px`;
  selection.style.height = `${getHeight(state)}px`;
};

const resetDOM = (selection: HTMLElement, state: SelectionState) => {
  selection.style.left = `${getLeft(state)}px`;
  selection.style.top = `${getTop(state)}px`;
  selection.style.width = `0px`;
  selection.style.height = `0px`;
};

const hideDOM = (selection: HTMLElement): void => {
  selection.style.display = 'none';
};

export const Selection = {
  mounted() {
    initCopy(this);

    const selection: HTMLElement = this.el;

    const selectionState: SelectionState = {
      fromX: 0,
      fromY: 0,
      toX: 0,
      toY: 0,
      selecting: false,
    };

    document.addEventListener('mousedown', (event: MouseEvent) => {
      selectionState.selecting = true;
      selectionState.fromX = event.x;
      selectionState.fromY = event.y;

      showDOM(selection);
    });

    document.addEventListener('mousemove', (event) => {
      if (!selectionState.selecting) {
        return;
      }

      selectionState.toX = event.x;
      selectionState.toY = event.y;

      updateDOM(selection, selectionState);
    });

    document.addEventListener('mouseup', () => {
      selectionState.selecting = false;

      if (getWidth(selectionState) < 5 || getHeight(selectionState) < 5) {
        return;
      }

      const allBlocks = document.querySelectorAll<HTMLElement>('[data-block]');

      const results = Array.from(allBlocks).filter((block) =>
        overlaps(block, selection)
      );

      const payload = {
        block_ids: results.map((el) => el.id),
      };
      resetDOM(selection, selectionState);
      hideDOM(selection);

      this.pushEventTo(getTarget(this.el), 'select_blocks', payload);
    });
  },
} as ViewHook;
