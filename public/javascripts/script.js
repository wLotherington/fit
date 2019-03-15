$(function() {
  $("form.delete").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Are you sure you want to delete this?");
    if (ok) {
      this.submit();
    }
  });
});

function toggle_visiblity(idx) {
  var x = document.getElementById(idx);
  if (x.style.visibility === "collapse") {
    x.style.visibility = "visible";
  } else {
    x.style.visibility = "collapse";
  }
}
