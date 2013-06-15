(function ($) {

  function init() {
    showSetup();
    attachToDom();
  }
  
  function setCookie(c_name,value,exdays) {
    var exdate=new Date();
    exdate.setDate(exdate.getDate() + exdays);
    var c_value=escape(value) + ((exdays==null) ? "" : "; expires="+exdate.toUTCString());
    document.cookie=c_name + "=" + c_value;
  }

  function readCookie(name) {
    var nameEQ = name + "=";
    var ca = document.cookie.split(';');
    for(var i=0;i < ca.length;i++) {
        var c = ca[i];
        while (c.charAt(0)==' ') c = c.substring(1,c.length);
        if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
    }
    return null;
  }

  function showSetup() {
    if(document.cookie.match(/kindle_mail/)==null) {
      //$('#setupNotice').modal();
    } else {
      var email = readCookie('kindle_mail');
      $('input[name="email"]').val(email);
    }
  }

  function attachToDom() {
    $('#notice-form').submit(function() {
      var email = $('#kindle-mail').val();
      if (email.match(/kindle\.com/)!=null) {
	setCookie('kindle_mail',email,300);
	$('input[name="email"]').val(email);
	$('#setupNotice').modal('hide');
      } else {
	alert('must use a kindle.com or free.kindle.com email address for this to work.')
      }
      return false;
    });
  }

  init();

}(jQuery));