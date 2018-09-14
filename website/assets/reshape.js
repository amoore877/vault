const footer = require('@hashicorp/hashi-footer')
const nav = require('@hashicorp/hashi-nav')
const button = require('@hashicorp/hashi-button')
const productSubnav = require('@hashicorp/hashi-product-subnav')
const content = require('@hashicorp/hashi-content')

const docsSidebar = require('./js/components/docs-sidebar')

module.exports = {
  'hashi-footer': footer,
  'hashi-nav': nav,
  'hashi-button': button,
  'hashi-docs-sidebar': docsSidebar,
  'hashi-product-subnav': productSubnav,
  'hashi-content': content
}
