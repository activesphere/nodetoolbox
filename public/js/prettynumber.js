(function($) {
	$.fn.prettynumber = function(options) {
		var opts = $.extend({}, $.fn.prettynumber.defaults, options);
		return this.each(function() {
			$this = $(this);
			var o = $.meta ? $.extend({}, opts, $this.data()) : opts;
			var str = $this.html();
			$this.html($this.html().toString().replace(new RegExp("(^\\d{"+($this.html().toString().length%3||-1)+"})(?=\\d{3})"),"$1"+o.delimiter).replace(/(\d{3})(?=\d)/g,"$1"+o.delimiter));
		});
	};
	$.fn.prettynumber.defaults = {
		delimiter       : '.'	
	};
})(jQuery);