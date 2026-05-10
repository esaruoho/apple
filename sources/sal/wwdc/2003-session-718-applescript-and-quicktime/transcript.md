# WWDC 2003 Session 718: AppleScript and QuickTime — Transcript

*Whisper-generated transcript via nonstrict.eu/wwdcindex. May contain transcription errors.*

Source: https://nonstrict.eu/wwdcindex/wwdc2003/718/

---

Let's get the whole view here, right? I got this shirt in Hawaii. I just came back from the Geek Cruise. Did anybody hear about the Geek Cruise? It's the weirdest thing. You get a bunch of Mack heads on a boat with normal people, and you cruise around places.

So I did the Geek Cruise to Alaska last year, and this year was Hawaii. And it was interesting because in order to save money, conferences are working together. So we had a combined conference. It was actually Mackmania, which was the Mac geek part of it, Pearl Whirl for Pearl guys, and Star Trek.

And you know, so you go into the main dining room and you're sitting there, they assign you seats. And the conversation was unbelievably strange. And this year I had Pearl going in like this while I was getting Vulcan stuff going that way. And somewhere in the middle they met and made sense. I don't know how it worked.

Thank you for spending time today and coming in for the Apple Scripting QuickTime session. You're going to get an overview of what's available for you to use right now, what kind of QuickTime tools are out there and some ideas about how to use them to automate some of the processes that you do with QuickTime content every day. Just a quick question so I can get a sense of whom I am talking to. How many of you in here are scripting already?

Yes. See, your work has been validated right here. And I assume that most of you are also doing QuickTime content as well. - Quick time. Okay, so there's some scriptures in here I see by the disparity and difference there that are scriptures that want to start incorporating QuickTime into their lifestyles. Is this true? Okay, right there, there's one right there. He just got a cable modem, he wants to live the QuickTime life. Okay.

I do too all the time, I think. The story of Apple scripting QuickTime is one of the real unsung success stories at Apple Computer. And through the very diligent hard work of Gary Flynn, Tom Becker, Rona, Frank, and everybody involved in this, it's been an ongoing process. It's just bloomed and bloomed and bloomed. And it basically came down to the same idea that affects every business is how do I get consistency? How do I get accuracy?

How do I get speed? How can I scale what I do and make more money and stay competitive? And the answer in any business, whether it's in multimedia or whether it's print or whatever kind of business it is, it's automation is the answer. So with that in mind, the QuickTime team and the AppleScript team focused on delivering core functionality that allows you to automate a lot of the repetitive things that you do with QuickTime content, such as, you know, applying annotations to 400 movies that are going to go up on the website. Done by hand, that's very tedious. Done with a script, it's go get a donut. So the whole idea is to incorporate this automation with the world of QuickTime. And so what I'm going to do, first of all, can I have laptop one, please? Laptop one.

That was all the slides you're going to get out of me, by the way. I don't slide. I like to show you what it is instead of talk about it. It's like dancing about architecture or something. So what we're going to look at first is what's available to us. What kind of resources are there? What kind of things has Apple done?

Where is it on my operating system? What does it look like? And then we're going to go from there into three core new features added in the most recent version of QuickTime just for AppleScript. Just for AppleScript. You're very special. There are three extremely powerful features that can only be done with AppleScript. And they're in the new version. We're going to look at those.

And I'm going to have a guest come up and show some of the automations based upon some of that technology that we use in-house and with some customers. And then at the end, we're going to look at AppleScript Studio, which is part of the Xcode package. And what that allows you to do is create a native Mac OS X application using AppleScript, Objective-C, Java, C, or any combination thereof.

But what we're going to particularly pay attention to with AppleScript Studio is the ability to talk directly to the QuickTime APIs from AppleScript. So all the commands that you wanted but you couldn't get to, you can now make yourself. And I'll show you an example project that you can download today and start using. So let's begin.

My first slide is going to take you to the venerable QuickTime website. We all know how to get there. QuickTime.com is the shortcut that the people in the know use. You can do the same for AppleScript as well. It's AppleScript.com. And down the right-hand side, you'll see a thing that says QuickTime products over here.

And under QuickTime Pro, there's a nice page that gives you all the reasons why you want to get QuickTime Pro. And trust me, if you don't have it, you do want to buy it because it turns on a lot of functionality that you really want to take advantage of. Thank you.

And one of the links there, number 10, is AppleScript, which will take you to a page within the AppleScript world that contains scripts about the QuickTime player. If we want to get to the same page via AppleScript, you just type in www.apple.com/applescript or applescript.com, click the Applications button, navigation bar, click on the QuickTime player, and it takes you to the same page.

Now, this collection that we post is over 100 and, what is it, about 150 scripts, 160 last time we looked, right? There were some other additions in there. Every script that's posted on here is fully editable. You can open it up, steal the code, change the code, bake the code, squeeze the code, whatever you want to do with it. We encourage you to open up these scripts and look at them.

They're not only usable tools as they are, but they're really jumping off points for going farther with AppleScript. There's a collection of Applets, AppleScript Applets, which are self-running applications with an icon that looks like this, and AppleScript Droplets, which look like this with a nice little blue arrow on it. And these are the kind of scripts that you drag files on or folders of files on.

All of our App--all of our Droplets are designed to handle multi-layered folders of QuickTime content. So if you have a folder of 50 movies with other folders of 50 movies, just drag the whole thing on there and the script will parse it for you and recurse through each level doing the process that it's designed to do.

And some of the applets and droplets that we post include things like as simple as adding to favorites, making a quick way to add something to a favorites, being able to set the annotations of a movie, every annotation that's available. and here's a list of all the possible annotations that you can set.

And you can have a script that's preset to your specific set of annotations, or you can have a copy of the script for 10 different kinds of settings, and just take a movie, drag it on it, it will open up the movie, apply the settings for you, and close the movie back. So it's just a quick drag that saves you about 10 minutes of work by yourself.

There's applets and droplets for clearing the annotations, converting droplets for converting to QuickTime streams, QuickTime format. You can create slideshows from folders of images, display a particular folder as a slideshow just to get a quick idea of what it's going to look like. If you just want to do a quick set of annotations, you could use the limited annotations droplet and go to the comment field in the finder on the droplet and set a couple properties, and I'll be demonstrating that one for you as well.

