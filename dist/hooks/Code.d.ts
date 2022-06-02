/**
 * Heavily inspired by
 * https://css-tricks.com/creating-an-editable-textarea-that-supports-syntax-highlighted-code/
 *
 * The goal here was to do the bare minimum JS to get it to work, while relying
 * on the elixir update to manage the content.
 */
import 'prismjs/components/prism-elixir.min.js';
import { ViewHook } from './types';
export declare const Code: ViewHook;
