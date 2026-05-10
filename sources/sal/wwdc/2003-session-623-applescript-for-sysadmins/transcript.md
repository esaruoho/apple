# WWDC 2003 Session 623: AppleScript for SysAdmins — Transcript

*Whisper-generated transcript via nonstrict.eu/wwdcindex. May contain transcription errors.*

Source: https://nonstrict.eu/wwdcindex/wwdc2003/623/

---

Please welcome Sal Segoyan, the AppleScript product manager to the stage. Wow, this is, whoa, okay, let me adjust my voice. Yes, Sal is very thundering at times. How's that? Is that better? Okay. This is quite a response. It just confirms my gut instinct that AppleScript's on fire again, another year of AppleScript just thundering forward.

Because of the interest I can see a lot of these faces I haven't seen before. So either you're in the wrong session, This is about bird watching, right? Okay. Or you're interested in some of the core technologies that you haven't touched in Mac OS X before, namely AppleScript. Your best friend in life is AppleScript. I must give you a legal warning up front. I'm required by law. It started in Wisconsin, but I'm required by law to give you the following legal warning. AppleScript is the cocaine of programming. One line, and you'll be ours forever.

So you have been warned, resist as much as you can. Let me ask just a couple standard questions to find out a sense about where you're at and see if that kind of hopefully, please, please, matches up with my idea about the session. How many of you are aware of AppleScript? We'll start with that one. So everybody, okay. How many of you are scripting? How many of you are scripting well?

How many just kind of like jumped into it because you had to do something and you heard you can do it, but you don't know how it worked and you just pieced it together and you banged your head against the wall 20 times? OK. That's how I learned too.

I spent years and years pounding my head against the wall going, "No, I guess that doesn't work." And coercion, I thought, was just moving the matter to the other side. I didn't realize it was actually applying to the code in the window. My original idea when I was talking to Skip Levins about this session was to answer that need for a quick indoctrination into the mystery secrets about AppleScript.

Because a lot of people get thrown into it. They are introduced to it in a situation where they suddenly have to deliver some project. And they find a way that works. They find something that works for them. And it might not be the best way to do something.

They might be unaware of all the different things that AppleScript can do. And so my aim with this session is to give you a peek to the inside workings of a scripter's brain and to turn you on to all the hidden secrets that I've developed over the years about how to get up to speed quickly with AppleScript. And I focus particularly on some issues that are pertinent to what you do as a system administrator. I don't think I need those. Can I go to laptop, please?

Essential AppleScript tools and tips is what I call it. And for those that know me, which is probably one or two people in the room, this is the first time in seven years that I've done slides. So, I was so impressed with some of the slide stuff going on in the session, I had to get some together.

And I'm not gonna do all slides, 'cause I like doing a lot of hands-on. I like showing you what is there. I like just, you know, Emeril Dugassi, you know, you put stuff together and go bam, you know, that's what I wanna do. But I put together some slides so we could organize some of the concepts behind this topic.

That's it. You like that one. Introduction. Okay. Purpose of the session is to familiarize those that are already sophisticated computer users like yourself with the intricacies of a high-level language like AppleScript because it's very strange. It has some unique properties about the way that it works and the way that it thinks, and I just wanted to help you get across the bridge quickly.

Does that sound like the right thing to do? Hmm, grumble? Hmm? Okay. All right, polite golf clap, I like that. And we're going to focus on issues like file setup and manipulation and the kind of things that you do. What is AppleScript? We'll start there. AppleScript is a peer to Aqua.

Aqua is the graphic user interface to the OS, and AppleScript is the language user interface to the OS. I like to think about it in those terms. There's also another language interface that's really low level, which is the Unix interface that you're familiar with, the terminal and shell and that stuff, too.

But we also have the ability to control most of the operating system, a lot of the applications that run on it, and we can also talk, when I say we, I mean the royal we of AppleScript, Also have the ability to talk across networks in the Internet and control applications, to query web services, those kind of things. AppleScript has a very large scope in the operating system, and it can be your best friend.

we're going to look at the AppleScript language itself. AppleScript is an English-like language that sits on top of an architecture called Apple Events. Apple Events are messages that are sent internally within the operating system that communicate between processes, communicate between applications, communicate between networks. It's like e-mails being sent between a bunch of people. So any action that you do in the operating system usually has an Apple Event attached to it. And we know this because we broke AppleScript once and the whole OS stopped and everybody turned around and looked at us and we had to do another build.

I remember those days. But the AppleScript language itself is an English-like language that is approachable by the average person. It gives you a quick way to accomplish a task. You basically write what you think. Duplicate every file of the startup disk whose name contains Smith Project to the folder named Backup. That's actually a script. It's not just a concept. It's actually a script. And it's the principle behind what AppleScript can do. You take the mind, you rethink the thought, and you write it, and it should work. Most of the time.

It targets scriptable applications such as Microsoft Word, Excel, iTunes, just about every database, Adobe Illustrator, Adobe InDesign, Photoshop, QuarkXPress, dozens and dozens and dozens and hundreds of applications are scriptable. They are ready to receive these Apple events that occur when you write an English-like sentence that gets translated into these messages. Those messages get sent to the application and the application responds.

We're going to also learn how do you refer to scriptable items. This is a tough one. This is one of the big issues that usually ties you up and really confuses you because there's five ways in the operating system to identify an item. There's five different means to have a file reference in Mac OS X.

And AppleScript takes a certain one of them, and it supports all of them. And we're going to look at that and take the mystery out of, how do you use different reference types with AppleScript? I saw somebody go, ah, ah, ah. And we're going to learn how to use Apple Script to find items.

