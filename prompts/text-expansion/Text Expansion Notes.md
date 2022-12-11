
### One Line

Expand text, allowing them to type much less, while communicating their meaning in a well formed friendly way.

### Current State

**Current preferred prompt:** GTP3_davinci-003/v4.txt 

**Status:** Very rough prompt engineering, minimal tuning, lots to learn. No well defined test or validation sets. Really early, and seeing if there's something here worth pushing deeper on. Goal is to see great potential sometimes, before optimizing.

### Inspiration

This is inspired by real conversations. Often it takes too long to write out fully formed sentences, so instead the speaker will just give you one or two words: "hungry", "how school", "my jacket". Those around them who know how to speak to them will ask a few quick follow up questions to quickly get to the meaning with only nods. As and example, hungry would lead to: "are you hungry?" "are you offering us food?", and we'd quickly arrive at an understanding, faster and with less text entry. 

This works but has 2 downsides:
1) To express themselves quickly the speaker needs to ask for help
2) It only works with people who know the system, and the system is different for each person.

With text expansion, we want to move the rapid fire question round onto the speaker's iPad, and allow them to express themselves correctly, eloquently, and quickly, to anyone, without assistance.

### Goals

 - expand short versions into longer. "cold" -> "I am cold."
 - correct grammar and spelling errors
 - make the responses sound natural. Provide a friendly and casual tone good for social conversations.
 - Provide unique meanings if the original meaning is at all ambiguous. Example: "cold" could be "I am cold" or "Are you cold?". Important there is variety, and we find the correct one most of the time.
 - produce ~6 options

 ### Non-goals

 At least to start we aren't tackling:

  - control tone. Let's aim for friendly+casual. No need for professional, funny, angry, etc. Controlling tone might be cool, but we'll tackle that separately and later.


