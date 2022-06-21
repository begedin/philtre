import {
  addBlockButton,
  allBlocks,
  block,
  removeBlockButton,
  section,
  visitNew,
} from '../utils';

describe('ui.page', () => {
  it('loads default content', () => {
    visitNew();

    allBlocks().its('length').should('eq', 2);
    block(0).should('contain.text', 'This is the title of your page');
    block(1).should('contain.text', 'This is your first paragraph.');
  });

  it('can add and remove a block using buttons', () => {
    visitNew();
    allBlocks().should('have.length', 2);

    addBlockButton(1).click();
    allBlocks().should('have.length', 3);
    removeBlockButton(2).click();
    allBlocks().should('have.length', 2);
  });

  it('can add and edit a li after a code block (regression)', () => {
    visitNew();
    block(1).focus().type('{moveToEnd}{enter}');
    block(2).focus().type('* ');

    block(2, 'li').type('A list item').type('{enter}');
    allBlocks().should('have.length', 4);
    block(3, 'li').focus().type('Another list item');

    block(2).should('contain.text', 'A list item');
    block(3).should('contain.text', 'Another list item');
  });

  // not the most robust of tests, as tab is achieved via custom plugin and
  // typing without changing focus is not easily possible
  it('can navigate focused blocks via tab and shift+tab', () => {
    visitNew();
    section(0).focus().tab();
    section(0).should('not.have.attr', 'data-focused');
    section(1).should('have.attr', 'data-focused');
    section(1).focus().tab({ shift: true });

    section(1).should('not.have.attr', 'data-focused');
    section(0).should('have.attr', 'data-focused');

    // ensures merging blocks preserves focus
    block(1).type('{moveToEnd}{enter}');
    block(2).should('exist');
    section(2).should('have.attr', 'data-focused');
    block(2).focus().type('bar').type('{moveToStart}').type('{backspace}');

    section(1).should('have.attr', 'data-focused');
    section(0).should('not.have.attr', 'data-focused');

    block(1).should('contain.text', 'paragraph.bar').tab({ shift: true });
    section(1).should('not.have.attr', 'data-focused');
    section(0).should('have.attr', 'data-focused');
  });
});