AppleScript has incredible ability, more so than just about any language I've ever come across, to quickly locate something in a very easy manner. You remember that sentence I just said, duplicate every file of the startup disk whose name contains Smith Project to the folder named backup. That sentence not only contains a command to do an action, but it also contains a query that locates every file whose name contains Smith Project. and then performs an action with it. The process of finding every file whose name contains Smith Project is done for you automatically, recursively, using every whose clause object specifiers. Very technical.

We're also going to look at some of the basic techniques for programming AppleScript. It is a serious language, although I have a lot of fun with it and I like to make fun when I'm talking about it. AppleScript is very much an industrial strength language. It is a peer development language with Java and Objective C in our tools.

You can make applications entirely out of AppleScript, partially out of AppleScript, or a mix or a conglomerate of any of those type of languages. And we sit at the table with the rest of the guys. We're no longer at the little child's table in the back. We sit at the big table, so anything that happens to Cocoa happens to us, too. We're a peer development language.

And we're going to learn some of the basic techniques that the language has, such as how do you do a repeat loop? How do you do a conditional statement? How do you do an error handler? These are mysterious things to people coming from another language because AppleScript has their own little way about doing it.

But once you've seen it once, you go, "Oh, duh. I got it." Well, we'll practice that part. And then we're going to look at some of the AppleScript tools that are available right on the OS. All of this is free, by the way. Did I say free? I meant to say free.

Did I say free? Free, free, free. You don't have to pay for AppleScript. You don't have to pay for this incredible ability. It's part of every computer that Apple Computer sells. And among some of the tools are the new script editor and the script menu, folder actions as well, and it contains a new thing called AppleScript Studio, which is part of the Xcode development tools that we'll be looking at as well. So let's get started. I'm going to dig right into the AppleScript language. and I'm going to reveal the mysteries of the universe. Are we ready? Amen.

Okay. How do you refer to items? This is the big thing. How do you locate a file? If I found a bunch of files whose name contains Smith Project, how do I use the reference of those files in a script? How do I take those items I've found, and how am I able to pass them to routines or to other applications to open them or to process them?

Well, scriptable items are referenced by their position in their object hierarchy or where they are in their chain of command. That's the way that it works in AppleScript. In other words, An example of a reference for an item would be file new car data of folder documents, of folder home, of folder users of startup disk. You can see that chain identifies where the item is. It's the file here in this folder, in this folder of this disk.

And that type of relationship, or that hierarchical relationship, is what AppleScript's based upon. It's based upon objects, and objects having properties, and objects having a location. And their identity as objects is determined by where they are in their hierarchy, or where they are in their chain of command. Does that kind of make sense? Let's take a look at this.

There's different kinds of references. I just said that there's five different kinds of references. The first one is a nested reference, and I just gave you an example of it. File cars are folder documents of folder sal, of folder users of startup disk. That's a nested reference. Why is it called a nested reference? Because it shows you that each item is contained inside the other item, and it uses the possessive of to indicate ownership.

The file is owned by folder documents, which is owned by folder Sal, which is owned by folder users, which is on the startup disk. And that nested reference acts like a bunch of Russian dolls that you kind of stick inside of each other. But it's just one type of reference.

There's path references, which are a means to identify an item by identifying each part of that hierarchy as a name separated by a series of colons. We'll look at that. There are alias references, which are similar to past references, but point to a live existing item. They're also very interesting in that they change, and Apple Script will find them and track them. So if you include an alias reference in your script and you move the file later, the reference inside the script changes as well.

There are Unix references that we're all probably familiar with, POSIX, PASS, that kind of stuff. And there's a thing called file URLs. These are the five types of references that you can use when identifying items in Mac OS X, and these are the five kinds that AppleScript supports. Nested references.

A nested reference, like I said, indicates an item's position by using a series of possessives, the of, so that it identifies the final object of a container, of a container, of a container, of a disk. And is that what I said? A nested reference describes an item's position and its object from the bottom to the top of its chain using the possessive of or where it is in its change of command. Nested references are the default format used by scriptable applications. And that's for the Finder, that's for system events, that's for iTunes, that's for the QuickTime player. Every scriptable app, when you query it about an object, returns you a reference in the nested format.

And nested references are used for scriptable items other than files. Let's look at some examples. Here's an example of a nested reference. Folder documents, a folder username, whichever your username is, a folder users of the startup disk. You can see that the documents folders, the target object here, and its position, its identity, is indicated by where it is in the chain of command.

Document file cars.pdf of folder documents, a folder username of folder users of startup disk. Here's the same kind of thing, but now we're looking at a file within a document folder. Here's an example of a QuickTime movie, frame 13 of track video overlay of movie two. Every scriptable item is identified by its position in its object hierarchy or where it is in its chain of command, whether it's a file or whether it's a frame, or whether it's a text box of a page of a spread of a document in QuarkXPress or InDesign, whether it's a transition of a video track of a program of a project in Media 100. This principle about nested reference and object hierarchy for AppleScript stays constant across the world of AppleScript.

Path references. Nested references, unfortunately, cannot be generated by a script. If you have a script and you want to pass the reference to this object to the finder to have it delete it, or you want to pass this to QuarkXPress to open it, or you want to pass it to some processor to resize your image, you can't generate a nested reference with AppleScript.

You can't make a thing that says something of, something of, something of, something of. The way that we pass a reference to an object, to an application, so that it can process it, this is interesting, I like that, is through this method called path references. I guess you carry data like this then, right? It would be like that. Path references are used to pass a reference to an object to the finder and to the system events applications.

Today, I'm going to have a lot of focus on what I do on files and folders and directories and those kind of things, because that's the meat and potatoes of a lot of sysadmin work, is dealing with these kind of things. So I'm going to focus on that, But just remember that it also works for any kind of an object, like an iTunes track or something else as well.

