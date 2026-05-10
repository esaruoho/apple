# WWDC 2003 Session 401: AppleScript Update — Transcript

*Whisper-generated transcript via nonstrict.eu/wwdcindex. May contain transcription errors.*

Source: https://nonstrict.eu/wwdcindex/wwdc2003/401/

---

Testing. Hello. Do I get introduced? I guess not. I said no. All right, guys, you're going to get me in trouble. I'm Sal Segoe, and I'm the AppleScript product manager for Apple Computer, and thank you for coming here today. Thank you for coming to San Francisco. Thank you for being a part of this revolution that's going on right now. And I really appreciate you being here, and the AppleScript team appreciates it as well.

I first fell in love with AppleScript back in 1992 when I got the developer CD, and I saw that there was the ability for a normal schmo to be able to make the computer do what I wanted it to do. And the vision I had then was to be able to create automation and workflows where I could take information from one program, manipulate it, move it to another program, take that and move it to another program and build something. And in the decade following, that vision has not dimmed at all.

As a matter of fact, it has grown considerably. As you saw today, it's the pinnacle of what we've been able to do with our new Xcode and AppleScript's integration as a peer language with Objective-C and Java as a development language in the operating system. It's unparalleled in what it can do now. We have access into all the system APIs. We can call the command line. We can do web services.

We have the interface, and we can even control the UI elements of applications that aren't scriptable. So it's been quite an adventure, and it's progressing on and going even farther every day. But instead of me giving you this overview, I'm going to introduce someone who is new to the AppleScript team.

He's leading the team now, and he's doing an incredible job, as you're seeing in Panther, of delivering more and more tools and abilities to you, our AppleScript customers. So I'd like to introduce Mr. Todd Fernandez. And please come on up, Todd. Thank you. How is this thing not working? Thanks a lot, Sal. Good afternoon. The clicker seems to be a little haywire today, but eventually, perhaps we'll get a slide with my name on it.

There we go. All right. Well, good afternoon. Welcome to Session 401, AppleScript Update. As I've done that gracious introduction, I'm Todd Fernandez. I'm the relatively new AppleScript Engineering Manager, and I'm very pleased to be here with you today to talk to you and show you a lot of the great new work we've been doing for Panther.

Now, I know a lot of you have been coming to WWDC for years and have been working with AppleScript for years and are probably wondering who I am and what I'm doing up here, since for the last five years running, Chris Espinosa has been presenting this session. And in fact, last year, both presenters were named Chris. So I'll tell you what I'm going to do. To make everybody feel more comfortable, you can call me Chris. I'll respond, Todd, Chris, whatever. So now that we've gotten that out of the way, let's get started.

So here's our agenda. We'll go through a brief introduction. I'll make sure we bring everybody up to date on what's happened since the last time we were here together, and then spend the bulk of the presentation going over the many new features and enhancements we've got cooking for Panther.

This thing is really finicky. All right. So the first thing I want to do is go over the three things that I hope that you all take away from this session today. First of all, what are the changes that we're making in Panther for Apple Script? Secondly, and more importantly, how you can take advantage of them to improve your scripts and applications.

And something that Sal just was talking about and which I hope you saw in the keynote and Steve using it for his demo, that all the changes we're making, all of the work that you're doing with your scripts, enhancing your scriptable applications, hopefully there are people here with newly scriptable applications, we really feel there's a lot of momentum building behind AppleScript on Mac OS X.

And we hope that we can share our excitement with you during this session. And what I really want to do is thank all of you, because the community is one of the things that makes AppleScript so great. And all the work we're doing, combining with all the work you're doing, to solve problems for our customers.

And so what I'd like to do, I can't thank all of you personally, but what I'd like to do is have Sal come back up here and give a quick demo of a recently released application from a pioneer in scriptable design and layout workflows. They just released a great new version of their flagship application. And I'd like Sal to show you a little bit about what you can do with QuarkXPress 6 combined with some of the great scriptable apps on Mac OS X. Sal? Thank you.

This is the new QuarkXPress 6. It's changed its idea. They're borrowing from our iApp approach. And the whole idea is you put things on the left, and then it turns to text sentences. They get published. Actually, one of the big things that's been happening this year besides AppleScript is the Apple Music Store. It's captivated the country. It's captivated the city. It's captivated Cupertino. and I'm spending my entire paycheck buying songs.

And so I've gotten so many songs in my library now that I wanted to make some way to have a discography that keeps track of what artists I have, gives me a little bio information about them, and perhaps would list what tracks I've already purchased and which albums so I know which ones to buy next.

And I wrote a little script for doing that with the new QuarkXPress 6, which is just introduced recently, and it's running natively on Mac OS X. And the purpose of the app is really simple. What I'll do is I'll just kind of scroll through here and find some people I like. Julie London, ooh. Oscar Peterson, I'll pick a track by him.

Fish is great. Oh, I'll take a little Reba McEntire. And let's try something else. Sheryl Crow. Stevie Ray Vaughan, okay, I'll pick some of him. And what I want to do is create this discography. Now, in QuarkXPress, I have a template that I built myself. This is the cover for my discography.

And I want to, again, get information from the Internet, a bio and a picture of the artist, bring that down, and then search the database in iTunes for information. I'm going to use the new script menu in QuarkXPress, choose Build Discography. And the script will analyze what I have selected in iTunes and then search for that artist on allmusic.com.

