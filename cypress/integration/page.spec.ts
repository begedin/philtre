import { NewPage } from '../pageModel';

it('can add and remove a block using buttons', () => {
  const page = new NewPage();
  page.visit();

  page.blocks.its('length').should('eq', 2);
  page.clickNewBlockButton(1);
  page.blocks.its('length').should('eq', 3);
  page.clickRemoveBlockButton(2);
  page.blocks.its('length').should('eq', 2);
});
