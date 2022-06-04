import {
  addBlockButton,
  allBlocks,
  block,
  removeBlockButton,
  visitNew,
} from '../utils';

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
