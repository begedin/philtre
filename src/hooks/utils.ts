export const getTarget = (el: HTMLElement): string => {
  const target = el.getAttribute('phx-target');
  if (!target) {
    throw new Error('Target element does not have a "phx-target" attribute');
  }
  return target;
};
