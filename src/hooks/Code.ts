/**
 * Heavily inspired by
 * https://css-tricks.com/creating-an-editable-textarea-that-supports-syntax-highlighted-code/
 *
 * The goal here was to do the bare minimum JS to get it to work, while relying
 * on the elixir update to manage the content.
 */

import Prism from 'prismjs';

import 'prismjs/components/prism-elixir.min.js';

import { ViewHook } from './types';
import { getTarget } from './utils';

const getHiglightEl = (el: HTMLElement): HTMLElement => {
  const codeEl = el.querySelector<HTMLElement>('.philtre__code__highlighted');
  if (!codeEl) {
    throw 'Highlight container not found';
  }
  return codeEl;
};

const setupHighlight = (el: HTMLElement) => {
  const language = el.dataset.language;
  if (!language) {
    throw 'Language not specified ';
  }

  const highlightEl = getHiglightEl(el);

  const toRemove: string[] = [];
  highlightEl.classList.forEach((c) => {
    if (c.startsWith('lang')) {
      toRemove.push(c);
    }
  });

  toRemove.forEach((c) => highlightEl.classList.remove(c));
  highlightEl.classList.add(`language-${language}`);
  highlightEl.classList.add(`lang-${language}`);

  console.log('highlighting with', language);
};

const getCodeEl = (el: HTMLElement): HTMLTextAreaElement => {
  const codeEl = el.querySelector<HTMLTextAreaElement>(
    '.philtre__code__editable'
  );
  if (!codeEl) {
    throw 'Editable container not found';
  }
  return codeEl;
};

const updateHighlight = (el: HTMLElement) => {
  const highlightEl = getHiglightEl(el);
  const codeEl = getCodeEl(el);

  const newValue = codeEl.value.endsWith('\n')
    ? codeEl.value.concat('\n')
    : codeEl.value;

  highlightEl.innerHTML = newValue;
  Prism.highlightElement(highlightEl);
};

const bindInput = (el: HTMLElement, hook: ViewHook): void => {
  const codeEl = getCodeEl(el);

  codeEl.addEventListener('keypress', (e) => {
    if (e.key === 'Enter' && e.shiftKey) {
      e.preventDefault();
      hook.pushEventTo(getTarget(el), 'add_block');
    }
  });

  codeEl.addEventListener('input', () => {
    updateHighlight(el);
    hook.pushEventTo(getTarget(el), 'update', { value: codeEl.value });
  });
};

export const Code = {
  mounted() {
    setupHighlight(this.el);
    bindInput(this.el, this);
    updateHighlight(this.el);
  },
  updated() {
    setupHighlight(this.el);
    updateHighlight(this.el);
  },
} as ViewHook;
