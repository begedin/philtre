import { block, visitNew } from '../../utils';
describe('li', () => {
  it('is converted from P, converts down to P', () => {
    visitNew();
    block(1).focus().type('{moveToStart}* ');
    block(1, 'li').should('exist');

    block(1, 'li').type('{moveToStart}{backspace}');
    block(1, 'p').should('exist');
  });

  it('splits into LI', () => {
    visitNew();
    block(1).focus().type('{moveToStart}* ');
    block(1, 'li').type('{moveToEnd}{enter}');

    block(0, 'h1').should('exist');
    block(1, 'li').should('exist');
    block(2, 'li').should('exist');
  });
});
