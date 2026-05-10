# WWDC 2003 Session 306: AppleScript Studio — Transcript

*Whisper-generated transcript via nonstrict.eu/wwdcindex. May contain transcription errors.*

Source: https://nonstrict.eu/wwdcindex/wwdc2003/306/

---

Thank you. Thank you for all coming here. Thank you for being part of the experience and the renovation, rejuvenation, revolution that Apple's going through right now. It's an incredible time to be a developer. It's an incredible time to be an Apple employee, and especially for AppleScript. Over the last year, AppleScript has progressed more and more and grown faster and faster. It's just on fire.

And with the evolution of AppleScript becoming a peer development language with Objective-C and Java and Cocoa, Carbon, and the rest of it, and the development tools and Xcode, we have pushed farther and grown faster, and we're reaching farther and farther every day. We want to deliver more for you with AppleScript, and we want to be able to be your hands and fingers into the world to get the things done that make you money. Because this is all about money. Well, some of it's about fun, but some of it's about money and making sure that you're successful at what you do.

AppleScript Studio can be a great part and a component of that process for you in that it can combine disparate parts of code and resources and put them together in a way that not only makes your users and customers satisfied and easy to use, but it can also deliver a lot of power under the hood. So today you're going to see an overview of some of the new things that are in AppleScript Studio, plus a good portion of what AppleScript Studio can do in its new environment.

And to do that, we have a couple people today that are the key to this technology. First is Tim Bumgarner, who is the senior engineer for AppleScript Studio. He's the brains and execution behind it. And the man behind the man, he couldn't be the man without the man, is John Coelho, venerable AppleScript Studio guide and source and sage. So with that, I'll let Tim take it away. Thank you. All right.

All right, thanks, Al. Well, I was thinking about last year's session, and I just knew what I started my session out last year would come back to haunt me, because if you'll remember, I had a slide that came out and said, maybe I'd consider myself Mr. AppleScript Studio.

And, of course, the acronym was ASS, and I would be known as Mr. Ass. And sure enough, somebody walks up to me, a colleague, and says, I'd like to introduce you to my friend, and this is Mr. Ass. And I, great. So I think I'm going to go with Mr. Studio. So the worst you can call me is Mr. S. And that's a subtle difference, but important.

The other thing I noticed when I went through my session last year is that I talked a million miles an hour. And hopefully I can slow down. But my apologies to the language translator, because I have no clue how she kept up last year. Great. So let's go ahead and get started and talk about AppleScript Studio. And hopefully we'll have good luck with the clicker. Must be the bane of our existence in AppleScript. We had the same problem in AppleScript Studio, or the AppleScript updates, so. Okay.

Looks like the slide is probably at the end and it's the wrong one that's loaded so we didn't get the right slide. Try this again. Okay. Simple enough to fix. There are -- if this is the worst that happens to me, I'm pretty happy. All right. This way we get to see the nice movie fronting along. I knew we were missing something there. Okay. And Sal's already been here. I'm here. We're all here. Let's get going. Okay, so let's talk about the agenda.

And what we're going to do is a little bit of an introduction. We'll go through a little overview. I'm not going to go through the detail I did last year. Hopefully enough of you have used it and looked at it to know how it works. But we'll just do a quick demonstration of how to do that. Now, last year we were talking about what was in Studio 1.1. We also previewed a little bit about what was in Studio 1.2. We weren't able to actually show you the features because we hadn't shipped Jaguar yet or were far enough along.

And so we're going to go through some of those important key features that we added in Studio 1.2 in the Jaguar timeframe. In Studio 1.3, we're going to talk about what we're releasing for the upcoming Panther release. And some of these things are already in the preview release, and we'll talk about that in a bit. And then we'll just discuss a little again about future features, documentation, and Q&A.

Introduction. What is AppleScript Studio? And so what we've done is we've taken a combination of all these wonderful technologies. We've taken advantage of AppleScript, and we've integrated it into every one of these technologies. We've integrated it into Xcode. It was in Project Builder in the previous versions. We moved it right directly straight into Xcode.

And insidiously enough, we've even inserted ourselves even deeper. It's a requirement. It has to be there. We've also, through a palette, have been able to integrate into Interface Builder. And then all of that is built on top of the Cocoa application frameworks. And so we get the advantage of everything that Cocoa provides.

But it's also two things. It's the development environment. It's where you get to go in and you develop your application. And then it's also a runtime, so that when you get your application built, you can send it out, put it out on the web, distribute it through your company, and then anybody can just run it. They don't need any extra extensions.

They don't need any additions, any plug-ins. It just works. And that makes it really terrific to do that for deployment. So what can you do with Studio? First and foremost, we're creating native Macintosh applications. It's for all fundamental purposes is a Cocoa application, but it uses AppleScript as the development language.

Thank you. And we get to take advantage of everything that Cocoa provides. We get all of the wonderful table views, outline views, buttons, widgets, you name it, we've got it. We can script those. And, of course, with AppleScript, we really get to leverage. We get to take advantage of being able to create solutions that uses applications that are local to my computer.

I can talk to other applications that are across the network or even out through the Internet and take advantage of the next thing, which are web services. Just like we talk to a local application, we can talk to a web service. We simply say tell application and we use using XML, RPC and SOAP, we can go get data from that and populate and provide a front end to it with a nice UI.

And then we can go down to a very deeper level. And since Mac OS X is basically a Unix-like operating system built on top of that, we can take advantage of the do shell script that AppleScript gives us. And you can go down and you can put a nice wrapper around some of those gnarly terminal applications or code pieces and fundamentally put something that people just wouldn't usually understand. They could use a really nice, simple UI to do that. And then, of course, with being inside of Xcode, Xcode allows you to build C applications, C++. We can use Objective-C, we can use Java. Any of those languages we can actually call directly from inside of AppleScript.

