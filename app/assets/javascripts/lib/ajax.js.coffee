## TODO: выпилить это, т.к. везде должны использоваться либо turbolinks, либо postloader
#pending_request = null

## подгрузка части контента аяксом
#@do_ajax = (url, $postloader, break_pending) ->
  #url = location.protocol + "//" + location.host + url  if url.indexOf(location.protocol + "//" + location.host) is -1
  #$.ajax
    #url: url
    #data: null
    #dataType: "json"
    #beforeSend: (xhr) ->
      #if pending_request and break_pending
        #if 'abort' of pending_request
          #pending_request.abort()
        #else
          #pending_request.aborted = true
        #pending_request = null

      #if $(@).hasClass('disabled') || pending_request
        #xhr.abort()
        #return

      #cached_data = AjaxCacher.get(url)

      #if cached_data
        #xhr.abort()

        #if "abort" of cached_data and "setRequestHeader" of cached_data
          #self = this
          #cached_data.success((data, status, xhr) ->
            #process_ajax data, url, $postloader
            #return
          #).complete(@complete).error @error
        #else
          #process_ajax cached_data, url, $postloader
          #return

      #else

      #pending_request = this

      ## если подгрузка следующей страницы при прокруте, то никаких индикаций загрузки не надо
      #return if $postloader
      #if $(".ajax").children().length isnt 1 or $(".ajax").children(".ajax-loading").length isnt 1
        #$(".ajax:not(.no-animation), .ajax-opacity").animate opacity: 0.3
        #$(".ajax.no-animation").css opacity: 0.3
      #$.cursorMessage()

    #success: (data, status, xhr) ->
      #AjaxCacher.push url, data
      #return if "aborted" of this and @aborted
      #process_ajax data, url, $postloader

    #complete: (xhr) ->
      #pending_request = null

    #error: (xhr, status, error) ->
      #pending_request = null
      #try
        #errors = JSON.parse(xhr.responseText)
      #catch e
        #errors = {}
      #if xhr.responseText.match(/invalid/) # || xhr.responseText.match(/unauthenticated/)) {
        #$.flash alert: "Неверный логин или пароль"
      #else if xhr.status is 401
        #$.flash alert: "Вы не авторизованы"
        #$("#sign_in").trigger "click"
      #else if xhr.status is 403
        #$.flash alert: "У вас нет прав для данного действия"
      #else if _.size(errors)
        #$.flash alert: _.map(errors, (v, k) ->
          #"<strong>" + ((if k of I18N then I18N[k] else k)) + "</strong> " + v
        #).join("<br />")
      #else
        #$.flash alert: "Пожалуста, повторите попытку позже"
      #$.hideCursorMessage()
      #$(".ajax").trigger("ajax:failure").unbind "ajax:success"
      #history.back()

#process_ajax = (data, url, $postloader) ->
  #if $postloader
    #process_ajax_postload data, url, $postloader
  #else
    #process_ajax_response data, url

## обработка контента, полученного при прокрутке вниз
#process_ajax_postload = (data, url, $postloader) ->
  #$postloader.replaceWith data.content

## обработка контента, полученного при подгрузке произвольной страницы
#process_ajax_response = (data, url) ->
  #$content = $(".ajax")
  #$content.html data.content
  #if data.title_page
    #document.title = ((if ("current_page" of data) and data.current_page > 1 then "Страница " + data.current_page + " / " else "")) + ((if "head_title" of data then data.head_title else "")) + ((if data.title_page.constructor is Array then data.title_page.reverse().join(" / ") else data.title_page)) + " / Шикимори"
    #title = data.h1 or data.title_page
    #$(".new-header h1, .forum-nav .title, .head.ajaxable h1").html title
    #$(".new-header .description, .forum-nav .notice, .head.ajaxable .notice").html data.title_notice

  ## отслеживание страниц в гугл аналитике и яндекс метрике
  #if url
    #if "_gaq" of window
      #_gaq.push [
        #"_trackPageview"
        #url.replace(/\.json$/, "")
      #]
    #yaCounter7915231.hit url.replace(/\.json$/, "") if "yaCounter7915231" of window

  #$content.add(".ajax-opacity").stop(true, false).css "opacity", 1
  #$.hideCursorMessage()
  #$(".ajax").trigger("ajax:success", data).unbind "ajax:failure"