It will get the profile of the artist and extract that and the artist's picture from the page, insert a new page, put it into the Quark document, the size of the text, the scale of it, then it will go to the iTunes database, find out which songs I have by Reba McEntire, get those pictures out of the iTunes database, add them in there, and then list all the songs underneath those pictures about what I have and does the same thing then for Oscar Peterson.

And we'll add a page for Oscar and then get the pictures out and then put the songs in there. So this shows the power and the connectivity of AppleScript that I can take some simple apps like this and put them together to build something for myself. This has always been the vision of AppleScript and this will continue to be the vision of AppleScript, whether it's a big multipurpose workflow for a big company or something small and simple like this. So in a couple seconds, I now have my discography that I can print and keep on my coffee table to amaze my friends at how much money I blow on music. Thank you.

Thanks very much, Sal. And I'd like to continue by going over the version history of AppleScript so we're up to speed with where we are. It's been a busy couple of years. You're going to see a whole lot of releases we've done since the release of Mac OS X a little over two years ago.

We shipped AppleScript 1.6 alongside with the initial release of AppleScript of Mac OS X, followed by version 1.7 with Mac OS X 10.1 and for Mac OS 9 as well. We then shipped AppleScript 1.8 with the December 2001 developer tools and a series of updates after that, culminating in AppleScript 1.8.3, which was an independent software update for both Mac OS 9 and Mac OS X.

Last year at the conference, we were talking about AppleScript 1.9, which in fact we shipped with Jaguar, Mac OS X 10.2. We shipped a significant update late last year as AppleScript 1.9.1 in the Mac OS X 10.2.3 update, and then the Script Editor 2 and System Events betas with the December 2002 developer tools late last year.

So that brings us up to date with where we are with AppleScript, and I'm pleased to announce today, we're going to be shipping-- if the clicker will cooperate-- AppleScript 1.9.2 with Panther. Now, you might look at the version number there and think, well, gosh, they must not have been working very hard. It's just a minor release. But we're just conserving version numbers. We, in fact, have done an awful lot of work, which we'll go through now.

if we can actually get the clicker to work. So let's dive right in and start talking about what we've been working on for Panther. go through four separate areas. We're going to talk about some new formats for saving your scripts and applets. A long list of scriptability enhancements, touching nearly every component of the Apple Script system. There are a few changes to be aware of as you move to Panther for both scripts and your scriptable applications. And then I'm going to touch briefly on Apple Script Studio.

So let's just jump right in. So you might be wondering, well, what are these new bundle formats? And you might actually see them someday here. All right. Well, they're a new alternative to the data and resource fork formats you're all familiar with. They use the standard Mac OS X packaging with script document file packages for compiled scripts and.app application bundles for applets and droplets.

Of course, they're supported by all the standard tools. Script Editor, OSA Compile, and Store Script all can save and access scripts in applets in these new formats. And in fact, I know that a lot of you have been asking for this for years. OSA Compile and StoreScript can now create new applets and droplets in the new format.

Yes, thank you very much. The team's worked very hard on this. However, in order to get some of these advantages, there is a downside. Because the old Apple Script runtime and tools on earlier versions of Mac OS X don't know anything about these new formats, these new formats do require Panther. However, if you do need your scripts to run on earlier versions of Mac OS X, of course the old formats are still supported and still will be supported.

However, there are some pretty significant advantages to these new formats that we think will make them worth your while to adopt if, in fact, you can live with the lack of backward compatibility. They're more flexible. Applets can be moved easily across file systems even if the file systems don't know anything about resource forks. This makes it easy to store large chunks of data that your scripts depend on right as part of the script itself, such as pictures or movies.

This also enables us to save persistent script attributes, particularly in Script Editor 2. Examples are the description for your script and the window bounds and location so that every time you open your script again, you don't have to drag it down and resize it just the way you like it. Now in fact, Script Editor 2, the version that's in the Panther Developer Preview, doesn't yet do this, but it will before we ship it. Stay tuned.

So, so far I've been talking about what these new formats mean for scripters. What do they mean for application developers? So if your application needs to interact directly with scripts and load and run them, we have a set of new OSA APIs that support all the script file formats, the new ones as well as all the old ones. So we strongly encourage you to adopt these APIs in your application.

The obvious pairs, we have OSA load file and store file to load and store scripts. And we have a pair of convenience methods that build on OSA load file and do with script what you need to do with them. We think that these new OSA APIs will help you simplify your code, make it easier to read and maintain. And of course, you'll need to do this to support the new bundle formats.

Thank you. So that's the new bundle formats. Let's start going through all the enhancements we made to Scriptability in Panther. And as you can see from this list, as I mentioned earlier, we've touched almost every component in the system. So let's start with Script Editor 2, which hopefully many of you have seen already. We released the beta late last year.

As you know, it's a Cocoa Scriptable replacement for what we understand is the oldest remaining application that still ships as part of Mac OS X, but no longer. So those of you who have worked with it realize it's got some amazing new technology. Check this out. Unlike the technology built into this clicker, it's got drag and drop. It's got find and replace. Can you believe it?

It can work with scripts larger than 32K. I don't know why anyone would want to, but if you do, now you can. And hey, it's got undo. Now I'm sure no one in this audience would ever make a mistake when they're coding their scripts. But sometimes maybe the cat walks across the keyboard when you're getting coffee or something. I don't know. So it's there if you need it. So more seriously though, we're really excited about this great new tool that we're providing for you.

And what we're doing-- hopefully many of you saw the demos and the sessions on the new Xcode IDE. And what we're trying to do with Script Editor 2 is adopt some of the innovative new user interface elements that have gone into Xcode. And we're going to continue to do that as we approach the final release of Script Editor 2 alongside with Panther.

