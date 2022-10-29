import { allBlocks, block, blockCell, focusBlock, visitNew } from '../../utils';

/**
 * Selects first matched occurrence of a string within the specified cell
 *
 * Cypress does not provide commands for selection of specific text.
 *
 * One can `cy.type('{selectAll}')`, but actions such as `{shift+rightArrow}` do
 * not add to selection. This executes js int he browser, to synthetise the
 * selection that way.
 */
const selectText = (blockIndex: number, cellIndex: number, text: string) =>
  block(blockIndex)
    .focus()
    .find('[data-cell-id]')
    .eq(cellIndex)
    .then((cell) => {
      const el = cell[0];
      const document = el.ownerDocument;
      const textIndex = el.innerText.indexOf(text);
      const range = document.createRange();

      range.setStart(el.childNodes[0], textIndex);
      range.setEnd(el.childNodes[0], textIndex + text.length);

      const selection = document.getSelection();
      selection.removeAllRanges();
      selection.addRange(range);
    });
describe('p', () => {
  it('splits and joins correctly', () => {
    visitNew();
    allBlocks().its('length').should('eq', 2);

    focusBlock(0)
      .type('{selectall}{rightArrow}')
      .type('{leftArrow}{leftArrow}{leftArrow}{leftArrow}')
      .type('{enter}');

    allBlocks().its('length').should('eq', 3);
    block(0).should('contain.text', 'This is the title of your ');
    block(1).should('contain.text', 'page');
    block(2).should('contain.text', 'This is your first paragraph.');

    focusBlock(1).type('{moveToStart}{backspace}');

    block(0).should('contain.text', 'This is the title of your page');
    block(1).should('contain.text', 'This is your first paragraph.');

    block(0)
      .type('original first ')
      .should('contain.text', 'This is the title of your original first page')
      .type('with more content ')
      .should(
        'contain.text',
        'This is the title of your original first with more content page'
      );
    block(1).should('contain.text', 'This is your first paragraph.');
  });

  it('handles new line in the middle ', () => {
    visitNew();
    allBlocks().its('length').should('eq', 2);

    focusBlock(1)
      .type('{moveToEnd}')
      .type('{leftArrow}{leftArrow}{leftArrow}{leftArrow}{shift+enter}');

    allBlocks().its('length').should('eq', 2);
    block(0).should('contain.text', 'This is the title of your page');

    blockCell(1, 0).should('contain.text', 'This is your first paragr\naph');

    focusBlock(1).type('{moveToStart}{downArrow}{backspace}');
    block(0).should('contain.text', 'This is the title of your page');
    blockCell(1, 0).should('contain.text', 'This is your first paragraph.');
  });

  it('handles new line at end', () => {
    visitNew();
    allBlocks().its('length').should('eq', 2);

    focusBlock(1).type('{selectAll}{rightArrow}{shift+enter}A new line');
    blockCell(1, 0).should(
      'contain.text',
      'This is your first paragraph.\nA new line'
    );

    focusBlock(1).type('{moveToStart}{downArrow}{backspace}');
    blockCell(1, 0).should(
      'contain.text',
      'This is your first paragraph.A new line'
    );
  });

  it('allows toggling styles styles within', () => {
    visitNew();

    selectText(1, 0, 'is').type('{meta+b}');
    blockCell(1, 1).should('have.text', 'is').should('have.class', 'bold');

    selectText(1, 1, 'is').type('{meta+b}');
    blockCell(1, 0).should('have.text', 'This is your first paragraph.');

    selectText(1, 0, 'your').type('{meta+i}');
    blockCell(1, 1).should('have.text', 'your').should('have.class', 'italic');

    selectText(1, 1, 'your').type('{meta+i}');
    blockCell(1, 0).should('have.text', 'This is your first paragraph.');
  });
});