There's also applications and droplets for automating the playback of movies and presenting movies full screen. Those are very useful. If you have a dozen movies and you want to just play them and sit back and watch, you drag the folder or just drag the files onto the script, and it will open them up one by one and present them in the manner that you indicate, whether it is full screen, double size, or normal size, whichever way that you want.

There's also a version that you can place the playback script in the folder with the movies, run the script and it looks around itself, finds the movies and presents those as well. There's a script for sampling an audio CD and you'll see that today. There's scripts for saving things as uneditable, so once you've got that file the way that you want and you don't want anybody else going in, you can just quickly drag it onto that and post it up where you want and then it becomes an uneditable file.

Saving is hinted, saving in QuickTime format. You can actually control the QuickTime playback on machines remotely using program linking in this script. You can set controller types. Setting the href property of a movie has always been something that people like to do, but it's been difficult to do. And with this droplet, you just assign the URL of the movie that you want and drag it on. We'll look at that.

Then there are the playback properties droplets, and these control the hidden features like auto close so that a movie, when it's done playing, closes up after itself. Or auto quits so that when the movie's done, it quits the QuickTime player. or it will automatically go into presentation mode full screen for you.

You might not know that these features are there, but you can set them with AppleScript as just a droplet, and it really makes a difference in the way that your customers and your consumers of your content get to view the content, and we'll look at those as well.

Then those are our self-standing, self-running scripts. The other 100 scripts that we have in this collection are script menu scripts, and they're designed to be run from Apple's system level script menu. Now this script menu is installed in every copy of Jaguar. You just, did I say Jagwire? Did I actually do that?

It's infectious, isn't it? It really is. This script menu is installed in the Apple script folder, which is in the applications folder. You just double-click the thing that says script menu, and it installs up into the menu bar for you, and you can't see the glorious-looking icon that we have, but by default, it has dozens and dozens, about 30 or 40 scripts pre-installed for you, and when you download this script collection, you can get the QuickTime broadcaster scripts and the QuickTime player scripts, And this hundred scripts right here are these scripts in this particular collection.

It's really easy to install. You simply go to open the scripts folder, which is in your home library folder. You drag your folder, QuickTime Player scripts into that folder, and they show up in the menu. It really is that easy. And then anytime you need to run a script, you can access it from there. We have some nice scripts that really help save some time. For example, one that was that this was one of Rhonda's big ones. She came to me about this when she said, Sal, we have to automate this.

And it's chapter creation. Instead of creating text files with certain codings and importing it, this is really interactive. You literally just put the movie where you want to go and say, make a chapter here, and it will do that. We'll be demonstrating it. So all of these scripts deal with the various things about chapters, editing them, renaming them, deleting them. We have a section of scripts that just deal with the nuts and bolts of editing movie files.

For example, if you want to cut from the current selection to a new movie, instead of going through a bunch of steps on your own, there's a quick script to do it. Cut from the beginning, copy a selection to a new movie, edit a frame in Graphic Converter. That's a nice one. Merge the front movie into the second movie automatically for you. Scale the front movie to a specific percentage.

little tools like that that you'd use throughout the day that each one saves you a couple seconds or saves you a half a minute. And by the end of the day, you're able to stay more focused on the tasks that you're doing than the how am I going to do this. There's a section of scripts for exporting. And there's a special one right here that we'll be talking about, save export settings. That's a new feature. There's a section of scripts that deal with favorites.

actually an HTML embed tag wizard. If you've ever been daunted by the task of writing to HTML for a QuickTime embed tag, this actually walks you through it. It looks at the front movie and analyzes it and asks you a couple questions about what you want to do with it and then writes the embed tag for you. We'll either put it into a file or copy it to the clipboard. There's a section on infoscripts and these give you more information for the front movie quickly.

Here's a nice one, how to get the source URL so the front movie if you're interested in where streams coming from some miscellaneous ones here's a very useful one that we'll be demonstrating is creating a thumbnail link movie to place into a web page so that it's a miniature of your movie and when they click it it actually launches your movie in the QuickTime player that usually takes a lot of steps to create that and then embed it in your page and there's a script that does it very easily for you there's some other navigation scripts some play scripts some previewing scripts, some property scripts, and these are setting the specific playback properties like auto quit when done, auto close when done, auto play playback properties in general, href of the front movie. There's a couple scripts dealing with smile, S-M-I-L. If you want to be able to write XML but never got around to it, these scripts will write it for you.

And then there's a series of scripts dealing with text tracks and tracks in general, just about every property that you want to deal with the track you can deal with these scripts and finally an interesting script for setting the position of the movie in the window because movies remember that and if you wanted exactly 72 pixels by 90 pixels down from the left you can do this if you're anal retentive like me so there's a page that you're going to go to and you can download that script collection that I'm going to be demonstrating now from that site and start using these today to start saving yourself some time any about that at all no pretty straight ahead isn't it okay and this is the QuickTime scripts collection as it looks like when you download it the readme file again is the same open Safari Nice, okay, but let's just drag it up over here.

The README file is the same file that you just saw, so all that explanation, you don't have to write it down or copy it from the website. It's right there for you, a detailed description of each one of the scripts that we'll be dealing with. There's installation instructions that tell you, you know, where you're going to put the files and what you're going to do with them, what kind of requirements you have for the scripts.

And then there's the collection of scripts themselves, applet droplets there are some example files to help you try out these scripts there are some script templates that you're going to use today and that I'll be demonstrating that make actually writing the scripts a very easy process because they're pre done for you you literally just open up these templates put in the couple lines of code that you want and save it in all of the error handling and repeat routines and everything else has already been done for you I know I'm bowling you over with all this stuff, right? There is the collection of QuickTime player scripts, which are the ones that I have installed in the menu up here. That's the collection right here, the QuickTime player scripts.

And there's some various images involved in this as well. And I have this new thing called export settings that we'll be looking at in just a little while. So let's begin by looking at some of the applets and droplets that are available and how they work and how you can use some of these yourself. Yes?

