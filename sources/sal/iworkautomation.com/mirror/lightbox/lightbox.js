function lightboxThisImage(triggerImageLink) {
	// turn off document scroll behind lightbox
	document.body.style.overflow="hidden";
	// retrieve the path to the high-res version
	var imageURL = triggerImageLink.getAttribute('highResURL');
	// retrieve the caption
	var imageCaption = triggerImageLink.getAttribute('caption');
	// retrieve the display width
	var imageWidthString = triggerImageLink.getAttribute('displayWidth');
	var imageWidth = parseInt(imageWidthString);
	// retrieve the display height
	var imageWHeightString = triggerImageLink.getAttribute('displayHeight');
	var imageHeight = parseInt(imageWHeightString);

	// create the overlay element
	var overlay = document.createElement('div');
	// assign the created element an ID
	overlay.id = 'overlay';
	// insert the overlay element into the body of the document
	document.body.appendChild(overlay);
	
	// create a container for the image and caption
	var contentBox = document.createElement('div');
	// assign the created element an ID
	contentBox.id = 'content-box';
	
	// create an image object
	var displayImage = document.createElement("img");
	// set the source parameter of the image object
	displayImage.setAttribute('src', imageURL);
	// adjust the image size to fit based on page and image orientation
	var pagewidth = document.body.clientWidth;
	var pageheight = document.body.clientHeight;
	var imageW = displayImage.width;
	var imageH = displayImage.height;
	var scaledValue = 0;
	if ( pagewidth > pageheight ) {
	 if ( imageW > imageH ) {
	 	displayImage.width = imageW * 2; // pagewidth * 0.65;
	 } else {
	 	displayImage.height = imageH * 2; // pageheight * 0.75;
	 }
	} else {
	 if ( imageH > imageW ) {
	 	displayImage.height = imageW * 1.25; // pageheight * .75;
	 } else {
	 	displayImage.width = imageH * 2; // pagewidth * 0.75;
	 }
	}
	
	displayImage.width = imageWidth;
	displayImage.height = imageHeight;
	
	// append the image to the content box
	contentBox.appendChild(displayImage);
	// make the image a clickable close object
	displayImage.addEventListener('click', function() {
		removeOverlay();
	}, false);
	
	// create a container for the caption
	var captionBox = document.createElement('div');
	// assign an ID to the caption box
	captionBox.id = 'caption-box';
	// add the caption text to the caption box
	captionBox.innerHTML = imageCaption
	// append the caption box to the content box
	contentBox.appendChild(captionBox);
	// insert the content box into the overlay
	overlay.appendChild(contentBox);
	// adjust the size of the caption box to fit the content box
	var overlayImageWidth = contentBox.getElementsByTagName('img')[0].offsetWidth;
	document.getElementById('caption-box').style.width = String(overlayImageWidth)+'px';
	document.getElementById('caption-box').style.color = 'black';
	//setTimeout("document.getElementById('caption-box').style.width=document.getElementById('content-box').getElementsByTagName('img')[0].offsetWidth;",0);
	
	// make the overlay visible
	overlay.className='visible';
}

function lightboxDisclaimerImage() {
	// turn off document scroll behind lightbox
	document.body.style.overflow="hidden";
	// retrieve the path to the high-res version
	var imageURL = "lightbox/disclaimer.jpg";
	// retrieve the display width
	var imageWidth = 580;
	// retrieve the display height
	var imageHeight = 580;

	// create the overlay element
	var overlay = document.createElement('div');
	// assign the created element an ID
	overlay.id = 'overlay';
	// insert the overlay element into the body of the document
	document.body.appendChild(overlay);
	
	// create a container for the image and caption
	var contentBox = document.createElement('div');
	// assign the created element an ID
	contentBox.id = 'content-box';
	
	// create an image object
	var displayImage = document.createElement("img");
	// set the source parameter of the image object
	displayImage.setAttribute('src', imageURL);
	// adjust the image size to fit based on page and image orientation
	var pagewidth = document.body.clientWidth;
	var pageheight = document.body.clientHeight;
	var imageW = displayImage.width;
	var imageH = displayImage.height;
	var scaledValue = 0;
	if ( pagewidth > pageheight ) {
	 if ( imageW > imageH ) {
	 	displayImage.width = imageW * 2; // pagewidth * 0.65;
	 } else {
	 	displayImage.height = imageH * 2; // pageheight * 0.75;
	 }
	} else {
	 if ( imageH > imageW ) {
	 	displayImage.height = imageW * 1.25; // pageheight * .75;
	 } else {
	 	displayImage.width = imageH * 2; // pagewidth * 0.75;
	 }
	}
	
	displayImage.width = imageWidth;
	displayImage.height = imageHeight;
	
	// append the image to the content box
	contentBox.appendChild(displayImage);
	// make the image a clickable close object
	displayImage.addEventListener('click', function() {
		removeOverlay();
	}, false);
	
	// create a container for the caption
	var captionBox = document.createElement('div');
	// assign an ID to the caption box
	captionBox.id = 'caption-box';
	// add the caption text to the caption box
	captionBox.innerHTML = "";
	// append the caption box to the content box
	contentBox.appendChild(captionBox);
	// insert the content box into the overlay
	overlay.appendChild(contentBox);
	// adjust the size of the caption box to fit the content box
	var overlayImageWidth = contentBox.getElementsByTagName('img')[0].offsetWidth;
	document.getElementById('caption-box').style.width = String(overlayImageWidth)+'px';
	document.getElementById('caption-box').style.color = 'black';
	//setTimeout("document.getElementById('caption-box').style.width=document.getElementById('content-box').getElementsByTagName('img')[0].offsetWidth;",0);
	
	// make the overlay visible
	overlay.className='visible';
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