A path is a text string read left to right, and it contains the name of each item that's part of the object's chain. And these items are separated by a colon. Path references are preceded with the name of the class of the target item, such as a disk, a file, a document file, or an item, or the generic term item, meaning anything.

And path references to folders and disks always end with a colon. So if the target item is a directory, your path ends with a colon. And here's some examples. Tell application finder. So these particular paths are going to be within the scope of the finder application. Disk, quote, Macintosh HD, colon, end quote.

Strings and proper names are always placed within straight quotes in the world of AppleScript. That's the way that they're identified to scripts. Anything not within quotes is analyzed as being part of a dictionary or part of an application's ability. So this is a path to a disk. This is a path reference to a disk.

folder Macintosh HD colon users colon sal colon documents. So this is a path to the documents folder on my hard drive. You notice that since the target item is a folder, I've identified the class as folder up front and then passed that string behind it. Item is a term used that's generic.

So if you have a document file, an alias file, a font folder, a regular folder, a suitcase, any kind of object that's supported by the finder or the operating system, you can use the word item in front of it, and it's just a generic way to handle it. So if the script set you're writing and you're not sure what kind of thing you're going to be dealing with, you can use this item. Document file is used by the finder in particular as a way of describing a certain kind of item.

And then there's another example of a file item using item. And those all occur within the scope of the finder. That's a finder tell block. We'll be looking at those. It begins with addressing the finder application with tell application finder, and then everything after it pertains to the finder, and it finally ends with an end tell.

Another application that also is included with Mac OS X that can be used for controlling files or finding files or doing queries for you is the system events application. It's an FBA, it's a faceless background application that runs, and it's scriptable, and it has a disk file folder suite that is almost identical to what the Finder has.

And it does the same kind of thing as the Finder, there's only a slight difference is that instead of document file, which the Finder has, it uses the word file. Don't worry about document file, you can type the word file in and the Finder will change it for you when it needs to. so you could use file generically and it would work.

Those are path references. This is an alias reference. These are universal file specifications that are honored by every application in Apple Script. And they are what you use when you need to pass a reference between applications. They look like a path reference, only they have the word "alias" in front of them.

and they point to existing items that are tracked by AppleScript. We'll see how that works in just a second. Here's an example. So the previous example where we were pointing to a disk using a path reference, this is what it would look like as an alias reference. This is what the documents folder looks like as an alias reference. This is what the file in the document folder looks like.

And then we have POSIX references. You're familiar with these. They're derived from the Unix underpinnings of our operating system. It's one of the great abilities that we got that really makes Mac OS X move forward is its Unix history. But these kind of paths, the slash paths, are generally not supported by scriptable applications.

We've been around since System 7. We're based upon the colon alias kind of idea, and we're not yet aware of the slash idea. But there are easy ways to get back and forth between the two of them. Here are some naturally some POSIX examples. You can see, you know, there's the documents folder. There's a file in the documents folder.

There's another drive, a folder named backup. And you notice that the characters are escaped there because of the spaces. And then at the bottom, you notice that the entire line is quoted because of the spaces inside of the path, right? Did I do that correctly? Yes, I did. Thank you very much.

Now, AppleScript does provide a way for get-- driving POSIX references from other reference types using a construct called POSIXPATH. And it also-- I took the wrong key there-- also provides a way to coerce these POSIX references into the kind that AppleScript can use with a construct called POSIXFILE.

Here's how you derive a POSIX path. You say POSIX path of, and then you provide an alias reference to an object. In this case, our object is the documents folder. If I ask for the POSIX path of this reference, we get returned to our script, users/sal/documents. So that's how you get a POSIX path from an alias reference.

There's the POSIX path of. Just place that in front of your reference. Now, if you're not sure that the user might have used some strange characters or some spaces or stuff like that, which often occurs on Macintosh World, you might want to ask for the quoted form of the POSIX path of this reference.

And what that does is, neatly in white, see I'm getting into the slide thing, Neatly in white, you notice how it puts those little apostrophes so it quotes the line for us automatically. So quoted form of posix path of. If you didn't know that, you'll be sitting there pulling your hair out and then you'll make these stupid routines to try to figure out how to append apostrophes to the end of what you were deriving.

Thank you. Some of you might have already tried that. How to coerce a POSIX path. Now, to get to an alias reference, it's going to take us a couple steps. The first one is that we need to get to what is called a POSIX file. And if you take a POSIX path and you say as POSIX file, you will coerce it to this format here, which looks like our path reference, right? File, then colon delineated from the drive down to the object itself.

It's by saying "as." Any time you want to do a coercion from one format into another in AppleScript, you use the term "as." You could take a number, coerce it to a string by saying "ten as string." You could take a string and coerce it to a number by saying "five as number." Use the as word, the as verb. That's not a verb, it's a... Preposition, I'm guessing, is that right? Okay. Whatever it is, it's a wonderful word. It's a magical thing. Use that when you're doing a coercion. That's how you coerce in Apple script.

Now, to get to the alias, we're going to do a double coercion. We're going to, first of all, coerce to a POSIX file. Then the result of that will be coerced to an alias. That's because Apple scripts are read left to right, and they're executed left to right and from the top down in a script.

So the first thing that happens is that that POSIX path is coerced to a POSIX file, which is a path reference, and then it's coerced to an alias. So the end result then is an alias reference that I can use with QuickTime Player or any other scriptable application to have that folder become a target folder or open. That's how you coerce from POSIX to alias in one line. If you didn't know that, life is horrible. If you do know that, you're in the air conditioning.

File URLs, little known but can be useful in extreme situations. File URLs describe items on your drive in the same manner that-- the same way that they're described on the internet, which is HTTP, blah, blah, blah, blah, with all the different slashes and stuff. And they can get these file URLs from either the system events application or from the finder, or you can make them up yourself if you want to.