Yes. You can get those from the AppleScript website. They're on the page about Bluetooth and the clicker controlling the broadcaster. Yes, and you can just download them and copy them from there. I just got them and put them in a little collection. Any other questions before I roll on here? I'm sorry? I'm sorry?

Okay. Okay, very good. So, if it's a burning desire, wherever I got that from. No? Okay. Then we'll, as Rhonda pointed out so nicely to me, we'll save the questions for the end unless it's something really important. And then you can come up to the mic and say it so that we can get the translators to translate it so that everybody else in the world out there at large gets to enjoy this as well.

Here's our Applet collection and there's the add to favorites, annotations drop, all annotations, annotations and credits droplet, clear all annotations. For example, and all of these droplets, the ones with the blue arrow, are designed to be double-clicked, and you get a preference dialog. All of them have some kind of a dialog that tells you what the script does and then usually has a set of preferences involved with it.

For example, if I click this, it says, do you want to retain the existing full name of the movie when you set these settings? and I say yes and then you can enter a value for the album artist I'll just click enter key so you can set any of these properties and it will get stored in the script and be part of the settings when they get set so you can copy the script to keep a couple copies rename it call one you know internal use call one website call one you know CD use and then based upon what you're going to do with your movie, you just drag it on there and it sets the annotations.

Here's one called annotations and credits. This actually will make a rolling credits based upon your annotations. But I'm going to start with the limited annotations droplet. Now this particular droplet applies a small subset of your annotations. It doesn't go through all 40 that are available, just the ones that you have put into the property and to the comment window of that particular script so I just got the information for that droplet and you'll see down in the comments field it says product colon product is the name of the annotation colon divides it from whatever value you're going to have so I have three annotations your video product authors ordinary user performers there's me myself and I so to set the annotations to a movie I just drag that movie onto the droplet it opens up the movie, applies the stuff, and closes it.

It's that fast. So now let's go back and open up that movie again. And then when I get the information for that movie, you can see up here that it applied the annotations for you automatically. Now, that's not so impressive with one movie, but it's very impressive with 300.

Small, we're starting small, we're building here, okay? We're gonna take that same movie now that has that applied, the annotations applied to it, I'm gonna drag it onto the annotations and credits droplet and let that go. And it's going to want to know a destination for the new movie that it's going to make from this. And I'm going to just put this as a destination.

Create and choose that. So it'll open up the movie and then extract all the annotations, create a credits that goes in front of the movie, then save it off. Now this is useful for if you're reviewing content and you can't keep track of every movie that you're seeing. You need something that brings up the annotations information first. So we'll go back to this destination folder, open up the movie, and then run it. and you'll see that it brings up the annotations information before it plays the movie.

Impressive. Very, very impressive. Plague golf clap, I like that. Very societal. Oh, these guys are great. Tarantino has nothing on them. And then it plays, ah, of course, copyright. and then the movie itself. Voila. Okay. So there's an example of a script that builds upon something else that another script did.

But that way you can now take that movie and give it to somebody else who's not familiar with your organization and your material. And they instantly have all the information in front of the movie. And it took me all of how many seconds to do it. Little things like this make a big difference during the day.

And let's continue to look for some of our other examples here. Display a folder as a slideshow. This is useful. I'll open QuickTime scripts here, go to my examples files, and I'm going to choose a slide show images. So this has a couple images in it, and what I'll do is I'll just drag that onto the script.

And now I have an instant slide show just so I can preview and see what's going on. I don't have to actually import them into iPhoto to be able to, you know, quickly browse through a folder of images to see what I want. That ability is already built into QuickTime. Now if I want to save this at this point, I can, or I can just delete it and don't save it at all.

But that's a quick way to do an entire folder as a set. You can also, there's another pair to that one where you can save the entire folder as a slideshow as well, and that's called create slideshow from folder here, and that will go through the process of actually building it and saving it. So you can automate 40 or 50 slideshows if you want to do it that way. There's the limited annotations droplet that we just saw where it does a small amount of annotations, and then there's the playback scripts. For example, let me open up another.

Switch. I hope you like switch ads because I'm going to use those as my material today. Is that okay? All right with that? Switch. All right. I'm going to double click the script because all of our scripts can be set. There are preferences that can be stored. So the presentation is normal size continuation dialogue. Now what is a continuation dialogue? Well I made the script for automating the playback of movies and I forgot to give it a way to stop.

So what happens was guys internally at Apple were using these shows and they go, oh, okay, I got to stop. And they'd stop the one movie, but the script would keep going and load the next one. And it became Fantasia with the water wizard and everything happening all at once. So what this does is it brings up a quick dialogue for a couple seconds, self-closes that says, do you want to go continue?

And that's an option. You could say, I want to display the movie at a normal size and bring me a continuation dialogue. Okay. So let me just grab a couple of these, and I'll try to do different ones each time we do them, okay? I'll grab this one and this one, and I'll drag it onto the play movie script. Now these you can keep in your dock as well.

just have them there all the time. - Get your iPod. iPod's here. I sell iPods at Dodger games. Two and then you gotta pass them down kind of the way they sell hot dogs. I got about 1500 in the trunk of my car. I'm usually shirtless. Just for effect, the money just starts flowing in. Could listen to all these songs. I say at least over 50 songs. I'm not quite sure of the amount. I think it's like two million songs. My name is Will Ferrell.

and I'm a porn actor. So it closes it, brings up the continuation dialogue, and then does the next one. So I'm going to just save that one for a little bit later. And then the script senses that there's no more movies open, and it will close itself. So if you have a series of movies, again, that you want to be able to just present, how do you do it? What do you do? You line them all up in the movie player, and then click, click, click, click, play all movies and they all start going, I'm Will Ferrell, no, I'm Will Ferrell. So this is just a little organized way to do that.

Now, as long as we're getting into being able to play movies, movies have specific invisible properties that make them very appealing. And some of these properties are such things as setting a movie to automatically close or automatically quit or automatically play. Now we know from the QuickTime player interface that you can set that flag in the properties to do an automatic play, but there's no place in the interface to set an auto close. So I'll take Will, I'm gonna drag him onto auto close. And now Will's ready to go. And so while I'm at it, I'm going to drag Will onto autoplay.

