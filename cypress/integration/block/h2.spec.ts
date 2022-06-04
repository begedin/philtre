import { block, visitNew } from '../../utils';

it('is converted from P, converts down to H3', () => {
  visitNew();
  block(1).focus().type('{moveToStart}## ');
  block(1, 'h2').should('exist');

  block(1, 'h2').type('{moveToStart}{backspace}');
  block(1, 'h3').should('exist');
});

it('splits into P', () => {
  visitNew();
  block(1).focus().type('{moveToStart}## ');
  block(1, 'h2').type('{moveToEnd}{enter}');

  block(0, 'h1').should('exist');
  block(1, 'h2').should('exist');
  block(2, 'p').should('exist');
});