And with some of the process or progress that's being made with AppleScript itself at Cocoa level, you can turn around and from those other languages, particularly Cocoa, you can actually create an AppleScript and then talk back into your studio application. So it's a bit of a round trip, which is great. So a little bit of an overview. Let's talk about where we've been.

Studio 1.0 was released. We came out with that in our December 2001 developer tools. And that was, I believe, Mac OS X version 10.1.2. So you can run your studio apps from that time forward. Then we released in April, about four months later, we released our 1.1 release in the April developer tools. And then we, of course, released 1.2, which was a big feature release in the Jaguar of last year.

And there was a point release, some bug fixes that we needed to get in, and went out in the December tools. And then of course we're going to talk about AppleScript Studio 1.3. A little point of clarification. I want to make sure that everybody understands that what went out in the developer preview release is exactly that.

The Studio 1.3 is just a preview release. It's not finished. It will be finished as part of Panther. So it's a sneak preview for you to look at it, use it, take advantage of some of the new features, but you really can't deploy any applications until Panther goes to GM.

And so what I'd like to do is show you how easy it is to create a studio application. And if we look at it, we basically go through the same cycle. We create a project in Xcode, we open up the interface, lay it out the way we want to, we name our objects, attach some handlers, we edit the script, we build and run, and then just go through the cycle, making sure, adding to it and enhancing that application. So I'd like to actually go right to that, and we will demonstrate how easy that is to do. So if we can go to the demo machine.

Excellent. So I'm going to go right into Xcode, and I'm going to choose new project from the file menu. And you can see that Xcode itself is able to create all kinds of different applications. There's applications, bundles, frameworks, Java, tools, you name it, we've got it. The first three are the ones, of course, great with AppleScript, starting with A. We always get to go at the head of the class. And we've got three different types of project templates here. We have the AppleScript application.

We have a document-based application if we want multiple documents. and then we have something we call a droplet. It's very similar to the applet that you would create with Script Editor. So I'm in this case, going to just choose the Apple Script application. And we're going to use of course, the good old standby, our Hello World. And I'll name that project. And the first thing I do is I'm going to go right into the nib file, our main menu.nib, and work on the interface.

Since this is Hello World, there's not much interface. As a matter of fact, I'm actually going to get rid of this default window that you see here. I'm just going to go ahead and delete that. And then I'm going to go to the show info panel, and I'm going to select this files owner. This represents the application object. And any time you want to do anything with AppleScript inside of Interface Builder, you go to the AppleScript inspector, and that's in this case is Command 7 as a shortcut.

And I notice that there are different aspects here. We have our name field. This lets me name objects. Whenever you reference something inside of AppleScript, there are several different ways that you can do that, and one of them is by name, and that's the most recommended. You can also do it by index or by ID.

And then the next section shows us the event handlers. These are the handlers that are related to the object that is currently selected. So if I had a button selected, it would have a different set of event handlers. And then down finally at the last is the script section. This shows us all the scripts that are currently in our project. So if you see over here, we have a hello world.AppleScript back in Xcode.

So what I want to find out is when the application is launched. So what I simply do is go in and click on the launched event handler. I go down, attach it to this hello world, which is our application script, and then I'm going to click the edit script button. And when I do that, it jumps me back over to Xcode, and it selects the contents of the onlaunched handler.

It actually inserted that for me, so I don't have to remember what the parameters are or how it's spelled. I just choose it, and it inserts it for me. And we're going to go with about the simplest bit of code that you can write in AppleScript, and it's just display dialog, hello world.

And then when that dialogue is done, I'm just going to go ahead and tell the application to quit. I don't want to have to quit it. I just want it to go away. So we're going to go ahead and save that. And then from the build menu, we're going to go ahead and choose build and run.

Amen. And it's going to go ahead and it compiles the.apple script file, links it, and then runs it. And there you go. You've got the display dialog. And so when I go ahead and choose OK, the application actually quits and finishes. So that's just as simple as it is to create, you know, obviously a very simple app. But from here, it's the same process. Edit the interface, attach your handlers, edit your script, build and run, and then just keep building and keep building. All right. So we go back to slides, please.

Okay, so let's talk about some of the Studio One 2 features that we added in the Jaguar that we didn't get a chance to actually demonstrate and talk about, but they're really important and they were some of the most requested features that we had. And the first is drag and drop support, and then also pasteboard support, data source enhancements, and document-based applications.

And so we're going to go through each of these features, and what we're going to do is we're going to develop an application from start to finish that employs and builds upon and adds each of these features as we go. So let's talk about drag and drop support.

We've got a series of new event handlers. There's actually about six of them here, I believe. There's a drag, enter, exit, and updated. This is while you're dragging objects across a view. There's a drop, which is the one that we almost always care about. That's the only one that's the most important. There's a prepare drop and conclude. These happen before and after the drop handler. We've also added a new command or variant on the command register.

We need to be able to tell the view what is it that we want to listen for, What kind of drop do we want? What type of data? And so we do that with the register drag types. So in order to help me with this, I'm going to bring up John Coelho as our QA engineer for studio, and he's going to help me make sure I don't mess up. So let's welcome him up.

So what we're going to do, and for the sake of time, we don't have time to lay out everything as far as the interface is concerned. So we're gonna go ahead and we've already laid out a project, but we haven't added any script yet. So we're just gonna bring up the interface. So let's go ahead and double click on document.dib.

And you'll see that what we have here is our application is going to be a document-based application. It's going to present a window that has a table view on the top. It's in a split view, and below the bottom is a text view. And so what we're going to be able to do is drag files from the finder into the table view.

It'll list that information in the table view. And then in the bottom, we'll actually have a script. We can put in some Apple script, and when we're all done, we're going to be able to build and execute that Apple script for every item in the table view. So this is something in an app that we're calling batch processor. So let's go ahead and take a look at it. We're going to start attaching some scripts to it.

