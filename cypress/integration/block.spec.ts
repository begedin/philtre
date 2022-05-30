import { NewPage } from '../pageModel';

const allBlocks = () => cy.get('[data-block]');

const block = (blockIndex: number) => allBlocks().eq(blockIndex);

const focusBlock = (blockIndex: number) => block(blockIndex).focus();

const focusStartOfBlock = (blockIndex: number) =>
  focusBlock(blockIndex).type('{moveToStart}');

const blockCell = (blockIndex: number, cellIndex: number) =>
  block(blockIndex).find('[data-cell-id]').eq(cellIndex);

const visitNew = () => cy.visit('/documents/new').get('.phx-connected');

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
      console.log(el.innerText);

      range.setStart(el.childNodes[0], textIndex);
      range.setEnd(el.childNodes[0], textIndex + text.length);

      const selection = document.getSelection();
      selection.removeAllRanges();
      selection.addRange(range);
    });

it('loads default content', () => {
  const page = new NewPage();
  page.visit();

  allBlocks().its('length').should('eq', 2);
  block(0).should('contain.text', 'This is the title of your page');
  block(1).should('contain.text', 'This is your first paragraph.');
});

it('splits and joins blocks correctly', () => {
  const page = new NewPage();
  page.visit();
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

it('handles new line in the middle of block', () => {
  const page = new NewPage();
  page.visit();
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

it('handles new line at end of block', () => {
  const page = new NewPage();
  page.visit();
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

it('allows toggling styles styles within a block', () => {
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

describe('H1', () => {
  it('is converted from P, converts down to H2', () => {
    const page = new NewPage();
    page.visit();
    focusBlock(1).type('{moveToStart}# ');
    cy.get('h1.philtre-block').should('have.length', 2);
    page.blockType(1).should('eq', 'H1');
    page.backspace(1);
    page.blockType(1).should('eq', 'H2');
    page.backspace(1);
    page.blockType(1).should('eq', 'H3');
    page.backspace(1);
    page.blockType(1).should('eq', 'P');
  });

  it('splits into P', () => {
    const page = new NewPage();
    page.visit();
    page.newBlockAfter(0);
    page.blocks.its('length').should('eq', 3);
    page.blockType(0).should('eq', 'H1');
    page.blockType(1).should('eq', 'P');
    page.blockType(2).should('eq', 'P');
  });
});

describe('H2', () => {
  it('is converted from P, converts down to H3', () => {
    const page = new NewPage();
    page.visit();
    page
      .setCursorStart(1)
      .type('## ')
      .get('h2.philtre-block')
      .should('have.length', 1);

    page.blockType(1).should('eq', 'H2');
    page.backspace(1);
    page.blockType(1).should('eq', 'H3');
  });

  it('splits into P', () => {
    const page = new NewPage();
    page.visit();
    page
      .setCursorStart(1)
      .type('## ')
      .get('h2.philtre-block')
      .should('have.length', 1);

    page.newBlockAfter(1);
    page.blocks.its('length').should('eq', 3);
    page.blockType(0).should('eq', 'H1');
    page.blockType(1).should('eq', 'H2');
    page.blockType(2).should('eq', 'P');
  });
});

describe('H3', () => {
  it('is converted from P, converts down to P', () => {
    const page = new NewPage();
    page.visit();
    focusStartOfBlock(1)
      .type('### ')
      .get('h3.philtre-block')
      .should('have.length', 1);
    page.blockType(1).should('eq', 'H3');
    page.backspace(1);
    page.blockType(1).should('eq', 'P');
  });

  it('splits into P', () => {
    const page = new NewPage();
    page.visit();
    focusStartOfBlock(1)
      .type('### ')
      .get('h3.philtre-block')
      .should('have.length', 1);
    page.newBlockAfter(1);
    page.blocks.its('length').should('eq', 3);
    page.blockType(0).should('eq', 'H1');
    page.blockType(1).should('eq', 'H3');
    page.blockType(2).should('eq', 'P');
  });
});

describe('PRE', () => {
  it('is converted from P, converts down to P', () => {
    const page = new NewPage();
    page.visit();
    focusStartOfBlock(1)
      .type('```')
      .get('pre.philtre-block')
      .should('have.length', 1);
    page.blockType(1).should('eq', 'PRE');
    page.backspace(1);
    page.blockType(1).should('eq', 'P');
  });

  it('splits into P', () => {
    const page = new NewPage();
    page.visit();
    focusStartOfBlock(1).type('```');
    cy.get('pre.philtre-block').should('have.length', 1);
    page.newBlockAfter(1);
    page.blocks.its('length').should('eq', 3);
    page.blockType(0).should('eq', 'H1');
    page.blockType(1).should('eq', 'PRE');
    page.blockType(2).should('eq', 'P');
  });
});

describe('BLOCKQUOTE', () => {
  it('is converted from P, converts down to P', () => {
    const page = new NewPage();
    page.visit();
    focusStartOfBlock(1)
      .type('> ')
      .get('blockquote.philtre-block')
      .should('have.length', 1);
    page.blockType(1).should('eq', 'BLOCKQUOTE');
    page.backspace(1);
    page.blockType(1).should('eq', 'P');
  });

  it('splits into P', () => {
    const page = new NewPage();
    page.visit();
    focusStartOfBlock(1)
      .type('> ')
      .get('blockquote.philtre-block')
      .should('have.length', 1);
    page.newBlockAfter(1);
    allBlocks().its('length').should('eq', 3);
    page.blockType(0).should('eq', 'H1');
    page.blockType(1).should('eq', 'BLOCKQUOTE');
    page.blockType(2).should('eq', 'P');
  });
});

describe('LI', () => {
  it('is converted from P, converts down to P', () => {
    const page = new NewPage();
    page.visit();
    focusStartOfBlock(1)
      .type('* ')
      .get('li.philtre-block')
      .should('have.length', 1);
    page.blockType(1).should('eq', 'LI');
    page.backspace(1);
    page.blockType(1).should('eq', 'P');
  });

  it('splits into LI', () => {
    const page = new NewPage();
    page.visit();
    focusStartOfBlock(1)
      .type('* ')
      .get('li.philtre-block')
      .should('have.length', 1);
    page.newBlockAfter(1);
    page.blocks.its('length').should('eq', 3);
    page.blockType(0).should('eq', 'H1');
    page.blockType(1).should('eq', 'LI');
    page.blockType(2).should('eq', 'LI');
  });
});
