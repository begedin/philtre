import { block, visitNew } from '../../utils';

it('is converted from P, converts down to P', () => {
  visitNew();
  block(1).focus().type('{moveToStart}```');
  block(1, 'pre').should('exist');

  block(1, 'pre').type('{moveToStart}{backspace}');
  block(1, 'p').should('exist');
});

it('splits into P', () => {
  visitNew();
  block(1).focus().type('{moveToStart}```');
  block(1, 'pre').type('{moveToEnd}{enter}');

  block(0, 'h1').should('exist');
  block(1, 'pre').should('exist');
  block(2, 'p').should('exist');
});