So we see that we've named some objects already, and we've named the table view. And we can tell that we've got the table view selected because you can see that it has the table view name up in the title of the info panel. And what we're going to look for is that there's a category called drag and drop. And so he's going to check the drop event handler for us. And then also when the nib is loaded, we want to set and make sure that we register for a particular type of drag. So let's go ahead and click the drag.

or the Wake from Nib. And then, okay, we're going to attach this to our document.AppleScript file. So let's go ahead and we'll edit the script now. So he's going to fill out. Now, lest you think that John's the world's fastest typer, we're actually using something called Demo Assistant.

It's a sample that ships with Mac OS X and the developer tools. It allows you to do this fancy little command too and we populate all the script for you. And so he's filled out the Wake from Nib and let's go ahead and fill out the onDrop and then we'll talk about that. All right.

Okay, so let's look at the onawakefromnip. And you can see we have the tell the object, in this case the object is the table view, to register for drag types, and we want the file names. We could pass it a full list. We could pass it string, color, font. There's a lot of different types that you can register for. In this case, we just want file names.

Now, up in the onDropped handler, you'll see that we have simply just a display dialog because we're just going to test this. We're going to drag in some files, and what we should get when we're done is a dialogue popping up. So let's go ahead and build and run this, John.

Okay, so the application comes up, and he's going to go into the finder, and we're going to show a kind of cool Mac OS X thing we can do. We can go to our Apple Script Studio's examples and go into the little search field and type.pbproj, and it will quickly filter all of the project files, because when we're done, we're actually going to build some things using some Xcode scriptability. So now he's gonna move that over, drag those files in.

As you see now, as he's dragging that over the table view, you get the little plus indicator indicating that it actually drops. If you were to try to drag it over the text view, you see nothing because we've only registered for a drag in the table view. So go ahead and drop those in, John. And there you go. We've got the drop handler just got executed. Okay, so that's how easy it is to add and at least get notified that a drop has happened. So can we go back to slides, please?

Yes. Okay, now that's great. So we've got a drop happening. We've got the right kind of data, at least we hope so, and this is what we're going to find out. So in order to support drag and drop, we had to do the next step. We had to expose the pasteboard class. And so we've done that, and it actually has a series of named pasteboards. There's a general pasteboard, a drag pasteboard, find. If you ever notice in Cocoa, you do a find in one app.

For better or worse, that same find is in another Cocoa app, and we can actually script that as well. And we also then have a preferred contents property. You can put data on a pasteboard in a lot of different formats. It can have strings, files, lists, images. This way we could say, we want this type of data in this format and we can get and set it in that particular format.

So what we're going to do is demonstrate a little bit using bringing up our new script editor and having the application still running. We're going to look and find out what we can about pasteboards. So John's going to use the contextual menu on script editor. And he's going to actually insert some script in a tell application block. And he's going to type in batch processor. Okay. And then he's going to fill out, and we're going to just ask it for the pasteboards. What pasteboards do you have in your application?

Thank you. And when he goes ahead and checks and runs that, you'll see down in the result window that we have a series of pasteboards. They're all named. There's a general, there's a font, find, and drag. And the one that we're going to test at the moment is just look at the general pasteboard. So let's see what the pasteboard, what the things there are about a pasteboard that are interesting. So let's look at the properties of the pasteboard.

When we look at the particular pasteboard, we're gonna do it by name. So we'll go ahead and run that. And you'll see that there is actually a lot of different types of data on that pasteboard. Some of it is listed as rich text string. There's also some Carbon types. Don't ask me what they are, but they're there if you need them.

And then there's also the different type of class. The preferred type in this case is defaults to string. And the contents at the moment has the string general. And so we can actually go ahead and change the contents of the pasteboard. And we'll do a set contents of pasteboard general.

And he's going to go ahead and run that. And then he'll just choose paste somewhere, and you'll see that it now has that variable. Now, there's a reason why I demonstrated this for you. And this is a great tool while developing studio apps. They're live, they're running, they're scriptable.

You can easily delve in, use it as a great debugging tool to figure out where your views are, why something is or isn't responding. And so this is a great way to do that. So let's go ahead and we'll quit that. We'll quit Project Builder. I'm sorry, I knew I'd do that.

Xcode, our batch processor, and the other application, R script editor. And let's go back in and we're going to fill out the drop handler. So we'll get rid of that display dialog. And we'll go ahead and let John put all these lines in and then we'll quickly talk about them.

Now, so what's going to happen is that the drop is going to happen, and you'll see up there that there's a variable called drag info, and that's a type of called drag info. And it has a couple different things. It has one of them, and the one we care about is it has the pasteboard property.

And so what we're going to do is we're going to find out the types that are in the pasteboard of this drag. And then we want to go on to the next line and make sure that what we have in that list or array is the file names. So let's go on down to it.

It's hard to see on this monitor, so I'll look over here. And we're going to set the preferred type. We want to make sure that we get the data out of that pasteboard as file names. And then we're going to simply get the contents and put it in a list. And in this case, we're going to just display a dialogue, show the fact that we got the data that we were expecting. So let's go ahead and build and run this, John.

compiles and launches, and he's gonna drag that out. We'll open up our list of files again. And this time as he adds it, we'll get a dialogue that lists the fact that we're actually, we're not getting files or aliases, but we're getting full POSIX paths. Typically everything in Studio works because it's built on top of Cocoa Scripting, currently works in the Notion and POSIX paths. We're hoping to unify that in some future release. So let's go ahead. And go back. And now we'll go on to the back to the slides, please.

