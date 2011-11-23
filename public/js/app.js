(function() {
  $(document).ready(function() {
    $('.package').twipsy();
    $('span.timeago').timeago();
    if ($("#top_dependent_packages").length !== 0) {
      $("#top_dependent_packages").ready(function() {
        return $.get('/top_dependent_packages', function(data) {
          return $("#top_dependent_packages").html(data);
        });
      });
    }
    if ($("#recently_added").length !== 0) {
      $("#recently_added").ready(function() {
        return $.get('/recently_added', function(data) {
          var recently_added_element;
          recently_added_element = $("#recently_added");
          recently_added_element.html(data);
          recently_added_element.find('.timeago').timeago();
          return recently_added_element;
        });
      });
    }
    $(".content").delegate(".close", 'click', function(event) {
      event.preventDefault();
      return $(this).parent().hide();
    });
    return $('#like a').click(function() {
      var jqXHR, package;
      package = $(this).data('package');
      jqXHR = $.ajax({
        type: 'POST',
        url: "/packages/" + package + "/like"
      });
      jqXHR.success(function(data) {
        return $('.like_count').text(data.count);
      });
      return jqXHR.fail(function(jqxhr, message) {
        return alert(jqxhr.responseText);
      });
    });
  });
}).call(this);
