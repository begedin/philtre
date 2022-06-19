import { block, visitNew } from '../../utils';

describe('h3', () => {
  it('is converted from P, converts down to P', () => {
    visitNew();
    block(1).focus().type('{moveToStart}### ');
    block(1, 'h3').should('exist');

    block(1, 'h3').type('{moveToStart}{backspace}');
    block(1, 'p').should('exist');
  });

  it('splits into P', () => {
    visitNew();
    block(1).focus().type('{moveToStart}### ');
    block(1, 'h3').type('{moveToEnd}{enter}');

    block(0, 'h1').should('exist');
    block(1, 'h3').should('exist');
    block(2, 'p').should('exist');
  });
});
