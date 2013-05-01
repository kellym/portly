$(function() {
  function onMessage(event) {
    console.log(event.data);
	}
	websocket = new WebSocket("ws://localhost:9393/io");
	websocket.onmessage = function(evt) { onMessage(evt); };

});
