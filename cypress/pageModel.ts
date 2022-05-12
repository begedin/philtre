export class NewPage {
  visit() {
    return cy.visit('/documents/new').get('.phx-connected');
  }

  get blocks() {
    return cy.get('.philtre-block');
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

  get addBlockButtons() {
    return cy.get('.philtre-page button[phx-click="add_block"]');
  }

  clickNewBlockButton(blockIndex: number) {
    return this.addBlockButtons.eq(blockIndex).click();
  }

  get removeBlockButtons() {
    return cy.get('.philtre-page button[phx-click="remove_block"]');
  }

  clickRemoveBlockButton(blockIndex: number) {
    return this.removeBlockButtons.eq(blockIndex).click();
  }
}