And they look like this. Tell application finder to get the URL of folder documents of home. Well, that would return me file colon slash slash localhost slash users slash style slash documents. File localhost users slash style. Now you'll notice that in the other ones, It automatically provides that for you.

When you're asking for the file URL, you don't have to worry about the percentage encoding. That'll get handled for you in the information that's returned. So those are the five types, and how do we coerce between them? So let me just review. They are nested reference, path reference, alias reference, posix, and then file URLs.

To coerce between them, we'll review this quickly. You can coerce between the following reference types: nested reference to an alias reference. So I can get a nested reference back from the finder and say, "I'd like this as an alias." You can coerce between a path reference to an alias reference. So I can take a path reference that I construct myself with my script and then coerce that to an alias that I can then pass to an application.

You can coerce from a POSIX path to a POSIX file to an alias reference, like we just saw. And then you can coerce between an alias reference to a POSIX path, as we saw previously. Nested references, again, cannot be generated by scripts. So here's an example. Folder applications of the startup disk as an alias will return me alias Macintosh HD colon applications colon.

Folder Macintosh HD applications as alias. This is an example of a path reference within the parens coerced to an alias. So that returns the same thing. And then entail. The POSIX path of an alias Macintosh HD blah, blah. So we have an alias reference here. We're asking for the POSIX path. That will return us the POSIX path to that particular directory.

And then if I take that and coerce it to a POSIX file and then to an alias, it returns us back to an alias. So that's how you coerce in AppleScript between the various types. Has anybody ever told you that stuff before? It's like mysterious stuff, isn't it? If you don't know it in the world of AppleScript, you'll go like this. And you can see that half my head's worn away from that.

So let's take a look at some of this kind of stuff. Can I have this machine? What do I call this machine? Demo? That's-- Demo 1. Thank you. Demo 1. Okay, this is demo one. So before we begin taking a look at these path kind of ideas, We need to find out where AppleScript is on your computer, and I'll be happy to show you. AppleScript lives in a couple locations on the computer. The main location is in the AppleScript folder. And if you open up your -- ooh, yellow. I like that. Soft on the eyes. That's nice. Thank you. That was really good. Nice touch.

If you open up the applications folder, within that folder is a folder called AppleScript. This is AppleScript's home turf. This is where we live. And we're in Panther right now, so, you know, some of these icons might become a little bit more sophisticated by the time we ship.

we do have a script editor that has an icon though and this is the script editor application It's new for, it's the beta version that we've been posting on the website, and a lot of people have been using it. It's an incredibly nicer version than we had before. We had the distinction of being the oldest piece of code shipping in the operating system prior to this. This is a native Cocoa application. It has a lot of power. Don't be fooled by how clean and nice it looks.

This is the script editor application. This is where you read and write and record your scripts. It contains two different panes. In the top area here is where we write scripts. application quote finder, remember names get put within a quote mark, to open the startup disk. And this is our compile button for checking our code to make sure it's been written correctly. This is our run button. And when I run it-- well, that's interesting.

Oh, I hit others. Okay, sorry. I fooled myself. I only have me to blame. And that pane is where we write our scripts. You'll notice that as I clicked the compile when it was checking the script to make sure it was written properly, certain words become bold. Certain words will become indented. This is to show you which words belong to the AppleScript language, which words belong to the application that you're addressing.

For example, the word tell belongs to Apple Scripts, so does tell, so does to, and so does the. Startup disk and the verb open belong to the finder. At the bottom here is a multi-paned area, and we have three panes. One is a description pane, and scripts can actually post little dialogues with scrolling information about the script. And you can just save a button, click a checkbox when you save your script, and they will do that for you.

and you keep that information that you want to present to the user in this pane right here, your description field. The result field shows you the last action of your script, the result of the last action. So if you had 10 actions, it would show you the result of the 10th line of your script.

The event log is a way of tracking what you do with your script. It will follow along and show you each of the actions and the result from that. So if I asked the finder to get the name-- I'm not spelling today-- the name of the startup disk and click that, you can see that my event log shows that a command was sent to the finder, get the name of the startup disk, and then indented underneath it shows you the result of that action.

So this is a way to debug your scripts. You can use the event log as a way of tracking what you're doing. And the result window always contains the result of the last action, which is the name of that wonderful name, Panther W Tools HD, the name of my startup disk. This is the script editor window. This is a script window within the script editor.

It does have some new features, especially for this new release. And one is called the navigation bar. If you have a rather complex script that has a lot of different routines and handlers in they would show up here. And if you're using other scriptable language besides AppleScript, they would show up over here.

Which ones were you referring to clapping to? Python. Somebody said once Python. Perl. And JavaScript, right? There is a JavaScript OSA component from Mark Aldred of Late Night Software, and you can install that, and that would show up right there, and you could use that if you wanted to.

The script editor also provides us with a way to view the internal dictionaries of applications. Applications that are scriptable have scriptable objects. They contain scriptable objects. And each of those objects contain certain qualities that make it a scriptable object. And you can examine the entire structure of a scriptable application by asking for its dictionary. So I just choose the "open dictionary" command from the desktop, and I'm going to open up the QuickTime player.

choose open and this is the dictionary window for the QuickTime player. This window contains on the left hand side will contain the terms and the phrases used and on the right hand side will naturally contain a description about those. Selected by default is the standard suite and these are the commands that are part of the standard suite.

By standard suite, those are usually the commands that are available in most scriptable applications support this. And they're your core set of verbs such as close, count, delete, exist, make, open, print, save. Those kind of verbs are part of the standard suite. So when I told the finder to open something, I used this verb.

