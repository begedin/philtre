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
const Selection = {
  mounted() {
    const selection: HTMLElement = this.el;

    let selecting = false;
    const initial = { x: 0, y: 0 };

    document.addEventListener('mousedown', (event: MouseEvent) => {
      selection.style.display = 'none';
      selection.style.background = 'rgba(0,0,255,0.1)';
      selection.style.position = 'fixed';

      selecting = true;

      initial.x = event.x;
      initial.y = event.y;

      selection.style.display = 'block';
    });

    document.addEventListener('mousemove', (event) => {
      if (!selecting) {
        return;
      }

      const width = Math.abs(event.x - initial.x);
      const height = Math.abs(event.y - initial.y);

      const left = initial.x < event.x ? initial.x : event.x;
      const top = initial.y < event.y ? initial.y : event.y;

      selection.style.left = `${left}px`;
      selection.style.top = `${top}px`;
      selection.style.width = `${width}px`;
      selection.style.height = `${height}px`;
    });

    document.addEventListener('mouseup', () => {
      const allBlocks = document.querySelectorAll<HTMLElement>('[data-block]');
      const results = Array.from(allBlocks).filter((block) =>
        overlaps(block, selection)
      );

      this.pushEventTo(this.getTarget(), 'select_blocks', {
        block_ids: results.map((el) => el.dataset.blockId),
      });

      selecting = false;
      selection.style.display = 'none';
      selection.style.left = `${initial.x}px`;
      selection.style.top = `${initial.y}px`;
      selection.style.width = '0';
      selection.style.height = '0';
    });
  },

  getTarget(): string {
    return this.el.getAttribute('phx-target');
  },
};

export default Selection;