Yes. So that talks about the pasteboard. So now we've done the drag. We got the data out of it, out of the pasteboards. Now we need to do something with it. We need to populate that table and put the data so that you can see that. And the way that we do that is with data sources.

And we've made some enhancements. There were several issues that came up, and we've listened to that, and we tried to fix as many things as we could. And one of them was Make New. We wanted to be able to support Make New for data sources. You used to have to go in, drag this funny-looking cube thing out, make a connection.

It was about a page and a half of documentation to describe something that should be simple. What we did is made it very simple. You just simply say, make new data source, and you get your new data source in one line. We also found that it wasn't terribly fast to creating new data rows individually, populating the data cells. And we found that we could just simply do it with an append command. You give it an append command with a list of records, AppleScript records, and it does it all for you very, very quickly, much faster than you could do it yourself.

We also added sorting support, so you could sort the data sources. And you can pick out which is the default sort column, if they have ascending, descending, what type of sort that they will have. And so we'll take a look at that. So we're gonna go on to the next step, so let's go back to our demo machine.

And so what we're going to do is we're going to go back to our wake from nib. And when the table view is loaded from the nib, we need to set some things up in order to make this happen. And so, again, I'll just let John go ahead and fill those out. And then we'll come back and we'll talk about that. So the idea is we're going to create a data source.

We're going to create a data column that matches every table view column that we had in our table view. And then after that, when we do the drag, we'll later add the data rows that go with that. So let's take a look at that make new data source.

Okay. you can see that we make a new data source and we put it at the end of the data source. AppleScript always wants to know where to put things when you make them. Quite often there's a default place. In this case, we needed to specify that to put it at the end of the data sources. The next section just creates all of our data columns, again, using make new.

And we actually pass a few different parameters to it. Name, we have to name each of these data columns. And this is an important thing to remember when you're using data sources. The name of each data column has to match the AppleScript name of the table view column. And that's how it does all of its magic in matching it up. If they're named incorrectly or they don't match, it won't work. You won't get any data in your column.

So you have to make sure those are correct. And there's also some sort information you can specify for a data sort, whether it's ascending or descending, alphabetical or numerical, and some other data. So let's go on and look at the rest of it. Okay, the next thing you need to do is to tell it that it is sorted because you could go ahead and set everything up and then turn on sorting or turn it off as you like, and you simply do that by setting the property.

And then the next thing we want to do is make sure we set the sort column for that. And then the very last thing and the most important is to hook it up. So we basically set the data source property again of the object, which is the table view, to this new data source that we created.

All right. And then what we're going to do is we're going to go replace that display dialog. So we've got our data source all ready to go. And we're going to add a few lines here to replace that. And we want to make sure that we got at least one file dropped onto our table view. And then we're going to call this handler called add files to data source. And we're going to go add that down at the end here.

And you can see that it's a local handler that we're going to call. We're going to pass it the files, and we're going to pass it the data source that we want to append this information to. And we'll go to the first line. It's an important line, the setup date. I'll go ahead and add the next piece, John.

Thank you. Okay, and let's take a look at the update views of data source. Whenever you're going to put a bunch of data into the data source, you want to make sure that you turn off the updating of views. Otherwise, what will happen is in the table view, you'll see them individually added. And not only is it distracting to see them individually added, but it's much slower. So turn those off.

Go into a repeat loop. We make each new data row. We're going to store away a reference to that full file path. We're going to set the contents of each data cell, because what happens is when we make a new data row, It creates for you a named data cell for every row, or there's a cell for every table or data row in the column.

Okay? And then we'll go down and we're going to set the contents of the name one in this particular case. And we're going to use call method. And remember I told you that we could actually use Objective-C or other languages. And there happens to be this wonderful little utility class on Objective-C and a string. And it's a last path component. And what it does is it takes a posix path and gives me the last item. I don't have to worry about parsing the slashes or the colons. And with a simple little call method, I can directly message the object.

and it will get it of the item, again, is the string, the full POSIX path. And then we'll do the same thing with date. Date is actually going to call a local handler, which we'll skip for now, and then it goes and sets up the path, and now what we want is just the opposite.

We want everything but the last path component, and there it happens again, being that same utility class, another method called string, by deleting last path component. And then we go on, we finish our repeat, and then the last thing that you want to do is turning the updates back on, so that you can see them all populated. So I think we're ready, John. You ready? Let's build and run that.

So we're getting closer, getting closer, building this application. So now when it's up and running, he's going to go in there, drag some files, and you can see, voila, we've added our files and they've all shown up, all parsed correctly, and it has our date modified filled out, our name filled out in the path, and the status we'll take care of in a minute. Now you'll notice that John's going to try clicking on the columns.

Well, we said it'd be sorted, but unfortunately we forgot one thing to add. And we're not recognizing the fact that the column got clicked. So we need to add that event handler. So we'll go back into our document bib in Interface Builder. And we'll go to the Data View categories.

And we'll look for, I know that there's one of them called column clicked, and we want to select that one. And it's already attached to the document as Apple scripts, so we'll click our edit script. Now, the script that he's inserting here is pretty much boilerplate. Anytime that you're going to do sorting on a table view, just go copy this code.

There's examples already that we ship that has this bit of script. And it basically looks at it, says, oh, what was the last column? If it's the last sorted column is different, switch to that and make that the primary column. If it's the same one, just switch the ordering. So it's something that we'll do there.

What we'd like to do is make this even more automatic so that it just happens. You don't have to worry about doing a click tantrum. We'll try to do that for you. So I think that should be it for sorting, John. Let's go ahead and go ahead and run that.

Yes. Okay, let's drag out some items. See what we got. Drag out a few more. And we just keep adding as we like. And you'll notice now as it clicks, that it actually changes the ascending and descending order. If it clicks on a different column, we can change the type and date modified.