It says open, and then it expects a reference. A reference to what? Whatever it is that I'm supposed to open. It will take a list of them or a single one. In this case, I said the startup disk, and that's what it did. In this case, the QuickTimePlayer suite contains all the classes of objects that are scriptable within the QuickTimePlayer. For example, the parts of the QuickTimePlayer that are scriptable, let's start with the most obvious one, is we'll look at the application. This is the QuickTimePlayer application itself. You can see that the dictionary is divided into a section up here called elements.

That's what makes up the QuickTime player. It can have a display. It can have a favorite, a movie, a recent item, and a window. The properties of the application itself, it does have some properties that you can set from ignoring auto present to what is your QuickTime, is QuickTime Pro installed, and it will return a Boolean value for that. So I can just take this right here. Go to my script. until application QuickTimePlayer.

run that and it'll launch the QuickTime player and return me true. QuickTime Pro is installed on this machine. And you'll notice that it said, it brought up my little welcome movie, I guess what they're calling it, and it's currently set in the preferences, player preferences, to show this movie for me automatically. Well, I see that that's also a property down here and it takes a Boolean value, so I could use this and say set to false.

check my syntax and run it. And now when I go back to the QuickTime player, If I choose preferences, player preferences, that's turned off. So what happens is this piece of code, this English-like sentence, is translated into an event that gets sent to the QuickTime player. The QuickTime player takes that event, responds to it, and does something accordingly. The dictionary is where you learn about your particular applications that you want to script and all the things that they can do. For example, if we'll open up here and we'll look at the Finder dictionary.

I'll show you the dictionary quickly for the finder. This is how the finder dictionary is divided. It has a standard suite just like the other application. It has its own basic suite which contains some classes of objects and then it also has commands. It has some finder items.

And these are the properties, owner privileges, and then it has some verbs like clean up, eject, empty, erase, reveal. You can use the reveal verb with a reference to the object to be made visible. Well, let's try that out. So I'll say, tell app, notice the shortcut, Reveal the reveal folder. Users of the startup disk.

Mistake, something happened. And there's a typo here. Start up disk. Now let's check it again. And I'm going to get one teacher verb, activate, which will bring the finder to the foreground. And let's run that. And there it is. It selects it and highlights it for you. It uses the verb reveal. So the point I'm showing you here is that the dictionary contains the commands for the various applications.

You're going to have to go into these dictionaries and parse them, play with them, have fun with them to learn all the different things that they can do. But they are available to you right from within the script editor. So let's take a look at some of the reference types that we were looking at here. And the first one was a nested reference. So I'm going to take away the activate verb here. And I'm going to say, open up my hard drive and take a look in my home directory.

And I'm going to go into my pictures folder, webcam images, and get that, copy that. So I'm going to say, let's make a nested reference to that. So if I just say home and run that, it gives me the reference to the home directory, folder apple of folder users of startup disk of application finder.

of startup disk. So if I said folder pictures, Now I have a reference to folder pictures of folder Apple, of folder users of startup disk of application finder. And then in that, there was a folder called webcam images. So I would say folder webcam images. images of folder this. As you can see, nested references are rather verbose. That's why we don't create them. And then I'm going to take a movie out of there.

And then I could say document file quote this of. And that points to that movie file. That's an example of a nested reference. It can use that with any of the commands like open, and it opens up the movie, just as if you double-clicked it from the Finder. Or I could use the verb "delete."

and then look in the trash, and you can see it placed it in the trash. That's a nested reference. It's used by the Finder application, and it's used by, as the default, for most scriptable applications. The next kind of reference we're gonna look at is a path reference. Now I was writing this nested reference by hand. I passed this reference to the finder by hand because I wanted to create that for you.

If you have a script that you're writing or that's functioning, that's performing an action, you won't be able to create this kind of thing indirectly. What you can do is pass it a reference as a path reference, which would be file or document file. this part I can create because this is just a string. It looks something like this, and then users: Apple, is it Apple? Apple. And then pictures.

Then the name of that file, oh, no. Then the name of this file again, I'll grab it again. So a script could generate this because it's just a text string and expected--see? And I misspelled webcam images? Pictures, that's right. Well, let's -- hold on a second. Let's try that out. So let's see if I got this right. doesn't exist, right? Because I missed this one thing here called webcam images. Cam.

And again, it opens it. A script can create this, because this is a text string. We can get the path to the startup disk, or we could get the path to another directory, and then add or concatenate the name of the file that we want to the end of that. Take that, put the word document file in front of it, and pass it to the finder. And that's what we have here. Or you can coerce a path to, so let's say, home as Alias or home as string, I'm sorry. Home as string.

And if we run this, it gives me the path to the home directory, but as a string. So then I can take that. I'm going to make a variable, and in AppleScript, This location to home is that. In AppleScript, when you make a variable, are we familiar with what variables are? I assume. Variables are containers. They contain information.

In AppleScript, to make a variable, you just make up a name that AppleScript doesn't know that's not part of a dictionary. You can make them up in a variety of ways, such as this, where I use two words that are underscored together, or you could make it probably something like this, where you have an intercap, or you could just make it X, Whatever you want to use for your variable, you can do that. But I'm going to say this location.

to home is string, and then I have that part stored into the variable, and then I could set the target file to, and make this a variable here, set the target file to this location, ampersand, concatenate, and then I'm gonna pass it the rest of the path. So I'll say pictures, webcam images, And then the name of the file, which I'll grab one more time because I'm lazy to memorize it.

So what I've done now is created a string. Let's run that. And I have a string to make it a path reference. All I need to do now is tell the finder to open document, file, and then whatever's inside of this container, which is a path reference. And now that's how you pass a reference to the finder or to an application. Does that make sense?