And now, Playwell. Christmas songs that drive Santa crazy are "I Saw Mama Kissing Santa Underneath the Christmas Tree," "The Jingle Bell Rock," "White Christmas," "Forget It," "Enough." I've heard that over a billion times. Yes, Santa has an iPod and playlists. 980 Christmas songs. And then 20 Doobie Brothers.

And one Sheryl Crow. My name is S. Claus. I live in the North Pole with elves and reindeer. So, did you notice the movie closed on its own? Nice way to present. So that stays with the movie file. As a matter of fact, if you use that movie linked from another movie or from a link in the website, this kind of thing happens. He's got all this stuff like prepared in a little example things and where, where, Sally, Wally. Okay. Help Center. I'm going to find my copy of Safari.

So this is a QuickTime movie. It's a one-frame movie that has a href applied to it using the href droplet. And the href is interesting. It is a open bracket, self-present.move, close bracket. The self-present.move is the name of the movie that this is targeted to. The movie is naturally set to self-present, right?

The T means target. Then the next bracket is QuickTimePlayer end bracket. And if you use this as your URL, what's that saying is open up this particular movie that's in the same folder as this file and play it in the QuickTimePlayer. So a simple click on this opens up the movie.

and then closes it. Nice way to present a movie from a web page, isn't it? Or from a help page. The user doesn't have to know anything about controls or about how to manipulate the player or anything else. All they have to do is just click. Click. OK, click. Reload. Click.

Oh, the QuickTime player. That's because I have Panther installed on the other stupid partition. It's been bugging me all week. OK. Hold on. So click. So this movie is set to auto quit as well as auto close, right? So I'll relaunch the player here to get it back. So there's an example of how you can take that playback property and incorporate it and change the way that you're displaying the content on a website.

So we have decided this Okay, we're going to continue on. There is the auto-quit property, auto-play, and then there are some droplets for batch setting them. So if you want to set the playback properties back to where they were, you just drag it on top of this, and it gets rid of all those playback properties and returns the movie back to its pristine state.

If you want to do them all together, then you can double-click this particular droplet and determine what time you want to have it for display and then drag it onto that to set. That's a couple of those playback properties. Another example where AppleScript can really help you save some time is in media skins. How many people are using media skins? How do you go about doing media skins? Media scheme.

It's a multi-step process, isn't it? It's a quite involved process. You have to have all your materials together. It's like watching the Saturday morning cooking shows. They make it look so easy because somebody else has already cut up the carrots, and they have the little thing here, and they just make their happy little mess, and then they don't even have to cook it. They just look at something that's already cooked, and they go, blah.

Uh... What a bunch of cooks. I don't think any of them can actually cook. So here's an example of how AppleScript can automate some of the process and take some of the sting out of making media skins so you can really take advantage of this incredible technology that's unique to QuickTime.

Here I have some of the elements that are incorporated in the process of making a media skin. There's the media skin itself. There's the mask. that indicates the area that's going to be cut away. And there's the drag mass, which is going to indicate which part of the QuickTime skin is going to actually show. My source movie is this little movie here of a plane.

So I want the plane to fly through this queue. Now instead of going through the multi-step process of having to do that by hand, I'm just going to take the plane and drop it onto this script. And it says, where do you want me to put this particular movie when I get done with it? I'm going to say choose right there.

and I left these little dialogues in, you can turn them off, but I left them in so you can see the steps that it's doing. It's going to add the media skin to the background, move it to the back, activate transparent areas. OK, that's a bug on my computer and nobody else's. That area that's white should actually be white. It's going to write the XML data to disk, open the new movie, and then apply the playback settings, save the finished movie, close it.

Delete temporary items, movie processed. So you can turn off those if you want to batch process this kind of thing. You don't have to have those dialogues running. And here is the resulting movie. On my computer, I have a bug in my computer that makes it so that you can't see through. So I'm going to go in here by hand and go properties of this movie and I'll show you what it looks like actually.

And we're going to choose media skin background, graphics mode, transparent and set the color for white, I believe it is. No, it's black. This way, Sal. That's only on my computer, it's not on yours. This will actually work on your computer. Save it, close it, and now launch it.

So that's a multi-step process. Thank you. It's a multi-stage process involving a lot of work that's now automated down to just a single drag and drop. And now we've added in some playback properties to make it even cooler. And that's, again, part of this whole collection of applets and droplets that are available for you from the website. There's other ones such as set controller type, set window position, save as uneditable, save in various formats like copy, make a copy as hinted, export it to a DV stream if you want to. So all the export kind of ideas are available to you as well.

I'll show you one more, which is the set href property. and I'm going to set the preference for the target URL to be http://www.apple.com/applescript. And that's going to be the preference for this, so that when I drag on any movie onto that script-- and let's do this one.

Yeah, right, I'm gonna love expose, right. Okay, so it just set the href of this movie. play. There it is. Went right to the website. So that's how you set the href for a movie, very easily with AppleScript. Again, so you can begin to get an idea about a workflow that would involve maybe having a folder of some of your favorite automation scripts in a location on your computer, either on the dock or someplace else.

And as you're working with quick-time content during the day, for those small tasks that you need to do, I need a copy of this in this format, I need to set this for our home URL, I need to set the annotations on this one, It's just a matter of you dragging to these little tools. It's like those neat little kitchen tool things.

Okay, let's take a look at some of the scripts that are part of the QuickTime scripts collection. I'm going to open up my Momoko, Momoko again. And I'm going to add chapters into this movie. Now how do you do chapters? How do you add chapters into a movie?

You shoot yourself? Okay. It's an interesting way to go about doing it. Probably a more pacifist way would be to use AppleScript, and we're going to try it that way. Thank you for being patient. So the QuickTime player, I'll choose chapters, and the first thing I'll do is create chapter track.

And what that script will do is says, which track do you want to tie the chapters to, the audio or the video track? And I'll choose the video track. So it goes through the process of creating a chapter track and inserting a chapter at the very beginning. Start.