Now you'll notice there's no little indicator. I'm hoping that Cocoa puts that in there for us, but I'll probably have to put that in there myself so that you'll know which way that those are sorting. So again, those are as much as we can do for you, that's what we wanna do. So that takes care of doing the data source support with supporting. Let's go back to the slides, please.

Okay. In the process of building this application, we started out with a document-based app. And what we wanted to do ultimately is to be able to save those files that we drug in there plus the script and save it as a document and then we could open it up and process this later. And there are two ways that you can do document-based support in Apple Script Studio.

One is there's two event handlers that are high-level handlers and there are two low-level. Now, the high-level are the easiest ones. Well, they're both pretty easy, The first two are the easiest, and those are the ones that are on by default. This is when what you'll do is data representation gets called when the document is about to be saved, and you just return the data that you want saved in the document. You don't have to worry about writing the file or anything like that. You just pass back the AppleScript data that you want saved.

Then when the document is opened, you go to the load data representation handler gets called, and it passes back to you the data that you gave it when it was saved before. So then you simply update your UI with that data. Now, if it's important to you to actually be concerned about how each byte is read from the disk or the format or the structure of the file, you can use the low level event handlers.

And you just get past the POSIX path to the file and you could write out the data and then you could read the data back yourself. And so in this case, we're going to use the high level event handlers. They're exclusive though. You can't pick and choose. You either have to go high or you have to go low. So we're gonna go high. So let's switch back to our demo machine.

And you'll see that this particular, since we chose a document-based application project, it already starts out with those two handlers checked. So we don't have to go into the document app or Nib and turn them on. They're already there. We're just going to go ahead and fill them out. So let's fill out the data representation one.

All right. I'll let them put that in. And again, remember, this will get called when it's time to save your application. And the object represents the document object and of type just tells you what type of file that you might wanna save. And you can set up for multiple types. In this case, we just have the default. And he's going to fill out the load data representation then we'll quickly talk about those. Let's go back up to the first one.

And so the first thing we do is we have the document. What we really need to do is get the data out of the table view or out of the data source of the table view. And we can do that by using the window elements of a document. So we get window one of that document.

And then we go ahead and get the table view and get the data source out of the table view. And then we're going to get the associated object of every data row. This is the thing I love about AppleScript. This one single line saves me from repeating over things. I just say, give me this property of every single one of those data rows. What we get back is originally what we were given in the drop, that we get a list of files, of POSIX paths.

So then we'll get the contents of the TextView, because we also want to save out the script, and then we want to return that. So look at what we're returning, is we are returning the files to process, and we're returning the script as an AppleScript record, so that when load data representation happens, That's what we're gonna get passed back in. We're gonna get passed back in an Apple script record that has this two elements. So let's go ahead and look at the load data representation.

Basically the same thing. Need to get the window, need to get the data source. And then we're going to use that same handler that we had before, the add files to data source, 'cause we'll have exactly the same format of data. And then let's take a look and then we'll set the contents of the script view. So let's go ahead and build and run this. Let's see if it works.

Okay, so we got our view, we got our table view ready to go. We'll open up our files, drag some files in, And then we'll actually go modify the script because it always comes up with a default script. So you'll see that we're actually going to be saving a different script. And let's choose a save from the file menu. And we'll give it a name.

and save that. And we already had one there before, that's okay, we'll go ahead and close it now. And then we're gonna go to the File menu, and we'll go to Open Recent, and we're going to choose that file we just saved. And there you go, we've opened back up the files and the script with just very little script. Okay, so let's go back to the slides, please.

So those are the 1.2 features. So we were able to drag and drop, be able to get the data from a pasteboard. We were able to add data to the table view through the data source with the enhancements we made, and then very easily create a document from that, which is far simpler than we had in our earlier releases. So now what I'd like to do is talk about some of the features that we're releasing in Studio 1.3.

Drum roll, please. What is it? Well, it may look like a short list, but it's a very, very important list. And the first one is a script property, and the second one is plugin support. And we're going to show you that with some Xcode scriptability. Let's talk about that first one.

This is the one I'm most excited about. It's really going to have a great, terrific impact on the way that you write studio applications. The fact is, every object, any Cocoa InEssence masked object, gets a script property, so that you can do things like access the properties or globals or event handlers of a script.

So you can imagine that you have a foo property on a script on a button. So now you can say foo of script of button one. Or if we're able to step over the script, you'll just be able to say foo of button one and get that property, or set foo of button one to some new value. So you can imagine, instead of these big monolithic scripts that we've had to write in the past, that you can have very small scripts because now it's very easy to talk to scripts of other objects. And we can call their handlers as well.

The other cool thing is that you can take those scripts and you can set new ones dynamically. You could change during runtime, set a button to actually have a different unclicked handler or a new menu item, if you like, and be able to create those things on the fly and have different behaviors.

And another cool thing is that external applications can access that same script property. So you can have another studio app or some other script editor or script running, and you can get the properties, the globals, and the handlers of that running studio application. So you can now call back in to a studio application and execute that event handler using Apple Script Studio.

Thank you. All right, we'd like to demonstrate just a little bit about that. And this is going to put the finishing touches on the last of our batch processor demonstration. So what we'd like to do is go into our main menu nib this time, because we're going to hook some handlers to our File menu.

And you'll see that there are two menu items already added for us. One is process all, and the other one is process selected. So we want to be able to just easily choose a file or a menu item and have all of those items in our table view processed.

So the first thing we have to do is we have to name it. We just name it so that we can refer to it by name, and I'll show you why in a second. Then we want to make sure we have the Choose Menu item selected, and we're going to attach it this time to the application script, which is our batch_supporter.apple script. And we'll do the same thing for the selected.