You can create these yourself by putting together pieces of string. You can't create a nested reference on the fly like this is doing. Then the last thing that we wanted to look at was the alias reference. So I could ask this location. I'm going to delete that again. Instead of as string, I'm going to say as alias. I misspelled alias.

And that's how I can coerce from a nested reference right to an alias reference. So now, within the variable, I have alias panthered this to a directory to my home folder. So if I say, open this location, what will happen? my home directory open. That's how you coerce to an alias. So those are the different kinds of references.

Nested reference, path reference, alias reference, and then we have POSIX paths as well. So if I wanted to take this and then coerce that to a POSIX path, then I could say, POSIX path of this location, because what's inside the variable is just the same thing as if I was addressing it, and I misspelled path.

Notice how AppleScript finds that for me. And there it gives me the POSIX pass. So if I needed to do a do shell script, or I needed to pass something to the terminal, then I could coerce what I had into this kind of a thing. Does that make sense? We see how that works? Very simple. OK. Let's go back to these slides. Laptop 1. This is kind of dry stuff, but it's the stuff that nobody's going to tell you otherwise.

Okay, finding items. How do you find items? Specific items can be located by querying the finder or the system events applications. And the way that you do this is just by asking. Items can be located in two different kinds of ways. You can identify items by two different kinds of ways. Does anybody know what they are?

index and property. For example, we have people here. I'm standing here and I could say, if I need to find somebody by index, I could say, third person in the third row on my left hand side, please stand up. And that would be this gentleman right here. I won't embarrass you, please sit down. So that's an index, right? Third, third, we're looking at a number, where they are in a position, in a list of people or a row of people, I'm looking for a specific one.

I could say the 10th row please stand up, and the 10th row from here would stand up. I'm using the index property of an item to identify a specific one to get to where I want to get to. The second way that you can identify items in Apple Script is by a property. Now we all have properties. Every scriptable object has properties. A movie has a property of a duration. A movie has a property of a kind. Is it an audio track or a video track? As a matter of fact, it relates a lot to the way life is.

Consider Sal to be a scriptable object. As a scriptable object, I have certain qualities that make me who I am. I have a height. I have a weight, unfortunately. I have an age. I have a position in the room. I have a name. And these qualities define who Sal is, or help define all that is Sal. Now, you can use the properties of a scriptable object as a way of identifying it. For example, here's one. Would everybody who's named Bob please stand up?

Oh, come on, really? An entire place? There's no bobs? OK. Wow. Charlene? OK, but you get the idea. I could say-- we could go by color. I could say, well, everybody's wearing a red shirt. Please stand up. And then people would stand up if they so felt like it. But you can see what I'm talking about. You can use a property. You can use a quality or a value of a property as a way of identifying a specific item. And the same works in AppleScript.

You can find by index or you can find by property. Here's how you find by index. Every scriptable item on disk or belonging to an application occupies a specific space in the order of items in its parent container. Ugh, what does that mean? Okay, finder windows. Here's a good one, right?

Can there be two finder windows on the same level? No. For some reason, there always has to be one finder window that can move on top of another. There's always one finder window that gets on another. In other words, if we looked at the finder sideways, we would see a stack of windows that were open. That stack is a list of windows, and every window has an index number corresponding to the way it is in that stack.

The middle guy might be window three. The top guy will be window... Right, and the last guy would be the total sum of the number of windows. So the index property identifies where an object is in the list of objects. If I had five movies open in QuickTime Player, there could only be one front movie, right?

So the front movie would have an index value of... So I could say, tell movie one to play. and it would play. If I said tell movie two to play, the front movie wouldn't play, the movie behind it would play. So the index property is a way of identifying a particular item in AppleScript. Thank you. Numeric values represent an item's place and blah, blah. It's called an index. Okay, here's an example. Tell application finder to get item one of the startup disk. What's that going to get?

What would that return? It would probably return something like folder applications of the startup disk. It's going to return me a nested reference to the first object that it finds on the startup disk. item one so i'm using the term item which is generic identifier member and i'm saying give me the first one and by saying the index value of one Tell application finder to get item 12 of home. Well, that could return anything on anybody's machine, but in this case, I have a nested reference to the folder downloads, the folder sale of folder users of the startup disk. So I'm identifying it by it's the 12th item in the container that I know lovingly as home.

So items are, when you have a bunch of items in a container, they're actually like a list. This is a list in AppleScript. This is what a list looks like in AppleScript. And it's the same kind of list that works for a list of references, a list of data, a list of numbers, a list of names, a list of combination of anything.

In AppleScript, you can put all kinds of stuff into a list. It doesn't make any difference. You don't have to declare, this list only has fish. No, you can put in anything that you want to. And it begins with a curly brace and each item in the list is separated by a comma and it's closed with a curly brace. So let's imagine that that's a list of items.

So if I ask teleapplication finder to get item count of items of home of home. Now what's that? What am I doing there? I'm asking for the last file or last item. Could be an item, right? So it could be a folder. We don't know. But I'm asking for the last thing in the home directory. I'm doing it by with this paren thing. As we know in algebra-- what was that? It's like turn and then twist. I like that.

Turn and twist. That's good. The count of items of home will get executed first because it's within parentheses, right? Similar to like what we learn in seventh grade with algebra. Things inside of parentheses get done first, and then the result replaces them, and then the thing continues from the outside in.

So the first thing that this script will do is it's going to get the count of the items of home, replace that, and then use that number as whatever item is. If I have 24 items in the home directory, that will be item 24 will be returned to me.

So in this case, it was folder USB keys, U being the last thing I probably had in the folder. Now, so far we've been looking at our list from left to right. But AppleScript has this interesting thing called the negative index. Ooh, see this is the kind of stuff that you get when you come to see Uncle Sal.