So, one great enhancement I know you're all going to love is that we've made OpenDictionary much faster in the new script editor. Thank you. You're not going to believe it. There is a caveat, however, that I'll get to later when we get to changes to be aware of for you scriptable application developers out there. However, we told you about it last year, so you shouldn't need to worry about it anymore.

And Script Editor 2 creates new applets in the bundle format that we just talked about. However, it will save existing applets in the same format that they're already in. So that's Script Editor 2. Let's move on to folder actions. As you know, folder actions returned-- although it's not going to show up on the slide-- last year in Mac OS X 10.2. We believe in Panther. We've made them better than ever.

So the contextual menu in Finder is back in Panther. Now, of course, that doesn't make it better than ever. It returns us to where we were with Mac OS 9. But we've got a great new tool that we're really excited about that we never had before. We call it Folder Action Setup, which, again, if the slide ever-- there we go.

All right, so Folder Action Setup shows you all of the attached folder actions on your system as a whole, something you couldn't do before. It also provides UI for enabling, disabling, attaching, removing, or editing individual folder actions or scripts. And that's something you couldn't do before either. It wasn't possible to enable or disable an individual script that was part of a folder action. But now you can.

Folder actions setup is in the Panther Developer Preview, but I do want to make you aware that the functionality that's in the Developer Preview is not complete for what we're going to ship in Panther. It's already very useful, and I think you're going to like it. But it's not complete.

Now we've talked about folder actions, let's move on to script menu. We've got a lot of great new enhancements. Script menu make it even easier to use. In fact, you saw Steve was running it during the demo. I'll start from the bottom because even -- unfortunately, it's not enabled by default, but it's very easy to install, and we're going to show that to you in a moment. We've also added support for aliases, including to remote machines. And you can put applications, droplets, documents, almost anything you want in there, and ScriptMenu will do the correct thing to open it or display it or whatever would be the appropriate thing.

We've also added some new ways to access what you've got stored in ScriptMenu. If you select a folder, it will open it for you in Finder. If you select a script while holding down the option key, it will open it for you in Script Editor so you can get right to editing your script. We've also made it easier to work with Script Menu if you've got a lot of your own scripts.

Previously you had all the library example scripts in the top of the menu and the user scripts down at the bottom. We've now made it very easy to hide the library example scripts so that it's easier to work with your own scripts. And we've also added a great new feature that allows you to add scripts specific to a particular application to script menu so that when you have that application frontmost, those scripts show up beneath your user scripts.

So now I've been talking about all these things. I'd like to actually show them to you. And I'd like to ask Tim Bumgarner to come up and help me show you the enhancements we made to Script Menu, Folder Actions, and Script Editor 2 in Panther. TIM BUMGARN: Thank you. Thanks, Doug.

So the first thing we'd like to do is show you how easy it is to install it on your menu bar. Yes, notice that it's not in here by default. And we'll just double click here. Simple double click. There it is. And you can see all the library example scripts are there. But all you need to do is hide them.

And then you'll see just your user scripts, which are the ones in your library scripts off your home directory. So if you select a folder, as I just mentioned, it'll open them for you in Finder. And if you hold down the Option key while selecting a script, it will open a 4-inch script editor.

So if you notice here, if Tim will go back to script menu, you see all the script editor scripts there. So how did we do that? If we go back to Finder, you'll see that the scripts are no longer there in Script Menu because Script Actor 2 is no longer frontmost.

But what if we wanted to have some Finder-specific scripts? So all you need to do is in your library scripts folder, create a folder called applications, which you can see in the Finder window there. - Turn it over. - Yep, and you can see we've got a link to script editor. And we just made a link to the finder example scripts. Of course, you can make these anything you want that you want to show up when finder's frontmost.

You just need to make the name of the alias of the folder, whatever's in there, match the name of the application that you want these scripts to show up for. And now if we go back to script menu, you'll see that all the finder scripts have shown up.

And you can see each one has its own individual set. This is an exciting feature. I've been looking for this for a long time. And hopefully all of you will find it useful as well. So let's move on to folder actions. So as I mentioned, the Folder Actions contextual menu is back.

So if we select a folder, hold down the Control key, you'll see we've got a couple of options there. We can enable Folder Actions. And let's add one. So attach a folder action to the desktop. And let's just use one of the examples. We'll go down the long way here. Flying and demoing without a net.

There we go. All right. Click Choose. Okay, that's how easy it is. You can see that it actually is there. It added it, so we can remove it if we needed to. Or edit it. All right, well, let's try one out. We've actually got a folder action. Steve mentioned this morning about the new built-in conversion from PostScript to PDF that's available in Panther. We're going to make use of that now using AppleScript.

We've got a folder action attached to this PDF output folder. There's a PostScript to PDF attached to it. And if we drop this PostScript file in there, It's going to shug along. And you can see that our new item alert we just added to the desktop pops up to let us know we've got this new PDF that's just been created there.

And it's a handy file for this week, nice map of San Francisco. - And we're here somewhere, I'm not sure exactly where. - Well, we're all here, right? All right, so I mentioned that we've got this great new tool folder action setup, so let's show you that. You can access it from the applications AppleScript menu, or in folder and finder, or just launch it from the contextual menu, as Tim just did. As you can see, you can enable and disable folder actions.