Okay, we'll choose menu item and add it to that. Let's go ahead and edit our script. Now, we had two menu items. They're both going to execute the same handler, at least the way that we set it up at the moment. And so we need to know which one was chosen. And the way we do that is we use the name of the object. So go ahead and finish that out and we'll take a look at it when you're finished.

And this is a common practice. We do this a lot. You'll have four or five buttons in a window, and they're all going to call the same click handler. So the easiest thing to do is just to look at the name of the object and do something appropriately.

Remember back to what I talked about, the script property in the next release is that we're going to be able to even make smaller ones. You can have four different scripts, one for each button, doing their own thing. You won't have to do this if naming, but we didn't get into demo this today. So let's go ahead and look at that.

So again, we get the window of the front document. We get the table view. and then this is the fun part. We get the script of the front document. Remember document.AppleScript? We're going to get that script object and then we're going to be able to call a handler in that AppleScript.

In this case, when it's for the all menu, we're going to call process all files of table view and then on the else case, we're checking to see if it was the selected items and then we go through and we get the window, get the table view and we get the script again and this time we're going to call a different handler. We're going to call process selected files. So let's go ahead and save this document we'll go and add that handler to our document.AppleScript.

So John with his amazing dexterity is going to drag in a bit of a little more script this time, and we'll just kind of go quickly over it. I can't see it on this monitor, so I'll read it from here. The first one is to clear the status of the data rows in the table view. When it's time to process, remember we had that status column. We just want to wipe out whatever was currently setting in those data cells, so we know that we're starting over fresh.

We also have another one below that called process data rows using script text. So what we're gonna do is get the text out of that script, and we're going to execute the script on every one of those items that we pass into this handler. And you'll see that it does that right in there with the run script. So run the script for this item calls run script, and we pass it the script text with a set of parameters. And we'll look at and see how that works.

And then, of course, these are the two handlers that we're calling from our main application script. One is process all files, and the other one is process selected files. The only real difference is one just gives us the list of the files, of all of them. The other one is just whatever is currently selected. So I think we're all right. Go ahead and build and run.

Now, what it's going to do is we're going to bring it up this time. We're going to drag in a bunch of several AppleScript Studio projects. Thank you. And what we're going to do is we're going to actually put a real script, a running script in here this time. Now, this isn't a script view, so it's not going to check the syntax, but I'm just able to paste in a little script here. So let's go ahead and put that in, John.

First thing we do is the file to process is the file that's passed to us. It's going to be a POSIX path, so we have to get the alias to it using the POSIX file. It's a good way to transfer from POSIX file to POSIX path. We added that support in a couple of versions of AppleScript ago.

And then we're going to go in and we're going to tell application because that code is scriptable now. It has more work to go yet, but there's still quite a bit of functionality there. So what we're going to do is we're going to open the file, and that's just a standard open message, and then we're going to set the status message because what we're going to do is call the build last project document. There's a build command in Xcode. It's going to build and it'll tell us right now, it tells us if it succeeded or failed.

And then we return that status message and our code that we didn't go through in detail will actually put the status message in the column for us. So let's go ahead and we'll build and run this. Or actually we'll just choose now from the file menu our process all.

And you'll see that it says processing. It's going to tell Xcode to open the document. It compiles it, switches back, and you see that it succeeded in each of these cases. So there you go. We're able to run that process over each of those items in that document.

Now this is actually quite useful because I can save this as a document now and whenever I want to open those up and process that I can, but it's very flexible. If I wanted to add a bunch of images, I could drag some images in and that little run script could call something to manipulate those images.

So we're gonna put this out as an example. It'll be out there certainly in the Panther release. Hopefully we can put it up sooner so you can play with it with the code that you have. And with that, I'd like to thank John for his help on that part of the demo today. Thanks, John.

Of course, I want all my support now. It all probably goes downhill from here because I'll drive the rest of the demo. So let's see what we got. Okay. Next thing, plug-in support. I'm also very excited about this. What we can do with Xcode Scriptability, we can now create studio plug-ins that are written in AppleScript that you can plug into Xcode and enhance the environment in ways that we haven't even begun to think of. And we're able to do that. We've added a new plug-in loaded event handler. And through that, it's supported currently with Xcode. I believe Sal's got lots of ideas on where to plug these things in. So just stay tuned, okay?

We've also, in order to do anything meaningful, we needed to add more make new support, in particular menu items or menus and menu items, because it's not very interesting if your plug-in gets loaded and you can't really do anything in the environment, you need to at least provide some access to your plug-in. So this is the first steps we're going to add more in the future. Okay.

So I want to talk a little bit about the Xcode scriptability. There are a set of low-level classes that we'll have that talk about projects and targets and file references, and there's lots more, believe me. And then there's the high-level classes, documents, windows, and views. And so we're just beginning on this.

There's quite a bit in the preview release. There's more to come. And we're going to take advantage of this. What I'm going to do is put together a plug-in that we're going to add to Xcode and cross your fingers and hope it all works. Let's go back to our demo machine.

Okay. And what I like to do is open up a different project. Again, there's a bit of UI involved in this, so I didn't want to bore you with going through the process of setting up the UI. But I do have a nib here that's set up already. It's our settings viewer plug-in.

Now, actually, before I get started with that, I did want to show you one thing. And I wanted to go back to Script Editor and show you a little bit of that scriptability. So I'm going to go in here and do a... Actually, I'm going to open up the nice library window. We worked hard. We want to make sure we show it.

So I can come in here and I can find, open up the dictionary for Xcode. And you can see that there are low level. Some of these are the build phases. They still unfortunately have PB, but the references, targets, applications, and document views, lots of different suites. They're actually quite large, some of these.

And there's a lot to play with, which is great. I think that's probably the first thing that most people do when they see a new scriptable application is look at all the different objects you get to play with. A great big sandbox. It's great. It's lovely. And so what we can do is kind of play with that a bit. And I'm going to go over and create a new script for Xcode.