Apple scripts supports the iteration of lists actually in both directions. As if you're not confused enough, you need more. Items in a list have a positive index value when the list is transverse from left to right, or from top to bottom in the case of Windows, right? Okay. But when you read them from right to left or from bottom to top, they have negative numbers. Ooh, interesting. For example, left to right, this list is item one, item two, item three, item four, item five, right?

But when you read it the other way, from right to left, that's item minus 1, item minus 2, item minus 3, item minus 4, item minus 5. Okay, let's do that again. Left to right, one, two, three, four, five, this way, back this way, minus one, minus two, minus three, minus four, minus five.

That's called a negative index value. Now why do we know that? Why do we want to use that? What do we care about that? Well, remember how I said tell application finder to get item count of items of home of home? That's a lot of work to do just to get the last guy in the home. What else could I use instead?

Minus one, darn right. So if that returns the USB, so does this. Tell application finder to get item minus one of home, returns folder USB key of folder cell of folder users of startup disk. So this is an example of why you want to use negative index values on occasion. If I wanted to get the item before the last item of home, what would I use? The one before the before, three. The one before the before, the before, four. And now I'm lost. I'm not going any farther.

together. Okay, we can also find items by range. I can ask for a range of items using index values. For example, I could say, tell Application Finder to get items two through five of the startup disk, and that's going to return me perhaps something like that, you know, folder applications, and the next thing in the list. So in this case, the list is a list of references.

Before, it was just a list of names, right? But now, a list can contain anything we want. It's a list of first references, folder applications, the startup disk application finder, comma, next list item, blah, blah, blah, blah, blah, blah, next list item like that. So I get back a list of items by identifying a range using numbers.

Tell application finder to get items 1 through minus 1 of the startup disk. What will that do? Everything. Why don't I just use this instead? See, that's the beauty of AppleScript. We've got all this cool stuff, so instead of doing one to minus one, you can just say every. Every is a great word in AppleScript. Every item of the startup disk.

Thank you. Finding items by descriptive index. Now, I'm giving you the extra stuff that you normally don't get, so here's something cool. Since AppleScript's supposed to be conversational, you can write it as terse as you like, or you can write it as verbose as you like. You can use words like this. First, second, third, fourth, fifth, sixth, seventh, eighth, ninth, tenth. You can use those instead of writing out the numbers. Why, I don't know.

So you can say, here's why. You can tell Application Finder to get the first item of home. So you can use the word first. God bless you. Or you can use first, 23rd, 10th, you know, 4,678th. So it supports that as well. So you could say, tell application finder to get the 22nd item of home.

Instead of saying item 22, you could say 22nd item. Conversational. Finding items by relative position. Now this is interesting. So items can be referenced in terms of the position relative to other items in their parent container. So will the person next to the person on the end wave his hand of the second row?

There you go. A little bit of prompting, it worked. So there, I took somebody as an identifier, was the gentleman on the end of the second row. And that was my pivot. And then based upon him, I referred to somebody else. Would the person who's sitting across from the gentleman in the second row wave his hand?

Right here. So you're using an item by index and then referring in relative position to that. You can do the same thing with AppleScript and files and things like that. And you can use these terms when doing relative position. Front, first, back, last, middle. So I could say, give me the name of the middle window of a stack of windows, and it's going to find the window that's in the middle and return that.

I could say, "Give me the name of the last window. Give me the name of the front window." And as a matter of fact, there's the last item of the startup disk, the middle track of the front library, that's iTunes. You can expand and alter that relative positioning using the words "after" and "before."

the item before the last item, the item after the middle item. So those are examples of how you can use relative positioning to find specific things with index values. Also, you can generate random things by using the word sum. So if I ask for some item of the startup disk, every time it's gonna give me something different.

So that's finding items by index. That's an important concept to get, but once you do that with AppleScript, it's really good for doing that kind of thing. The only thing that's tricky about index is if something moves, everything changes. If somebody leaves this row, the quality of the row has changed. Now my index stuff that I had set up doesn't work anymore.

So be careful when using index value as a way to find an item, but it can be very useful. Now, finding items by property. Well, you pretty much guessed this one too, right? Every item on disk, like Sal, has a property name, blah, blah. He gets older and older. Some of the properties you can change. I can change my shirt. I can't change my age. That, unfortunately, is a read-only property.

There are some properties like name, kind, which is also file type. You can find items by file type, size, creation, modification, dates. Just about any property of an item can be used to delineate it when you're looking for it with AppleScript on a disk. You can find them by comparing the value of their properties to a desired set of values. For example, the first document file whose name contains Smith Project. I'm asking for the first document file whose name contains Smith Project. Now watch this magic happen.

The first folder whose size is greater than 500,000, that's bytes. In AppleScript world, you'd say bytes, and then you'd have to do the math. We have math, though. Every document file whose file type is JPEG, hmm, might be useful. Every document file whose name extension is PDF, hmm, that might be interesting, too, as well. Let's examine this farther. How do you do these queries, these finding queries? How do you create a query?

Well, we know that when you do Command-F in the finder, what do you get? You get that pop-up window thing that has the, you go add another detail, add, remove, damn, I want the other detail, the pop date created, and so you're basically writing a sentence is what you're doing with those things, right? You want something whose name begins with this, but creation date is after so-and-so. Well, a query in AppleScript is composed by combining these elements first.

God bless you. a positional indicator, a target object type, a target container, an object specifier, a target property, and a comparison operator. Is there any more? And a target property value. Ooh, ugly, ugly, ugly, ugly. But it's true. And it looks like this. The first document file of home whose name contains Smith Project is actually all those things. We don't think when we're doing it. We just think like that because we're trained to think like English thinking people. Whoa.

