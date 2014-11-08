$(document).on 'click', '.collapse', (e, custom) ->
  $this = $(@)
  is_hide = $this.children('.action').html().match(/свернуть/)

  # блок-заглушка, в которую сворачивается контент
  $placeholder = $this.next()
  $placeholder = $placeholder.next() unless $placeholder.hasClass('collapsed')

  # еонтент, убираемый под спойлер
  $hideable = $placeholder.next()

  # если в $hideable ничего, значит надо идти на уровень выше и брать next оттуда
  $hideable = $this.parent().next() unless $hideable.exists()

  # скрываем не только следующий элемент, но и все последующие с классом collapse-merged
  $hideable = $hideable.add($hideable.last().next())  while $hideable.last().next().hasClass('collapse-merged')

  # при этом игнорируем то, что имеет класс collapse-ignored
  $hideable = $hideable.filter(':not(.collapse-ignored)')  if $hideable.length > 1
  if is_hide
    $placeholder.show()
    $hideable.hide()
  else
    $hideable.show()
    $placeholder.hide()

  # корректный текст для кнопки действия
  $this.children('.action').html ->
    $this = $(this)

    if $this.hasClass('half-hidden')
      if is_hide
        $this.hide()
      else
        $this.show()

    if is_hide
      $this.html().replace('свернуть', 'развернуть')
    else
      $this.html().replace('развернуть', 'свернуть')

  unless custom
    id = $this.parent().attr('id')
    if id && id != '' && id.indexOf('-') != -1
      name = id.split('-').slice(1).join("-") + ";"
      collapses = $.cookie('collapses') || ''
      if is_hide && collapses.indexOf(name) == -1
        $.cookie "collapses", collapses + name,
          expires: 730
          path: "/"

      else if !is_hide && collapses.indexOf(name) != -1
        $.cookie "collapses", collapses.replace(name, ""),
          expires: 730
          path: "/"

  $placeholder.next().trigger "show"

  # всем картинкам внутри спойлера надо заново проверить высоту
  #$hideable.find('img').addClass 'check-width'

# клик на "свернуть"
$(document).on 'click', '.collapsed', ->
  $trigger = $(@).prev()
  $trigger = $trigger.prev() unless $trigger.hasClass('collapse')
  $trigger.trigger('click')

# клик на содержимое спойлера
$(document).on 'click', '.spoiler.target', ->
  return unless $(@).hasClass('dashed')
  $(@).hide().prev().show().prev().show()