And what I want to do is just let's look at what projects we have running. And right now I have Project Settings Viewer. And we can do things like look at the targets of projects. Well, let's just, in this case, we'll name it. So we'll just call it settings viewer.

So I actually see that I have a bundle target that's part of that. And we can even keep drilling further and further down. And this is where it's gonna get interesting and pertinent to the demo that we're going to create today. And we're gonna look at the build settings of the target. And you'll see that there's these funny looking archaic constants here with various settings.

And how I want to relate this, you would get to the same information from the UI itself by going to the target, selecting the inspector, the target there, and bring up the inspector. Well, actually, in this case, we have to look at it in a different place. We have to go into our editor and look at the expert view. And here they are. Those are the things that you actually saw.

Now, the cool thing is you can do it from inside a script editor. You can actually set build settings or change those build settings back in the target. But what I wanted to do, and I thought about the inspectors are cool and everything, and I have reasons for it. Ask me later, and I'll tell you why I think the inspectors are cool.

But it's top-down. You have to drill down to get to that particular build setting. What I wanted to do was turn it upside down. I wanted to go find out every build setting that's defined in my project and find out who defines it. So that's not in the application itself yet, so I can write a plug-in to do that. So I'll jump over, and I've called the Settings Viewer plug-in. and I open up the plugin. Try this again. And what I'm going to do is bring up my Apple Script Panel inspector.

And I see that there's now a new category called Plugin Loaded. So I choose that and I'm going to set it on the Settings Viewer plugin. And we'll go over and edit the script and we'll ignore that error. And I have no clue what it said, but we'll just ignore it. And I'm going to make a new script. And my wonderful one-handed typing here.

We're going to go off and I'll come back and talk about this in a second okay so what I'm gonna do is I'm actually gonna create this local script and in that script I'm going to put a non choose menu item just like you saw back in the last demonstration but it's actually now inside a script object and the next thing I'm going to do is I'm going to find another one of those lovely AppleScript things I'm gonna go find the first menu item whose title is project so I'm gonna go over and find the project menu now I'm gonna get the class browser what I want to do is insert a menu item right after the show class browser menu item.

So what I do is I sort of get a couple of references for those, and then I'm going to make a new menu item. And I set it to be after that show browser menu item, and then I set it with some properties. I set a title and a name.

And then finally, you see I dynamically set the script of that menu item by passing it this script right here. So what it's going to do is when I build this, When we actually install the plugin and run it, it's going to add a menu item, and then when I choose it, it should present a display dialog for us. So we do need to, in this case, quit Xcode. And I'm going to bring up... Hide this for the moment. And we're going to find the build.

And just to show you, this is where I built the project, and this is my plugin. It's an extension of pbplugin. And this is the local plugins on my library in my user's account. So it's library, application support, Apple, developer tools, plugins. So I just copy that over, drop it in, and I go back into Xcode, launch that, and now what's happened is that that plugin got loaded in the process of starting Xcode.

And if I go and open up a project, oh, let's do CountDimeTimer, and you'll see now under the project menu, this wasn't here before. Of course, I should have shown that to you 'cause you may not believe me now. I could if you want me to. I'll throw the plug-in out and we'll start over. But let's go on. So now when I choose this, if all is working well, it actually will display my dialogue so that at least I know I've got the plug-in loaded.

Okay, well that's not very interesting, and that certainly doesn't get the job done, so let's go and finish working on that project. So I'm going to go back in, I'm going to open up my Settings Viewer plugin, and this time we're going to go into the, much easier to sort it this way, and I'm going to go into the Settings Viewer itself, and I'm going to describe a little bit about the UI for this plugin.

When you choose that menu item, I'm going to present this outline view, and I'm going to go through, and I'm going to ask every single project, or ask the project, ask every target, ask every build phase, everything I can possibly ask, for its build settings. And then I'm going to list the build settings as top level items, and then child items will be added as from whoever defines those particular settings. And that's the way that this should look. And so what I need to do is actually add an event handler.

And I want to know when this window gets opened, because we're going to add something back in our menu item chooser to do that, to load the nib for us. So I go in here, and we'll click on the open. And this time I'm going to put it in the settings viewer. And since there's a little bit of code here, I'm actually hopefully going to be able to do this right and drag in our snippet one.

Now this is a little bit of code here, and what I want to describe is that we, in this case, we need to use the terms from Xcode, and we're going to fix this as just a limitation of the current implementation. But what we want to do is get the last project document, and I'm going to do a little bit of call methods. I do a lot of this, Al scolds me, but you know, I'll learn sooner or later.

But again, I use that string by deleting path extension. It's so simple, it's just one call, I know it's there. So I want to use that. And then I've got a little spinning indicator, you didn't see it, but it's a little progress indicator up in the view, and I'm going to tell it that I want to use threaded animation. So it just spins on its own. I don't need to tell it to do anything. And then I'm going to start that indicator spinning.

And then what I'm going to do is there's a little status text field. I guess I could show these where these things are here. There's actually a little indicator there, and there's actually a little status indicator here. And I'm going to set that status right here, passing it in the project title that we're currently looking at. We have update the object. That's to tell it to redraw. Please ignore the delays. There's one that's just a little kludge. But okay. Onto outline view settings, the scroll view.

We get the outline view out of that window, and then we get the data source. We make a new one, just like we did before. We make a new data source. We're gonna create three new columns, name, kind, and value. And then again, we're going to set that data source of the outline view.

And then we're gonna call a couple handlers here. One is called find settings for items in project. So we're gonna pass up the project, go find all those items, and then we're going to expand the settings. What I wanna do is find every setting that's defined more than once, so I can look at, like, build styles, check development versus deployment, and you'll see how that works.