Now I'd like to add some, let's see, full screen. So go back right to there. Okay, so it's just about to, right there. So she's standing up. Okay. Now at that point I'm going to go back to the QuickTime player and I'm going to choose chapters. Add chapter at the current time. I'm going to give it a name of full shot.

Right there. Click okay. and you can see that it added a chapter there and it has still wanted to start like that and then we continue down over here too where it brings in the logo. So I'll go back and choose chapters, add a chapter at the current time. I'll say logo.

Logo, choose OK. So now I have chapters inserted for a full shot, start, logo, And of course they change as the movie is playing. This one doesn't want to scroll very well today. If I want to delete one of those or rename a chapter, I can go back and do that. I'll choose chapter and I could say delete chapter or rename a chapter. So instead of full shot, I'll call that halfway.

And you can see from our chapter list here, our chapter pop-up, there's halfway, start, and logo. Easy. Chapters are a piece of cake now. And what can you do with chapters? You can add chapters into your QuickTime content, and then when you put that into the new iDVD, it will automatically sense that and break those out into separate DVD portions for you.

So you don't necessarily have to be in iMovie in order to add chapter tracks into your movie content. It's really easy to do right from AppleScript. Now, all of this has been happening because of the power of AppleScript working-- behind the scenes talking to the QuickTime player. All of these scripts have involved the use of the QuickTime player application.

It's actually the pro version. You know, I got the pro version. I actually bought the pro version myself, I must say. I want to support my company. I bought the pro version myself, you know, and then I took five keys off the server and used them for other things, you know. But basically, I did pay for it.

And all of this has been happening with the QuickTime Player application, and it involves the process of writing scripts. When you write scripts and use AppleScript, as you guys well know, use the script editor. This is the first version of the new script editor, Beta 2. The second version has a lot nicer icons and a little bit different interface here, but it's basically the idea that this is the area right here in which you write your scripts.

Now, I'm going to open up the dictionary or the internal commands available to us from Apple Script for the QuickTime player. And to do that, I went to the file menu, and I chose Open Dictionary. I get this wonderful dialogue that shows me every scriptable app on my computer. Hopefully, your computer does not look anything like mine. Okay.

And here is the dictionary for the QuickTime player. Now since a lot of you have scripted before, you're not afraid of seeing this kind of a thing. This makes a lot of sense to you. There are the standard suite of events. These are commands that are common to most scriptable application.

They're usually a set of verbs or commands that indicate standard actions such as close, count, delete, does something exist, make, make a new movie, open, print, quit. So these are the commands, the verbs that you use, and this section of the dictionary is the QuickTime Player Suite. And this contains commands and objects that are particular to the QuickTime Player application. Under the category of classes, you see this collapsible thing right here. Those are the objects that can be scripted. There's commands or verbs that are the action, and then there's the nouns, which are the objects that can receive those action commands.

There's annotations, and an annotation has some properties about it. It has a property called full text. It has an ID. It has a name. The application, which is the QuickTime player application itself, actually has a very interesting set of properties here, and it also shows you that the QuickTime player has these elements that belong to it.

it has a display which is your monitor a favorite a movie a recent item and a window are all things that the quicktime player application deals with on a script double basis and these are some the properties of just the application itself and some of these are pretty interesting like open new movie open movie a new player so you can remotely have apple script control the way that the movie player on the customers machines going to respond before you even play the first movie So you can set this property, you can get this property, and change it as you need to.

You can find out what is your current QuickTime connection speed. You can find out what QuickTime language is QuickTime Pro installed. What is the version of QuickTime? Do you want to show the equalizer? Do you want to show the favorites window? Do you want to show the movie window window? Do you want to show the welcome movie automatically?

And what version of the QuickTime player are you dealing with? There are then the scriptable objects themselves that make up the QuickTime player. And one of the first ones we're going to go to at a higher level is the movie object, because we all deal with this pretty much. And a movie is composed of annotations, it has chapters, it has a file, or an internet location, an internet location for a stream, right?

A file for a movie that you're running on a CD. It has tracks, it might have video tracks, audio tracks, graphic tracks, any kind of QuickTime track would show up here. and it has a window that the movie executes in. And these are the properties of a movie.

And you can see that Gary's done an incredible job of supplying the kind of things that we need. It's really, really amazing. There's your auto quit when done, and it says it's a Boolean value, which is true or false. So I could say set auto quit when done of the front movie to false, and it will not quit when done.

If I say set auto quit when done of the front movie to true, then it will quit the QuickTime player when it's done. The same applies for close when done. You can set the controller type to a specific kind of controller type, to none or to VR player or whatever you need. You can get the current time of the movie. You can get the dimensions. You can get the duration, fast start. You can get the href.

So this is what those droplets use to go in and set the various parameters of a movie. And you can see that they're quite extensive in their variety. Now, a movie is composed of tracks. Well, tracks also have a collection of properties involved with them. From whether it's an audio sample rate, or whether it's a language, or what kind is it? Is it a video grayscale? What are the natural dimensions of that track?

All of these properties can be gotten or set from Apple Script. Now, a track can also have a chapter, and chapter has a name, a time that it occurs, and an index. Also, there are frames in a movie. Frames have a duration, an index, a time, a value.

There's images, an internet location, the palette, the RGB color, recent items, streams, text frames, tracks. Text frames, we already covered tracks event. And then some of the events that are available. These are some of the verbs that apply to these kind of objects that are pertinent to just QuickTime. Add, can export, clear, copy, cut, enter full screen, exit full screen, export, find, flip horizontal, flip vertical, get URL, invert, open image sequence, open location, paste, play, present, redo, replace, resize, rotate left, right.

So you can see that there's a really big collection of tools available for you here to take advantage of just in the QuickTime Pro player that let you really shorten what you do and the scripts that we've presented to you are ways to shortcut that process now let me take it to the another example of this and what I'm going to do now is show an example of three of the new features that are part of the QuickTime dictionary. So let me go back here for a second and pull that dictionary back up again. What's it, recent items, the template dictionary. And one of the new events is enter full screen and exit full screen.