For example, a positional indicator is first. What if I want the last? What if I want every? I could say every document file of home whose name contains Smith Project. I could say the last document file. So that's just a positional indicator indicating where in the list of items in the home folder this particular one is that I want.

Then there's the target object type. What kind of object are you looking for? If you want just everything, you say item. If you want a document file, you say document file. If you want a folder, you say folder. If you want an alias file, you say alias file. An alias file is that thing that you double click and it takes you to the real location. If object type goes next. Then the target container.

Where am I searching? Okay. In this case, the word home indicates in the finder your home directory. That could also be a variable containing an alias reference to some other path that I want to have searched. Right? I could have it that be folder nested way inside of my preferences folder and then just pass that into the search.

Next comes the object specifier, which is whose. There's also where. You can use where with AppleScript and the word its. Where its blah is blah. Instead of using whose blah is blah, you can say where its blah is blah. And what the English grammatical rule is for that, I have no idea.

But we support it. Then what kind of property are you searching on? We're looking by property now, right? So in this particular case, I'm using the name property. I could use its modification date. I could use its size. I could use its comment tag. I could use whatever label. Labels are in... Okay, yeah. I thought I gave something up there. Okay.

laughter That's right, it's all right, it's all right, it's all bad. Target property, so then you have to identify what property is, then your comparison operator. Now, this is the interesting one, contains. Well, you can use every one that you can think of. Contains, does not contain, is in, begins with, ends with, is greater than, is less than, is greater than or equal to, is not greater than or equal to, isn't greater than or equal to. Just about any one of the things that you can think up in your head for the English language will fit into one of these comparison operators.

And then finally, what is the value of a property that you're searching on? And that is, in this particular case, the Name Value Smith project. So all of those things that have names just go into that. We understand these implicitly. You really don't have to think about them beyond that.

Now, here's how you can change the positional indicator to change your query. The first document file, the last document file, every document file. You can change the comparison operator to change your query. Every document file whose name contains Smith Project. Every document file whose name does not contain Smith Project. Every document file whose name begins with Smith Project.

Every document file whose name ends with Smith Project. And you can also change the property value that you're looking for. document file whose name contains Smith Project or every document file whose name contains ACC Stats. Do you get the idea of how this works? It's pretty much like you think, right? Now, what about recursing? How do you get down through a directory, a hierarchy?

So if I have a folder within my documents folder for a project, I want to search everything in that folder. How do I do that? Well, you go to JavaScript and you write for if, and and then you start doing a recursive loop that recalls itself back up at the top again when you get down to here. No, we don't do that in AppleScript. We're civilized.

We're bohemian but civilized, aren't it? And the way you do that is with the entire contents property. Every document file of the entire contents of folder documents of home whose name contains Smith Project will do all the recursing for me. What will I get back? I'll get back a list of references to every item within that entire hierarchy who matches those particular query objects that I set up.

Now, let's take a look at some of that. Can I go to demo, please? One, demo one. Index value, demo one, demo two. Demo one, demo two. Can I go to the machine next to demo-- the other demo machine besides demo two? That is not-- a demo machine that is not demo two.

Quick, write it again. Write it again. Demo one. Thank you. Sal, your irreverence has cost you. Okay, you guys are gonna make it hard on me, all right? I'm gonna try something here. I'm just gonna copy this. be webcam images. And I'm going to go to the script editor.

And I'm going to set up a -- open the window here called library. And this is my little shortcut window to my favorite things. I'm just going to go click a new script for that. And then I'm going to go up to the menu here and go paste. Nope, it doesn't let me paste reference anymore.

Okay. Feature. Never Okay, so what I want to do is I want to do some searching here. So let me see if I have anything that's searchable. Every... Every file, every document file, document file of the desktop Desktop is a special area whose kind is JPEG image. I think that works.

and it gave me a link to an image. And it gave it to me in a list format. Why did it give it to me in a list? because I asked for every and it just happens to be one right so if I want to get something out that list then I could say set this image, my variable, to item one of, and then I'll put that all in parentheses like this, so I'll get the first one. That's one way to get the first one.

Can't get item one of every document file. That's interesting. That's a bug. I'll have it done by Tuesday. Let's shortcut the process by doing that. And that gives me back one. Why? Because I asked for the first instead of every. Now that I have this image, then I can go open this image.

So there's how to do a query and find something and do something with it, right? Let's try something else. Let's go... every item of home whose name contains S. Okay, there's a lot of stuff. You can see that it returns me a list of all the matching items, right? Folder sites whose name contains "SI." Folder music, which contains SI, and folder sites that contains SI. And then I wonder if I can say reveal if it will let me do that. I'm gonna try that.

And it probably did the, it selected both of them. There they are. Both of them have been selected. So, ooh. So what we have here is cleaning and waxing in one motion. One motion I find the stuff, the other one I actually do something with it. In one line of Apple script, we are able to clean and wax together.

And that's how you do it using these type of finding techniques. Let's go back to slide machine please, which is laptop. Now, I'm going to go through some of this. This is secret stuff that we're done. Oh, we're done? Can I just have everybody come back to my room?

You guys want to come back to my room? They won't mind. The Argent, I'm right over at the Argent. We'll just walk in, you know. They're with me. I apologize about that, but I hope perhaps that maybe this gave you a little inkling of what some of the AppleScript can do for you and a little bit of the ability. One place you go, www.apple.com slash AppleScript. Click the Resources button, and there's a ton of stuff there for you to peruse. Thank you so much. I appreciate it. Thank you.

Created by Nonstrict, makers of the Bezel app. This site is not affiliated with Apple. All content is provided for informational purposes only.
