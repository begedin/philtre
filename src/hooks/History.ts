import { ViewHook } from './types';
import { getTarget } from './utils';

export const History = {
  mounted() {
    document.addEventListener('keydown', (e) => {
      if (e.key === 'z' && e.metaKey && e.shiftKey) {
        this.pushEventTo(getTarget(this.el), 'redo');
        e.preventDefault();
        return;
      }

      if (e.key === 'z' && e.metaKey) {
        this.pushEventTo(getTarget(this.el), 'undo');
        e.preventDefault();
        return;
      }

      if (e.key === 'y' && e.metaKey) {
        this.pushEventTo(getTarget(this.el), 'redo');
        e.preventDefault();
      }
    });
  },
} as ViewHook;