You can examine existing folder actions and see the attached scripts that are part of them. You can delete or remove attached scripts. That's fine. And you can also delete entire folder actions. And of course, add them. You can also edit scripts directly from folder action setup. We go to public. Either one, hit edit script. We'll open it for us in script editor.

So that's the new tool, Folder Action Setup. Give it a try. Give us your feedback. As I said, we're still working on it. We want to add some great new functionality to it. And with that, I'll turn it over to Tim to go over some new features in Script Editor 2. TIMOTHY JORDAN: Great. Well, thank you, Todd. Good job. All right. Very excited about this. We're releasing a second beta here at the conference in the Panther.

It should be out on your Panther CD, as Todd mentioned. And I want to talk about a few things, as Todd mentioned as well, that it's built on Cocoa. And that's really powerful. We get a lot of functionality for free, and he went through those. So I'm just going to go right in and talk about some of the new things, the scriptability of Script Editor itself.

And I'm going to type a little script here and what I'm going to do is I'm going to make a new document. So I'm in Script Editor itself. I don't need to tell another application because I'm scripting Script Editor itself. So I'm going to make a new document and I'm going to set the contents of the front document.

Now, you'll notice if you're watching really carefully, there was some little ellipses in there and some type ahead. And if I start typing here, you'll see that it's got a little ellipses. This is a new feature called Code Assistant. Not sure the name will stay the same because we use code since it's the same technology that we're using in Xcode.

So it's trying to guess what the thing is that I'm trying to type. So if I type an I or an SP, in this case it's diacriticals. Oh, there it is. Expose jumped right in and got me. Okay. There we go. Don't hit that key. In this case, it's not set up for display, but I could bring up a list.

and choose which one I want. And so I can figure out which one it is. In this case, the display dialog wasn't there, so I'm just gonna go on and type this. And we're going to say hello, I don't know if I spelled it right, Scripters, okay, hello, And hopefully I typed that correctly. And now, so what I've done is I'm going to tell it, script editor, make a new document, set the contents of that new document to this other script, and now I'm going to tell it to execute. So I'm going to execute the front document.

So we're gonna compile that, build and run, and what you're going to see is a new window and a display dialog that comes up right after that. So I could use scripting and script the script editor itself, it's a pretty cool thing that you could do. And there's tons of things that you could do with that.

Okay, so let's close all those. Another thing that we can do-- Another new feature is we've added this nav bar. And again, Todd had mentioned that we're trying to work with the tools group and use some of the same technology, the same look and feel. And so if I show the navigation bar, it actually shows me a couple different things. This nav bar pops up.

One is the different components that we have on the system. In this case, we just have the AppleScript component. And this lists our elements. So if I use our drag and drop, I can drag in a simple little script here. And you'll notice now that it populates it, so I can go to my global property or a global or a property or to a different handler. And even more importantly, as I'm moving around, you'll notice up here that it's tracking which script or what element that I'm in, which is great for really large scripts. You can jump and navigate very simply and find out where you are.

Okay. Another thing I'm really excited about and I use all the time myself is under the window menu we've added a library window. And when you bring this up, it lists all of the -- I can put any scriptable application that I'm using on a regular basis. And so I can just simply go through here and select one like the finder and click on the open dictionary and I can quickly get to the dictionary and find out any information I want about that. So I can just double click on it, do the same thing, look at text edit.

And the The other thing I can do is I can create a new script from here. So if I click the finder and say make new script, you can see that it automatically fills out the tele-application block for me so I don't have to go type that every time which saves a ton of time. I can do something like name of every -- you can see it's auto-typing for me.

I can hit the complete key and I can type window and hit the complete key. So it knows what I'm trying to type and let me do that. So let's go ahead and run that. In this case I don't have any windows open so let's go in here and add a few windows And I'll even minimize those because they don't have to be open.

And we'll run this again. And you can see down here, another thing we've done is we've consolidated the separate result window and event log. And we've put them all into a single window, which makes it much simpler to use. And it keeps it with the themes that we're trying to do in the tools group as well. All right, so let's go ahead and close that.

Now, since the script editor itself is scriptable, what we're going to do is we can take advantage of that, and we have these things that are the contextual menus. They're the same menus that are over here, so you can use them now in two different ways. You can come choose them from here, or you can actually come in here and type something like name of every window, and I can select these and use the modifier key, the control key, I can bring up the contextual menu, and do a tell block.

So I can say, let's do tell finder, and it takes that bit of code and puts it inside the tell block for me. And we can run that, and we've already seen that. But I can come in here and say, oh, let's make a set disk list to every disk. Okay?

Now, using that same scriptability, we can select this list, and what I want to do is I want to iterate or repeat over every item in that list and do a little action. So I select the disk list, go down to the repeat, and choose process every item, and watch what will happen in the script itself. It goes through, takes the list, writes the script for us, and substitutes that and gets ready for us just to put our action here for every item in that list.

Now another feature that we've added, which I really use a lot, because I do a lot of testing of scripting, and we've added histories. There's a result history and event log history. You might have noticed that as I bring up a script window here, I can type current date and run that, and you'll see that the history shows up here. And if I run it again, I'll get a little bit of a different value. And I can even compare that by selecting two of them and see what the differences were between that.

or I can come back to this script that ran a little earlier. And now the nice thing is that I'll go ahead and close this window. And you go, I just did something in that script just a minute ago, but I closed it. I forgot to save it.

Well, you can just double click and get back to the script that generated that result. So you can go back to that. There are a lot, there's a ton of other features and we're going to just keep improving this. We're really excited about it. And I'll bring Todd back up, thanks.