We have the ability to auto present a movie. So you saw previously when I did click the link in the web page that the movie went full screen and then presented itself and then closed off. But you can actually see the movie loading in. You can actually see the file open up and then play.

For smoother presentation, what we've implemented in the new version of QuickTime with these two commands is the ability to first set the monitor to a color, just a plain color that you want, whether it's white, black, red, chartreuse, teal, whatever you like. And then we load the movie in behind it and then present the movie.

When the movie's done, we close the movie, bring up the next one, play that, then close that one, then bring the screen back to normal. So this enter full screen command comes in very useful when you need to present to somebody who's got a wallet that has money in it.

See, I always think about how Apple scripts used in money, you know, in terms of money, because I used to write scripts for a living. And all of this technology has now been built, that command has been built into the new version of the present movies script. So, some of the new abilities are presentation, do you want it full screen, do you want it double normal, do you want a continuation dialogue, do you want it to loop, do you want to set the volume, and what kind of background color do you want to apply to it. So, I'll set some of these preferences. I'll let it go full screen. I'll leave the default volume.

Should it play? No continuation dialog, no looping, and I want to set this background of it to white. So you can see that that's been applied and saved into the script. Now, when I drag... a, let's see, since we're programmers here, I'm going to drag these two onto the script. What did I do?

You see it go full white first. You didn't see the movie load. It happens very fast and very smooth. I had everything set up on Windows. I had my whole life on that machine. You know, my illustrations, my writing, my banking. You know, it's like being stuck in a relationship. My fiancé knows him. It works on some level.

So now you know somebody that knows somebody that knows him. You don't want to make the effort to do it. But then once you do it, you realize you should have done it a long time ago. Okay, well, let's watch when this closes. - Freelance writer and illustrator.

Closes screen, new movie, comes in, smooth. 

We decided to try to upgrade. We were lured by the iMac. Then we looked at the operating system and said, wow, this is possibly the best operating system I've ever seen. 

So I was expecting to see 3,000 guys looking at him here.

Imagine my surprise. - And stunned by this. It's not just for artists. It's not just for pointy-headed intellectuals from California. - Yes! - It's for us. - Pointy-headed. - It's for developers. is an all-around computer. I can use this for everything. Now watch it close. I'm a programmer, if I try.

Then back to normal. Nice. Let's thank the QuickTime team for putting that in there for us. Another new feature that they inserted into the new version of QuickTime that's very useful, especially for those that actually know what they're doing, is this thing called a matrix. Anybody here familiar with matrices?

Grumble, grumble, couple people. Yeah, yeah, cool. Couple people, algebra. I hated it. I hated it. I hated it. It's like where you have three numbers, and then you have three numbers underneath that, and then three numbers underneath that, and you change these numbers, and somehow it does something.

They have it in Photoshop, and I've opened up images and just typed in numbers and watched them go, "Bah, bah, bah," and then you can't get them back, and Aunt Louise has a carrot growing out of her nose, and it gets weird. So they've opened up the ability for us to set and get the current matrix for a movie. So what I'm going to do is open up a movie.

and uh... and what i'm going to do is go in here and choose uh... get movie properties video track size adjust so first thing i do is just grab this here you click it once and then it's kind of skew it a little bit like this So I've actually changed the movie.

The movie still plays like this, but now it's been altered. And this has been altered to a mathematical calculation involving a matrix. So I'm going to write a script, tell application QuickTime player. to get the current matrix. Can you see that? Of the front movie. Don't you love this heavy programming stuff?

And if I run it, you can see that down here at the bottom, we have an AppleScript list of three numbers corresponding to the top numbers, three numbers corresponding to the middle numbers, and three numbers corresponding to the bottom numbers. That's the matrix of this movie. And then if I go into the movie and I again do some more things to it like--I'll grab the rotationable-- rotate it like that and then run the script again, you can see that the value here changed.

So you can literally go in and use AppleScript now to morph your movies into any kind of way that you want to, and this is available to you. I forgot to turn it off, okay? And there's a script in the QuickTime Player Collection called X Miscellaneous, set matrix of the front movie, and we've included a couple just by default. Horizontal squeeze, where it slightly squeezes the front movie. - Ooh.

Go back to that, miscellaneous, matrix of the front movie. Make it back to normal, and see normal. And don't worry about hurting your movie because the movie actually knows what it originally looked like, and you can really muck it up in it and get it back to normal. You can even make it look like a flying card, you know.

It doesn't freeze. It's Superman. Everything just works. It just works. Unfortunately, my dad-- So I'm interested to see what kind of mathematics some of the guys out there who really know what they're doing with this kind of thing can do with movies, maybe turn them into Krispy Kreme donuts or something like that with weird centers and things like that. But that's another second feature involved in the new QuickTime Player.

The third feature, the third new feature that I want to talk about is-- a very important one that's been a wish list item for everybody for quite some time. Now, you'll notice that under export, we've always wanted to use the incredible engine that's built into the operating system of QuickTime to do compression. You might not know this, but, you know, all the compression tools you need for really doing good quality compression are built into the QuickTime architecture and can be accessed from the QuickTime player.

And naturally, since they're scriptable, you can use those to batch process some export of items yourself. And until now, until the most recent version of QuickTime, you would have to say using a settings preset, which was one of these things. So if I open up Dave again, and I choose-- We had gotten so disgusted with the machine.

Dave got so disgusted with me, I had him set to autoplay and present, didn't I? So if I chose export-- These settings here, I could use default settings, most recent settings, or something that was pre-named. We didn't have the ability in AppleScript to go into the options and really get at all the various settings and get into details. And we couldn't set those on the fly like we wanted to to be able to do some very sophisticated batch processing. So what they've implemented in the new QuickTime player is the ability to actually save an export setting.

Now, these settings get saved to a specific kind of file that only QuickTime pays attention to. You can't open it up into BBEdit and play with it. But what you can do then is save off your favorite set of settings and then use those settings when you want to batch export. So you could have 20 different settings for just audio. You might have a set that really worked well for classical stuff. You might have a set that really worked great for jazz.