And then at the end, we're going to turn off the progress indicator, and then we're going to update the status of the field to clear it out, or at least set the project title there, update the object, ignore the obvious clues with the blazer. That's to make sure that it draws correctly.

All right, trust me, it's needed, but we'll fix that. So that part is in there. We actually need to add a little bit more here. Resize this down. We need to add these two handlers and any supporting items that go with that. So hopefully it's this piece that I've got copied off here.

All right. And so what it's going to do, again, we have to use the using terms block. It's going to turn off the updating just like we did before because we're going to add some data to it. And, yes, it's going to do some call methods that I've added to this project, repeats through each of the build styles, adding those settings, reprocess each target, adding those build settings.

And if I would like, I could go actually find every build file and get its settings. So what it's going to return me is a whole data source populated with all the build settings and those that define it. And then finally at the end it's going to call expand settings. So it's going to go through, it's going to find out which ones have more than one data item and then expand it. So I think it takes care of that. And then the last thing we need to do is go back into the plugin script.

And we need to replace this display dialog. And we'll put that in. And again, call method. You notice there's lots of call method. I love it. It's great. It makes it easy to add things. But this is sort of a workaround for a bug. We're going to fix this by the time release comes out so that it's easy to load a nib that's actually now in a plug-in. We already have support for load nib.

You just pass it load nib and the name of the nib and it just works. In this case, though, the plug-in doesn't or the nib isn't in the application. It's in the plug-in. So we need to add an extension. We'll get that in there. So, I'm gonna go ahead and build this.

and it's built so I'm going to have to quit again. And we'll quit this and I have to go throw this one away 'cause I don't need it anymore. Copy that one over. And now when I go back into Xcode, magically appears, right, okay. So then let's go in and let's open up another project here.

And cross your fingers, I choose this, it should open a window, spins the indicator, goes finds all the settings, and expands all of the settings that are defined multiply. So I can look and see that ZeroLink is on for development, it's off for deployment. I can check all of these various settings.

It's just a way to look at the settings. I know this appeals to all the engineers in the crowd, so some of us may not get it. But this is a very cool thing. And we've been able to plug it right in, take advantage of the scriptability in Xcode. Thank you.

Okay, back to the slides. Future features. Well, I won't tell you that I looked at last year's list of future features and did a scorecard, so we'll just go right along here. We're going to add make new and delete support. I think it's really important, especially with things like plug-ins and other type of dynamic, especially with a script property, you're going to want to be able to create new things. And what are some of those new things you want to create? Toolbars. It would be excellent to be able to take advantage of the toolbars that are in Cocoa.

The reason that it isn't there currently is that there is no way to put toolbars together in Interface Builder, and that's where we hook everything up. But now that we're dynamic, now you can see the picture, right? We can start creating these things. Same thing with the doc menu. You're going to be able to support the doc menu that pops up and add your own items and respond to those.

Dictionary viewer. Sometimes it's a bit difficult, especially when you get very large terminologies, to find the data that you need and to find the classes and the commands. And so what we're going to do is build on all the wonderful things we've done in Xcode. You can imagine a little search field.

So as you type window, we're going to filter that for you, or a particular code. We're going to pull that into the dictionary viewer and make it a much nicer place. We're going to be able to show you, hopefully, documentation examples right in line in the dictionary viewer. Okay. Thank you.

Thank you. Roadmap. So obviously we've already had some of these, so for the disk we'll look at 401. I had our AppleScript update. We already had our feedback form. It would be nice that we had these at the end, but that's okay. We have our AppleScript, and QuickTime already happened at 2.

We have a session tomorrow, 414. This is to show you, if you're interested, how to make your Carbon or Cocoa applications scriptable so that we can take advantage and do even more cool things with AppleScript Studio. We'll open up much more applications, and they'll show you how to do that.

Session 311 on Friday will show you how to automate your testing. With some of the things like GUI scripting that we've provided, you can actually click on buttons and choose menu items, and there's other tools that can be used to check in and test your software. And then in 623, we have an AppleScript for system administrators. I feel like a flight attendant. It's like, you know, this is AppleScript Airlines. Welcome to Flight 306.

On your tour, our final destination is AppleScript Nirvana. If this is not your destination, there are exits for and after. Okay. Whom to contact? Well, don't call me, but you can send me an email. I'll try to respond as best I can. We have Todd Fernandez, who is our engineering manager. Sal Seguin. Everybody knows Sal. Knows and loves him. And then we have Jason Yeo, who is our technology manager.

And for more information, you can find all of these wonderful references. We have building applications, which is a bit of a tutorial. This is probably our first documentation that we wrote, and we know that we're going to enhance it hopefully in the future and make it even better. And the Studio Terminology reference was new with Jaguar last year. It's a wonderful reference. And actually, can I switch back over to the machine for just a minute? Because I've had a lot of requests for this.

It used to be in Project Builder, it showed up right here. It said, show our AppleScript Studio help. What we've done is consolidated a bit, so you have to, unfortunately, push it down a level a little lower. You bring up the Documentation Viewer, but we get to be at the top of the class. We're first thing AppleScript. And you can actually just come in here and find out about AppleScript Studio, the references, they're all right there. And you actually even can take advantage of some of the searching features to get to that help. Okay, we go back to the slides again, thank you.

Release notes. Every time we send out a revision, we didn't get them in the 1.3 preview release, but in the final release, we'll make sure we have a good set of release notes. There is also lots and lots. I think I have 33 examples at this point, and I will keep adding more of those, the ones you saw today, and other examples. That's probably your best resource when you're getting right into it. Go open each of those examples, build it, run it. We try to be very specific to the tasks that we're trying to demonstrate. And of course, there's a studio website that's updated all the time. Thank you.

Created by Nonstrict, makers of the Bezel app. This site is not affiliated with Apple. All content is provided for informational purposes only.
