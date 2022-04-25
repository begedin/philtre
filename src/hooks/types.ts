export type ViewHook = {
  el: HTMLElement;
  viewName: string;
  pushEvent(
    event: string,
    payload?: object,
    onReply?: (reply: any, ref: number) => any
  ): void;
  pushEventTo(
    selectorOrTarget: any,
    event: string,
    payload?: object,
    onReply?: (reply: any, ref: number) => any
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
