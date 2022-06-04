import { addBlockButton } from './utils';

export class NewPage {
  visit() {
    return cy.visit('/documents/new').get('.phx-connected');
  }

  get blocks() {
    return cy.get('.philtre-block');
  }

  get sections() {
    return cy.get('.philtre-page__section');
  }

  sectionAt(index: number) {
    return this.sections.eq(index);
  }

  backspace(blockIndex: number) {
    return this.blocks
      .eq(blockIndex)
      .click()
      .type('{moveToStart}')
      .type('{backspace}');
  }

  blockType(blockIndex: number) {
    return this.blocks.eq(blockIndex).then((el) => el.prop('tagName'));
  }

  setCursorStart(blockIndex: number) {
    return this.blocks.eq(blockIndex).click().type('{moveToStart}');
  }

  setCursorEnd(blockIndex: number) {
    return this.blocks.eq(blockIndex).click().type('{moveToEnd}');
  }

  newBlockAfter(blockIndex: number) {
    return this.setCursorEnd(blockIndex).type('{enter}');
  }

  clickNewBlockButton(blockIndex: number) {
    return addBlockButton(blockIndex).click();
  }

  get removeBlockButtons() {
    return cy.get('.philtre-page button[phx-click="remove_block"]');
  }

  clickRemoveBlockButton(blockIndex: number) {
    return this.removeBlockButtons.eq(blockIndex).click();
  }

  save() {
    cy.get('button').contains('Save').click();
  }
}
