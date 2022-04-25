/// <reference types="cypress" />
declare class NewPage {
    visit(): Cypress.Chainable<JQuery<HTMLElement>>;
    get blocks(): Cypress.Chainable<JQuery<HTMLElement>>;
    backspace(blockIndex: number): Cypress.Chainable<JQuery<HTMLElement>>;
    blockType(blockIndex: number): Cypress.Chainable<any>;
    setCursorStart(blockIndex: number): Cypress.Chainable<JQuery<HTMLElement>>;
    setCursorEnd(blockIndex: number): Cypress.Chainable<JQuery<HTMLElement>>;
    newBlockAfter(blockIndex: number): Cypress.Chainable<JQuery<HTMLElement>>;
}
