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
image1.src = "gfx/shane.jpg";
var image2 = new Image();
image2.onLoad = addToLoadList();
image2.src = "gfx/book02.jpg";
var image3 = new Image();
image3.onLoad = addToLoadList();
image3.src = "gfx/book03.jpg";
var image4 = new Image();
image4.onLoad = addToLoadList();
image4.src = "gfx/book04.jpg";
var image5 = new Image();
image5.onLoad = addToLoadList();
image5.src = "gfx/book05.jpg";
var image6 = new Image();
image6.onLoad = addToLoadList();
image6.src = "gfx/book06.jpg";
var image7 = new Image();
image7.onLoad = addToLoadList();
image7.src = "gfx/book07.jpg";
var image8 = new Image();
image8.onLoad = addToLoadList();
image8.src = "gfx/book08.jpg";
var image9 = new Image();
image9.onLoad = addToLoadList();
image9.src = "gfx/book09.jpg";
var image10 = new Image();
image10.onLoad = addToLoadList();
image10.src = "gfx/book10.jpg";
var image11 = new Image();
image11.onLoad = addToLoadList();
image11.src = "gfx/book11.jpg";
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