Back to slides, please. Thank you. One thing that I neglected to mention earlier and I wanted to let you know is in addition to shipping this new version of Script Editor in the Panther Developer Preview, we're also making it available as a second beta for Mac OS 10.2. And that's already available on the Apple Script website.

So, so far we've been talking about tools. What about the AppleScript runtime in standard editions? So we've made a lot of improvements there as well. And before I show you this next slide, I will warn you that my speaker training instructor would be horrified to see this slide, but I really left it this way so you get an idea of the scope of the number of changes that we've made in the standard edition. So you might want to shield your eyes if, in fact, the clicker will work.

There we go. So that's a lot of stuff up on the screen, but I would like to highlight two things. One, the new Choose Color standard edition. And that gives you a standard Mac OS X color picker and returns you a list of the RGB values. The second I'd like to highlight is the long list of new special folder enumerations we've added a path to. If you want to get to the movies folder, we've made it very easy to do that and in a portable way so that it's very easy for you to give the script to somebody else and it will work correctly on their system as well.

So let's talk about the Apps Script runtime as well. We've made a lot of changes there also. First of which I know that a lot of you are going to be excited about, applets now handle events first in, first out, so that you can now write Apple Script CGI's.

Thank you. A little excitement there. All right. We've made Unicode constants much more easy to use. And we've made a number of enhancements to the date class, which we'll go over now. I think you'll be excited about these two. Well, first we added a short date string. And the format of this string is controlled by the international panel and system preferences. But more exciting, I think, might be that months can now be coerced to numbers.

And of course, that means that months can be compared. So you can write things like this. All right. So let's dive back into some tools. System events. We released a beta late last year with the new GUI scripting feature, which I'll get to in a moment. We've also made a number of other changes in the various suites that make up system events. So in the system events suite, we've merged all the application classes from the other suites into one in the system event suite. And that class has gained a number of new properties, including one related to the new GUI scripting feature.

Disk folder file has also seen a number of improvements. We've added a handful of new verbs and new classes, including a new class called disk item, which both file and folder inherit from. So that if you want to see all files, you can do that. If you want to see all folders, you can do that.

And if you want to see both of them, all the disk items, we've made it very easy to do that. We've also added the same list of special folder properties to match path to. So it doesn't matter whether you're using the scripting edition or scripting system events. And that brings us to the processes suite, which is where the new GUI scripting feature is.

I may just carry the keyboard with me. Will that actually work? There we go. Yay! So GUI scripting. I'm sure a number of you have worked with the beta that we released last year. But I want to make sure that the message gets clear, gets through, about what we think GUI scripting is good for. Thanks.

So we believe there are two main uses for GUI scripting. One is for automated GUI testing of applications. And if you're interested in that, you should come to John Comiskey's session 311 on Friday morning. He's going to tell you all about it. The second one is if you've got-- Some monkey I was, huh?

Sorry. Actually, I don't know. You were an outstanding monkey. Was I right on time? I thought it was going well. So the second use we see for GUI scripting is you've got a complicated workflow. You've got a number of great scriptable applications to do what you're doing for your workflow.

And there's one application that's not scriptable or has one little alert panel that's not scriptable. And all you need to do is click OK, and your entire workflow will be scriptable. That might be a good problem that GUI scripting might be able to help you solve. However, and I can't stress this strongly enough... Slide, please.

It's not a substitute for object model scriptability. It's not. So let's not get confused about that. I'll go into more detail about why in a moment. But practically speaking, GUI scripting is part of the system events processes suite. There's a new UI element class that process now inherits from, and it also has it as an element so that you can walk down the hierarchy of UI elements in an application.

And UI elements are just standard GUI widgets you're familiar with, splitters, radio buttons, the ones there I've listed on the slide. Slide, please. So why isn't this a good replacement for object model scriptability? Well, there are four big limitations. One is that it's disabled by default. So that if you write a great GUI scripting script and you hand it off to somebody else, well, it's not going to run on their system until they set a specific obscure preference in system preferences.

What we recommend is that you actually add a check to your GUI scripting scripts that will tell the user why it's not going to run and tell them what they need to do so it will run. So that's a resolvable problem. However, the next ones are a little bit more serious.

GUI scripting scripts are going to be extremely fragile when the application's UI changes because they're dependent on the ordering of the different UI elements on the window. So that whenever the developer adds a new button, a new text field, a new whatever, which pretty much means every time they release a new version of the application, your GUI scripting script is going to break. Now, if you're paying a software tester to test your application, they probably are going to be willing to put up with that. But your customers aren't. They really need object model scripting to protect them against this fragility.

Another serious limitation is that GUI scripting scripts cannot control non-standard interface elements. So if you're writing your own special widget that's not Cocoa, GUI scripting scripts aren't going to be able to control it unless you do a lot of extra work to make it work with the accessibility API. Now, I'm sure none of you use non-standard controls. I'm sure you just drag them in IB off the palette. But if you do, GUI scripting won't work for your customers.

And a fourth limitation is that GUI scripting does not work well with non-English languages. This is primarily connected with keystrokes and keycodes. We have some ideas of how to address this particular limitation, but it's never going to be completely robust. So what are the solutions to these limitations?

Well, you need object model scriptability, so that if you're a scripter and you have an application that you need to use or want to use and it's not scriptable, you should request object model scriptability from the developer. And if you're an application developer and you haven't made your application scriptable yet, well, you should come to the session on Thursday morning and find out how, because your customers need and deserve object model scriptability.

