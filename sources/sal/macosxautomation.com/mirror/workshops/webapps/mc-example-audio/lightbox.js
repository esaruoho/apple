function lightboxThisImage(triggeringLink) {
    // turn off document scroll behind lightbox
	document.body.style.overflow="hidden";
	makeOverlay();
	addImage(triggeringLink);
}
function makeOverlay() {
	// create the overlay element in memory
	var overlay = document.createElement('div');
	// assign the created element an ID
	overlay.id = 'overlay';
	// insert the element into the body of the document
	document.body.appendChild(overlay);
	// create a container for the image
	var contentBox = document.createElement('div');
	// assign the created element an ID
	contentBox.id = 'content-box';
	// insert the element into the overlay
	overlay.appendChild(contentBox);
	// assign properties and trigger transistion by setting the class name of the added element
	setTimeout("overlay.className='visible';", 0);    
}
function removeOverlay() {
    // turn on document scroll behind lightbox
	document.body.style.overflow="auto";
	// locate the overlay
	var overlay = document.getElementById('overlay');
	// changing its class triggers the transistion again
	overlay.className='invisible';
	// remove the element. The timeout value must be slightly larger than the transistion duration.
	setTimeout('document.body.removeChild(overlay);',600);
}
function addImage(triggerImageLink) {
	// retrieve the path to the high-res version
	var imageURL = triggerImageLink.getAttribute('highResURL');
	// retrieve the caption
	var imageCaption = triggerImageLink.getAttribute('caption');
	// locate the content box
	var contentBox = document.getElementById('content-box');
	// create an image object
	var displayImage = document.createElement("img");
	// set the source parameter of the image object
	displayImage.setAttribute('src', imageURL);
	// append the image to the content box
	contentBox.appendChild(displayImage);
	// make the image a clickable close object
	displayImage.addEventListener('click', function() {
		removeOverlay();
	}, false);
	var overlayLayer = document.getElementById('overlay');
	// create a container for the caption
	var captionBox = document.createElement('div');
	// assign an ID to the caption box
	captionBox.id = 'caption-box';
	// insert the caption into the caption box
	captionBox.innerHTML = imageCaption;
	// append the caption to the content box
	contentBox.appendChild(captionBox);
}
