export type ViewHook = {
  el: HTMLElement;
  viewName: string;
  pushEvent(
    event: string,
    payload?: object,
    onReply?: (reply: object, ref: number) => void
  ): void;
  pushEventTo(
    selectorOrTarget: string | Element,
    event: string,
    payload?: object,
    onReply?: (reply: object, ref: number) => void
  ): void;
  handleEvent(event: string, callback: (payload: object) => void): void;

  // callbacks
  mounted?: (() => void) | undefined;
  beforeUpdate?: (() => void) | undefined;
  updated?: (() => void) | undefined;
  beforeDestroy?: (() => void) | undefined;
  destroyed?: (() => void) | undefined;
  disconnected?: (() => void) | undefined;
  reconnected?: (() => void) | undefined;
};