So that brings me to a completely new feature, image events. Now, okay then. So we can deconstruct the name here. Events, well, it sounds like system events. In fact, it's also a faceless scriptable application like system events. Hang on, Tim. An image, well, you know, you're working with images. So it's actually a superset of color sync and image capture scriptability.

Slide, please. So what can you do with image events? Well, you can manipulate images in color sync profiles. You can access image metadata. You can add or change a profile. You can rotate crop scale images. And you can translate file formats. So hang on. I'll point at you.

So we're excited about this. We think this will be very useful for workflows where you don't necessarily want to be launching all these UIs to script your application. You can just tell Image Events what you want to do with your images and do a lot of batch processing.

However, the version of Image Events that's in your Panther developer preview is not functional yet. The dictionary is there, so you can definitely look at that in Script Editor and give us your feedback on the dictionary. But you'll have to wait for the final release of Panther to see Image Events in all its glory.

Thank you, Tim. So PDF workflow. Steve talked a lot about PDFs this morning in the keynote. And although this feature isn't actually new in Panther, it was added in Mac OS X 10.2.4, we think it's a great feature, and we're going to actually show it to you in a demo in a few moments.

It's documented on the AppleScript website, how to use it. And what it allows you to do is do arbitrary processing of saved PDF files directly from the print dialog. You can run any AppleScript you want. So you can do anything that AppleScript can do with the PDF file. And I'll show you a couple examples. What you need to do for your Apple scripts are use an open handler to receive the references to the saved files.

And when you create scripts or some of the other things that you can do to affect what the saved PDF file will do is just add these scripts and links to folders or anything else like that to a PDF services folder in your library folder. And you can put this in your home directory library folder if you just want to see it yourself. If you want to make it available to anyone using your machine, you can put it in /library, and of course you can put it in network library as well.

Thanks, Tim. One of the things we're very excited about, and I think you can tell from hearing AppleScript mention in all the earlier sessions, is across Mac OS X, we're seeing enhanced scriptability to major system applications, such as Address Book, Finder, iPhoto, and Mail. And in fact, we have two major newly scriptable apps in Panther. The new iChat AV is scriptable.

And the new Xcode IDE is also scriptable. And Tim, in fact, is going to demo that scriptability in his Apple Script Studio session on Wednesday afternoon. So we're very excited about this. And we're going to continue to work with our colleagues to continue adding great new scriptable apps on Mac OS X. And with that, I'd actually like to show you the PDF workflow feature. and tie it together with some of the great scriptable apps on Mac OS X. Can we add demo three, please?

So this is the web page that documents the feature on the AppleScript web page. And I'll just show you what it looks like before we add this feature. You bring up the print dialogs, the one you're used to. Here's the Save as PDF button that Steve highlighted this morning. We're going to make it even better. So one of the things you can do-- well, first of all, we need to create a PDF services folder in our library folder. Let's just drag that over.

All right, and one thing we can do is we can actually drag in an alias to a folder and what that will tell it to do is to copy the saved PDF to that folder. And we'll change the title of this alias because the name of whatever is in this folder is what will show up in the save to PDF menu.

That's one thing you do. Another thing you do is drag applications in, or aliases to them. Say you want to have it open in preview. But what's most powerful is using AppleScript, of course, which allows you to do almost anything. So let's just drag in the AppleScript. And I already like that name.

Let's go back to Safari. And if we bring up the print dialog again, you'll see that the nice little Save as PDF button is now a menu. And you can see that you still can just save as PDF, but you can also copy the PDF to that folder that we made and open it with preview or any Acrobat reader, whatever you want to add in here, any application. And then the script. Now what the script is going to do is actually receive the PDF file.

after creates it. It's going to prompt me for a file name for it. So let's see, PDF workflow doc. And when I click OK, what it's going to do is save the file, then ask Address Book for the names and email addresses for the members of a PDF reviewers group within Address Book.

And then tell Mail to create a new message with this PDF file as an attachment addressed to those recipients. And you can see the new addresses as objects. And this is just one small example of what you can do with this feature and combining it with other great scriptable applications. So back to slides, please.

Can we get slides, please? Thank you. All right, so we've been talking mostly about changes that affect scripters. There are also some significant enhancements of Cocoa Scripting for you application developers out there to improve the scriptability in your application. One great new enhancement is that you can now suspend and then resume the processing of the particular Apple Evander script command that's being handled currently. This allows you to avoid having the scripts block on some long process in a particular application you're scripting.

And also there's new API that allows you to access the exact Apple event that's being handled which means you can now set the return code for the Apple event which allows you to get much better error handling in your scriptable applications. You can also get direct access to parameters that Cocoa Scripting doesn't provide direct access to like the subject parameter and considering ignoring.

And Cocoa Scripting now completely handles properties for you. You don't have to write any code and you get it for free. So that brings us to the end of our list of scriptability enhancements in Panther. Slide, please. So I now want to talk about the small number of things that you really need to be aware of as you move your applications and your scripts to Panther.

The first one is that with the new bundled formats, if you're using path to me in a bundled applet, you will get a path return that ends with a colon. What this means is if your script is relying on getting the container for the applet by just removing the last element in the path, that logic is going to break.

Of course, it's pretty easy to fix. You just remove the colon and the last element. However, if you're using a bundle, what you really should do is use it as a bundle and store the files that you're trying to access inside the bundle in the contents resources directory, in which case you want the colon there because you're going to have to add contents and resources. So the next change is that we've changed the default behavior of offset of, and I'll go into more detail in a moment.

