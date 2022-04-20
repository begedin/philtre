export const History = {
  mounted() {
    document.addEventListener('keydown', (e) => {
      if (e.key === 'z' && e.metaKey && e.shiftKey) {
        this.pushEventTo(this.getTarget(), 'redo');
        e.preventDefault();
        return;
      }

      if (e.key === 'z' && e.metaKey) {
        this.pushEventTo(this.getTarget(), 'undo');
        e.preventDefault();
        return;
      }

      if (e.key === 'y' && e.metaKey) {
        this.pushEventTo(this.getTarget(), 'redo');
        e.preventDefault();
      }
    });
  },

  getTarget(): string {
    return this.el.getAttribute('phx-target');
  },
};