Or you might have a set for video that you like a certain way. And now all of those are available to you using the save export command. And the way you would do that is you would say save export settings for the front movie, for perhaps MPEG-4 to a file location. And you always want to do this. You always want to, first of all, set up your settings. So I'm going to go options, MPEG-4. I want video to be here.

Ding, ding, ding. I want that like that. Ooh, this is going to be ugly. Like that over here and about there, okay? And then I go, okay, save, and then start the export and then stop it. What that has done is that's set into the QuickTime player, those as being your most recent settings. Now when I use the command in AppleScript to save export settings, I'm actually saving those settings.

So yes, it's going to take you maybe, you know, a couple hours to set up all a batch of your favorite settings. But once you do, you can do cool things with it. And so I'd like to bring up now Ryan Lynch from the QuickTime team who's going to demonstrate this tool that he created himself to use internally and with some clients. Thank you, Ryan.

Can we have demo two, please? Oh, yes, demo two. So part of my job is dealing with production of streaming media. And so it's terribly tedious and repetitive if you don't have any tools to take care of it. So what I've done is use a lot of the scripts that we have.

Demo two. Some of the things that Sal came up with before and tweaked them a lot and helped to really automate some of the processes that we have to do. So taking off on the saving this export settings, I have a fun little tool that I wrote here called QuickTime Compression Helper.

And so I've got some nifty AIFF files. And I want to actually do a batch and code of these things. So if I were to open it up in QuickTime Player, we'll go through this whole thing and set up the-- I want to export to a QuickTime movie, perhaps, with-- AAC is awesome, so we'll do that.

And good enough. So OK, so if we were to export that to desktop, go. So now if I were to run this, I can just say, save my QuickTime settings. Because I just did the QuickTime movie, so let's save the QuickTime movie settings. You can save any of the settings for 3GPP, which is new in 6.3 QuickTime, or even the hinted movie, any of them. So let's save that. I'm going to call it-- I like Bob. So Bob test. Now it's saved it off. And if I were to grab all of these files, drag them on there.

gives me a list of all the settings that I have that I've already saved off in my settings directory. So I can say, Bob, test in a 96K. Go. And now it's going to go through and export those two movies at both those bit rates, save them back out to disk. Really cool. So you can basically set up your own poor man's version of Cleaner, and it works very well. I actually like to think of it as the smart man's version of Cleaner.

Because the nice thing is this is yours. You customize it the way that you want. You're not dealing with somebody else's interface. You're not dealing with somebody else's rules of the game. This is something that you do that's yours, that really works for your needs and the needs of your client. And it's a tool that costs, Rhonda, what does QuickTime Pro sell for?

$29.99 and you get access to this incredible technology and compression ability. Can you get it free in a book? That's another good one. There's a quick time for... The web. Web. I thought I was going to get somebody to say that. Quick time for the web. It also includes that as well. OK, so we got one that came out.

I think this is the last one. Okay. That's not bad. What are we doing this on? What is that? Oh, it's not a G5. How come? I want one. - No. Okay, that's enough of that anyway, so we'll stop that. And let's take a look at what we got. So we have four new files that's created, it's exported, and I've named them with the names of the settings that I used so that you know what you've just exported. So that's kind of nifty and works pretty well. Oh, got to tell this to shut up.

And so now I've got these files. But when you have just movie file or just audio files, they don't look very pretty. So when we present these things for the web, I usually like to add a graphic onto them so there's something for the user to actually see and get more of an experience. So I've got some-- no, not that one, the other one.

I've got some files here that are all audio files. They're not very special. You know, they've got-- they just-- They're all the same, actually. So we're going to take these guys, and I'm going to drop them on my little image and annotation script. And none of them had annotations, so I like to do a whole bunch of things together and just string a whole bunch of operations into one Apple script. Like a workflow. Yeah, a workflow. So it works very well. So I'm going to set the annotations. It actually saves-- this version saves the annotations that I used last time so that I can use them again, which is kind of nifty. It's a wonderful feature. properties.

You can save everything into them. And so there we go. That sounds good. I'm going to choose my graphic file. Hey, that looks good. Go for it. So then it's copying and pasting it in there and boom. Done. So now, if I were to open this up, I guess that one sets autoplay too.

Okay. So you could actually have a series of images and have a slideshow going along as that's playing, too, just with images you get of the group from the web or whatever as well. Great use. Yeah. Excellent example of a simple workflow put together with AppleScript and the tools of the QuickTime player. Thank you. My pleasure. Appreciate it. Thank you.

So the next thing, can we go back to laptop one? Laptop one. So that's some of what's in the QuickTime scripts. If you actually delve through there, there's a lot more involved, and there's a lot more that you can take advantage of. Due to time constraints, we're going to move on to some heavier hitting things.

This year for Apple and the last year for Apple has been a tremendous year of innovation. And as Steve said a couple years ago, when he was asked a question about the economic slump, he said that Apple plans to innovate its way out of the slump, and we've been doing that, as witnessed by some of the materials and things that you've seen at this show. One of the key things that we were able to do that we introduced a while ago was AppleScript Studio.

What AppleScript Studio is, it's a peer development language to Objective-C, Java, and C, uses the same tools, development tools, that all those other languages use. And now at this series, at this conference, we introduce the culmination of the original work that we did with Project Builder, and we introduced Xcode. Xcode.org. and I've just opened up Xcode here.

And AppleScript Studio is actually a component of Xcode. It's part of Xcode. And what it lets you do is it lets you develop real applications for Mac OS X written entirely in AppleScript, partially in AppleScript, or a combination of AppleScript, Java, C, Carbon, Cocoa, whatever you want. You put it together and it's yours and it looks like a Mac OS X app because it is a Mac OS X app.

And one of the neat things about this, and one of the really innovative things about this, is the crosstalk now between languages. AppleScript can now communicate directly with any system API or any framework, including the QuickTime framework. I'm going to launch this little app that's on my desktop here called the Movie Player. So what this will do is -- I'll just do it and you'll watch.

watch it fade who do you get it way faded in a run again I found a new property. See the way the movie faded in? And it's gonna fade out. Now interesting thing about this movie, I get to fade it in one more time. I like my toys. I'm going to stop it. As this movie player application has some commands, I can rewind. I can play.

