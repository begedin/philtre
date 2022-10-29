// taken from https://github.com/kuceb/cypress-plugin-tab/blob/master/src/index.d.ts
// since migrating Cypress to 10.x.x, this declaration no longer automatically works
// so needs to be pasted here

declare namespace Cypress {
  interface Chainable {
    tab(options?: Partial<{ shift: boolean }>): Chainable;
  }
}
