import {
  createCode,
  deleteTestFiles,
  navigateToFileInReadOnly,
  openFile,
  savePage,
} from '../../utils';

beforeEach(() => {
  deleteTestFiles();
});

describe('code', () => {
  it('can save a page containing an elixir code block', () => {
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

  it('can save a page containing a javascript code block', () => {
    createCode();
    cy.get('.philtre__code textarea')
      .focus()
      .type('{moveToStart}')
      .type('const foo = () => false');

    cy.get('.philtre__code')
      .get('.philtre__code__language select')
      .select('javascript');

    const filename = savePage();
    openFile(filename);

    const expectedText = 'const foo = () => false';

    cy.get('.philtre__code__highlighted.language-javascript').should(
      'have.text',
      expectedText
    );

    cy.get('textarea.philtre__code__editable').should(
      'have.text',
      expectedText
    );
  });

  it('can render a saved code block in read-only', () => {
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
});
