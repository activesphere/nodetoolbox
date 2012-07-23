$(document).ready () ->
  $('.package').twipsy?()
  $('.chosen-categories').chosen().change () ->
    form = $(this).parent()
    $.post form.attr('action'), form.serialize(), ()->
      true
    false
  $('span.timeago').timeago()
  unless $("#top_dependent_packages").length is 0
    $("#top_dependent_packages").ready () ->
      $.get '/top_dependent_packages', (data) ->
        $("#top_dependent_packages").html(data)

  unless $("#recently_added").length is 0
    $("#recently_added").ready () ->
      $.get '/recently_added', (data) ->
        recently_added_element = $("#recently_added")
        recently_added_element.html(data)
        recently_added_element.find('.timeago').timeago()
        return recently_added_element

  $(".content").delegate  ".close", 'click', (event) ->
    event.preventDefault()
    $(this).parent().hide()

  $('#like a').click () ->
    pkg = $(this).data 'package'
    jqXHR = $.ajax(type: 'POST',url: "/packages/#{pkg}/like")
    jqXHR.success (data) -> $('.like_count').text data.count
    jqXHR.fail (jqxhr, message) -> alert  jqxhr.responseText
