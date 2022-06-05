import { ViewHook } from './types';
import { getTarget } from './utils';

const getFocusable = (el: HTMLElement) => {
  const focusable = el.querySelector<HTMLElement>('[data-block]');
  if (!focusable) {
    throw new Error('Section does not contain a block');
  }
  return focusable;
};

const maybeFocusBlock = (el: HTMLElement) => {
  if (!('focused' in el.dataset)) {
    return;
  }

  //no need to focus if the block already has focus
  const focusable = getFocusable(el);
  if (focusable.id === document.activeElement?.id) {
    return;
  }

  focusable.focus();
};

/**
 * Handles block navigation by binding to key events and dispatching navigation
 * events to the backend
 */
export const BlockNavigation = {
  mounted() {
    const el = this.el;
    const target = getTarget(this.el);

    const focusCurrent = () =>
      this.pushEventTo(getTarget(el), 'focus_current', {
        block_id: getFocusable(el).id,
      });

    const focusPrevious = () => this.pushEventTo(target, 'focus_previous');
    const focusNext = () => this.pushEventTo(target, 'focus_next');

    // on tab and shift + tab, we focus next and previous section/block respectively
    el.addEventListener('keydown', (e) => {
      if (e.key !== 'Tab') {
        return;
      }

      if (e.metaKey) {
        return;
      }

      e.preventDefault();
      e.shiftKey ? focusPrevious() : focusNext();
    });

    // when the block itself gains focus via user interaction or backend change
    // we need to mark the section as focused
    getFocusable(el).addEventListener('focus', () => {
      if ('focused' in el.dataset) {
        return;
      }

      focusCurrent();
    });

    // This hook is bound to a section container
    // the actual inner block might get removed or modified in some wayh, where
    // the focus event listener will get detached.
    // To track that scenario, we observe dom changes on the children of this block and
    // refocus when applicable.
    // This is not a very clean solution. It should be possible to instead restructure the
    // backend code to track this a bit better.
    const observer = new MutationObserver((mutations) => {
      const addedElements = Array.from(mutations)
        .map((m) => Array.from(m.addedNodes))
        .flat() as unknown as HTMLElement[];

      const addedBlock = addedElements.find(
        (n) => 'dataset' in n && 'block' in n.dataset
      );

      if (!addedBlock) {
        return;
      }

      if ('focused' in el.dataset) {
        return;
      }

      if (document.activeElement?.id !== addedBlock.id) {
        return;
      }

      focusCurrent();
    });

    observer.observe(el, {
      subtree: false,
      childList: true,
    });

    maybeFocusBlock(this.el);
  },
  updated() {
    maybeFocusBlock(this.el);
  },
} as ViewHook;
