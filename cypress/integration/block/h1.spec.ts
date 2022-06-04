import { allBlocks, block, visitNew } from '../../utils';

it('is converted from P, converts down to H2', () => {
  visitNew();
  block(1).focus().type('{moveToStart}# ');
  block(1, 'h1').should('exist');
  allBlocks().should('have.length', 2);

  block(1).focus().type('{moveToStart}{backspace}');
  block(1, 'h2').should('exist');

  block(1).focus().type('{moveToStart}{backspace}');
  block(1, 'h3').should('exist');

  block(1).focus().type('{moveToStart}{backspace}');
  block(1, 'p').should('exist');
});

it('splits into P', () => {
  visitNew();
  block(1).focus().type('{moveToEnd}{enter}');
  allBlocks().should('have.length', 3);
  block(0, 'h1').should('exist');
  block(1, 'p').should('exist');
  block(2, 'p').should('exist');
});

it('can start as an empty block (regression)', () => {
  // there was a bug where starting a new blank block and typing into it would
  // error out, due to it starting with a fully empty string, so the block was
  // focusing into a test node

  visitNew();
  block(1).focus().type('{moveToEnd}{enter}');
  block(2, 'p').focus().type('# ');
  block(2, 'h1').type('New header');

  block(2, 'h1').should('contain.text', 'New header');
});
