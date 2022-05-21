import { NewPage } from '../pageModel';

beforeEach(() => {
  cy.exec('rm -rf playground/priv/documents/cypress_*', {
    log: true,
    failOnNonZeroExit: false,
  });
});

const openFile = (filename: string): Cypress.Chainable =>
  cy.get(`a[href*="${filename}.json"]`).click();

const rowAt = (rowIndex: number) => cy.get('table').find('tr').eq(rowIndex);

const cellAt = (rowIndex: number, cellIndex: number) =>
  rowAt(rowIndex).find('td').eq(cellIndex);

const navigateToFileInReadOnly = (filename: string): Cypress.Chainable => {
  cy.visit('/');
  return openFile(filename);
};

const createTable = () => {
  const page = new NewPage();
  page.visit();
  page.clickNewBlockButton(1);
  return page.setCursorStart(2).type('/table');
};

const savePage = () => {
  const timestamp = new Date().toISOString();
  const filename = `cypress_${timestamp}`;
  cy.get('input[name=filename]').type(filename);
  cy.get('button').contains('Save').click();
  return filename;
};

it('can save a page containing a table', () => {
  const page = new NewPage();
  page.visit();

  page.clickNewBlockButton(1);
  page.setCursorStart(2).type('/table');

  page.sectionAt(2).get('table').should('exist').type('foo');

  const filename = savePage();
  openFile(filename);

  page
    .sectionAt(2)
    .get('table')
    .should('exist')
    .find('input[type=text]')
    .should('have.value', 'foo');
});

it('can render a saved table in read-only', () => {
  createTable();

  cy.get('table').find('button[phx-click="add_column"]').click();
  cy.get('table').find('button[phx-click="add_row"]').click();

  cellAt(1, 0).type('foo');
  cellAt(1, 1).type('bar');
  cellAt(2, 0).type('baz');
  cellAt(2, 1).type('bam');

  const filename = savePage();

  navigateToFileInReadOnly(filename);

  cellAt(0, 0).should('have.text', 'foo');
  cellAt(0, 1).should('have.text', 'bar');
  cellAt(1, 0).should('have.text', 'baz');
  cellAt(1, 1).should('have.text', 'bam');
});

it('can add and remove rows and columns', () => {
  createTable();
  cy.get('table tr').should('have.length', 3);

  cy.get('table').find('button[phx-click="add_row"]').click();
  cy.get('table tr').should('have.length', 4);

  cy.get('table').find('button[phx-click="remove_row"]').eq(0).click();
  cy.get('table tr').should('have.length', 3);

  rowAt(1).find('td').should('have.length', 3);

  rowAt(1).find('button[phx-click="add_column"]').click();
  rowAt(1).find('td').should('have.length', 4);

  rowAt(0).find('button[phx-click="remove_column"]').eq(1).click();
  rowAt(1).find('td').should('have.length', 3);
});
