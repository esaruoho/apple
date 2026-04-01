var loadList = new Array();
var imageCount = 11;

function addToLoadList() {
	loadList[loadList.length] = 1;
	var currentCount = loadList.length;
	if ( currentCount == imageCount ) {
		setTimeout('removeAPIOverlay();',500);
		loadList.length = 0;
	} else {
		// optionally, insert code here for displaying progress
	}
}

function loadImages() {
makeAPIOverlay();
// each image must have the similar loading statements
var image1 = new Image();
image1.onLoad = addToLoadList();
image1.src = "epub/gfx/multilanguageexample.jpg";
}

function makeAPIOverlay() {
	// create the overlay element in memory
	var overlay = document.createElement('div');
	// assign the created element an ID
	overlay.id = 'loading-overlay';
	// assign the created element a class
	overlay.className='running';
	// create a text object
	var APImessage = document.createElement("p");
	APImessage.innerHTML = 'Loading images&hellip;';
	// append the text object to the overlay
	overlay.appendChild(APImessage);
	// create an image object
	var APIimage = document.createElement("img");
	// assign the created element an ID
	APIimage.id = 'asynchronous-progress-indicator';
	// assign the created element a class
	APIimage.className='running';
	// set the source parameter of the image object
	APIimage.setAttribute('src','spinner.png');
	// append the image to the overlay
	overlay.appendChild(APIimage);
	// insert the element into the body of the document
	document.body.appendChild(overlay);
	// turn off page cover
	document.getElementById("page-cover").style.display = 'none';
}
function removeAPIOverlay() {
	// locate the overlay
	var loadingOverlay = document.getElementById('loading-overlay');
	// changing its class triggers the transistion
	loadingOverlay.className='stopped';
	// wait for the transition and then remove the element. The timeout value must be slightly larger than the transistion duration.
	setTimeout('document.body.removeChild(document.getElementById("loading-overlay"));',600);
}