import {
  createCode,
  deleteTestFiles,
  navigateToFileInReadOnly,
  openFile,
} from '../utils';

beforeEach(() => {
  deleteTestFiles();
});

const savePage = () => {
  const timestamp = new Date().toISOString();
  const filename = `cypress_${timestamp}`;
  cy.get('input[name=filename]').type(filename);
  cy.get('button').contains('Save').click();
  return filename;
};

it('can save a page containing a table', () => {
  createCode();
  cy.get('.philtre__code textarea')
    .focus()
    .type('{moveToStart}')
    .type('defmodule Foo do{enter}')
    .type('  @moduledoc false{enter}')
    .type('end');
  const filename = savePage();
  openFile(filename);

  const expectedText = 'defmodule Foo do\n  @moduledoc false\nend';

  cy.get('.philtre__code__highlighted')
    .should('exist')
    .should('have.class', 'language-elixir')
    .should('have.text', expectedText);

  cy.get('textarea.philtre__code__editable').should(
    'have.text',
    'defmodule Foo do\n  @moduledoc false\nend'
  );
});

it('can render a saved table in read-only', () => {
  createCode();

  cy.get('.philtre__code textarea')
    .focus()
    .type('{moveToStart}')
    .type('defmodule Foo do{enter}')
    .type('  @moduledoc false{enter}')
    .type('end');
  const filename = savePage();

  navigateToFileInReadOnly(filename);

  cy.get('pre').should(
    'have.text',
    'defmodule Foo do\n  @moduledoc false\nend'
  );
});