I can stop and I can set preferences. So it has a series of preferences that I can set for auto play, auto quit when done, do I want to hide other application windows when I launch this application, and do I want to fade the movie in and out.

And this is a native Mac OS X application. I've created my own movie player application. And like any other Mac OS X application that's created, it has a bundle. It is actually a package of things. And if I open up the contents folder, resources folder, there's a folder in there called movie. And I can literally just take this movie out and drag in another one. I won't take that one. I want something more. What do you mean, Momoko? Yeah, there we go. And I'm going to close that and now run the app again.

My computer is a little black, but I wrote an email to my friend. us right there and you can go AppleScript.com. 'cause like the QuickTime guys, we got our own address. And click the AppleScript Studio button, and there's a project down here that's called MoviePlayer Project, and you can download it and actually use this. And I'm gonna open that project up right now into Xcode. And you do that by just clicking the blue kind of file.

And this is Xcode, if you've seen it demonstrated throughout the conference so far. And we live in this project. We live in this environment, too. This is our environment just as much as it is Objective-C, Cocoa, Carbon, any other language. This belongs to Apple Script, too. We are peer development language now on Mac OS X. And as you can see, the Movie Player project contains a scripts folder, which will contain the scripts for our project. It contains a resources folder that in this particular case contains a movie folder with my movie in it as well, icons.

And you'll notice that there's a frameworks folder. And one of the things that are in the frameworks folder, let me open this up a little bit here, is I've loaded in the QuickTime framework. So AppleScript can tie into the QuickTime framework directly. You can write your own commands to do this. So what I'm gonna do is, for example, I'll open up the AppleScript script itself. I'll just double-click it.

And this is the AppleScript script that's in there. I'm going to set this for editing out of a single window. And it has a lot of documentation built right into the header, so it tells you how to use this. And it tells you about some of the QuickTime calls that are available to you and documents each one of them.

But I'm going to just jump to where the script is. So this is actually the script that makes up this particular application. It has some handlers for what it does when it launches. It has some properties that it stores and writes to a preference file, like any other Mac OS X application.

And it has routines for loading the movie, what it will do when the movie's finished launching, what the application will do once it's finished launching. And then it has an idle handler right here that the application will watch and determine when the movie's finished playing. Well, that's not a command that's readily available to AppleScript. There's no is movie done playing command built into Xcode at this point. So how did we accomplish that? Well, we did that by tying into one of the QuickTime APIs. We created a little routine for ourselves here.

And it ties into the QuickTime API. This is a little Cocoa thing here. It's a Boolean value, meaning true or false. This is the name of the routine I've put together, isMovieFinished. And here you can see it's actually calling into the QuickTime API. An API call that they have is called isMovieDone.

It returns a value of 0 or 1, true or false true, depending upon whether that movie is done. And you pass it in the QuickTime movie that you're going to be examining. And all of this can be found. You can go find and--no, not here. I want to go up here, find. Find in project. No, not--yeah, in frameworks, I want to find the word "done" and find that.

Is movie done? It's too fast for me here. It's in the movies.h file right here. So this just went into the QuickTime.h file, and you can see that here this was put in version 10.0 and later, Carbon 1.0, QuickTime Live 2.5 and 3, and here's the, oh, it moved it on me. Natural bounds, wherever it went to. It slid around.

But you can see it takes you right into the QuickTime headers, and you can actually see all the calls that you can make. And the way that it's called in the AppleScript application is this particular thing called call method. Then you give it the name of the method with any parameters that you're passing through.

So at this point, AppleScript leaves its world, calls into the QuickTime frameworks, has it do something or return some information, and then gets that information back and then proceeds on with it. Now, this sample project that's up on the website contains a library here. Let's just go right to it. I'll show it to you..h file.

Oh, that's the wrong one..m file. And then switch over to the thing. Here are some of the calls that are available in this little sample that we have in this project. Getting the time value for a movie, setting the time value, getting the duration value for a movie, getting the time scale, the bounds of the movie, the natural bounds of the movie, rewinding the movie, going to the end, is the movie done, what's the bounds of the main screen and setting the volume for the movie. This augments the abilities of AppleScript Studio as it is right now, and it's a great example of how to expand your work beyond the normal scope that you've been able to do with AppleScript.

Instead of waiting for a scripting edition to be written by a third party that you have to make sure is installed on every machine, you can now just call the calls directly yourself through AppleScript Studio and create a visual interface that determines what the user sees. As part of the project, of every project, this particular application has a nib file, an interface builder.

And this is the interface builder. Let me hide all the other stuff so you can see. This is the preferences window. Here's the application menu. This is the floating window, and it has certain properties involved with it as far as how it's designed to expand. And the movie view that's inside of that window that I have stretched to fill it is also set to expand so that when the movie's placed in there AppleScript asks for the size of the movie from QuickTime and then tells the window to size yourself automatically to these dimensions and naturally the movie goes to that dimensions and then it shows it. All of that put together with inside of AppleScript Studio. Brave New World, you have a lot more abilities than you ever had before and it's all available to you on Mac OS X, Jaguar and Panther with Xcode moving forward.

So that's just a quick overview of some of the things that you can do with AppleScript and AppleScript Studio and QuickTime and some of the resources that are available today. Small things and big things. So with that, we have a few more minutes. I'll be glad to take some questions. Do I have an assistant on the questions here? Ah, OK. Thank you. So I guess I'm the assistant on the questions.

So quickly we'll go through the upcoming roadmap. And as we're doing that, please line up at the microphones if you have any questions for Sal or Ryan, if you have any. Here's the roadmap of upcoming things. There is a QuickTime alternative programming environment, which obviously we just had a big lesson on that.

And if there's any questions on who to contact regarding anything to do with QuickTime, it's Guillermo Ortiz. He's at QuickTimeMan at Apple.com. Reference library. Sal pretty much told you about all this stuff. And don't miss, there's a lab downstairs, open every day, where you can talk to engineers about anything you need to do. And there's also a content creation lab about creating content.

Created by Nonstrict, makers of the Bezel app. This site is not affiliated with Apple. All content is provided for informational purposes only.