This we also told you last year and we're reinforcing again this year that you should avoid implicitly encoded text types. And again, I'll go into a little bit more detail on further slides. The final one, and I alluded to this earlier in talking about the improved performance of open dictionary in Script Editor 2.

We're using a new API that only sees applications that have NSAppleScript enabled equals yes in their info.plist. Now, we told you about this last year, so we hope that all of your applications now have this setting, but if they don't, your application won't show up in the open dictionary list. Now, of course, your customers can still drag the application over script editor and can still browse to your application, but if you want it to show up in open dictionary, you will need to add the setting in your next release. Slide, please.

So up to AppleScript 1.9.1, offset of always considered case and ignore diacriticals. This was, in fact, the opposite of the defaults in the Apps Script runtime. And in fact, the scripting edition didn't honor ignoring and considering statements. What we decided to do in AppleScript 1.9.2-- slide, please-- is make the default behavior match the AppleScript defaults so the system is more consistent, and make sure that offset of honors considering and ignoring statements. What this means is if your script-- slide, please-- if your script depends on the old behavior, you're going to need to add considering case and ignoring diacritical statements around your uses of offset of. Hang on. OK.

Let's get back to where-- There is one caveat, however. About a week and a half ago, the underlying API that we used to implement ignoring diacriticals was changed on us so that, in fact, in the developer preview, ignoring diacriticals won't work. But we will fix this for Panther.

Next slide, please. So you need to avoid using implicitly encoded text types, specifically type text, and the reason is it's incapable of representing international characters. And in fact, you want to also avoid type C string and type P string. Not only can they not represent international characters, they don't support the full set of text coercions. We're deprecating them in Panther, and we will remove them in a future release, so you need to move off of these text types. And what we suggest instead is that you use type Unicode text. Thanks, Tim.

So those are the small number of changes you need to be aware of as you move your scripts and apps to Panther. And I'd just like to briefly mention Apple Scripts Studio. I'm going to not steal too much of Tim's thunder. We'd definitely like to thank all of you for the great number of Studio apps you've been writing.

It's really exciting to see all the new apps out there. And in fact, if you're interested in Studio, you may want to go to the Migrating to Mac OS X session on Thursday morning. I understand a representative from Pixar is going to be showing and talking about the Studio application they used to move through 300 of their users from Mac OS 9 to Mac OS X.

We're going to be shipping Apple Script Studio 1.3. It's in the developer preview. And it's got a handful of new features, a new property, a couple of new event handlers. And the major new feature, which is very exciting, and Tim's going to demo on Wednesday, you can now write Apple Script Studio plugins for the new Xcode IDE.

And as I mentioned, Wednesday afternoon, Tim will go through this in great detail. So since you've been such a great audience in putting up with me up here instead of a Chris, I thought I'd actually bring up a Chris to talk to you about some of the things he talked about last year. So Chris, please come up.

Thank you, Todd. So that doesn't look quite right. Could you... Thank you. - All right, so last year, slide please, I was up here talking to you about all the nifty new stuff we were going to do over the following year, that is to say, by now. Now, So how do we do? Well, you know, in theory there's no difference between theory and practice, right? So reality check time. What we talked about last year was an XML replacement for the old AET resource format for dictionaries called SDEF.

We're going to have a new API called Carbon Scripting that would make it much easier to make your application scriptable if you were writing in Carbon. We'd allow you to create scriptable plugins, both for applications and as part of AppleScript itself. We are going to start moving away from four character codes for terminology. And we're going to introduce a major new rev of AppleScript itself called AppleScript 10. This year we have some good news, we have some bad news, and we have some slightly weird news. So, slide please.

Thanks. So the good news first. SDEF actually shipped. It's there, it's usable, we have a few clients and we've made a few improvements to the SDEF format itself and the SDP tool that works with it in Panther. And the cool thing about this is, and this is one of the reasons we moved to XML in the first place, is that we can actually make changes to the format without incredible pain in breaking everybody so it's all backward compatible it all works we have a few are we have several internal clients now mail by chat and i believe xcode uh... are all using s_f_ to generate their terminal their scripting terminology in panther house that's very cool especially because it forces to fix several things that were present or broken direct support in Cocoa scripting is still coming for now you have to use s_d_ to turn your SDF into a script suite and script terminology file.

So we're working on that. Maybe Panther, maybe not. We're working on that. OK, next slide. The bad news. Here's what didn't make it-- codeless terminology and AppleScript 10. Now, I want to be clear here that we are still planning on doing these. We haven't given up. However, they're not ready for prime time yet. In fact, they're not even really ready for late night. Hopefully next year I will have some good news on this slide instead.

Next, the weird news. So, Carbon scripting, you know, the We really, really liked Cocoa scripting. We liked what it does for you. We liked the way it very neatly meshes with your application. You have to put in very little effort to make your Cocoa application scriptable. And that's really what we wanted to emulate with Carbon scripting. So it was supposed to be very much a parallel to Cocoa scripting. It was built around object methods instead of these accessor functions, which you largely had to write yourself. And it would just do a lot more for you than the old object support did.

So, you know, we thought about this and tried to design it, and we're looking at all the work, and we say, "OK, it's just like cocoscripting." So I have to write this stuff, and it's just like cocoscripting, and I have to test it and it's just like cocoscripting, and I have to document it, and it's just like cocoscripting. What would happen if we just used cocoscripting? Well, you know, we tried it, and it actually works astonishingly well. Next.

