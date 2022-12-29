
Warning: well aware this isn't best practices. We're trading off speed of prototyping/concept validation, for scaleable robust data science. We should revisit these prompts with larger data sets, more clear and pre-defined success critiera, and witheld validation sets.

## Development Approach

We're using the following N "quotes" to test new prompts. Each should produce a good response (as defined by the metric "how Steve feels at the moment he reads it"... like I said, room for improvement here). At least we're testing each prompt on the same set and watching for regressions.

## Known soft spots

 - Question/Convo Switching: can switch into "2 person conversation" when the quote includes a question. Instead of the responses being follow ups, it generates responses that another person would say, but don't make sense for a "next sentence" generator.
 - Too specific: responses can be too specific ("Do you want to get lunch?" when it doesn't know time of day, and should say "do you want to get something to eat")
 - Missing context: see general context problems, but it's offering to do things a person with a disability can't do and wouldn't say

 ## Development quotes 

The following set of quotes are used for development. New prompt version should perform better on this set (tradeoffs expected). Add new problematic quotes to this list to ensure a very minimal level of improvement over time, and not just over-fitting to latest failure.

### Issues / concerns

 - "I'm feeling a bit chilly."
 - "I'm hungry!"

### Conversational

 - "How is school going?"
