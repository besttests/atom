_ = require 'underscore-plus'
{Disposable} = require 'event-kit'
{$} = require './space-pen-extensions'

# Essential: Associates tooltips with HTML elements or selectors.
#
# You can get the `TooltipManager` via `atom.tooltips`.
#
# ## Examples
#
# The essence of displaying a tooltip
#
# ```coffee
# # display it
# disposable = atom.tooltips.add(div, {title: 'This is a tooltip'})
#
# # remove it
# disposable.dispose()
# ```
#
# In practice there are usually multiple tooltips. So we add them to a
# CompositeDisposable
#
# ```coffee
# {CompositeDisposable} = require 'atom'
# subscriptions = new CompositeDisposable
#
# div1 = document.createElement('div')
# div2 = document.createElement('div')
# subscriptions.add atom.tooltips.add(div1, {title: 'This is a tooltip'})
# subscriptions.add atom.tooltips.add(div2, {title: 'Another tooltip'})
#
# # remove them all
# subscriptions.dispose()
# ```
#
# You can display a key binding in the tooltip as well with the
# `keyBindingCommand` option.
#
# ```coffee
# disposable = atom.tooltips.add @caseOptionButton,
#   title: "Match Case"
#   keyBindingCommand: 'find-and-replace:toggle-case-option'
#   keyBindingTarget: @findEditor.element
# ```
module.exports =
class TooltipManager
  defaults:
    delay:
      show: 1000
      hide: 100
    container: 'body'
    html: true
    placement: 'auto top'
    viewportPadding: 2

  # Essential: Add a tooltip to the given element.
  #
  # * `target` An `HTMLElement`
  # * `options` See http://getbootstrap.com/javascript/#tooltips for a full list
  #   of options. You can also supply the following additional options:
  #   * `title` {String} Text in the tip.
  #   * `keyBindingCommand` A {String} containing a command name. If you specify
  #     this option and a key binding exists that matches the command, it will
  #     be appended to the title or rendered alone if no title is specified.
  #   * `keyBindingTarget` An `HTMLElement` on which to look up the key binding.
  #     If this option is not supplied, the first of all matching key bindings
  #     for the given command will be rendered.
  #
  # Returns a {Disposable} on which `.dispose()` can be called to remove the
  # tooltip.
  add: (target, options) ->
    requireBootstrapTooltip()

    {keyBindingCommand, keyBindingTarget} = options

    if keyBindingCommand?
      bindings = atom.keymaps.findKeyBindings(command: keyBindingCommand, target: keyBindingTarget)
      keystroke = getKeystroke(bindings)
      if options.title? and keystroke?
        options.title += " " + getKeystroke(bindings)
      else if keystroke?
        options.title = getKeystroke(bindings)

    $target = $(target)
    $target.tooltip(_.defaults(options, @defaults))

    new Disposable ->
      tooltip = $target.data('bs.tooltip')
      tooltip.leave(currentTarget: target)
      tooltip.hide()
      $target.tooltip('destroy')

humanizeKeystrokes = (keystroke) ->
  keystrokes = keystroke.split(' ')
  keystrokes = (_.humanizeKeystroke(stroke) for stroke in keystrokes)
  keystrokes.join(' ')

getKeystroke = (bindings) ->
  if bindings?.length
    "<span class=\"keystroke\">#{humanizeKeystrokes(bindings[0].keystrokes)}</span>"
  else

requireBootstrapTooltip = _.once ->
  atom.requireWithGlobals('bootstrap/js/tooltip', {jQuery: $})