Thank you. No lie. It really does. What you do is you link in FoundationKit, which has all the scripting support. You write Objective-C classes that essentially front-end all your scripting, and they talk to your real Carbon implementation. And you add one line to your initialization, and it pretty much just works. So you can use this to do scriptable plug-ins. System Events does this today. It's actually been doing them for several releases. It's all already documented.

And it also works on any version of Mac OS X. You don't have to wait for Panther to use it. There are some more details on this in session 4.14, which I completely forget exactly when it is, but go see that one, making your Carbon and Cocoa applications scriptable. So, you know, this sounds -- this is pretty cool, right? It works, it's documented, it's there. Hang on and listen to the fine print. Next slide.

So first off, this is not completely free. There are significant runtime costs to this. Depending on if you do sort of the naive approach, it can actually add several seconds to your application launch time. There are ways around this, however, and we have some documentation prepared for those.

The other thing is that writing Glue to your existing application might be hard. Depending on how your application is implemented, of course, you're probably going to have that problem no matter what kind of API we provided. There's only so far we can pull a really old and crusty application design.

The other problems have to do with Cocoa Scripting itself. Cocoa Scripting, while it's pretty darn good, is not perfect. Its error handling is, shall we say, substandard. However, changes in Panther correct a lot of that. You can now get in sort of through the back door to do all the things that Cocoa Scripting won't do for you, and you weren't able to do that in Jaguar. so you can at least fix things yourself. In the future, we hope to improve Cocoa Scripting so that it really does handle all this sort of thing correctly for you. Pretty much all of our attention in terms of making applications scriptable will be focused on Cocoa Scripting.

Next. Oh, yes. So, summary. So, SDEF is here today. Use it. It's a lot nicer than writing sweet script terminology or AET resources by hand. So please use it. Give us feedback. Carbon scripting is Cocoa scripting. So, you know, this solution is not for everyone. So, you know, go to session 414 and figure out whether or not this actually works for you. It does work, but it's not completely ideal. And still to come, Apple Script 10, codeless terminology. We're actually going to do this stuff for real. At least that's my plan. So that's it for me. Thank you very much. Come on back, Todd. Thank you. Thanks, Chris.

Thank you. All right, well I'd like to conclude with a, we've run through some of the documentation resources we have available. Next slide please. I've got a substantial reference library consisting of lots of different pieces I'm going to walk through one by one. We've got a lot of updated content in the Panther Help Center, which you can see much of it is ready and in the developer preview.

And a little bit of idea about what we're planning for the future, updating the language guide, of course. And we're planning to write a new book on scripting interface guidelines to give all of you who are making your applications scriptable a better idea of how to make your application scriptable in a way that's going to be consistent across the platform with other applications so it's easier for your customers to learn how to script your application. Next slide, please. We're excited about it, too.

So we've got lots of documentation for scripters. Of course, the language guide is useful for application developers as well. Next slide, please. Got lots of documentation for application developers, whether you're Carbon or Cocoa. And of course, we just learned that sometimes it doesn't matter. Next slide, please. Lots of studio documentation.

Next slide. We've got a series of technical notes about specific areas of AppleScript and related technologies. Next slide, please. And this particular reference includes links to the previous ones as well as a lot of other technical notes that you might find useful. Next slide. There are some technical Q&As where we've got questions that developers have asked over time and answers as well as a lot of sample code.

We've got the AppleScript website, which is a great one-stop shop. It has links to many of the resources I just talked about. There are lots of third-party websites, perhaps maintained by some of you out there in the audience, and we thank you for that. There's the O'Reilly book, as well as many other third-party books on AppleScript, and there are more coming all the time.

So I'd just like to sum up by quickly going over what's next. We're going to be shipping AppleScript 1.9.2 in Panther, and you have a version of that with the developer preview with lots of enhanced scriptability and some great new tools. And we'll be working on delivering AppleScript 10 to you after Panther.

So what can you do with the developer preview that I'm sure many of you have picked up already? Well, if you're an application developer, you can test your application. Make sure it still works. You can, I hope, take advantage of some of the enhancements to Cocoa Scripting we refer to and improve the error handling of the scriptability in your application. We strongly encourage you to adopt the new OSA API so that your applications work with not only the old formats, but also the new bundle formats.

And definitely start writing terminology using SDEF. As Chris explained, we've got a couple of clients inside Apple, and we'd like to have you join us. If you're a scripter, there were the few changes that I talked about that you need to prepare your scripts for if they're affected and test them on the developer preview to make sure that they'll run when you move to Panther.

And with that, we'll get to kind of the standard slides. These are some of the contacts. Of course, you all know Sal. Now you've met me. Developer technical support and the engineer who covers AppleScript, Jean-Montbriand. And Jason Yeo, the Mac OS technology manager, who's going to be up here shortly to help run the Q&A.

Next slide. We've got a great slate of sessions this week. The order is a little bit weird, but we're going to do the feedback forum next actually on Wednesday morning, so we hope to see you there. We'd love to get your feedback on what you'd like -- what we've talked about today, what you see in the next couple days as you work with the developer preview, what you'd like to see in the future.

We've got sessions on interactions with other important Apple technologies like QuickTime, of course the studio session. Making your application scriptable. Next slide. And a set of sessions on Friday dealing with different aspects of using scriptability to solve different types of problems, whether you're testing software or whether you're trying to make your life as a system administrator much easier on Mac OS X.

Created by Nonstrict, makers of the Bezel app. This site is not affiliated with Apple. All content is provided for informational purposes only.
