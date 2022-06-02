import { NewPage } from './pageModel';

export const deleteTestFiles = () =>
  cy.exec('rm -rf playground/priv/documents/cypress_*', {
    log: true,
    failOnNonZeroExit: false,
  });

export const openFile = (filename: string): Cypress.Chainable =>
  cy.get(`a[href*="${filename}.json"]`).click();

export const navigateToFileInReadOnly = (
  filename: string
): Cypress.Chainable => {
  cy.visit('/');
  return openFile(filename);
};

const createNewBlock = (type: string) => {
  const page = new NewPage();
  page.visit();
  page.clickNewBlockButton(1);
  return page.setCursorStart(2).type(type);
};

export const createTable = () => createNewBlock('/table');

export const createCode = () => createNewBlock('/code');

export const allBlocks = () => cy.get('[data-block]');

export const block = (blockIndex: number) => allBlocks().eq(blockIndex);

export const focusBlock = (blockIndex: number) => block(blockIndex).focus();

export const focusStartOfBlock = (blockIndex: number) =>
  focusBlock(blockIndex).type('{moveToStart}');

export const blockCell = (blockIndex: number, cellIndex: number) =>
  block(blockIndex).find('[data-cell-id]').eq(cellIndex);

export const visitNew = () => cy.visit('/documents/new').get('.phx-connected');
