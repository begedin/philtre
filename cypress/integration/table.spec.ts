import { NewPage } from '../pageModel';
import {
  createTable,
  deleteTestFiles,
  navigateToFileInReadOnly,
  openFile,
} from '../utils';

beforeEach(() => {
  deleteTestFiles();
});

const rowAt = (rowIndex: number) => cy.get('table').find('tr').eq(rowIndex);

const cellAt = (rowIndex: number, cellIndex: number) =>
  rowAt(rowIndex).find('td,th').eq(cellIndex);

const savePage = () => {
  const timestamp = new Date().toISOString();
  const filename = `cypress_${timestamp}`;
  cy.get('input[name=filename]').type(filename);
  cy.get('button').contains('Save').click();
  return filename;
};

it('can save a page containing a table', () => {
  createTable();

  const page = new NewPage();
  page
    .sectionAt(2)
    .get('table')
    .should('exist')
    .find('textarea')
    .eq(0)
    .type('foo');

  const filename = savePage();
  openFile(filename);

  page
    .sectionAt(2)
    .get('table')
    .should('exist')
    .find('textarea')
    .eq(0)
    .should('have.text', 'foo');
});

it('can render a saved table in read-only', () => {
  createTable();

  cy.get('button[phx-click="add_column"]').click();
  cy.get('button[phx-click="add_row"]').click();

  cellAt(0, 0).find('textarea').type('foo');
  cellAt(0, 1).find('textarea').type('bar');
  cellAt(1, 0).find('textarea').type('baz');
  cellAt(1, 1).find('textarea').type('bam');

  const filename = savePage();

  navigateToFileInReadOnly(filename);

  cellAt(0, 0).should('have.text', 'foo');
  cellAt(0, 1).should('have.text', 'bar');
  cellAt(1, 0).should('have.text', 'baz');
  cellAt(1, 1).should('have.text', 'bam');
});

it('can add and remove rows and columns', () => {
  createTable();
  cy.get('table thead tr').should('have.length', 1);
  cy.get('table tbody tr').should('have.length', 1);

  cy.get('button[phx-click="add_row"]').click();
  cy.get('table thead tr').should('have.length', 1);
  cy.get('table tbody tr').should('have.length', 2);

  cy.get('button[phx-click="remove_row"]').eq(1).click();
  cy.get('table thead tr').should('have.length', 1);
  cy.get('table tbody tr').should('have.length', 1);

  rowAt(1).find('td').should('have.length', 1);

  cy.get('button[phx-click="add_column"]').click();
  rowAt(1).find('td').should('have.length', 2);

  cy.get('button[phx-click="remove_column"]').eq(1).click();
  rowAt(1).find('td').should('have.length', 1);
});
