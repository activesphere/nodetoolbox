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

  $('.action a').click () ->
    self = $(this)
    jqXHR = $.ajax(type: 'POST', url: $(this).attr "href")
    jqXHR.success (data) ->
      trigger = self.find '.count'  
      trigger.text data.count
      trigger.tooltip 'show'
      setTimeout(() -> 
        trigger.tooltip 'show'
      , 3000)
    jqXHR.fail (jqxhr, message) ->
      if(jqxhr.status == 403)
        $("#signin").dialog( title: jqxhr.responseText)
    false
  
  $('span.count.badge').tooltip trigger:'manual', placement: 'bottom'