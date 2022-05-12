import { NewPage } from '../pageModel';

it('loads default content', () => {
  const page = new NewPage();
  page.visit();

  page.blocks.its('length').should('eq', 2);
  page.blocks.eq(0).should('contain.text', 'This is the title of your page');
  page.blocks.eq(1).should('contain.text', 'This is your first paragraph.');
});

it('splits and joins blocks correctly', () => {
  const page = new NewPage();
  page.visit();
  page.blocks.its('length').should('eq', 2);

  page
    .setCursorEnd(0)
    .type('{selectall}{rightArrow}')
    .type('{leftArrow}{leftArrow}{leftArrow}{leftArrow}')
    .type('{enter}');

  page.blocks.its('length').should('eq', 3);
  page.blocks.eq(0).should('contain.text', 'This is the title of your ');
  page.blocks.eq(1).should('contain.text', 'page');
  page.blocks.eq(2).should('contain.text', 'This is your first paragraph.');

  page.backspace(1);

  page.blocks.eq(0).should('contain.text', 'This is the title of your page');
  page.blocks.eq(1).should('contain.text', 'This is your first paragraph.');

  page.blocks
    .eq(0)
    .type('original first ')
    .should('contain.text', 'This is the title of your original first page')
    .type('with more content ')
    .should(
      'contain.text',
      'This is the title of your original first with more content page'
    );
  page.blocks.eq(1).should('contain.text', 'This is your first paragraph.');
});

it('splits and joins lines correctly', () => {
  const page = new NewPage();
  page.visit();
  page.blocks.its('length').should('eq', 2);

  page
    .setCursorEnd(1)
    .type('{selectall}{rightArrow}')
    .type('{leftArrow}{leftArrow}{leftArrow}{leftArrow}{shift+enter}');

  page.blocks.its('length').should('eq', 2);
  page.blocks.eq(0).should('contain.text', 'This is the title of your page');
  page.blocks
    .eq(1)
    .find('.philtre-cell')
    .eq(0)
    .should('contain.text', 'This is your first paragr');

  page.blocks.eq(1).find('.philtre-cell').eq(1).should('have.text', '');
  page.blocks.eq(1).find('.philtre-cell').eq(2).should('have.text', 'aph.');

  page.blocks.eq(1).type('{backspace}');

  page.blocks.eq(0).should('contain.text', 'This is the title of your page');
  page.blocks.eq(1).should('contain.text', 'This is your first paragraph.');
});

describe('H1', () => {
  it('is converted from P, converts down to H2', () => {
    const page = new NewPage();
    page.visit();
    page
      .setCursorStart(1)
      .type('# ')
      .get('h1.philtre-block')
      .should('have.length', 2);
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
    page
      .setCursorStart(1)
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
    page
      .setCursorStart(1)
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
    page
      .setCursorStart(1)
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
    page.setCursorStart(1).type('```');
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
    page
      .setCursorStart(1)
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
    page
      .setCursorStart(1)
      .type('> ')
      .get('blockquote.philtre-block')
      .should('have.length', 1);
    page.newBlockAfter(1);
    page.blocks.its('length').should('eq', 3);
    page.blockType(0).should('eq', 'H1');
    page.blockType(1).should('eq', 'BLOCKQUOTE');
    page.blockType(2).should('eq', 'P');
  });
});

describe('LI', () => {
  it('is converted from P, converts down to P', () => {
    const page = new NewPage();
    page.visit();
    page
      .setCursorStart(1)
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
    page
      .setCursorStart(1)
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
