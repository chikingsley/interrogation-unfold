# Unfold - WIP Defold Modding Tool

**The Defoldmine**
4.0k views | 61 likes | 9 links | 8 users
November 2020

---

## Original Post

**Potota** - _November 2020_

Hey, all! I'm proud to release a little something I've been working on for a while now. It's a currently unfinished tool for modding Defold games, made in Defold. Right now, it can only extract files from a game's archive. It's possible to decompile most of these files into their original form, though implementing that requires a native extension port of `lua-lz4`, which I can't make myself. Adding in the ability to re-import assets (actually modding a game) also requires that extension, so I'm at a bit of a stand-still with development at the moment. The README has more details about the technical side of things, so go read it if you're interested.

### Installation

You can download a build from the [releases page](link_to_releases) or download the source code from the [GitHub page](link_to_github) and build it with Defold. Only Windows and macOS builds are available, since `def-diags` doesn't support Linux yet. Until that gets fixed, you can easily run the Windows build on Linux through Wine.

### Screenshots

**UI:**
_(Image of Unfold UI with Setup, Export, Import tabs and Bundle Folder input)_

**Output from @Pawel's Witchcrafter:**
_(Image of file tree output showing decompiled game assets)_

---

## Discussion

**Pkeod** _(Sir Defold)_ - _November 2020_

This is cool, and inevitable (devs have to assume anything they put into their games will inevitably be extracted / data mined), but by making it easy and accessible it lowers the technical barrier required to do other unfair things to the work of creators. Some of us had working exporting to see how possible it was years ago but did not publish it on purpose because a tool like this existing is a disincentive to use Defold. Besides being unfair to devs, it will encourage custom private forks of Defold that add more obstacles to the extraction process but also private forks of projects tend to not push their improvements back to main once they happen which hurts the entire ecosystem. Is easy modding worth it? Maybe. If you didn't do it, someone else would have eventually but it's still bittersweet when it happens.

**Pros:**

- Modding
- Learning
- Preservation

**Cons:**

- It can be illegal to do, unethical, immoral, opens people (who use this) up to liability
- Piracy (any Lua authentication is easily defeated)
- Cheating (multiplayer games get hacked clients even easier and faster to make)
- Stealing (ripping assets, rehosting domain locked html5 games, taking all code and simply reskinning)
- Malware (injecting bad code into your game and putting it on pirate sites)
- More private forks of Defold to make the obfuscation process more complicated / everything else positive made on private forks less likely to be contributed back
- Discourages devs to not publicize they made their games with Defold (why put a target on it, people will just search how to decompile Defold games)
- Discourages devs from using Defold (not having an easy public decompile tool was one less momentary advantage it had)

In response to this, to make potential devs looking at Defold feel better, there needs to be a way to use custom encryption keys that can be obfuscated in ways which are not easily extracted (though I doubt this will happen in the official releases). This still is a cat and mouse game but at least it can be distributed instead of having an all in one method. Decompiling should not be easy, not be easy to be human readable.

Other tools like Unity and Unreal have decompilers too, but they also make it less human readable and editable, and have options for custom encryption keys, so if people want a higher bar to decompiling it's one more reason to use them.

---

**Denis_Makhortov** - _November 2020_

+, I have the same questions. I am far from packing Defold files, so I would like to hear from more experienced ones: how much is the source code protected?

I quickly tried several decompilers and was unable to decompile the luac file. I don't know much about this, but I hope there is some kind of protection.

P.S. This project is really cool

---

**Pkeod** _(Sir Defold)_ - _November 2020_

This tool is for now not yet complete. Even with custom obfuscation you have to assume that someone motivated enough will eventually decompile it, but making it easy for anyone who can press buttons is a real pity.

You can always beat people to punch by releasing most of your project's code as public and open modules as many of us do.

---

**Denis_Makhortov** - _November 2020_

Referring to Pkeod: "This tool is for now not yet complete."

If completed, it will be amazing! Writing mods for Defold games. That sounds nice!

It would be just cool to know such things to take them into account when writing code (for example, multiplayer, verification or some special things)

---

**Pkeod** _(Sir Defold)_ - _November 2020_

Yes, though unauthorized mods. There were already ways to mod Defold based games that could be done in official ways without decompiling the entire project. I've thought about it a lot but to me it seems dangerous because it's hard to sandbox Lua code to protect users from dangerous mods that are actually malware. With the full project approach, there is no way to protect / sandbox users from malicious modifications. Once it happens we will all have to deal with many false positives from AV vendors in the future for all of our games.

---

**britzl** _(Defold team)_ - _November 2020_

Referring to Potota: "actually modding a game"
Referring to Denis_Makhortov: "Writing mods for Defold games. That sounds nice!"

If you really want to open up to modding of a game there's other ways to go about it.

- **Lua code can easily be loaded from external files and executed in a running Defold game.**

  - If you want to create a moddable game this is definitely the first and most obvious step.
  - If you add the ability to load external Lua files to your game you can open up your game to a lot of modding:
    - Modders could move UI elements, change their size and color.
    - Modders can create bots or tweak enemies, items and anything else imaginable

- **Being able to load and replace the contents of an entire texture is possible using `resource.set()` and something like the [Image Loader extension](link_to_image_loader).**

  - This would allow a modder to change the graphics in your game as well.

- **Switching out sounds should also be quite easy to do.**

Referring to Pkeod: "This is cool, and inevitable"

I agree. You can never ever protect your game from someone with enough dedication and time on their hands. But with accessible tools the bar is lowered.

Also, since the code of Defold now is available it makes it that much easier for someone intent on decompiling and ripping apart your game.

---

**WhiteBoxDev** _(Defold Game R...)_ - _November 2020_

Random thought from someone who doesn't know anything about decompiling or modding games. This project makes me feel two things: concern/anxiety and sadness.

I think it's sad that things like this exist because suddenly I feel like my privacy as a developer is gone. If people can easily dissect exactly how I made the game, I feel like everything I do with the project files (comments in the code, naming conventions, consistency, etc) are all being "watched" and judged by a bunch of random people. Although that may be irrational, it's only an initial impression.

Additionally, if I want to open my game to modding, I'd rather offer an "official" process for it like @britzl mentioned rather than dealing with people ripping and changing the source files without restriction.

The concern/anxiety of course refers to how this project looks like pure wizardry to me. Really impressive.

---

**Potota** - _November 2020_

Referring to Denis_Makhortov: "how much is the source code protected?"

There are currently two layers of protection in place against decompiling source code:

1. The code is encrypted using a static key and algorithm that are both available in plain text in the Defold repo
2. Even after decrypting it, decompiling code is very difficult, and there aren't any tools online that can completely decompile LuaJIT (though some do come close)
